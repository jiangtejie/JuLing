package com.lxjl.juling.module.erp.controller.admin.purchase.vo.price;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 采购取价结果 VO
 *
 * <p>供采购订单在「选供应商 + 选物料」时带出默认单价与税率。
 *
 * @author 亚特
 */
@Schema(description = "管理后台 - 采购取价结果 VO")
@Data
public class ErpPurchasePriceMatchRespVO {

    @Schema(description = "命中的价目表编号（为空表示价目表没命中，价格来自物料主数据兜底）", example = "1")
    private Long priceId;

    @Schema(description = "命中的价目表编码", example = "CJJM0001")
    private String priceCode;

    @Schema(description = "命中的价目表名称", example = "2026 年度彩云西南食品报价")
    private String priceName;

    @Schema(description = "命中的明细行编号", example = "2048")
    private Long itemId;

    @Schema(description = "单价（不含税）", example = "27.64")
    private BigDecimal price;

    @Schema(description = "税率(%)", example = "13")
    private BigDecimal taxPercent;

    @Schema(description = "价格来源：PRICE_LIST 价目表 / PRODUCT 物料主数据兜底", example = "PRICE_LIST")
    private String source;

}
