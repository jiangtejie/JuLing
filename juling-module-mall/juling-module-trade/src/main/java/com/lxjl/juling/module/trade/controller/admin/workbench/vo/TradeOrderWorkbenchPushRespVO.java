package com.lxjl.juling.module.trade.controller.admin.workbench.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 订单工作台 - 分料下推 Response VO
 *
 * @author 亚特
 */
@Schema(description = "管理后台 - 订单工作台分料下推 Response VO")
@Data
public class TradeOrderWorkbenchPushRespVO {

    @Schema(description = "生成/关联的 ERP 单据")
    private List<Result> results;

    @Schema(description = "下推结果")
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Result {

        @Schema(description = "订单行编号", example = "2048")
        private Long itemId;
        @Schema(description = "分料方式：CENTRAL 统配 / DIRECT 直拨", example = "CENTRAL")
        private String allocMode;
        @Schema(description = "目标单据类型（bill_type.code）：DELIVERY_OUT 配送出库 / PURCHASE_ORDER 采购订单", example = "DELIVERY_OUT")
        private String billType;
        @Schema(description = "目标单据编号", example = "1")
        private Long billId;
        @Schema(description = "目标单据号", example = "XSCK20260928000001")
        private String billNo;

    }

}
