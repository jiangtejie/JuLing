package com.lxjl.juling.module.erp.dal.dataobject.finance;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 门店往来台账 DO
 *
 * 口径（见 docs/store-receipt-and-receivables-design.md 第 7 段）：
 *   · 一行 = 一笔往来，amount 正数表示门店欠总部增加（配送应收 / 直拨应收 / 多收），
 *     负数表示减少（收款、冲销、少收调整）；
 *   · balance 是「记完这一笔之后」的余额快照，便于逐笔对账而不必每次 SUM；
 *   · 同一门店的记账在事务内先取 advisory lock 串行化，避免并发下余额快照错乱；
 *   · (bizType, sourceType, sourceId) 唯一 —— 审核/反审核反复切换不会重复挂账。
 *
 * @author 亚特
 */
@TableName("erp_customer_account")
@KeySequence("erp_customer_account_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErpCustomerAccountDO extends BaseDO {

    /**
     * 编号
     */
    @TableId
    private Long id;
    /**
     * 门店客户编号
     *
     * 关联 {@link com.lxjl.juling.module.erp.dal.dataobject.sale.ErpCustomerDO#getId()}
     */
    private Long customerId;
    /**
     * 门店部门编号
     */
    private Long deptId;
    /**
     * 业务类型
     *
     * 枚举 {@link com.lxjl.juling.module.erp.api.customer.enums.CustomerAccountBizTypeEnum}
     */
    private Integer bizType;
    /**
     * 金额：正数 = 门店欠总部增加，负数 = 减少
     */
    private BigDecimal amount;
    /**
     * 记账后余额快照（正数 = 门店欠总部）
     */
    private BigDecimal balance;
    /**
     * 业务时间
     */
    private LocalDateTime billTime;
    /**
     * 来源单据类型（DELIVERY_OUT / STORE_RECEIPT / TRADE_ORDER …）
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
