package com.lxjl.juling.module.erp.api.customer.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 门店往来明细 DTO（一行一笔）
 *
 * @author 亚特
 */
@Data
public class ErpCustomerAccountDetailRespDTO {

    /** 编号 */
    private Long id;
    /** 门店客户编号 */
    private Long customerId;
    /** 门店名称 */
    private String customerName;
    /** 业务类型：1 配送应收 / 3 收款 / 4 收货差异调整 / 11 配送应收冲销 … */
    private Integer bizType;
    /** 业务类型名称 */
    private String bizTypeName;
    /** 金额（正数 = 门店欠总部增加） */
    private BigDecimal amount;
    /** 记账后余额快照 */
    private BigDecimal balance;
    /** 业务时间 */
    private LocalDateTime billTime;
    /** 来源单据类型 */
    private String sourceType;
    /** 来源单号 */
    private String sourceNo;
    /** 备注 */
    private String remark;

}
