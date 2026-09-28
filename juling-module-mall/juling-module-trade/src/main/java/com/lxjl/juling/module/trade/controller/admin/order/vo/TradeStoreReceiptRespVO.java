package com.lxjl.juling.module.trade.controller.admin.order.vo;

import cn.idev.excel.annotation.ExcelIgnoreUnannotated;
import cn.idev.excel.annotation.ExcelProperty;
import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Schema(description = "管理后台 - 门店收货单 Response VO")
@Data
@ExcelIgnoreUnannotated
public class TradeStoreReceiptRespVO {

    @Schema(description = "编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    @ExcelProperty("编号")
    private Long id;

    @Schema(description = "收货单号", requiredMode = Schema.RequiredMode.REQUIRED, example = "MDSH20260929000001")
    @ExcelProperty("收货单号")
    private String no;

    @Schema(description = "门店要货单编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Long orderId;

    @Schema(description = "门店要货单号", example = "20260929000001")
    @ExcelProperty("要货单号")
    private String orderNo;

    @Schema(description = "门店客户编号", example = "6")
    private Long customerId;

    @Schema(description = "门店名称", example = "耙二哥双碑店")
    @ExcelProperty("门店")
    private String customerName;

    @Schema(description = "门店部门编号", example = "134")
    private Long deptId;

    @Schema(description = "门店部门名称", example = "耙二哥双碑店")
    @ExcelProperty("所属部门")
    private String deptName;

    @Schema(description = "门店仓编号", example = "4")
    private Long warehouseId;

    @Schema(description = "门店仓名称", example = "门店仓·耙二哥双碑店")
    @ExcelProperty("门店仓")
    private String warehouseName;

    @Schema(description = "配送出库单编号", example = "1")
    private Long saleOutId;

    @Schema(description = "配送出库单号", example = "XSCK20260929000001")
    @ExcelProperty("配送出库单号")
    private String saleOutNo;

    @Schema(description = "状态：0 待确认 / 10 已确认 / 20 已作废", example = "10")
    @ExcelProperty("状态")
    private Integer status;

    @Schema(description = "状态名", example = "已确认")
    @ExcelProperty("状态名")
    private String statusName;

    @Schema(description = "差异类型：0 无差异 / 1 少收 / 2 多收 / 3 破损 / 4 混合", example = "1")
    @ExcelProperty("差异类型")
    private Integer diffType;

    @Schema(description = "差异类型名", example = "少收")
    @ExcelProperty("差异类型名")
    private String diffTypeName;

    @Schema(description = "应收数量合计", example = "100")
    @ExcelProperty("应收数量")
    private BigDecimal totalCount;

    @Schema(description = "实收数量合计", example = "98")
    @ExcelProperty("实收数量")
    private BigDecimal receiptCount;

    @Schema(description = "差异数量合计（正数=多收）", example = "-2")
    @ExcelProperty("差异数量")
    private BigDecimal diffCount;

    @Schema(description = "应收金额合计", example = "1000.00")
    @ExcelProperty("应收金额")
    private BigDecimal totalPrice;

    @Schema(description = "实收金额合计", example = "980.00")
    @ExcelProperty("实收金额")
    private BigDecimal receiptPrice;

    @Schema(description = "差异金额合计（正数=多收）", example = "-20.00")
    @ExcelProperty("差异金额")
    private BigDecimal diffAmount;

    @Schema(description = "收货时间")
    @ExcelProperty("收货时间")
    private LocalDateTime receiveTime;

    @Schema(description = "收货人", example = "张三")
    @ExcelProperty("收货人")
    private String receiverName;

    @Schema(description = "收货人手机号", example = "13800000000")
    private String receiverMobile;

    @Schema(description = "收货凭证图片（JSON 数组字符串）")
    private String fileUrls;

    @Schema(description = "备注")
    @ExcelProperty("备注")
    private String remark;

    @Schema(description = "作废原因")
    private String cancelReason;

    @Schema(description = "创建人")
    private String creator;

    @Schema(description = "创建人昵称", example = "管理员")
    private String creatorName;

    @Schema(description = "创建时间", requiredMode = Schema.RequiredMode.REQUIRED)
    private LocalDateTime createTime;

    @Schema(description = "收货明细")
    private List<Item> items;

    @Schema(description = "管理后台 - 门店收货单明细")
    @Data
    public static class Item {

        @Schema(description = "编号", example = "1")
        private Long id;

        @Schema(description = "门店要货单行编号", example = "1")
        private Long orderItemId;

        @Schema(description = "商品 SPU 编号", example = "1")
        private Long spuId;

        @Schema(description = "商品 SKU 编号", example = "1")
        private Long skuId;

        @Schema(description = "商品名称", example = "鲜毛肚")
        private String spuName;

        @Schema(description = "商品属性")
        private String properties;

        @Schema(description = "商品图片")
        private String picUrl;

        @Schema(description = "ERP 物料编号", example = "20")
        private Long productId;

        @Schema(description = "ERP 物料名称", example = "鲜毛肚")
        private String productName;

        @Schema(description = "配送单价（门店进货成本）", example = "10.00")
        private BigDecimal price;

        @Schema(description = "应收（发货）数量", example = "50")
        private BigDecimal expectCount;

        @Schema(description = "实收数量", example = "48")
        private BigDecimal receiptCount;

        @Schema(description = "差异数量（正数=多收）", example = "-2")
        private BigDecimal diffCount;

        @Schema(description = "差异金额", example = "-20.00")
        private BigDecimal diffAmount;

        @Schema(description = "差异原因", example = "少一箱")
        private String diffReason;

        @Schema(description = "批次号", example = "B20260901")
        private String batchNo;

        @Schema(description = "生产日期")
        @JsonFormat(pattern = "yyyy-MM-dd")
        private LocalDate productionDate;

        @Schema(description = "到期日期")
        @JsonFormat(pattern = "yyyy-MM-dd")
        private LocalDate expiryDate;

        @Schema(description = "备注")
        private String remark;

    }

}