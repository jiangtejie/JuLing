package com.lxjl.juling.module.trade.service.price.bo;

import com.lxjl.juling.module.trade.enums.delivery.DeliveryTypeEnum;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

/**
 * 价格计算 Request BO
 *
 * @author 亚特
 */
@Data
public class TradePriceCalculateReqBO {

    /**
     * 用户编号
     *
     * 对应 MemberUserDO 的 id 编号
     */
    private Long userId;

    /**
     * 配送方式
     *
     * 枚举 {@link DeliveryTypeEnum}
     */
    private Integer deliveryType;
    /**
     * 收货地址编号
     *
     * 会员中心（含会员地址簿）已下线，恒为空、不再消费；仅为兼容 H5 保留字段
     */
    private Long addressId;

    /**
     * 下单门店（erp_customer.id）
     *
     * <p>用于按「配送价目表」定价 —— 配送价可以针对不同门店不同（见 sql/local/69）。
     * 为空时只匹配通用范围的配送价目表。
     */
    private Long customerId;
    /**
     * 商品 SKU 数组
     */
    @NotNull(message = "商品数组不能为空")
    private List<Item> items;

    /**
     * 商品 SKU
     */
    @Data
    @Valid
    public static class Item {

        /**
         * SKU 编号
         */
        @NotNull(message = "商品 SKU 编号不能为空")
        private Long skuId;

        /**
         * SKU 数量
         */
        @NotNull(message = "商品 SKU 数量不能为空")
        @Min(value = 0L, message = "商品 SKU 数量必须大于等于 0")
        private Integer count;

        /**
         * 购物车项的编号
         */
        private Long cartId;

        /**
         * 是否选中
         */
        @NotNull(message = "是否选中不能为空")
        private Boolean selected;

    }
}
