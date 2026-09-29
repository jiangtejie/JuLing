package com.lxjl.juling.module.erp.api.customer.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 门店往来余额汇总 DTO（一家门店一行）
 *
 * 供其它模块（订货 H5 的「我的账」）展示：累计应收 / 累计已收 / 当前余额。
 *
 * @author 亚特
 */
@Data
public class ErpCustomerAccountSummaryRespDTO {

    /** 门店客户编号 */
    private Long customerId;
    /** 门店名称 */
    private String customerName;
    /** 门店部门编号 */
    private Long deptId;
    /** 累计应收（正数记账合计） */
    private BigDecimal totalReceivable;
    /** 累计已收 / 冲减（负数记账的绝对值） */
    private BigDecimal totalReceived;
    /** 当前余额（正数 = 门店欠总部） */
    private BigDecimal balance;

}
