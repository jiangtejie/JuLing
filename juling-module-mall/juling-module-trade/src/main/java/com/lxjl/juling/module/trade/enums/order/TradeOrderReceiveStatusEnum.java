package com.lxjl.juling.module.trade.enums.order;

import com.lxjl.juling.framework.common.core.ArrayValuable;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

import java.util.Arrays;
import java.util.Objects;

/**
 * 交易订单 - 收款状态（订单维度）
 *
 * 由付款凭证聚合而来：已确认收款金额 &lt; 应收金额 为「部分收款」，收满为「已收齐」。
 * 对应字典 trade_payment_proof_status。
 *
 * @author 亚特
 */
@RequiredArgsConstructor
@Getter
public enum TradeOrderReceiveStatusEnum implements ArrayValuable<Integer> {

    NONE(0, "未上传凭证"),
    PENDING(1, "待核验"),
    REJECTED(2, "已驳回"),
    PARTIAL(3, "部分收款"),
    PAID(4, "已收齐");

    public static final Integer[] ARRAYS = Arrays.stream(values()).map(TradeOrderReceiveStatusEnum::getStatus).toArray(Integer[]::new);

    private final Integer status;
    private final String name;

    public static boolean isPaid(Integer status) {
        return Objects.equals(PAID.getStatus(), status);
    }

    public static boolean isPending(Integer status) {
        return Objects.equals(PENDING.getStatus(), status);
    }

    public static boolean isPartial(Integer status) {
        return Objects.equals(PARTIAL.getStatus(), status);
    }

    @Override
    public Integer[] array() {
        return ARRAYS;
    }

}
