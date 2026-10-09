package com.lxjl.juling.module.trade.controller.app.order.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.io.Serializable;
import java.util.List;

@Schema(description = "用户 App - 商品结算信息 Response VO")
@Data
public class AppTradeProductSettlementRespVO {

    @Schema(description = "SPU 商品编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Long spuId;

    @Schema(description = "SKU 价格信息数组", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private List<Sku> skus;

    @Schema(description = "SKU 价格信息")
    @Data
    public static class Sku implements Serializable {

        @Schema(description = "商品 SKU 编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
        private Long id;

    }

}
