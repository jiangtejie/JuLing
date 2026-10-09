package com.lxjl.juling.module.bill.dal.dataobject;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 单据关联 DO（上溯下推）
 *
 * 头级与行级都支持：source_item_id / target_item_id 为空表示头级关联。
 * 唯一索引防重复下推；qty 用于防超推。
 *
 * @author 亚特
 */
@TableName("bill_relation")
@KeySequence("bill_relation_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BillRelationDO extends BaseDO {

    @TableId
    private Long id;
    /** 源单类型 */
    private String sourceType;
    /** 源单编号 */
    private Long sourceId;
    /** 源单号（冗余，便于展示） */
    private String sourceNo;
    /** 源单行编号 */
    private Long sourceItemId;
    /** 目标单类型 */
    private String targetType;
    /** 目标单编号 */
    private Long targetId;
    /** 目标单号 */
    private String targetNo;
    /** 目标单行编号 */
    private Long targetItemId;
    /** 下推数量（行级时必填） */
    private BigDecimal qty;
    /** 状态 */
    private Integer status;
    /** 备注 */
    private String remark;

}
