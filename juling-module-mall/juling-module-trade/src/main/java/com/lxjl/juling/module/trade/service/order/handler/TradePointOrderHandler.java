package com.lxjl.juling.module.trade.service.order.handler;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.lang.Assert;
import com.lxjl.juling.module.promotion.api.point.PointActivityApi;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderItemDO;
import com.lxjl.juling.module.trade.enums.order.TradeOrderStatusEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderTypeEnum;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Objects;

/**
 * 积分商城活动订单的 {@link TradeOrderHandler} 实现类
 *
 * @author 亚特
 */
@Component
public class TradePointOrderHandler implements TradeOrderHandler {

    @Resource
    private PointActivityApi pointActivityApi;

    @Override
    public void beforeOrderCreate(TradeOrderDO order, List<TradeOrderItemDO> orderItems) {
        if (!TradeOrderTypeEnum.isPoint(order.getType())) {
            return;
        }
        // 明确校验一下
        Assert.isTrue(orderItems.size() == 1, "积分商城活动兑换商品兑换时，只允许选择一个商品");
        // 注意：会员中心（会员积分账户）已下线，不再校验用户积分余额；订单的 usePoint 恒为 0

        // 扣减积分商城活动的库存
        pointActivityApi.updatePointStockDecr(order.getPointActivityId(),
                orderItems.get(0).getSkuId(), orderItems.get(0).getCount());

        // 如果支付金额为 0，则直接设置为已支付
        if (Objects.equals(order.getPayPrice(), 0)) {
            order.setPayStatus(true).setStatus(TradeOrderStatusEnum.UNDELIVERED.getStatus());
        }
    }

    @Override
    public void afterCancelOrder(TradeOrderDO order, List<TradeOrderItemDO> orderItems) {
        if (!TradeOrderTypeEnum.isPoint(order.getType())) {
            return;
        }
        // 明确校验一下
        Assert.isTrue(orderItems.size() == 1, "积分商城活动兑换商品兑换时，只允许选择一个商品");

        // 售后的订单项，已经在 afterCancelOrderItem 回滚库存，所以这里不需要重复回滚
        orderItems = filterOrderItemListByNoneAfterSale(orderItems);
        if (CollUtil.isEmpty(orderItems)) {
            return;
        }
        afterCancelOrderItem(order, orderItems.get(0));
    }

    @Override
    public void afterCancelOrderItem(TradeOrderDO order, TradeOrderItemDO orderItem) {
        if (!TradeOrderTypeEnum.isPoint(order.getType())) {
            return;
        }
        // 恢复积分商城活动的库存
        pointActivityApi.updatePointStockIncr(order.getPointActivityId(),
                orderItem.getSkuId(), orderItem.getCount());
    }

}
