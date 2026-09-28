package com.lxjl.juling.module.trade.enums.order;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 门店结算模式枚举
 *
 * 与字典 trade_settlement_mode 对应；门店订货链按结算模式驱动付款与审核分支。
 *
 * @author 亚特
 */
@Getter
@AllArgsConstructor
public enum TradeSettlementModeEnum {

    PREPAID("PREPAID", "先款后货"),
    MONTHLY("MONTHLY", "月结"),
    ;

    /**
     * 模式
     */
    private final String mode;
    /**
     * 名字
     */
    private final String name;

    /**
     * 默认结算模式（门店未配置时）
     */
    public static final String DEFAULT_MODE = "PREPAID";

}
