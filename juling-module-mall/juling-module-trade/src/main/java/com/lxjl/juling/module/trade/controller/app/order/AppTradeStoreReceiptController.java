package com.lxjl.juling.module.trade.controller.app.order;

import cn.hutool.core.collection.CollUtil;
import com.lxjl.juling.framework.common.enums.UserTypeEnum;
import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.collection.MapUtils;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.framework.security.core.util.SecurityFrameworkUtils;
import com.lxjl.juling.module.erp.api.customer.ErpCustomerApi;
import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerRespDTO;
import com.lxjl.juling.module.erp.api.product.ErpProductApi;
import com.lxjl.juling.module.erp.api.product.dto.ErpProductRespDTO;
import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeStoreReceiptCreateReqVO;
import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeStoreReceiptPendingRespVO;
import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeStoreReceiptRespVO;
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
import jakarta.validation.Valid;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.Objects;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.pojo.CommonResult.success;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertMap;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertSet;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.ORDER_NOT_FOUND;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.ORDER_RECEIPT_NOT_EXISTS;

/**
 * 用户 App - 门店收货（待收货列表 / 收货详情 / 确认收货）
 *
 * 归属校验：收货单上的 memberUserId = 下单账号（trade_order.user_id），
 * 与当前登录会员不一致一律按「订单不存在」处理，避免越权看到别家门店的配送明细。
 *
 * @author 亚特
 */
@Tag(name = "用户 App - 门店收货")
@RestController
@RequestMapping("/trade/order/store-receipt")
@Validated
public class AppTradeStoreReceiptController {

    @Resource
    private TradeStoreReceiptService storeReceiptService;

    @Resource
    private ErpCustomerApi erpCustomerApi;
    @Resource
    private ErpProductApi erpProductApi;

    @GetMapping("/pending-page")
    @Operation(summary = "获得我的待收货分页（门店待收货列表）")
    public CommonResult<PageResult<AppTradeStoreReceiptPendingRespVO>> getPendingPage(
            @RequestParam(value = "pageNo", required = false) Integer pageNo,
            @RequestParam(value = "pageSize", required = false) Integer pageSize) {
        PageResult<TradeOrderReceiptDO> pageResult = storeReceiptService.getPendingPageByMember(
                getLoginUserId(), pageNo, pageSize);
        return success(new PageResult<>(buildPendingVOList(pageResult.getList()), pageResult.getTotal()));
    }

    @GetMapping("/get")
    @Operation(summary = "获得订单的收货单（待确认时用于填写实收数量）")
    @Parameter(name = "orderId", description = "门店要货单编号", required = true, example = "1")
    public CommonResult<AppTradeStoreReceiptRespVO> get(@RequestParam("orderId") Long orderId) {
        TradeOrderReceiptDO receipt = storeReceiptService.getReceiptByOrderId(orderId);
        validateBelongToLoginUser(receipt);
        AppTradeStoreReceiptRespVO vo = BeanUtils.toBean(receipt, AppTradeStoreReceiptRespVO.class);
        if (vo == null) {
            return success(null);
        }
        vo.setStatusName(TradeStoreReceiptStatusEnum.getName(vo.getStatus()));
        vo.setDiffTypeName(TradeStoreReceiptDiffTypeEnum.getName(vo.getDiffType()));
        MapUtils.findAndThen(customerMap(List.of(receipt)), vo.getCustomerId(),
                customer -> vo.setCustomerName(customer.getName()));
        List<TradeOrderReceiptItemDO> items = storeReceiptService.getReceiptItemList(receipt.getId());
        vo.setItems(buildItemVOList(items));
        return success(vo);
    }

    @PostMapping("/create")
    @Operation(summary = "确认收货（提交实收数量，可多收/少收/破损）")
    public CommonResult<Long> create(@Valid @RequestBody AppTradeStoreReceiptCreateReqVO reqVO) {
        TradeOrderReceiptDO receipt = storeReceiptService.getReceiptByOrderId(reqVO.getOrderId());
        validateBelongToLoginUser(receipt);
        return success(storeReceiptService.submitReceipt(new TradeStoreReceiptSubmitReqBO()
                .setOrderId(reqVO.getOrderId())
                .setReceiverName(reqVO.getReceiverName()).setReceiverMobile(reqVO.getReceiverMobile())
                .setFileUrls(reqVO.getFileUrls()).setRemark(reqVO.getRemark())
                .setOperatorUserId(getLoginUserId())
                .setOperatorUserType(UserTypeEnum.MEMBER.getValue())
                .setItems(BeanUtils.toBean(reqVO.getItems(), TradeStoreReceiptSubmitReqBO.Item.class))));
    }

    // ==================== 内部方法 ====================

    private Long getLoginUserId() {
        return SecurityFrameworkUtils.getLoginUserId();
    }

    /**
     * 收货单必须属于当前登录会员；不存在时抛「订单不存在」，不泄露别家门店信息
     */
    private void validateBelongToLoginUser(TradeOrderReceiptDO receipt) {
        if (receipt == null) {
            throw exception(ORDER_RECEIPT_NOT_EXISTS);
        }
        if (!Objects.equals(receipt.getMemberUserId(), getLoginUserId())) {
            throw exception(ORDER_NOT_FOUND);
        }
    }

    private Map<Long, ErpCustomerRespDTO> customerMap(List<TradeOrderReceiptDO> list) {
        return convertMap(erpCustomerApi.getCustomerList(convertSet(list, TradeOrderReceiptDO::getCustomerId)),
                ErpCustomerRespDTO::getId);
    }

    private List<AppTradeStoreReceiptPendingRespVO> buildPendingVOList(List<TradeOrderReceiptDO> list) {
        if (CollUtil.isEmpty(list)) {
            return List.of();
        }
        Map<Long, ErpCustomerRespDTO> customerMap = customerMap(list);
        return BeanUtils.toBean(list, AppTradeStoreReceiptPendingRespVO.class, vo -> {
            MapUtils.findAndThen(customerMap, vo.getCustomerId(), customer -> vo.setCustomerName(customer.getName()));
            vo.setStatusName(TradeStoreReceiptStatusEnum.getName(vo.getStatus()));
            vo.setDiffTypeName(TradeStoreReceiptDiffTypeEnum.getName(vo.getDiffType()));
        });
    }

    private List<AppTradeStoreReceiptRespVO.Item> buildItemVOList(List<TradeOrderReceiptItemDO> items) {
        if (CollUtil.isEmpty(items)) {
            return List.of();
        }
        Map<Long, ErpProductRespDTO> productMap = convertMap(
                erpProductApi.getProductList(convertSet(items, TradeOrderReceiptItemDO::getProductId)),
                ErpProductRespDTO::getId);
        return BeanUtils.toBean(items, AppTradeStoreReceiptRespVO.Item.class, vo ->
                MapUtils.findAndThen(productMap, vo.getProductId(), product -> vo.setProductName(product.getName())));
    }

}
