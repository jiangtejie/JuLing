package com.lxjl.juling.module.erp.service.stock.bo;

import lombok.Data;
import lombok.experimental.Accessors;

import java.math.BigDecimal;

/**
 * 可用量概览 BO：可用量 = 在仓 − 占用 + 在途
 *
 * @author 亚特
 */
@Data
@Accessors(chain = true)
public class ErpStockAvailableRespBO {

    /**
     * 物料编号
     */
    private Long productId;
    /**
     * 仓库编号
     */
    private Long warehouseId;
    /**
     * 在仓数量
     */
    private BigDecimal onHandCount = BigDecimal.ZERO;
    /**
     * 占用数量
     */
    private BigDecimal occupiedCount = BigDecimal.ZERO;
    /**
     * 在途数量
     */
    private BigDecimal transitCount = BigDecimal.ZERO;
    /**
     * 待检数量
     */
    private BigDecimal inspectingCount = BigDecimal.ZERO;
    /**
     * 可用量 = onHandCount − occupiedCount + transitCount
     */
    private BigDecimal availableCount = BigDecimal.ZERO;

}
