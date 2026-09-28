package com.lxjl.juling.module.trade.controller.app.order.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Schema(description = "用户 App - 待收货收货单 Response VO（列表用，不含明细）")
@Data
public class AppTradeStoreReceiptPendingRespVO {

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

    @Schema(description = "状态", example = "0")
    private Integer status;

    @Schema(description = "状态名", example = "待确认")
    private String statusName;

    @Schema(description = "差异类型", example = "0")
    private Integer diffType;

    @Schema(description = "差异类型名", example = "无差异")
    private String diffTypeName;

    @Schema(description = "应收数量合计", example = "100")
    private BigDecimal totalCount;

    @Schema(description = "应收金额合计", example = "1000.00")
    private BigDecimal totalPrice;

    @Schema(description = "收货时间")
    private LocalDateTime receiveTime;

    @Schema(description = "创建时间")
    private LocalDateTime createTime;

}
