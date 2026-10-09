package com.lxjl.juling.module.bill.dal.dataobject;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 单据类型 DO
 *
 * 注册一类单据的编号规则、是否审批、是否影响库存/核算（后期凭证引擎据此过滤）。
 *
 * @author 亚特
 */
@TableName("bill_type")
@KeySequence("bill_type_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BillTypeDO extends BaseDO {

    @TableId
    private Long id;
    /** 类型编码，如 PURCHASE_ORDER */
    private String code;
    /** 类型名称，如 采购订单 */
    private String name;
    /** 所属模块 */
    private String module;
    /** 单号前缀 */
    private String noPrefix;
    /** 单号日期格式 */
    private String noDateFormat;
    /** 单号重置周期：D/M/Y/N */
    private String noReset;
    /** 流水号位数 */
    private Integer noSeqLength;
    /** 是否需要审批 */
    private Boolean needAudit;
    /** BPM 流程定义 key */
    private String bpmProcessKey;
    /** 是否影响库存 */
    private Boolean affectStock;
    /** 是否产生会计事件（后期凭证引擎用） */
    private Boolean affectFinance;
    /** 状态 */
    private Integer status;
    /** 排序 */
    private Integer sort;
    /** 备注 */
    private String remark;

}
