package com.lxjl.juling.module.erp.controller.admin.purchase.vo.price;

import com.lxjl.juling.framework.excel.core.annotations.DictFormat;
import com.lxjl.juling.framework.excel.core.convert.DictConvert;
import cn.idev.excel.annotation.ExcelIgnoreUnannotated;
import cn.idev.excel.annotation.ExcelProperty;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Schema(description = "管理后台 - 采购价目表 Response VO")
@Data
@ExcelIgnoreUnannotated
public class ErpPurchasePriceRespVO {

    @Schema(description = "编号", example = "1024")
    private Long id;

    @Schema(description = "业务编码", example = "CJJM0001")
    @ExcelProperty("编码")
    private String code;

    @Schema(description = "价目表名称", example = "2026 年度彩云西南食品报价")
    @ExcelProperty("名称")
    private String name;

    @Schema(description = "供应商编号", example = "1")
    private Long supplierId;

    @Schema(description = "供应商名称（通用价目表为空）", example = "重庆彩云西南食品有限公司")
    @ExcelProperty("供应商")
    private String supplierName;

    @Schema(description = "是否默认价目表", example = "true")
    @ExcelProperty("默认价目表")
    private Boolean isDefault;

    @Schema(description = "状态", example = "0")
    @ExcelProperty(value = "状态", converter = DictConvert.class)
    @DictFormat("common_status")
    private Integer status;

    @Schema(description = "生效日期", example = "2026-01-01")
    @ExcelProperty("生效日期")
    private LocalDate effectiveDate;

    @Schema(description = "失效日期", example = "2026-12-31")
    @ExcelProperty("失效日期")
    private LocalDate expiryDate;

    @Schema(description = "备注", example = "年度框架协议价")
    @ExcelProperty("备注")
    private String remark;

    @Schema(description = "明细行数", example = "12")
    private Integer itemCount;

    @Schema(description = "创建时间")
    @ExcelProperty("创建时间")
    private LocalDateTime createTime;

    @Schema(description = "价目表明细")
    private List<Item> items;

    @Schema(description = "价目表明细行")
    @Data
    public static class Item {

        @Schema(description = "行编号", example = "2048")
        private Long id;

        @Schema(description = "物料编号", example = "2048")
        private Long productId;

        @Schema(description = "物料编码", example = "WL000001")
        private String productCode;

        @Schema(description = "物料名称", example = "黑芝麻酱454g")
        private String productName;

        @Schema(description = "计价单位名称（取物料的单位）", example = "瓶")
        private String unitName;

        @Schema(description = "数量区间起（含）", example = "0")
        private BigDecimal fromQty;

        @Schema(description = "数量区间止（不含）", example = "10")
        private BigDecimal toQty;

        @Schema(description = "单价（不含税）", example = "27.64")
        private BigDecimal price;

        @Schema(description = "含税单价 = price × (1 + taxPercent/100)", example = "31.23")
        private BigDecimal taxPrice;

        @Schema(description = "税率(%)", example = "13")
        private BigDecimal taxPercent;

        @Schema(description = "备注", example = "")
        private String remark;

    }

}
