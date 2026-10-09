package com.lxjl.juling.module.bill.dal.dataobject;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 单号流水 DO
 *
 * 按「单据类型 × 组织 × 期间」维护最后流水号；并发靠行锁（SELECT ... FOR UPDATE）。
 *
 * @author 亚特
 */
@TableName("bill_no_seq")
@KeySequence("bill_no_seq_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BillNoSeqDO extends BaseDO {

    @TableId
    private Long id;
    /** 单据类型编码 */
    private String billType;
    /** 组织编号（部门 id，0 表示不区分组织） */
    private Long orgId;
    /** 期间（按重置周期取值，如 20260928 / 202609 / 2026 / ALL） */
    private String period;
    /** 当前最大流水号 */
    private Long lastNo;

}
