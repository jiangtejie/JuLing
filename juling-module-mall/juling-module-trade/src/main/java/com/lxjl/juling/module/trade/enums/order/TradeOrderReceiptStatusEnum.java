package com.lxjl.juling.module.trade.enums.order;

import com.lxjl.juling.framework.common.core.ArrayValuable;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

import java.util.Arrays;

/**
 * 交易订单 - 收货状态（订单维度的聚合）
 *
 * 与「收货单状态」（{@link TradeStoreReceiptStatusEnum}）区分：
 *   · 收货单状态描述**一张收货单**的流转；
 *   · 本枚举描述**订单**整体收了多少 —— 只要有一行确认收货即「部分收货」，全部行收齐即「已收货」。
 *
 * @author 亚特
 */
@RequiredArgsConstructor
@Getter
public enum TradeOrderReceiptStatusEnum implements ArrayValuable<Integer> {

    NONE(0, "未收货"),
    PART(10, "部分收货"),
    ALL(20, "已收货"),
    ;

    public static final Integer[] ARRAYS = Arrays.stream(values()).map(TradeOrderReceiptStatusEnum::getStatus).toArray(Integer[]::new);

    private final Integer status;
    private final String name;

    public static String getName(Integer status) {
        return Arrays.stream(values()).filter(item -> item.getStatus().equals(status))
                .map(TradeOrderReceiptStatusEnum::getName).findFirst().orElse(null);
    }

    @Override
    public Integer[] array() {
        return ARRAYS;
    }

}
