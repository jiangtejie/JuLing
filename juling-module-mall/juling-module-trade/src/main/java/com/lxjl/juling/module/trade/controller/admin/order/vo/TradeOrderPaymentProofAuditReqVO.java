package com.lxjl.juling.module.trade.controller.admin.order.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Schema(description = "管理后台 - 交易订单付款凭证核验 Request VO")
@Data
public class TradeOrderPaymentProofAuditReqVO {

    @Schema(description = "凭证编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    @NotNull(message = "凭证编号不能为空")
    private Long id;

    @Schema(description = "是否确认收款：true 确认、false 驳回", requiredMode = Schema.RequiredMode.REQUIRED, example = "true")
    @NotNull(message = "核验结果不能为空")
    private Boolean approved;

    @Schema(description = "核定收款金额（分）；金额不符时填写实际到账金额，不填按客户申报金额", example = "1000")
    @Min(value = 0, message = "核定金额不能小于 0")
    private Integer confirmedAmount;

    @Schema(description = "核验意见（驳回时建议填写原因，客户可据此重新上传）", example = "截图金额与申报不一致")
    @Size(max = 255, message = "核验意见长度不能超过 255")
    private String auditRemark;

}
