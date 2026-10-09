package com.lxjl.juling.module.erp.api.stock.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * 门店库存汇总 DTO（一家门店一行）
 *
 * @author 亚特
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ErpStoreStockSummaryRespDTO {

    /** 门店客户编号 */
    private Long customerId;
    /** 门店名称 */
    private String customerName;
    /** 门店仓编号 */
    private Long warehouseId;
    /** 门店仓名称 */
    private String warehouseName;
    /** 有库存的物料数 */
    private Long productCount;
    /** 在仓数量合计 */
    private BigDecimal totalCount;
    /** 在仓成本合计 */
    private BigDecimal totalAmount;

}
