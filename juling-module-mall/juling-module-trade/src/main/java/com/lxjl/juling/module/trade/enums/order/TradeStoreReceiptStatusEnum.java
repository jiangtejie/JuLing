package com.lxjl.juling.module.trade.enums.order;

import com.lxjl.juling.framework.common.core.ArrayValuable;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

import java.util.Arrays;

/**
 * 门店收货单 - 状态
 *
 * 生命周期：ERP 配送出库单审核 → 生成「待确认」收货单 → 门店在 H5 确认 → 「已确认」；
 * 出库单反审核（门店尚未确认时）或后台作废 → 「已作废」。
 *
 * @author 亚特
 */
@RequiredArgsConstructor
@Getter
public enum TradeStoreReceiptStatusEnum implements ArrayValuable<Integer> {

    PENDING(0, "待确认"),
    CONFIRMED(10, "已确认"),
    CANCELED(20, "已作废"),
    ;

    public static final Integer[] ARRAYS = Arrays.stream(values()).map(TradeStoreReceiptStatusEnum::getStatus).toArray(Integer[]::new);

    private final Integer status;
    private final String name;

    public static String getName(Integer status) {
        return Arrays.stream(values()).filter(item -> item.getStatus().equals(status))
                .map(TradeStoreReceiptStatusEnum::getName).findFirst().orElse(null);
    }

    @Override
    public Integer[] array() {
        return ARRAYS;
    }

}
