package com.lxjl.juling.module.erp.controller.admin.stock.vo.batch;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

@Schema(description = "管理后台 - ERP 批次库存状态登记 Request VO（在途 / 占用 / 待检）")
@Data
public class ErpStockBatchStateReqVO {

    @Schema(description = "仓库编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "2")
    @NotNull(message = "仓库编号不能为空")
    private Long warehouseId;

    @Schema(description = "物料编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "6")
    @NotNull(message = "物料编号不能为空")
    private Long productId;

    @Schema(description = "批次号", requiredMode = Schema.RequiredMode.REQUIRED, example = "IN20260911-103")
    @NotNull(message = "批次号不能为空")
    private String batchNo;

    @Schema(description = "状态：IN_TRANSIT 在途 / OCCUPIED 占用 / INSPECTING 待检",
            requiredMode = Schema.RequiredMode.REQUIRED, example = "OCCUPIED")
    @NotNull(message = "状态不能为空")
    private String state;

    @Schema(description = "增量数量：正数增加、负数减少", requiredMode = Schema.RequiredMode.REQUIRED, example = "30")
    @NotNull(message = "增量数量不能为空")
    private BigDecimal delta;

    @Schema(description = "备注", example = "订单占用")
    private String remark;

}
