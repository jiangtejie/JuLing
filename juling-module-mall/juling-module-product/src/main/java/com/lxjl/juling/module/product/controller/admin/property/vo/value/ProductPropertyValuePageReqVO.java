package com.lxjl.juling.module.product.controller.admin.property.vo.value;

import com.lxjl.juling.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

@Schema(description = "管理后台 - 商品属性值分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class ProductPropertyValuePageReqVO extends PageParam {

    @Schema(description = "属性项的编号", example = "1024")
    // 注意：必须是 Long —— product_property_value.property_id 是 bigint，
    // PostgreSQL 不支持 bigint = character varying（MySQL 会隐式转换，切库后这里直接报语法错误）
    private Long propertyId;

    @Schema(description = "名称", example = "红色")
    private String name;

    @Schema(description = "状态", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Integer status;

}
