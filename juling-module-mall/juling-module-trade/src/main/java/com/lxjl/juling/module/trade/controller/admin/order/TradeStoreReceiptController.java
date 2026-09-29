package com.lxjl.juling.module.trade.controller.admin.order;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.NumberUtil;
import com.lxjl.juling.framework.apilog.core.annotation.ApiAccessLog;
import com.lxjl.juling.framework.common.enums.UserTypeEnum;
import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.common.pojo.PageParam;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.collection.MapUtils;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.framework.excel.core.util.ExcelUtils;
import com.lxjl.juling.framework.security.core.util.SecurityFrameworkUtils;
import com.lxjl.juling.module.erp.api.customer.ErpCustomerApi;
import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerRespDTO;
import com.lxjl.juling.module.erp.api.product.ErpProductApi;
import com.lxjl.juling.module.erp.api.product.dto.ErpProductRespDTO;
import com.lxjl.juling.module.erp.api.stock.ErpStoreStockApi;
import com.lxjl.juling.module.system.api.dept.DeptApi;
import com.lxjl.juling.module.system.api.dept.dto.DeptRespDTO;
import com.lxjl.juling.module.system.api.user.AdminUserApi;
import com.lxjl.juling.module.system.api.user.dto.AdminUserRespDTO;
import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeStoreReceiptCreateReqVO;
import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeStoreReceiptPageReqVO;
import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeStoreReceiptRespVO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderReceiptDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderReceiptItemDO;
import com.lxjl.juling.module.trade.enums.order.TradeStoreReceiptDiffTypeEnum;
import com.lxjl.juling.module.trade.enums.order.TradeStoreReceiptStatusEnum;
import com.lxjl.juling.module.trade.service.order.TradeStoreReceiptService;
import com.lxjl.juling.module.trade.service.order.bo.TradeStoreReceiptSubmitReqBO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

import static com.lxjl.juling.framework.apilog.core.enums.OperateTypeEnum.EXPORT;
import static com.lxjl.juling.framework.common.pojo.CommonResult.success;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertMap;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertSet;

/**
 * 管理后台 - 门店收货单
 *
 * 收货单由「ERP 配送出库单审核」自动生成（待确认），门店在 H5 确认；
 * 后台的职责是**查询/对账 + 代录**（门店不会用手机时由供应链代录），以及作废未确认的收货单。
 * 已确认的收货单不允许作废（库存与往来账已入账），撤销要走门店退货流程。
 *
 * @author 亚特
 */
@Tag(name = "管理后台 - 门店收货单")
@RestController
@RequestMapping("/trade/store-receipt")
@Validated
public class TradeStoreReceiptController {

    @Resource
    private TradeStoreReceiptService storeReceiptService;

    @Resource
    private ErpCustomerApi erpCustomerApi;
    @Resource
    private ErpProductApi erpProductApi;
    @Resource
    private ErpStoreStockApi erpStoreStockApi;
    @Resource
    private DeptApi deptApi;
    @Resource
    private AdminUserApi adminUserApi;

    @GetMapping("/page")
    @Operation(summary = "获得门店收货单分页")
    @PreAuthorize("@ss.hasPermission('trade:store-receipt:query')")
    public CommonResult<PageResult<TradeStoreReceiptRespVO>> getPage(@Valid TradeStoreReceiptPageReqVO pageReqVO) {
        PageResult<TradeOrderReceiptDO> pageResult = storeReceiptService.getReceiptPage(pageReqVO);
        return success(new PageResult<>(buildVOList(pageResult.getList()), pageResult.getTotal()));
    }

    @GetMapping("/get")
    @Operation(summary = "获得门店收货单（含明细）")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('trade:store-receipt:query')")
    public CommonResult<TradeStoreReceiptRespVO> get(@RequestParam("id") Long id) {
        TradeOrderReceiptDO receipt = storeReceiptService.getReceipt(id);
        if (receipt == null) {
            return success(null);
        }
        TradeStoreReceiptRespVO vo = buildVOList(List.of(receipt)).get(0);
        vo.setItems(buildItemVOList(storeReceiptService.getReceiptItemList(id)));
        return success(vo);
    }

    @PostMapping("/create")
    @Operation(summary = "代录门店收货（门店不会用 H5 时由供应链代录）")
    @PreAuthorize("@ss.hasPermission('trade:store-receipt:create')")
    public CommonResult<Long> create(@Valid @RequestBody TradeStoreReceiptCreateReqVO reqVO) {
        return success(storeReceiptService.submitReceipt(new TradeStoreReceiptSubmitReqBO()
                .setOrderId(reqVO.getOrderId())
                .setReceiverName(reqVO.getReceiverName()).setReceiverMobile(reqVO.getReceiverMobile())
                .setFileUrls(reqVO.getFileUrls()).setRemark(reqVO.getRemark())
                .setOperatorUserId(SecurityFrameworkUtils.getLoginUserId())
                .setOperatorUserType(UserTypeEnum.ADMIN.getValue())
                .setItems(BeanUtils.toBean(reqVO.getItems(), TradeStoreReceiptSubmitReqBO.Item.class))));
    }

    @PostMapping("/cancel")
    @Operation(summary = "作废门店收货单（只允许待确认状态）")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @Parameter(name = "reason", description = "作废原因", example = "重复生成")
    @PreAuthorize("@ss.hasPermission('trade:store-receipt:cancel')")
    public CommonResult<Boolean> cancel(@RequestParam("id") Long id,
                                        @RequestParam(value = "reason", required = false) String reason) {
        storeReceiptService.cancelReceipt(id, reason);
        return success(true);
    }

    @GetMapping("/export-excel")
    @Operation(summary = "导出门店收货单 Excel")
    @PreAuthorize("@ss.hasPermission('trade:store-receipt:export')")
    @ApiAccessLog(operateType = EXPORT)
    public void exportExcel(@Valid TradeStoreReceiptPageReqVO exportReqVO,
                           HttpServletResponse response) throws IOException {
        exportReqVO.setPageSize(PageParam.PAGE_SIZE_NONE);
        List<TradeOrderReceiptDO> list = storeReceiptService.getReceiptPage(exportReqVO).getList();
        ExcelUtils.write(response, "门店收货单.xlsx", "数据", TradeStoreReceiptRespVO.class, buildVOList(list));
    }

    // ==================== 组装 VO ====================

    private List<TradeStoreReceiptRespVO> buildVOList(List<TradeOrderReceiptDO> list) {
        if (CollUtil.isEmpty(list)) {
            return List.of();
        }
        Map<Long, ErpCustomerRespDTO> customerMap = convertMap(
                erpCustomerApi.getCustomerList(convertSet(list, TradeOrderReceiptDO::getCustomerId)),
                ErpCustomerRespDTO::getId);
        Map<Long, DeptRespDTO> deptMap = deptApi.getDeptMap(convertSet(list, TradeOrderReceiptDO::getDeptId));
        // creator 是「登录用户编号的字符串」，解析失败（系统写入）的要过滤掉，避免 selectByIds 收到 null
        Set<Long> creatorIds = list.stream().map(receipt -> parseUserId(receipt.getCreator()))
                .filter(Objects::nonNull).collect(Collectors.toSet());
        Map<Long, AdminUserRespDTO> userMap = adminUserApi.getUserMap(creatorIds);
        return BeanUtils.toBean(list, TradeStoreReceiptRespVO.class, vo -> {
            MapUtils.findAndThen(customerMap, vo.getCustomerId(), customer -> vo.setCustomerName(customer.getName()));
            MapUtils.findAndThen(deptMap, vo.getDeptId(), dept -> vo.setDeptName(dept.getName()));
            MapUtils.findAndThen(userMap, parseUserId(vo.getCreator()), user -> vo.setCreatorName(user.getNickname()));
            vo.setStatusName(TradeStoreReceiptStatusEnum.getName(vo.getStatus()));
            vo.setDiffTypeName(TradeStoreReceiptDiffTypeEnum.getName(vo.getDiffType()));
            if (vo.getWarehouseId() != null) {
                vo.setWarehouseName(erpStoreStockApi.getStoreWarehouseName(vo.getCustomerId()));
            }
        });
    }

    private List<TradeStoreReceiptRespVO.Item> buildItemVOList(List<TradeOrderReceiptItemDO> items) {
        if (CollUtil.isEmpty(items)) {
            return List.of();
        }
        Map<Long, ErpProductRespDTO> productMap = convertMap(
                erpProductApi.getProductList(convertSet(items, TradeOrderReceiptItemDO::getProductId)),
                ErpProductRespDTO::getId);
        return BeanUtils.toBean(items, TradeStoreReceiptRespVO.Item.class, vo ->
                MapUtils.findAndThen(productMap, vo.getProductId(), product -> vo.setProductName(product.getName())));
    }

    /**
     * BaseDO.creator 是「登录用户编号的字符串形式」，转成 Long 供 AdminUserApi 使用；
     * 解析失败（历史数据/系统任务写入的字符串）一律返回 null，不影响列表展示。
     */
    private Long parseUserId(String creator) {
        if (creator == null || !NumberUtil.isLong(creator)) {
            return null;
        }
        return Long.valueOf(creator);
    }

    @SuppressWarnings("unused")
    private static boolean isPending(Integer status) {
        return Objects.equals(TradeStoreReceiptStatusEnum.PENDING.getStatus(), status);
    }

}
