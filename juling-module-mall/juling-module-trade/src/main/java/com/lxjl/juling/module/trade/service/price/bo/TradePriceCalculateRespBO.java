package com.lxjl.juling.module.trade.service.price.bo;

import com.lxjl.juling.module.product.api.property.dto.ProductPropertyValueDetailRespDTO;
import com.lxjl.juling.module.trade.enums.order.TradeOrderTypeEnum;
import lombok.Data;

import java.util.List;

/**
 * 价格计算 Response BO
 *
 * 整体设计，参考 taobao 的技术文档：
 * 1. <a href="https://developer.alibaba.com/docs/doc.htm?treeId=1&articleId=1029&docType=1">订单管理</a>
 * 2. <a href="https://open.taobao.com/docV3.htm?docId=108471&docType=1">常用订单金额说明</a>
 *
 * @author 亚特
 */
@Data
public class TradePriceCalculateRespBO {

    /**
     * 订单类型
     *
     * 枚举 {@link TradeOrderTypeEnum}
     */
    private Integer type;

    /**
     * 订单价格
     */
    private Price price;

    /**
     * 订单项数组
     */
    private List<OrderItem> items;

    /**
     * 是否包邮
     */
    private Boolean freeDelivery;

    /**
     * 订单价格
     */
    @Data
    public static class Price {

        /**
         * 商品原价（总），单位：分
         *
         * 基于 {@link OrderItem#getPrice()} * {@link OrderItem#getCount()} 求和
         *
         * 对应 taobao 的 trade.total_fee 字段
         */
        private Integer totalPrice;
        /**
         * 订单优惠（总），单位：分
         *
         * 对应 taobao 的 order.discount_fee 字段
         */
        private Integer discountPrice;
        /**
         * 运费金额，单位：分
         */
        private Integer deliveryPrice;
        /**
         * 最终购买金额（总），单位：分
         *
         * = {@link #totalPrice}
         * - {@link #discountPrice}
         * + {@link #deliveryPrice}
         */
        private Integer payPrice;

    }

    /**
     * 订单商品 SKU
     */
    @Data
    public static class OrderItem {

        /**
         * SPU 编号
         */
        private Long spuId;
        /**
         * SKU 编号
         */
        private Long skuId;
        /**
         * 购买数量
         */
        private Integer count;
        /**
         * 购物车项的编号
         */
        private Long cartId;
        /**
         * 是否选中
         */
        private Boolean selected;

        /**
         * 商品原价（单），单位：分
         *
         * 对应 ProductSkuDO 的 price 字段
         * 对应 taobao 的 order.price 字段
         */
        private Integer price;
        /**
         * 优惠金额（总），单位：分
         *
         * 对应 taobao 的 order.discount_fee 字段
         */
        private Integer discountPrice;
        /**
         * 运费金额（总），单位：分
         */
        private Integer deliveryPrice;
        /**
         * 应付金额（总），单位：分
         *
         * = {@link #price} * {@link #count}
         * - {@link #discountPrice}
         * + {@link #deliveryPrice}
         */
        private Integer payPrice;

        // ========== 商品 SPU 信息 ==========
        /**
         * 商品名
         */
        private String spuName;
        /**
         * 商品图片
         *
         * 优先级：SKU.picUrl > SPU.picUrl
         */
        private String picUrl;
        /**
         * 分类编号
         */
        private Long categoryId;

        // ========== 物流相关字段 =========

        /**
         * 物流配置模板编号
         *
         * 对应 TradeDeliveryExpressTemplateDO 的 id 编号
         */
        private Long deliveryTemplateId;

        // ========== 商品 SKU 信息 ==========
        /**
         * 商品重量，单位：kg 千克
         */
        private Double weight;
        /**
         * 商品体积，单位：m^3 平米
         */
        private Double volume;

        /**
         * 商品属性数组
         */
        private List<ProductPropertyValueDetailRespDTO> properties;

    }

}
