package com.lxjl.juling.module.erp.api.customer.dto;

import lombok.Data;
import lombok.experimental.Accessors;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 门店往来记账请求 DTO
 *
 * @author 亚特
 */
@Data
@Accessors(chain = true)
public class ErpCustomerAccountRecordReqDTO {

    /**
     * 门店客户编号
     */
    private Long customerId;
    /**
     * 门店部门编号（冗余，便于按组织过滤）
     */
    private Long deptId;
    /**
     * 业务类型，枚举 {@link com.lxjl.juling.module.erp.api.customer.enums.CustomerAccountBizTypeEnum}
     */
    private Integer bizType;
    /**
     * 金额：正数 = 门店欠总部增加（应收），负数 = 减少（收款/冲销）
     */
    private BigDecimal amount;
    /**
     * 业务时间（空则取当前时间）
     */
    private LocalDateTime billTime;
    /**
     * 来源单据类型（DELIVERY_OUT / TRADE_ORDER / STORE_RECEIPT …）
     */
    private String sourceType;
    /**
     * 来源单据编号
     */
    private Long sourceId;
    /**
     * 来源单号
     */
    private String sourceNo;
    /**
     * 备注
     */
    private String remark;

}
