package com.lxjl.juling.module.trade.controller.app.order.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Schema(description = "用户 App - 交易订单付款凭证 Response VO")
@Data
public class AppTradeOrderPaymentProofRespVO {

    @Schema(description = "凭证编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    private Long id;

    @Schema(description = "交易订单编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "2048")
    private Long orderId;

    @Schema(description = "付款凭证图片地址（多图）", requiredMode = Schema.RequiredMode.REQUIRED)
    private List<String> urls;

    @Schema(description = "申报收款金额，单位：分", requiredMode = Schema.RequiredMode.REQUIRED, example = "1000")
    private Integer amount;

    @Schema(description = "核定的收款金额，单位：分", example = "1000")
    private Integer confirmedAmount;

    @Schema(description = "付款人姓名", example = "张三")
    private String payerName;

    @Schema(description = "收款渠道", example = "offline_transfer")
    private String payChannelCode;

    @Schema(description = "转账时间")
    private LocalDateTime transferTime;

    @Schema(description = "客户备注")
    private String remark;

    @Schema(description = "状态：0 待核验、1 已确认、2 已驳回", requiredMode = Schema.RequiredMode.REQUIRED, example = "0")
    private Integer status;

    @Schema(description = "核验时间")
    private LocalDateTime auditTime;

    @Schema(description = "核验意见（驳回原因）")
    private String auditRemark;

    @Schema(description = "提交时间", requiredMode = Schema.RequiredMode.REQUIRED)
    private LocalDateTime createTime;

}
