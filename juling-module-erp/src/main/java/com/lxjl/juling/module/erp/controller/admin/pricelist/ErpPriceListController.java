package com.lxjl.juling.module.erp.controller.admin.pricelist;

import com.lxjl.juling.framework.apilog.core.annotation.ApiAccessLog;
import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.common.pojo.PageParam;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.framework.excel.core.util.ExcelUtils;
import com.lxjl.juling.module.erp.controller.admin.pricelist.vo.ErpPriceListPageReqVO;
import com.lxjl.juling.module.erp.controller.admin.pricelist.vo.ErpPriceListRespVO;
import com.lxjl.juling.module.erp.controller.admin.pricelist.vo.ErpPriceListSaveReqVO;
import com.lxjl.juling.module.erp.controller.admin.pricelist.vo.ErpPriceMatchRespVO;
import com.lxjl.juling.module.erp.dal.dataobject.pricelist.ErpPriceListDO;
import com.lxjl.juling.module.erp.dal.dataobject.pricelist.ErpPriceListItemDO;
import com.lxjl.juling.module.erp.dal.dataobject.pricelist.ErpPriceListScopeDO;
import com.lxjl.juling.module.erp.dal.dataobject.product.ErpProductDO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpSupplierDO;
import com.lxjl.juling.module.erp.enums.ErpPriceTypeEnum;
import com.lxjl.juling.module.erp.service.pricelist.ErpPriceListService;
import com.lxjl.juling.module.erp.service.product.ErpProductService;
import com.lxjl.juling.module.erp.service.purchase.ErpSupplierService;
import com.lxjl.juling.module.system.api.user.AdminUserApi;
import com.lxjl.juling.module.system.api.user.dto.AdminUserRespDTO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import static com.lxjl.juling.framework.apilog.core.enums.OperateTypeEnum.EXPORT;
import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.pojo.CommonResult.success;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.*;
import static com.lxjl.juling.module.erp.enums.ErrorCodeConstants.PRICE_LIST_NOT_EXISTS;

/**
 * 价目表 Controller
 *
 * <p>采购价目表与配送价目表**共用本 Controller**，靠 priceType 区分（见 sql/local/69 的评估说明）。
 * 采购的适用范围对象是供应商，配送的是门店。
 */
@Tag(name = "管理后台 - 价目表")
@RestController
@RequestMapping("/erp/price-list")
@Validated
public class ErpPriceListController {

    @Resource
    private ErpPriceListService priceListService;
    @Resource
    private ErpSupplierService supplierService;
    @Resource
    private ErpProductService productService;
    @Resource
    private AdminUserApi adminUserApi;
    @Resource
    private com.lxjl.juling.module.erp.dal.mysql.sale.ErpCustomerMapper customerMapper;

    @PostMapping("/create")
    @Operation(summary = "创建价目表")
    @PreAuthorize("@ss.hasPermission('erp:price-list:create')")
    public CommonResult<Long> createPriceList(@Valid @RequestBody ErpPriceListSaveReqVO createReqVO) {
        return success(priceListService.createPriceList(createReqVO));
    }

    @PutMapping("/update")
    @Operation(summary = "更新价目表", description = "适用范围与明细整体替换（先删后插）；类型不可改")
    @PreAuthorize("@ss.hasPermission('erp:price-list:update')")
    public CommonResult<Boolean> updatePriceList(@Valid @RequestBody ErpPriceListSaveReqVO updateReqVO) {
        priceListService.updatePriceList(updateReqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除价目表")
    @Parameter(name = "id", description = "编号", required = true)
    @PreAuthorize("@ss.hasPermission('erp:price-list:delete')")
    public CommonResult<Boolean> deletePriceList(@RequestParam("id") Long id) {
        priceListService.deletePriceList(id);
        return success(true);
    }

    @DeleteMapping("/delete-list")
    @Operation(summary = "批量删除价目表")
    @PreAuthorize("@ss.hasPermission('erp:price-list:delete')")
    public CommonResult<Boolean> deletePriceListList(@RequestParam("ids") List<Long> ids) {
        priceListService.deletePriceListList(ids);
        return success(true);
    }

    @GetMapping("/get")
    @Operation(summary = "获得价目表（含适用范围与明细）")
    @PreAuthorize("@ss.hasPermission('erp:price-list:query')")
    public CommonResult<ErpPriceListRespVO> getPriceList(@RequestParam("id") Long id) {
        ErpPriceListDO priceList = priceListService.getPriceList(id);
        if (priceList == null) {
            throw exception(PRICE_LIST_NOT_EXISTS);
        }
        ErpPriceListRespVO vo = BeanUtils.toBean(priceList, ErpPriceListRespVO.class);
        List<ErpPriceListRespVO.Scope> scopes = BeanUtils.toBean(
                priceListService.getScopeList(id), ErpPriceListRespVO.Scope.class);
        fillPartnerName(priceList.getPriceType(), scopes);
        vo.setScopes(scopes);
        List<ErpPriceListRespVO.Item> items = BeanUtils.toBean(
                priceListService.getItemList(id), ErpPriceListRespVO.Item.class);
        fillProductInfo(items);
        vo.setItems(items);
        vo.setItemCount(items.size());
        fillPricerName(List.of(vo));
        return success(vo);
    }

    @GetMapping("/page")
    @Operation(summary = "获得价目表分页")
    @PreAuthorize("@ss.hasPermission('erp:price-list:query')")
    public CommonResult<PageResult<ErpPriceListRespVO>> getPriceListPage(@Valid ErpPriceListPageReqVO pageReqVO) {
        PageResult<ErpPriceListDO> pageResult = priceListService.getPriceListPage(pageReqVO);
        PageResult<ErpPriceListRespVO> result = BeanUtils.toBean(pageResult, ErpPriceListRespVO.class);
        fillPricerName(result.getList());
        if (!result.getList().isEmpty()) {
            List<Long> ids = convertList(result.getList(), ErpPriceListRespVO::getId);
            Map<Long, List<ErpPriceListItemDO>> itemMap = convertMultiMap(
                    priceListService.getItemListByPriceIds(ids), ErpPriceListItemDO::getPriceId);
            Map<Long, List<ErpPriceListScopeDO>> scopeMap = convertMultiMap(
                    priceListService.getScopeListByPriceIds(ids), ErpPriceListScopeDO::getPriceId);
            // 适用范围名：一次取回供应商与门店，避免 N+1
            Map<Long, String> partnerNameMap = loadPartnerNameMap(pageReqVO.getPriceType(),
                    convertList(scopeMap.values(), list -> convertSet(list, ErpPriceListScopeDO::getPartnerId)));
            result.getList().forEach(vo -> {
                List<ErpPriceListScopeDO> scopes = scopeMap.getOrDefault(vo.getId(), List.of());
                vo.setItemCount(itemMap.getOrDefault(vo.getId(), List.of()).size());
                vo.setIsDefault(scopes.stream().anyMatch(s -> Boolean.TRUE.equals(s.getIsDefault())));
                vo.setScopeSummary(scopes.stream()
                        .map(s -> s.getPartnerId() == null ? "通用（不限）" : partnerNameMap.getOrDefault(s.getPartnerId(), "-"))
                        .distinct().reduce((a, b) -> a + "、" + b).orElse("通用（不限）"));
            });
        }
        return success(result);
    }

    @GetMapping("/export-excel")
    @Operation(summary = "导出价目表 Excel")
    @PreAuthorize("@ss.hasPermission('erp:price-list:export')")
    @ApiAccessLog(operateType = EXPORT)
    public void exportPriceListExcel(@Valid ErpPriceListPageReqVO pageReqVO,
                                     HttpServletResponse response) throws IOException {
        pageReqVO.setPageSize(PageParam.PAGE_SIZE_NONE);
        List<ErpPriceListDO> list = priceListService.getPriceListPage(pageReqVO).getList();
        List<ErpPriceListRespVO> vos = BeanUtils.toBean(list, ErpPriceListRespVO.class);
        fillPricerName(vos);
        ExcelUtils.write(response, "价目表.xls", "数据", ErpPriceListRespVO.class, vos);
    }

    @GetMapping("/match")
    @Operation(summary = "取价", description = "按「类型 + 适用对象 + 物料 + 日期」取适用单价与税率；没命中时兜底取物料主数据上的价格")
    public CommonResult<ErpPriceMatchRespVO> matchPrice(
            @RequestParam("priceType") String priceType,
            @RequestParam(value = "partnerId", required = false) Long partnerId,
            @RequestParam("productId") Long productId,
            @RequestParam(value = "date", required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate date) {
        // 故意不加 @PreAuthorize：这是采购订单 / 门店订货录入时的辅助取价，与 simple-list 同性质
        return success(priceListService.matchPrice(priceType, partnerId, productId, date));
    }

    /** 补定价员名称 */
    private void fillPricerName(List<ErpPriceListRespVO> list) {
        Map<Long, AdminUserRespDTO> userMap = adminUserApi.getUserMap(
                convertSet(list, ErpPriceListRespVO::getPricerUserId));
        list.forEach(vo -> {
            AdminUserRespDTO user = userMap.get(vo.getPricerUserId());
            if (user != null) {
                vo.setPricerUserName(user.getNickname());
            }
        });
    }

    /** 适用范围里的对象名：采购取供应商、配送取门店 */
    private void fillPartnerName(String priceType, List<ErpPriceListRespVO.Scope> scopes) {
        Map<Long, String> nameMap = loadPartnerNameMap(priceType,
                List.of(convertSet(scopes, ErpPriceListRespVO.Scope::getPartnerId)));
        scopes.forEach(scope -> scope.setPartnerName(scope.getPartnerId() == null
                ? "通用（不限）" : nameMap.getOrDefault(scope.getPartnerId(), "-")));
    }

    private Map<Long, String> loadPartnerNameMap(String priceType, List<java.util.Set<Long>> idGroups) {
        List<Long> ids = idGroups.stream().flatMap(java.util.Collection::stream)
                .filter(Objects::nonNull).distinct().toList();
        if (ids.isEmpty()) {
            return Map.of();
        }
        if (ErpPriceTypeEnum.DELIVERY.getType().equals(priceType)) {
            return convertMap(customerMapper.selectByIds(ids), ErpCustomerDO -> ErpCustomerDO.getId(), ErpCustomerDO -> ErpCustomerDO.getName());
        }
        Map<Long, ErpSupplierDO> supplierMap = convertMap(supplierService.getSupplierList(ids), ErpSupplierDO::getId);
        Map<Long, String> result = new java.util.HashMap<>();
        supplierMap.forEach((k, v) -> result.put(k, v.getName()));
        return result;
    }

    /** 补物料编码 / 名称 / 规格 / 计价单位 */
    private void fillProductInfo(List<ErpPriceListRespVO.Item> items) {
        if (items.isEmpty()) {
            return;
        }
        Map<Long, com.lxjl.juling.module.erp.controller.admin.product.vo.product.ErpProductRespVO> productMap =
                productService.getProductVOMap(convertSet(items, ErpPriceListRespVO.Item::getProductId));
        items.forEach(item -> {
            var product = productMap.get(item.getProductId());
            if (product == null) {
                return;
            }
            item.setProductCode(product.getCode());
            item.setProductName(product.getName());
            item.setUnitName(product.getUnitName());
            item.setSpec(product.getStandard());
            if (item.getPrice() != null) {
                BigDecimal rate = item.getTaxPercent() == null ? BigDecimal.ZERO : item.getTaxPercent();
                item.setTaxPrice(item.getPrice().multiply(BigDecimal.ONE.add(rate.divide(BigDecimal.valueOf(100)))));
            }
        });
    }

}
