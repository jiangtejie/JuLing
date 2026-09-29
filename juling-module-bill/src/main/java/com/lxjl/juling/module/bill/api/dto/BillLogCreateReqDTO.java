package com.lxjl.juling.module.bill.api.dto;

import lombok.Data;

/**
 * 单据操作日志创建 Request DTO
 *
 * @author 亚特
 */
@Data
public class BillLogCreateReqDTO {

    private String billType;
    private Long billId;
    private String billNo;
    /** CREATE/SUBMIT/APPROVE/REJECT/DELIVER/RECEIVE/VOID/UN_AUDIT… */
    private String operateType;
    private Integer beforeStatus;
    private Integer afterStatus;
    private Long operatorId;
    private String operatorName;
    private String remark;

}
