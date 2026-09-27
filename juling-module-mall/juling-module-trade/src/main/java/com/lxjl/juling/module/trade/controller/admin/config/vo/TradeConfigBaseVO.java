package com.lxjl.juling.module.trade.controller.admin.config.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import java.util.List;

/**
 * 交易中心配置 Base VO，提供给添加、修改、详细的子 VO 使用
 * 如果子 VO 存在差异的字段，请不要添加到这里，影响 Swagger 文档生成
 */
@Data
public class TradeConfigBaseVO {

    // ========== 售后相关 ==========

    @Schema(description = "售后的退款理由", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotEmpty(message = "售后的退款理由不能为空")
    private List<String> afterSaleRefundReasons;

    @Schema(description = "售后的退货理由", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotEmpty(message = "售后的退货理由不能为空")
    private List<String> afterSaleReturnReasons;

    // ========== 配送相关 ==========

    /**
     * 是否启用全场包邮
     */
    @Schema(description = "是否启用全场包邮", requiredMode = Schema.RequiredMode.REQUIRED, example = "true")
    @NotNull(message = "是否启用全场包邮不能为空")
    private Boolean deliveryExpressFreeEnabled;

    @Schema(description = "全场包邮的最小金额", requiredMode = Schema.RequiredMode.REQUIRED, example = "1000")
    @NotNull(message = "全场包邮的最小金额不能为空")
    @PositiveOrZero(message = "全场包邮的最小金额不能是负数")
    private Integer deliveryExpressFreePrice;

    @Schema(description = "是否开启自提", requiredMode = Schema.RequiredMode.REQUIRED, example = "true")
    @NotNull(message = "是否开启自提不能为空")
    private Boolean deliveryPickUpEnabled;

}
