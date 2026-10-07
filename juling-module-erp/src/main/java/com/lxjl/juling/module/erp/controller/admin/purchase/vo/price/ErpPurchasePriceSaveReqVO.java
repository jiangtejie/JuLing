package com.lxjl.juling.module.erp.controller.admin.purchase.vo.price;

import com.lxjl.juling.framework.common.validation.InEnum;
import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Schema(description = "管理后台 - 采购价目表新增/修改 Request VO")
@Data
public class ErpPurchasePriceSaveReqVO {

    @Schema(description = "编号", example = "1024")
    private Long id;

    @Schema(description = "价目表名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "2026 年度彩云西南食品报价")
    @NotEmpty(message = "价目表名称不能为空")
    @Size(max = 64, message = "价目表名称长度不能超过 64 个字符")
    private String name;

    @Schema(description = "供应商编号；**为空表示通用价目表**", example = "1")
    private Long supplierId;

    @Schema(description = "是否默认价目表", example = "true")
    private Boolean isDefault;

    @Schema(description = "报价口径：true 表示供应商报的是含税价（只影响录入方向，行上的单价恒为不含税）", example = "false")
    private Boolean priceIncludesTax;

    @Schema(description = "定价员编号", example = "1")
    private Long pricerUserId;

    @Schema(description = "状态", requiredMode = Schema.RequiredMode.REQUIRED, example = "0")
    @NotNull(message = "状态不能为空")
    @InEnum(value = CommonStatusEnum.class)
    private Integer status;

    @Schema(description = "生效日期", example = "2026-01-01")
    private LocalDate effectiveDate;

    @Schema(description = "失效日期（为空表示长期有效）", example = "2026-12-31")
    private LocalDate expiryDate;

    @Schema(description = "备注", example = "年度框架协议价")
    @Size(max = 255, message = "备注长度不能超过 255 个字符")
    private String remark;

    @Schema(description = "价目表明细", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotEmpty(message = "价目表明细不能为空")
    @Valid
    private List<Item> items;

    @Schema(description = "价目表明细行")
    @Data
    public static class Item {

        @Schema(description = "行编号", example = "2048")
        private Long id;

        @Schema(description = "物料编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "2048")
        @NotNull(message = "物料不能为空")
        private Long productId;

        @Schema(description = "单价（不含税）", requiredMode = Schema.RequiredMode.REQUIRED, example = "27.64")
        @NotNull(message = "单价不能为空")
        @DecimalMin(value = "0", message = "单价不能为负")
        private BigDecimal price;

        @Schema(description = "税率(%)", example = "13")
        @DecimalMin(value = "0", message = "税率不能小于 0")
        @DecimalMax(value = "100", message = "税率不能大于 100")
        private BigDecimal taxPercent;

        @Schema(description = "备注", example = "")
        @Size(max = 255, message = "备注长度不能超过 255 个字符")
        private String remark;

    }

}
