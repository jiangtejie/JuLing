package com.lxjl.juling.module.erp.controller.admin.product.vo.product;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

@Schema(description = "管理后台 - ERP 物料新增/修改 Request VO")
@Data
public class ProductSaveReqVO {

    @Schema(description = "物料编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "15672")
    private Long id;

    @Schema(description = "物料名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "李四")
    @NotEmpty(message = "物料名称不能为空")
    private String name;

    @Schema(description = "物料条码", requiredMode = Schema.RequiredMode.REQUIRED, example = "X110")
    @NotEmpty(message = "物料条码不能为空")
    private String barCode;

    @Schema(description = "物料分类编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "11161")
    @NotNull(message = "物料分类编号不能为空")
    private Long categoryId;

    @Schema(description = "单位编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "8869")
    @NotNull(message = "单位编号不能为空")
    private Long unitId;

    @Schema(description = "物料状态", requiredMode = Schema.RequiredMode.REQUIRED, example = "2")
    @NotNull(message = "物料状态不能为空")
    private Integer status;

    @Schema(description = "物料规格", example = "红色")
    private String standard;

    @Schema(description = "物料备注", example = "你猜")
    private String remark;

    @Schema(description = "保质期天数", example = "10")
    private Integer expiryDay;

    @Schema(description = "基础重量（kg）", example = "1.00")
    private BigDecimal weight;

    @Schema(description = "采购价格，单位：元", example = "10.30")
    private BigDecimal purchasePrice;

    @Schema(description = "销售价格，单位：元", example = "74.32")
    private BigDecimal salePrice;

    @Schema(description = "最低价格，单位：元", example = "161.87")
    private BigDecimal minPrice;

    @Schema(description = "是否允许统配（中心库配送出库）", example = "true")
    private Boolean allowCentral;

    @Schema(description = "是否允许直拨（下采购订单、供应商直送门店）", example = "true")
    private Boolean allowDirect;

}