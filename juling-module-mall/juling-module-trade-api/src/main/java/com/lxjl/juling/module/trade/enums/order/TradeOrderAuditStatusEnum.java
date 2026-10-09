package com.lxjl.juling.module.trade.enums.order;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Objects;

/**
 * 交易订单（门店要货）审核状态枚举
 *
 * 门店订货链：付款核验通过后提交供应链审核，审核通过才允许发货。
 *
 * @author 亚特
 */
@Getter
@AllArgsConstructor
public enum TradeOrderAuditStatusEnum {

    DRAFT(0, "待提交"),
    PROCESS(10, "审核中"),
    APPROVE(20, "已通过"),
    REJECT(30, "已驳回"),
    ;

    /**
     * 状态
     */
    private final Integer status;
    /**
     * 名字
     */
    private final String name;

    public static boolean isApprove(Integer status) {
        return Objects.equals(APPROVE.getStatus(), status);
    }

}
