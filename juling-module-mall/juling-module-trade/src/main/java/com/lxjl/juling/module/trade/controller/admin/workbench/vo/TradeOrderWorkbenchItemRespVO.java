package com.lxjl.juling.module.trade.controller.admin.workbench.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 订单工作台 - 要货单明细行 Response VO（含物料分料属性与下推情况）
 *
 * @author 亚特
 */
@Schema(description = "管理后台 - 订单工作台明细行 Response VO")
@Data
public class TradeOrderWorkbenchItemRespVO {

    @Schema(description = "订单行编号", example = "2048")
    private Long id;
    @Schema(description = "商品 SPU 编号", example = "17")
    private Long spuId;
    @Schema(description = "商品名称", example = "午餐肉")
    private String spuName;
    @Schema(description = "商品 SKU 编号", example = "17")
    private Long skuId;
    @Schema(description = "商品图片")
    private String picUrl;

    @Schema(description = "要货数量", example = "2")
    private Integer count;
    @Schema(description = "单价，单位：分", example = "11000")
    private Integer price;
    @Schema(description = "小计金额，单位：分", example = "22000")
    private Integer payPrice;

    @Schema(description = "对应的 ERP 物料编号", example = "3")
    private Long erpProductId;
    @Schema(description = "对应的 ERP 物料名称", example = "午餐肉")
    private String erpProductName;
    @Schema(description = "ERP 物料条码（= 商城 SKU 条码）", example = "DS0001")
    private String erpProductBarCode;
    @Schema(description = "是否允许统配", example = "true")
    private Boolean allowCentral;
    @Schema(description = "是否允许直拨", example = "true")
    private Boolean allowDirect;

    @Schema(description = "已选分料方式：CENTRAL 统配 / DIRECT 直拨；空=未分料", example = "CENTRAL")
    private String allocMode;
    @Schema(description = "已下推数量", example = "1.000000")
    private BigDecimal allocCount;
    @Schema(description = "已下推的单据类型（bill_type.code）", example = "DELIVERY_OUT")
    private String pushedBillType;
    @Schema(description = "已下推的单据号", example = "XSCK20260928000001")
    private String pushedBillNo;

    @Schema(description = "可下推数量（= 要货数量 − 已下推数量）", example = "2")
    private BigDecimal availableCount;
    @Schema(description = "可下推数量提示", example = "可下推 2（未下推）")
    private String availableHint;

}
