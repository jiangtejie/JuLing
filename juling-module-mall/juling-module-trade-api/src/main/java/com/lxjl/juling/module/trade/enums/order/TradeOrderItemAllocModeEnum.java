package com.lxjl.juling.module.trade.enums.order;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Objects;

/**
 * 交易订单行 - 分料方式枚举（订单工作台）
 *
 * 门店订货链 S2：要货单审核通过后进入中心库「订单工作台」，逐行判定分料方式：
 *  · CENTRAL 统配：中心库配送出库（ERP 销售出库 / 配送出库单）；
 *  · DIRECT  直拨：中心库向供应商下采购订单，供应商直送门店（不入中心库）。
 * 物料（erp_product）的 allow_central / allow_direct 决定该行可选哪些方式。
 * 对应字典 trade_order_item_alloc_mode。
 *
 * @author 亚特
 */
@Getter
@AllArgsConstructor
public enum TradeOrderItemAllocModeEnum {

    CENTRAL("CENTRAL", "统配"),
    DIRECT("DIRECT", "直拨"),
    ;

    /**
     * 方式
     */
    private final String mode;
    /**
     * 名字
     */
    private final String name;

    public static TradeOrderItemAllocModeEnum valueOfMode(String mode) {
        for (TradeOrderItemAllocModeEnum item : values()) {
            if (Objects.equals(item.mode, mode)) {
                return item;
            }
        }
        return null;
    }

}
