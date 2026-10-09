package com.lxjl.juling.module.erp.controller.admin.pricelist.vo;

import com.lxjl.juling.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

@Schema(description = "管理后台 - 价目表分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class ErpPriceListPageReqVO extends PageParam {

    @Schema(description = "价目表类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "PURCHASE")
    private String priceType;

    @Schema(description = "业务编码（模糊）", example = "CJJM")
    private String code;

    @Schema(description = "价目表名称（模糊）", example = "彩云")
    private String name;

    @Schema(description = "状态", example = "0")
    private Integer status;

}
