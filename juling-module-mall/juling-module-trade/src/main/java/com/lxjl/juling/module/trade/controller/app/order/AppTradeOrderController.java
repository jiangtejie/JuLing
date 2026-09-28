package com.lxjl.juling.module.trade.controller.app.order;

import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.trade.controller.app.order.vo.*;
import com.lxjl.juling.module.trade.controller.app.order.vo.item.AppTradeOrderItemCommentCreateReqVO;
import com.lxjl.juling.module.trade.controller.app.order.vo.item.AppTradeOrderItemRespVO;
import com.lxjl.juling.module.trade.convert.order.TradeOrderConvert;
import com.lxjl.juling.module.trade.dal.dataobject.delivery.DeliveryExpressDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderItemDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderPaymentProofDO;
import com.lxjl.juling.module.trade.enums.order.TradeOrderStatusEnum;
import com.lxjl.juling.module.trade.framework.order.config.TradeOrderProperties;
import com.lxjl.juling.module.trade.service.aftersale.AfterSaleService;
import com.lxjl.juling.module.trade.service.delivery.DeliveryExpressService;
import com.lxjl.juling.module.trade.service.order.TradeOrderPaymentProofService;
import com.lxjl.juling.module.trade.service.order.TradeOrderQueryService;
import com.lxjl.juling.module.trade.service.order.TradeOrderStoreService;
import com.lxjl.juling.module.trade.service.order.TradeOrderUpdateService;
import com.lxjl.juling.module.trade.service.price.TradePriceService;
import com.google.common.collect.Maps;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.Parameters;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.annotation.security.PermitAll;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

import static com.lxjl.juling.framework.common.pojo.CommonResult.success;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertSet;
import static com.lxjl.juling.framework.security.core.util.SecurityFrameworkUtils.getLoginUserId;

@Tag(name = "用户 App - 交易订单")
@RestController
@RequestMapping("/trade/order")
@Validated
@Slf4j
public class AppTradeOrderController {

    @Resource
    private TradeOrderUpdateService tradeOrderUpdateService;
    @Resource
    private TradeOrderQueryService tradeOrderQueryService;
    @Resource
    private DeliveryExpressService deliveryExpressService;
    @Resource
    private AfterSaleService afterSaleService;
    @Resource
    private TradePriceService priceService;
    @Resource
    private TradeOrderPaymentProofService tradeOrderPaymentProofService;
    @Resource
    private TradeOrderStoreService tradeOrderStoreService;

    @Resource
    private TradeOrderProperties tradeOrderProperties;

    @GetMapping("/store-list")
    @Operation(summary = "获得可下单门店列表", description = "门店订货链：代理商账号可切换其名下门店下单")
    public CommonResult<List<AppTradeOrderStoreRespVO>> getStoreList() {
        return success(BeanUtils.toBean(tradeOrderStoreService.getStoreList(getLoginUserId()),
                AppTradeOrderStoreRespVO.class));
    }

    @GetMapping("/settlement")
    @Operation(summary = "获得订单结算信息")
    public CommonResult<AppTradeOrderSettlementRespVO> settlementOrder(@Valid AppTradeOrderSettlementReqVO settlementReqVO) {
        return success(tradeOrderUpdateService.settlementOrder(getLoginUserId(), settlementReqVO));
    }

    @GetMapping("/settlement-product")
    @Operation(summary = "获得商品结算信息", description = "用于商品列表、商品详情，获得参与活动后的价格信息")
    @Parameter(name = "spuIds", description = "商品 SPU 编号数组")
    @PermitAll
    public CommonResult<List<AppTradeProductSettlementRespVO>> settlementProduct(@RequestParam("spuIds") List<Long> spuIds) {
        return success(priceService.calculateProductPrice(getLoginUserId(), spuIds));
    }

    @PostMapping("/create")
    @Operation(summary = "创建订单")
    public CommonResult<AppTradeOrderCreateRespVO> createOrder(@Valid @RequestBody AppTradeOrderCreateReqVO createReqVO) {
        TradeOrderDO order = tradeOrderUpdateService.createOrder(getLoginUserId(), createReqVO);
        return success(new AppTradeOrderCreateRespVO().setId(order.getId()).setPayOrderId(order.getPayOrderId()));
    }

    @PostMapping("/payment-proof/create")
    @Operation(summary = "提交订单付款凭证", description = "线下收款：上传付款截图，支持多次上传；核验进度见订单收款状态")
    public CommonResult<Long> createPaymentProof(@Valid @RequestBody AppTradeOrderPaymentProofCreateReqVO createReqVO) {
        return success(tradeOrderPaymentProofService.createPaymentProof(getLoginUserId(), createReqVO));
    }

    @GetMapping("/payment-proof/list")
    @Operation(summary = "获得订单的付款凭证列表", description = "只能查询自己的订单")
    @Parameter(name = "orderId", description = "交易订单编号", required = true, example = "1024")
    public CommonResult<List<AppTradeOrderPaymentProofRespVO>> getPaymentProofList(@RequestParam("orderId") Long orderId) {
        List<TradeOrderPaymentProofDO> list = tradeOrderPaymentProofService
                .getPaymentProofListByOrderId(getLoginUserId(), orderId);
        return success(BeanUtils.toBean(list, AppTradeOrderPaymentProofRespVO.class));
    }

    @GetMapping("/get-detail")
    @Operation(summary = "获得交易订单")
    @Parameter(name = "id", description = "交易订单编号")
    public CommonResult<AppTradeOrderDetailRespVO> getOrderDetail(@RequestParam("id") Long id) {
        // 1.1 查询订单（线下收款：没有支付单需要同步）
        TradeOrderDO order = tradeOrderQueryService.getOrder(getLoginUserId(), id);
        if (order == null) {
            return success(null);
        }

        // 2.1 查询订单项
        List<TradeOrderItemDO> orderItems = tradeOrderQueryService.getOrderItemListByOrderId(order.getId());
        // 2.2 查询物流公司
        DeliveryExpressDO express = order.getLogisticsId() != null && order.getLogisticsId() > 0 ?
                deliveryExpressService.getDeliveryExpress(order.getLogisticsId()) : null;
        // 2.3 最终组合
        return success(TradeOrderConvert.INSTANCE.convert02(order, orderItems, tradeOrderProperties, express));
    }

    @GetMapping("/get-express-track-list")
    @Operation(summary = "获得交易订单的物流轨迹")
    @Parameter(name = "id", description = "交易订单编号")
    public CommonResult<List<AppOrderExpressTrackRespDTO>> getOrderExpressTrackList(@RequestParam("id") Long id) {
        return success(TradeOrderConvert.INSTANCE.convertList02(
                tradeOrderQueryService.getExpressTrackList(id, getLoginUserId())));
    }

    @GetMapping("/page")
    @Operation(summary = "获得交易订单分页")
    public CommonResult<PageResult<AppTradeOrderPageItemRespVO>> getOrderPage(AppTradeOrderPageReqVO reqVO) {
        // 查询订单
        PageResult<TradeOrderDO> pageResult = tradeOrderQueryService.getOrderPage(getLoginUserId(), reqVO);
        // 查询订单项
        List<TradeOrderItemDO> orderItems = tradeOrderQueryService.getOrderItemListByOrderId(
                convertSet(pageResult.getList(), TradeOrderDO::getId));
        // 最终组合
        return success(TradeOrderConvert.INSTANCE.convertPage02(pageResult, orderItems));
    }

    @GetMapping("/get-count")
    @Operation(summary = "获得交易订单数量")
    public CommonResult<Map<String, Long>> getOrderCount() {
        Map<String, Long> orderCount = Maps.newLinkedHashMapWithExpectedSize(5);
        // 全部
        orderCount.put("allCount", tradeOrderQueryService.getOrderCount(getLoginUserId(), null, null));
        // 待付款（未支付）
        orderCount.put("unpaidCount", tradeOrderQueryService.getOrderCount(getLoginUserId(),
                TradeOrderStatusEnum.UNPAID.getStatus(), null));
        // 待发货
        orderCount.put("undeliveredCount", tradeOrderQueryService.getOrderCount(getLoginUserId(),
                TradeOrderStatusEnum.UNDELIVERED.getStatus(), null));
        // 待收货
        orderCount.put("deliveredCount", tradeOrderQueryService.getOrderCount(getLoginUserId(),
                TradeOrderStatusEnum.DELIVERED.getStatus(), null));
        // 待评价
        orderCount.put("uncommentedCount", tradeOrderQueryService.getOrderCount(getLoginUserId(),
                TradeOrderStatusEnum.COMPLETED.getStatus(), false));
        // 售后数量
        orderCount.put("afterSaleCount", afterSaleService.getApplyingAfterSaleCount(getLoginUserId()));
        return success(orderCount);
    }

    @PutMapping("/receive")
    @Operation(summary = "确认交易订单收货")
    @Parameter(name = "id", description = "交易订单编号")
    public CommonResult<Boolean> receiveOrder(@RequestParam("id") Long id) {
        tradeOrderUpdateService.receiveOrderByMember(getLoginUserId(), id);
        return success(true);
    }

    @DeleteMapping("/cancel")
    @Operation(summary = "取消交易订单")
    @Parameter(name = "id", description = "交易订单编号")
    public CommonResult<Boolean> cancelOrder(@RequestParam("id") Long id) {
        tradeOrderUpdateService.cancelOrderByMember(getLoginUserId(), id);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除交易订单")
    @Parameter(name = "id", description = "交易订单编号")
    public CommonResult<Boolean> deleteOrder(@RequestParam("id") Long id) {
        tradeOrderUpdateService.deleteOrder(getLoginUserId(), id);
        return success(true);
    }

    // ========== 订单项 ==========

    @GetMapping("/item/get")
    @Operation(summary = "获得交易订单项")
    @Parameter(name = "id", description = "交易订单项编号")
    public CommonResult<AppTradeOrderItemRespVO> getOrderItem(@RequestParam("id") Long id) {
        TradeOrderItemDO item = tradeOrderQueryService.getOrderItem(getLoginUserId(), id);
        return success(TradeOrderConvert.INSTANCE.convert03(item));
    }

    @PostMapping("/item/create-comment")
    @Operation(summary = "创建交易订单项的评价")
    public CommonResult<Long> createOrderItemComment(@RequestBody AppTradeOrderItemCommentCreateReqVO createReqVO) {
        return success(tradeOrderUpdateService.createOrderItemCommentByMember(getLoginUserId(), createReqVO));
    }

}
