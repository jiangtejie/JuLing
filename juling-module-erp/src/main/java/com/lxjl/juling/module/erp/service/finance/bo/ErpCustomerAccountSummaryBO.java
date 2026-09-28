package com.lxjl.juling.module.erp.service.finance.bo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * 门店往来余额汇总 BO（一家门店一行）
 *
 * @author 亚特
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ErpCustomerAccountSummaryBO {

    /** 门店客户编号 */
    private Long customerId;
    /** 门店部门编号 */
    private Long deptId;
    /** 累计应收（正数记账合计） */
    private BigDecimal totalReceivable;
    /** 累计已收 / 冲减（负数记账的绝对值合计） */
    private BigDecimal totalReceived;
    /** 当前余额（正数 = 门店欠总部） */
    private BigDecimal balance;

}
