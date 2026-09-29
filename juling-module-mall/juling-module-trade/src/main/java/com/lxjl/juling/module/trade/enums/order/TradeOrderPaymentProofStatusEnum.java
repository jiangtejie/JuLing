package com.lxjl.juling.module.trade.enums.order;

import com.lxjl.juling.framework.common.core.ArrayValuable;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

import java.util.Arrays;
import java.util.Objects;

/**
 * 交易订单 - 付款凭证（单条）状态
 *
 * 线下收款流程：客户上传付款截图 → 待核验；后台核验 → 已确认 / 已驳回（可重传）。
 *
 * @author 亚特
 */
@RequiredArgsConstructor
@Getter
public enum TradeOrderPaymentProofStatusEnum implements ArrayValuable<Integer> {

    PENDING(0, "待核验"),
    CONFIRMED(1, "已确认"),
    REJECTED(2, "已驳回");

    public static final Integer[] ARRAYS = Arrays.stream(values()).map(TradeOrderPaymentProofStatusEnum::getStatus).toArray(Integer[]::new);

    private final Integer status;
    private final String name;

    public static boolean isPending(Integer status) {
        return Objects.equals(PENDING.getStatus(), status);
    }

    public static boolean isConfirmed(Integer status) {
        return Objects.equals(CONFIRMED.getStatus(), status);
    }

    public static boolean isRejected(Integer status) {
        return Objects.equals(REJECTED.getStatus(), status);
    }

    @Override
    public Integer[] array() {
        return ARRAYS;
    }

}
