package com.lxjl.juling.module.trade.controller.app.order.vo;

import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Schema(description = "用户 App - 门店收货单 Response VO")
@Data
public class AppTradeStoreReceiptRespVO {

    @Schema(description = "编号", example = "1")
    private Long id;

    @Schema(description = "收货单号", example = "MDSH20260929000001")
    private String no;

    @Schema(description = "门店要货单编号", example = "1")
    private Long orderId;

    @Schema(description = "门店要货单号", example = "20260929000001")
    private String orderNo;

    @Schema(description = "门店客户编号", example = "6")
    private Long customerId;

    @Schema(description = "门店名称", example = "耙二哥双碑店")
    private String customerName;

    @Schema(description = "配送出库单号", example = "XSCK20260929000001")
    private String saleOutNo;

    @Schema(description = "状态：0 待确认 / 10 已确认 / 20 已作废", example = "0")
    private Integer status;

    @Schema(description = "状态名", example = "待确认")
    private String statusName;

    @Schema(description = "差异类型", example = "0")
    private Integer diffType;

    @Schema(description = "差异类型名", example = "无差异")
    private String diffTypeName;

    @Schema(description = "应收数量合计", example = "100")
    private BigDecimal totalCount;

    @Schema(description = "实收数量合计", example = "98")
    private BigDecimal receiptCount;

    @Schema(description = "差异数量合计", example = "-2")
    private BigDecimal diffCount;

    @Schema(description = "应收金额合计", example = "1000.00")
    private BigDecimal totalPrice;

    @Schema(description = "实收金额合计", example = "980.00")
    private BigDecimal receiptPrice;

    @Schema(description = "差异金额合计", example = "-20.00")
    private BigDecimal diffAmount;

    @Schema(description = "收货人", example = "张三")
    private String receiverName;

    @Schema(description = "收货人手机号", example = "13800000000")
    private String receiverMobile;

    @Schema(description = "收货凭证图片（JSON 数组字符串）")
    private String fileUrls;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "收货时间")
    private LocalDateTime receiveTime;

    @Schema(description = "创建时间")
    private LocalDateTime createTime;

    @Schema(description = "收货明细")
    private List<Item> items;

    @Schema(description = "用户 App - 门店收货单明细")
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

        @Schema(description = "配送单价", example = "10.00")
        private BigDecimal price;

        @Schema(description = "应收（发货）数量", example = "50")
        private BigDecimal expectCount;

        @Schema(description = "实收数量", example = "48")
        private BigDecimal receiptCount;

        @Schema(description = "差异数量", example = "-2")
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

    }

}