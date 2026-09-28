package com.lxjl.juling.module.bill.dal.dataobject;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 单据扩展字段 DO
 *
 * 小需求（加一个字段）走这里，避免为每个客户改表结构。
 *
 * @author 亚特
 */
@TableName("bill_ext")
@KeySequence("bill_ext_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BillExtDO extends BaseDO {

    @TableId
    private Long id;
    /** 单据类型编码 */
    private String billType;
    /** 单据编号 */
    private Long billId;
    /** 字段 key */
    private String fieldKey;
    /** 字段值 */
    private String fieldValue;
    /** 字段类型：string/number/date/bool/json */
    private String fieldType;

}
