package com.lxjl.juling.module.erp.controller.admin.purchase.vo.price;

import com.lxjl.juling.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

@Schema(description = "管理后台 - 采购价目表分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class ErpPurchasePricePageReqVO extends PageParam {

    @Schema(description = "业务编码（模糊）", example = "CJJM")
    private String code;

    @Schema(description = "价目表名称（模糊）", example = "彩云")
    private String name;

    @Schema(description = "供应商编号", example = "1")
    private Long supplierId;

    @Schema(description = "状态", example = "0")
    private Integer status;

}
