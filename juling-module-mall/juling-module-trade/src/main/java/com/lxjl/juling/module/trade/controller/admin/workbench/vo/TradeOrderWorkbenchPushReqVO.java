package com.lxjl.juling.module.trade.controller.admin.workbench.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

/**
 * 订单工作台 - 分料下推 Request VO
 *
 * @author 亚特
 */
@Schema(description = "管理后台 - 订单工作台分料下推 Request VO")
@Data
public class TradeOrderWorkbenchPushReqVO {

    @Schema(description = "要货单编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    @NotNull(message = "要货单编号不能为空")
    private Long orderId;

    @Schema(description = "发货仓库编号（统配用；为空取 ERP 默认仓库=中心库）", example = "2")
    private Long warehouseId;

    @Schema(description = "直拨供应商编号（行上未指定时用这个），erp_supplier.id", example = "2")
    private Long supplierId;

    @Schema(description = "结算账户编号", example = "1")
    private Long accountId;

    @Schema(description = "分料行", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotEmpty(message = "分料行不能为空")
    @Valid
    private List<Item> items;

    @Schema(description = "分料行")
    @Data
    public static class Item {

        @Schema(description = "订单行编号（trade_order_item.id）", requiredMode = Schema.RequiredMode.REQUIRED, example = "2048")
        @NotNull(message = "订单行编号不能为空")
        private Long itemId;

        @Schema(description = "分料方式：CENTRAL 统配 / DIRECT 直拨", requiredMode = Schema.RequiredMode.REQUIRED, example = "CENTRAL")
        @NotNull(message = "分料方式不能为空")
        private String allocMode;

        @Schema(description = "下推数量（为空按整行数量），必须 ≤ 要货数量", example = "2")
        private BigDecimal count;

        @Schema(description = "供应商编号（直拨必填；为空时回退请求级 supplierId）", example = "2")
        private Long supplierId;

    }

}
