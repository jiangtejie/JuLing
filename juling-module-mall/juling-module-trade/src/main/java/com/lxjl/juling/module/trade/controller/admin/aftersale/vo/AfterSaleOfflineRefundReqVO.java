package com.lxjl.juling.module.trade.controller.admin.aftersale.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

/**
 * 管理后台 - 售后「线下退款」登记 Request VO
 *
 * 线下收款（转账/现金）没有线上退款单可发起：商家实际把钱退给客户后，
 * 在此登记退款渠道、回执凭证与备注，登记即视为退款完成。
 *
 * @author 亚特
 */
@Schema(description = "管理后台 - 售后线下退款登记 Request VO")
@Data
public class AfterSaleOfflineRefundReqVO {

    @Schema(description = "售后编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    @NotNull(message = "售后编号不能为空")
    private Long id;

    @Schema(description = "退款渠道（字典 pay_channel_code 的线下值）", example = "offline_transfer")
    private String refundChannelCode;

    @Schema(description = "退款凭证图片（多图，如转账回单）")
    private List<String> refundProofUrls;

    @Schema(description = "退款备注", example = "已对公转账退回，附言：9 月货款退款")
    @Size(max = 255, message = "退款备注长度不能超过 255")
    private String refundRemark;

}
