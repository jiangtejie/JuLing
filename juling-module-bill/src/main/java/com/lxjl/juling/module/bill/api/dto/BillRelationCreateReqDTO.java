package com.lxjl.juling.module.bill.api.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 单据关联（下推）创建 Request DTO
 *
 * @author 亚特
 */
@Data
public class BillRelationCreateReqDTO {

    /** 源单类型 */
    private String sourceType;
    /** 源单编号 */
    private Long sourceId;
    /** 源单号 */
    private String sourceNo;
    /** 源单行编号（行级关联时传） */
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
    /** 备注 */
    private String remark;

}
