package com.lxjl.juling.module.erp.controller.admin.purchase.vo.supplier;

import com.lxjl.juling.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

@Schema(description = "管理后台 - ERP 供应商分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class ErpSupplierPageReqVO extends PageParam {

    @Schema(description = "供应商名称", example = "亚特")
    private String name;

    @Schema(description = "手机号码", example = "15601691300")
    private String mobile;

    @Schema(description = "联系电话", example = "18818288888")
    private String telephone;

    @Schema(description = "结账方式", example = "MONTHLY")
    private String settlementType;

    @Schema(description = "开票情况", example = "FULL")
    private String invoiceMode;

    @Schema(description = "开票类型", example = "VAT_SPECIAL")
    private String invoiceType;

    @Schema(description = "是否已签订合同", example = "true")
    private Boolean contractSigned;

}