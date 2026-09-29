package com.lxjl.juling.module.bill.dal.dataobject;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 单据操作日志 DO
 *
 * @author 亚特
 */
@TableName("bill_log")
@KeySequence("bill_log_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BillLogDO extends BaseDO {

    @TableId
    private Long id;
    /** 单据类型编码 */
    private String billType;
    /** 单据编号 */
    private Long billId;
    /** 单据号 */
    private String billNo;
    /** 操作类型，如 CREATE/SUBMIT/APPROVE/REJECT/DELIVER/RECEIVE/VOID/UN_AUDIT */
    private String operateType;
    /** 变更前状态 */
    private Integer beforeStatus;
    /** 变更后状态 */
    private Integer afterStatus;
    /** 操作人编号 */
    private Long operatorId;
    /** 操作人名称 */
    private String operatorName;
    /** 操作时间 */
    private LocalDateTime operateTime;
    /** 备注 */
    private String remark;

}
