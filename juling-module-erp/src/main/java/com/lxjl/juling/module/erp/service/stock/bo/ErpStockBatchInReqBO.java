package com.lxjl.juling.module.erp.service.stock.bo;

import lombok.Data;
import lombok.experimental.Accessors;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 批次入库 Request BO
 *
 * 由「其它入库单审核」「采购入库单审核」等调用：
 * 按 仓库 × 物料 × 批次 记一批库存，并写一条带批次/成本口径的库存流水（同步增量更新 erp_stock.count）。
 *
 * @author 亚特
 */
@Data
@Accessors(chain = true)
public class ErpStockBatchInReqBO {

    /**
     * 仓库编号
     */
    private Long warehouseId;
    /**
     * 物料编号
     */
    private Long productId;
    /**
     * SKU 编号（预留，为空按 0 处理）
     */
    private Long skuId;
    /**
     * 批次号：为空时按 IN{yyyyMMdd}-{bizItemId} 生成
     */
    private String batchNo;
    /**
     * 生产日期
     */
    private LocalDate productionDate;
    /**
     * 到期日期
     */
    private LocalDate expiryDate;
    /**
     * 入库日期（FIFO 主排序键）：为空取当天
     */
    private LocalDate inDate;
    /**
     * 入库数量（正数）
     */
    private BigDecimal count;
    /**
     * 入库单位成本（成本取入库单价）：为空按 0 处理
     */
    private BigDecimal unitCost;

    /**
     * 业务类型
     *
     * 枚举 {@link com.lxjl.juling.module.erp.enums.stock.ErpStockRecordBizTypeEnum}
     */
    private Integer bizType;
    /**
     * 业务编号
     */
    private Long bizId;
    /**
     * 业务项编号
     */
    private Long bizItemId;
    /**
     * 业务单号
     */
    private String bizNo;
    /**
     * 备注
     */
    private String remark;

}
