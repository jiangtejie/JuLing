package com.lxjl.juling.module.trade.controller.app.order.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Schema(description = "用户 App - 交易订单付款凭证创建 Request VO")
@Data
public class AppTradeOrderPaymentProofCreateReqVO {

    @Schema(description = "交易订单编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    @NotNull(message = "交易订单编号不能为空")
    private Long orderId;

    @Schema(description = "付款凭证图片地址（多图）", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotEmpty(message = "请上传付款凭证")
    private List<String> urls;

    @Schema(description = "申报收款金额，单位：分", requiredMode = Schema.RequiredMode.REQUIRED, example = "1000")
    @NotNull(message = "收款金额不能为空")
    @Min(value = 1, message = "收款金额必须大于 0")
    private Integer amount;

    @Schema(description = "付款人姓名", example = "张三")
    private String payerName;

    @Schema(description = "收款渠道（字典 pay_channel_code 的线下值）", example = "offline_transfer")
    private String payChannelCode;

    @Schema(description = "转账时间")
    private LocalDateTime transferTime;

    @Schema(description = "备注", example = "对公转账，附言：9 月货款")
    private String remark;

}
