package com.lxjl.juling.module.erp.service.stock.bo;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * 库存明细的创建 Request BO
 *
 * @author 亚特
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ErpStockRecordCreateReqBO {

    /**
     * 产品编号
     */
    @NotNull(message = "产品编号不能为空")
    private Long productId;
    /**
     * 仓库编号
     */
    @NotNull(message = "仓库编号不能为空")
    private Long warehouseId;
    /**
     * 出入库数量
     *
     * 正数，表示入库；负数，表示出库
     */
    @NotNull(message = "出入库数量不能为空")
    private BigDecimal count;

    /**
     * 业务类型
     */
    @NotNull(message = "业务类型不能为空")
    private Integer bizType;
    /**
     * 业务编号
     */
    @NotNull(message = "业务编号不能为空")
    private Long bizId;
    /**
     * 业务项编号
     */
    @NotNull(message = "业务项编号不能为空")
    private Long bizItemId;
    /**
     * 业务单号
     */
    @NotNull(message = "业务单号不能为空")
    private String bizNo;

    // ==================== 批次库存（S2 切片一新增，可选） ====================

    /**
     * 批次号
     *
     * 出库按 FIFO 拆批后，一行流水对应一个批次；为空表示按物料整体记账
     */
    private String batchNo;
    /**
     * 库存状态
     *
     * 取值见 {@link com.lxjl.juling.module.erp.service.stock.ErpStockBatchService} 的 STATE_*；
     * 为空按「在仓」处理
     */
    private String stockState;
    /**
     * 批次单位成本
     */
    private BigDecimal unitCost;
    /**
     * 本行成本金额 = count × unitCost
     */
    private BigDecimal totalCost;
    /**
     * SKU 编号（预留）：空/0 表示按物料记账
     */
    private Long skuId;

    /**
     * 兼容构造：既有调用方（采购入库/销售出库/调拨/盘点等模块）都用 7 参构造，
     * 这里显式保留，避免它们因为新增字段而编译不过。
     */
    public ErpStockRecordCreateReqBO(Long productId, Long warehouseId, BigDecimal count,
                                     Integer bizType, Long bizId, Long bizItemId, String bizNo) {
        this.productId = productId;
        this.warehouseId = warehouseId;
        this.count = count;
        this.bizType = bizType;
        this.bizId = bizId;
        this.bizItemId = bizItemId;
        this.bizNo = bizNo;
    }

}
