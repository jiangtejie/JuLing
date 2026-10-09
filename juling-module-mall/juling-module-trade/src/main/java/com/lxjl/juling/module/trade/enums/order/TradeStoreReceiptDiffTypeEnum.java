package com.lxjl.juling.module.trade.enums.order;

import com.lxjl.juling.framework.common.core.ArrayValuable;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

import java.util.Arrays;

/**
 * 门店收货单 - 差异类型
 *
 * 口径：实收数量 − 发货数量。负数 = 少收（含途中损耗 / 破损未收），正数 = 多收（供应商多发 / 中心库多发）。
 * 差异会同步生成门店往来台账的调整分录（少收冲减应收、多收增加应收）。
 *
 * @author 亚特
 */
@RequiredArgsConstructor
@Getter
public enum TradeStoreReceiptDiffTypeEnum implements ArrayValuable<Integer> {

    NONE(0, "无差异"),
    LESS(1, "少收"),
    MORE(2, "多收"),
    DAMAGED(3, "破损"),
    MIXED(4, "混合差异"),
    ;

    public static final Integer[] ARRAYS = Arrays.stream(values()).map(TradeStoreReceiptDiffTypeEnum::getStatus).toArray(Integer[]::new);

    private final Integer status;
    private final String name;

    public static String getName(Integer status) {
        return Arrays.stream(values()).filter(item -> item.getStatus().equals(status))
                .map(TradeStoreReceiptDiffTypeEnum::getName).findFirst().orElse(null);
    }

    @Override
    public Integer[] array() {
        return ARRAYS;
    }

}
