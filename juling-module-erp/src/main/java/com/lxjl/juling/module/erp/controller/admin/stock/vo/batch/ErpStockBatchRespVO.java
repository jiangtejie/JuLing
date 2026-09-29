package com.lxjl.juling.module.erp.controller.admin.stock.vo.batch;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Schema(description = "管理后台 - ERP 批次库存 Response VO")
@Data
public class ErpStockBatchRespVO {

    @Schema(description = "批次库存编号", example = "1")
    private Long id;
    @Schema(description = "仓库编号", example = "2")
    private Long warehouseId;
    @Schema(description = "仓库名称", example = "中心库")
    private String warehouseName;
    @Schema(description = "物料编号", example = "6")
    private Long productId;
    @Schema(description = "物料名称", example = "打包盒")
    private String productName;
    @Schema(description = "SKU 编号（预留，0 = 按物料记账）", example = "0")
    private Long skuId;
    @Schema(description = "批次号", example = "IN20260910-101")
    private String batchNo;
    @Schema(description = "生产日期")
    private LocalDate productionDate;
    @Schema(description = "到期日期")
    private LocalDate expiryDate;
    @Schema(description = "入库日期（FIFO 主排序键）")
    private LocalDate inDate;

    @Schema(description = "在仓数量", example = "100.000000")
    private BigDecimal count;
    @Schema(description = "在途数量", example = "0.000000")
    private BigDecimal transitCount;
    @Schema(description = "占用数量", example = "0.000000")
    private BigDecimal occupiedCount;
    @Schema(description = "待检数量", example = "0.000000")
    private BigDecimal inspectingCount;
    @Schema(description = "可用量 = 在仓 − 占用 + 在途", example = "100.000000")
    private BigDecimal availableCount;

    @Schema(description = "批次单位成本", example = "10.00")
    private BigDecimal unitCost;
    @Schema(description = "批次在仓成本 = 在仓 × 单位成本", example = "1000.00")
    private BigDecimal totalCost;

    @Schema(description = "来源业务类型", example = "10")
    private Integer sourceBizType;
    @Schema(description = "来源单号", example = "QTRK20260928000001")
    private String sourceBizNo;
    @Schema(description = "来源是否已冲销：0 否 / 1 是", example = "0")
    private Integer sourceReversed;

    @Schema(description = "效期状态：EXPIRED 已过期 / WARNING 临期 / NORMAL 正常 / NONE 无有效期", example = "WARNING")
    private String expiryStatus;
    @Schema(description = "距到期天数（负数=已过期天数）", example = "12")
    private Long expiryDays;

    @Schema(description = "备注")
    private String remark;
    @Schema(description = "创建时间")
    private LocalDateTime createTime;

}
