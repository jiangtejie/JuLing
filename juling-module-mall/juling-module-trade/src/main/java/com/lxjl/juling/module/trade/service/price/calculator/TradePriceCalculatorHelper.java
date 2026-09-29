package com.lxjl.juling.module.trade.service.price.calculator;

import cn.hutool.core.lang.Assert;
import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.module.product.api.sku.dto.ProductSkuRespDTO;
import com.lxjl.juling.module.product.api.spu.dto.ProductSpuRespDTO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderItemDO;
import com.lxjl.juling.module.trade.enums.order.TradeOrderTypeEnum;
import com.lxjl.juling.module.trade.service.price.bo.TradePriceCalculateReqBO;
import com.lxjl.juling.module.trade.service.price.bo.TradePriceCalculateRespBO;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertMap;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.getSumValue;

/**
 * 价格计算结果的工具类
 *
 * 由 {@link TradePriceCalculateRespBO} 的构建使用：把 SKU/SPU 与请求参数摊平成价格计算结果。
 * 原先还服务于「价格计算器链」（{@code List<TradePriceCalculator>}），
 * 那些计算器（营销 / 会员价 / 运费）已随营销与会员中心物理删除，扩展点不再保留。
 *
 * @author 亚特
 */
public class TradePriceCalculatorHelper {

    public static TradePriceCalculateRespBO buildCalculateResp(TradePriceCalculateReqBO param,
                                                               List<ProductSpuRespDTO> spuList, List<ProductSkuRespDTO> skuList) {
        // 创建 PriceCalculateRespDTO 对象
        TradePriceCalculateRespBO result = new TradePriceCalculateRespBO();
        result.setType(TradeOrderTypeEnum.NORMAL.getType());

        // 创建它的 OrderItem 属性
        result.setItems(new ArrayList<>(param.getItems().size()));
        Map<Long, ProductSpuRespDTO> spuMap = convertMap(spuList, ProductSpuRespDTO::getId);
        Map<Long, ProductSkuRespDTO> skuMap = convertMap(skuList, ProductSkuRespDTO::getId);
        param.getItems().forEach(item -> {
            ProductSkuRespDTO sku = skuMap.get(item.getSkuId());
            if (sku == null) {
                return;
            }
            ProductSpuRespDTO spu = spuMap.get(sku.getSpuId());
            if (spu == null) {
                return;
            }
            // 商品项
            TradePriceCalculateRespBO.OrderItem orderItem = new TradePriceCalculateRespBO.OrderItem();
            result.getItems().add(orderItem);
            orderItem.setSpuId(sku.getSpuId()).setSkuId(sku.getId())
                    .setCount(item.getCount()).setCartId(item.getCartId()).setSelected(item.getSelected());
            // sku 价格
            orderItem.setPrice(sku.getPrice()).setPayPrice(sku.getPrice() * item.getCount())
                    .setDiscountPrice(0).setDeliveryPrice(0);
            // sku 信息
            orderItem.setPicUrl(sku.getPicUrl()).setProperties(sku.getProperties())
                    .setWeight(sku.getWeight()).setVolume(sku.getVolume());
            // spu 信息
            orderItem.setSpuName(spu.getName()).setCategoryId(spu.getCategoryId())
                    .setDeliveryTemplateId(spu.getDeliveryTemplateId());
            if (StrUtil.isBlank(orderItem.getPicUrl())) {
                orderItem.setPicUrl(spu.getPicUrl());
            }
        });

        // 创建它的 Price 属性
        result.setPrice(new TradePriceCalculateRespBO.Price());
        recountAllPrice(result);
        return result;
    }

    /**
     * 基于订单项，重新计算 price 总价
     *
     * @param result 计算结果
     */
    public static void recountAllPrice(TradePriceCalculateRespBO result) {
        // 先重置
        TradePriceCalculateRespBO.Price price = result.getPrice();
        price.setTotalPrice(0).setDiscountPrice(0).setDeliveryPrice(0).setPayPrice(0);
        // 再合计 item
        result.getItems().forEach(item -> {
            if (!item.getSelected()) {
                return;
            }
            price.setTotalPrice(price.getTotalPrice() + item.getPrice() * item.getCount());
            price.setDiscountPrice(price.getDiscountPrice() + item.getDiscountPrice());
            price.setDeliveryPrice(price.getDeliveryPrice() + item.getDeliveryPrice());
            price.setPayPrice(price.getPayPrice() + item.getPayPrice());
        });
    }

    /**
     * 重新计算单个订单项的支付金额
     *
     * @param orderItem 订单项
     */
    public static void recountPayPrice(TradePriceCalculateRespBO.OrderItem orderItem) {
        orderItem.setPayPrice(orderItem.getPrice() * orderItem.getCount()
                - orderItem.getDiscountPrice()
                + orderItem.getDeliveryPrice()
        );
    }

    /**
     * 重新计算每个订单项的支付金额
     *
     * 【目前主要是单测使用】
     *
     * @param orderItems 订单项数组
     */
    public static void recountPayPrice(List<TradePriceCalculateRespBO.OrderItem> orderItems) {
        orderItems.forEach(orderItem -> {
            if (orderItem.getDiscountPrice() == null) {
                orderItem.setDiscountPrice(0);
            }
            if (orderItem.getDeliveryPrice() == null) {
                orderItem.setDeliveryPrice(0);
            }
            recountPayPrice(orderItem);
        });
    }

    /**
     * 计算已选中的订单项，总支付金额
     *
     * @param orderItems 订单项数组
     * @return 总支付金额
     */
    public static Integer calculateTotalPayPrice(List<TradePriceCalculateRespBO.OrderItem> orderItems) {
        return getSumValue(orderItems,
                orderItem -> orderItem.getSelected() ? orderItem.getPayPrice() : 0, // 未选中的情况下，不计算支付金额
                Integer::sum);
    }

    /**
     * 计算已选中的订单项，总商品数
     *
     * @param orderItems 订单项数组
     * @return 总商品数
     */
    public static Integer calculateTotalCount(List<TradePriceCalculateRespBO.OrderItem> orderItems) {
        return getSumValue(orderItems,
                orderItem -> orderItem.getSelected() ? orderItem.getCount() : 0, // 未选中的情况下，不计算数量
                Integer::sum);
    }

    /**
     * 按照支付金额，返回每个订单项的分摊金额数组
     *
     * 实际上 price 不仅仅可以传递的是金额，也可以是积分。因为它的实现逻辑，就是根据 payPrice 做分摊而已
     *
     * @param orderItems 订单项数组
     * @param price      金额
     * @return 分摊金额数组，和传入的 orderItems 一一对应
     */
    public static List<Integer> dividePrice(List<TradePriceCalculateRespBO.OrderItem> orderItems, Integer price) {
        Integer total = calculateTotalPayPrice(orderItems);
        assert total != null;
        // 遍历每一个，进行分摊
        List<Integer> prices = new ArrayList<>(orderItems.size());
        int remainPrice = price;
        for (int i = 0; i < orderItems.size(); i++) {
            TradePriceCalculateRespBO.OrderItem orderItem = orderItems.get(i);
            // 1. 如果是未选中，则分摊为 0
            if (!orderItem.getSelected()) {
                prices.add(0);
                continue;
            }
            // 2. 如果选中，则按照百分比，进行分摊
            int partPrice;
            if (i < orderItems.size() - 1) { // 减一的原因，是因为拆分时，如果按照比例，可能会出现.所以最后一个，使用反减
                partPrice = (int) (price * (1.0D * orderItem.getPayPrice() / total));
                remainPrice -= partPrice;
            } else {
                partPrice = remainPrice;
            }
            Assert.isTrue(partPrice >= 0, "分摊金额必须大于等于 0");
            prices.add(partPrice);
        }
        return prices;
    }

    /**
     * 计算订单调价价格分摊
     *
     * 和 {@link #dividePrice(List, Integer)} 逻辑一致，只是传入的是 TradeOrderItemDO 对象
     *
     * @param items 订单项
     * @param price 订单支付金额
     * @return 分摊金额数组，和传入的 orderItems 一一对应
     */
    public static List<Integer> dividePrice2(List<TradeOrderItemDO> items, Integer price) {
        Integer total = getSumValue(items, TradeOrderItemDO::getPayPrice, Integer::sum);
        assert total != null;
        // 遍历每一个，进行分摊
        List<Integer> prices = new ArrayList<>(items.size());
        int remainPrice = price;
        for (int i = 0; i < items.size(); i++) {
            TradeOrderItemDO orderItem = items.get(i);
            int partPrice;
            if (i < items.size() - 1) { // 减一的原因，是因为拆分时，如果按照比例，可能会出现.所以最后一个，使用反减
                partPrice = (int) (price * (1.0D * orderItem.getPayPrice() / total));
                remainPrice -= partPrice;
            } else {
                partPrice = remainPrice;
            }
            prices.add(partPrice);
        }
        return prices;
    }

    public static String formatPrice(Integer price) {
        return String.format("%.2f", price / 100d);
    }

}
