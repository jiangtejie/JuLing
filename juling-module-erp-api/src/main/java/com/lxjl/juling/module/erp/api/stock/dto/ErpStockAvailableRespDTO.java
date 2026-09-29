package com.lxjl.juling.module.erp.api.stock.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * ERP 库存可用量 DTO（库存中心 · 四态口径）
 *
 * 可用量 = 在仓 − 占用 + 在途；待检不计入可用量。
 *
 * @author 亚特
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ErpStockAvailableRespDTO {

    /**
     * 物料编号（= erp_product.id）
     */
    private Long productId;
    /**
     * 仓库编号
     */
    private Long warehouseId;
    /**
     * 在仓数量
     */
    private BigDecimal onHandCount;
    /**
     * 占用数量（在仓的子集）
     */
    private BigDecimal occupiedCount;
    /**
     * 在途数量
     */
    private BigDecimal transitCount;
    /**
     * 待检数量
     */
    private BigDecimal inspectingCount;
    /**
     * 可用量 = onHandCount − occupiedCount + transitCount
     */
    private BigDecimal availableCount;

}
