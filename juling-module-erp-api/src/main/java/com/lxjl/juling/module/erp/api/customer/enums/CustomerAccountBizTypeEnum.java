package com.lxjl.juling.module.erp.api.customer.enums;

import com.lxjl.juling.framework.common.core.ArrayValuable;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

import java.util.Arrays;

/**
 * 门店往来台账 - 业务类型枚举
 *
 * 口径：正数记账（应收增加）= 1/2/4 中的正数场景；负数记账 = 收款、冲销、少收调整。
 *
 * @author 亚特
 */
@RequiredArgsConstructor
@Getter
public enum CustomerAccountBizTypeEnum implements ArrayValuable<Integer> {

    DELIVERY_AR(1, "配送应收"),
    DIRECT_AR(2, "直拨应收"),
    RECEIPT(3, "收款（含预收）"),
    RECEIPT_ADJUST(4, "收货差异调整"),
    SALE_RETURN(5, "退货冲减"),
    DELIVERY_AR_CANCEL(11, "配送应收冲销"),
    DIRECT_AR_CANCEL(12, "直拨应收冲销"),
    ;

    public static final Integer[] ARRAYS = Arrays.stream(values()).map(CustomerAccountBizTypeEnum::getType).toArray(Integer[]::new);

    /**
     * 类型
     */
    private final Integer type;
    /**
     * 名字
     */
    private final String name;

    @Override
    public Integer[] array() {
        return ARRAYS;
    }

}
