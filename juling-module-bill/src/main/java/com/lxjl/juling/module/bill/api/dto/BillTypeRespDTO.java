package com.lxjl.juling.module.bill.api.dto;

import lombok.Data;

/**
 * 单据类型 Response DTO（供其它模块判断是否需要审批/影响库存等）
 *
 * @author 亚特
 */
@Data
public class BillTypeRespDTO {

    private Long id;
    private String code;
    private String name;
    private String module;
    private String noPrefix;
    private Boolean needAudit;
    private String bpmProcessKey;
    private Boolean affectStock;
    private Boolean affectFinance;
    private Integer status;

}
