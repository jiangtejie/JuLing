package com.lxjl.juling.module.trade.controller.admin.workbench.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 订单工作台 - 待处理要货单 Response VO
 *
 * @author 亚特
 */
@Schema(description = "管理后台 - 订单工作台待处理要货单 Response VO")
@Data
public class TradeOrderWorkbenchRespVO {

    @Schema(description = "订单编号", example = "1024")
    private Long id;
    @Schema(description = "要货单号", example = "o202609280001")
    private String no;
    @Schema(description = "下单时间")
    private LocalDateTime createTime;

    @Schema(description = "下单门店客户编号", example = "9")
    private Long customerId;
    @Schema(description = "下单门店名称", example = "卤校长杨家坪店（门店）")
    private String customerName;
    @Schema(description = "下单门店所属部门编号", example = "137")
    private Long deptId;
    @Schema(description = "店型：DIRECT 直营 / FRANCHISE 加盟", example = "FRANCHISE")
    private String storeType;
    @Schema(description = "结算模式：PREPAID 先款后货 / MONTHLY 月结", example = "PREPAID")
    private String settlementMode;

    @Schema(description = "应付金额，单位：分", example = "5400")
    private Integer payPrice;
    @Schema(description = "已确认收款金额，单位：分", example = "5400")
    private Integer paidAmount;
    @Schema(description = "收款状态（TradeOrderReceiveStatusEnum）", example = "4")
    private Integer paymentProofStatus;
    @Schema(description = "审核状态（TradeOrderAuditStatusEnum）", example = "20")
    private Integer auditStatus;
    @Schema(description = "订单状态（TradeOrderStatusEnum）", example = "10")
    private Integer status;

    @Schema(description = "订单行数", example = "2")
    private Integer itemCount;
    @Schema(description = "未分料行数", example = "2")
    private Integer pendingItemCount;

}
