package com.lxjl.juling.module.trade.dal.dataobject.order;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.lxjl.juling.module.trade.dal.dataobject.aftersale.AfterSaleDO;
import com.lxjl.juling.module.trade.dal.dataobject.cart.CartDO;
import com.lxjl.juling.module.trade.enums.order.TradeOrderItemAfterSaleStatusEnum;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import lombok.Data;

import java.io.Serializable;
import java.util.List;

/**
 * 交易订单项 DO
 *
 * @author 亚特
 */
@TableName(value = "trade_order_item", autoResultMap = true)
@KeySequence("trade_order_item_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
public class TradeOrderItemDO extends BaseDO {

    // ========== 订单项基本信息 ==========
    /**
     * 编号
     */
    private Long id;
    /**
     * 用户编号
     *
     * 关联 MemberUserDO 的 id 编号
     */
    private Long userId;
    /**
     * 订单编号
     *
     * 关联 {@link TradeOrderDO#getId()}
     */
    private Long orderId;
    /**
     * 购物车项编号
     *
     * 关联 {@link CartDO#getId()}
     */
    private Long cartId;

    // ========== 商品基本信息; 冗余较多字段，减少关联查询 ==========
    /**
     * 商品 SPU 编号
     *
     * 关联 ProductSkuDO 的 spuId 编号
     */
    private Long spuId;
    /**
     * 商品 SPU 名称
     *
     * 冗余 ProductSkuDO 的 spuName 编号
     */
    private String spuName;
    /**
     * 商品 SKU 编号
     *
     * 关联 ProductSkuDO 的 id 编号
     */
    private Long skuId;
    /**
     * 属性数组，JSON 格式
     *
     * 冗余 ProductSkuDO 的 properties 字段
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<Property> properties;
    /**
     * 商品图片
     */
    private String picUrl;
    /**
     * 购买数量
     */
    private Integer count;

    // ========== 价格 + 支付基本信息 ==========

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
     * 订单调价（总），单位：分
     *
     * 正数，加价；负数，减价
     */
    private Integer adjustPrice;
    /**
     * 应付金额（总），单位：分
     *
     * = {@link #price} * {@link #count}
     * - {@link #discountPrice}
     * + {@link #deliveryPrice}
     * + {@link #adjustPrice}
     */
    private Integer payPrice;

    // ========== 售后基本信息 ==========

    /**
     * 售后单编号
     *
     * 关联 {@link AfterSaleDO#getId()} 字段
     */
    private Long afterSaleId;
    /**
     * 售后状态
     *
     * 枚举 {@link TradeOrderItemAfterSaleStatusEnum}
     */
    private Integer afterSaleStatus;

    // ========== 门店订货链：分料（订单工作台） ==========

    /**
     * 分料方式
     *
     * 枚举 {@link com.lxjl.juling.module.trade.enums.order.TradeOrderItemAllocModeEnum}；
     * 为空表示「未分料」（订单工作台待处理），非空表示该行已下推过 ERP 单据。
     */
    private String allocMode;
    /**
     * 分料下推数量（≤ {@link #count}）；为空表示未下推
     */
    private java.math.BigDecimal allocCount;
    /**
     * ERP 已发货数量（配送出库单审核后回写）
     *
     * 口径：出库单实际发出多少，不含门店收货差异。门店实收数量见 {@link #receiptCount}。
     */
    private java.math.BigDecimal deliveredCount;
    /**
     * 门店已确认收货数量（门店收货单确认后回写）
     */
    private java.math.BigDecimal receiptCount;

    /**
     * 商品属性
     */
    @Data
    public static class Property implements Serializable {

        /**
         * 属性编号
         *
         * 关联 ProductPropertyDO 的 id 编号
         */
        private Long propertyId;
        /**
         * 属性名字
         *
         * 关联 ProductPropertyDO 的 name 字段
         */
        private String propertyName;

        /**
         * 属性值编号
         *
         * 关联 ProductPropertyValueDO 的 id 编号
         */
        private Long valueId;
        /**
         * 属性值名字
         *
         * 关联 ProductPropertyValueDO 的 name 字段
         */
        private String valueName;

    }

}

