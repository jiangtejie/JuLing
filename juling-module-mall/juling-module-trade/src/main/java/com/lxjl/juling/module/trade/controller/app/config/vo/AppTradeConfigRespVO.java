package com.lxjl.juling.module.trade.controller.app.config.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import jakarta.validation.constraints.NotNull;
import java.util.List;

@Schema(description = "用户 App - 交易配置 Response VO")
@Data
public class AppTradeConfigRespVO {

    @Schema(description = "腾讯地图 KEY", requiredMode = Schema.RequiredMode.REQUIRED, example = "123456")
    private String tencentLbsKey;

    // ========== 售后相关 ==========

    @Schema(description = "售后的退款理由", requiredMode = Schema.RequiredMode.REQUIRED)
    private List<String> afterSaleRefundReasons;

    @Schema(description = "售后的退货理由", requiredMode = Schema.RequiredMode.REQUIRED)
    private List<String> afterSaleReturnReasons;

}
