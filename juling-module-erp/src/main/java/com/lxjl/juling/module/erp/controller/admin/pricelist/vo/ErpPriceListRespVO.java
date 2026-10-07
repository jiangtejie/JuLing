package com.lxjl.juling.module.erp.controller.admin.pricelist.vo;

import cn.idev.excel.annotation.ExcelIgnoreUnannotated;
import cn.idev.excel.annotation.ExcelProperty;
import com.lxjl.juling.framework.excel.core.annotations.DictFormat;
import com.lxjl.juling.framework.excel.core.convert.DictConvert;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Schema(description = "管理后台 - 价目表 Response VO")
@Data
@ExcelIgnoreUnannotated
public class ErpPriceListRespVO {

    @Schema(description = "编号", example = "1024")
    private Long id;

    @Schema(description = "价目表类型", example = "PURCHASE")
    private String priceType;

    @Schema(description = "业务编码", example = "CJJM0001")
    @ExcelProperty("编码")
    private String code;

    @Schema(description = "价目表名称", example = "2026 年度彩云西南食品报价")
    @ExcelProperty("名称")
    private String name;

    @Schema(description = "适用范围摘要（供应商名 / 门店名，多个用 、 连接；通用范围为空）", example = "萍姐鸡煲香水门店")
    @ExcelProperty("适用范围")
    private String scopeSummary;

    @Schema(description = "是否默认价目表（适用范围里任一行为默认即为 true，仅用于列表展示）", example = "true")
    @ExcelProperty("默认价目表")
    private Boolean isDefault;

    @Schema(description = "报价口径：true 表示含税报价", example = "false")
    @ExcelProperty("含税报价")
    private Boolean priceIncludesTax;

    @Schema(description = "定价员编号", example = "1")
    private Long pricerUserId;

    @Schema(description = "定价员名称", example = "张新宇")
    @ExcelProperty("定价员")
    private String pricerUserName;

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

    @Schema(description = "适用范围")
    private List<Scope> scopes;

    @Schema(description = "价目表明细")
    private List<Item> items;

    @Schema(description = "适用范围行")
    @Data
    public static class Scope {

        @Schema(description = "行编号", example = "2048")
        private Long id;

        @Schema(description = "适用对象编号；为空表示通用范围", example = "1")
        private Long partnerId;

        @Schema(description = "适用对象名称（供应商名 / 门店名；通用范围显示为「通用（不限）」）", example = "萍姐鸡煲香水门店")
        private String partnerName;

        @Schema(description = "该对象下的默认价目表", example = "false")
        private Boolean isDefault;

        @Schema(description = "备注", example = "")
        private String remark;

    }

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

        @Schema(description = "规格型号（取物料的规格，仅展示）", example = "直径34cm")
        private String spec;

        @Schema(description = "计价单位名称（取物料的单位）", example = "瓶")
        private String unitName;

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
