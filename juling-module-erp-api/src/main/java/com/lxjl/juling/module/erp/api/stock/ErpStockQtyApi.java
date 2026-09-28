package com.lxjl.juling.module.erp.api.stock;

import com.lxjl.juling.module.erp.api.stock.dto.ErpStockAvailableRespDTO;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.Map;

/**
 * ERP 库存可用量查询 API（库存中心对外出口）
 *
 * 其它模块（商城/门店要货工作台、H5 订货…）**不能**直接读 erp_stock_batch，只能走本接口：
 *   · 可用量 = 在仓 − 占用 + 在途（四态口径，见 docs/stock-center.md）；
 *   · 批次/效期/FIFO 成本属于 ERP 内部实现，不通过本接口暴露。
 *
 * @author 亚特
 */
public interface ErpStockQtyApi {

    /**
     * 默认发货仓（erp_warehouse.default_status = true，当前为「中心库」）
     *
     * @return 仓库编号；没有默认仓时返回 null
     */
    Long getDefaultWarehouseId();

    /**
     * 默认发货仓名称（用于工作台文案「中心库可用 …」）
     *
     * @return 仓库名称；没有默认仓时返回 null
     */
    String getDefaultWarehouseName();

    /**
     * 查询某物料在某仓库的可用量 = 在仓 − 占用 + 在途
     *
     * @param warehouseId 仓库编号
     * @param productId   物料编号
     * @return 可用量（无批次时返回 0）
     */
    BigDecimal getAvailableCount(Long warehouseId, Long productId);

    /**
     * 批量查询可用量
     *
     * @param warehouseId 仓库编号
     * @param productIds  物料编号集合
     * @return productId -> 可用量（查不到的物料不出现在 Map 中）
     */
    Map<Long, BigDecimal> getAvailableCountMap(Long warehouseId, Collection<Long> productIds);

    /**
     * 批量查询四态数量与可用量（工作台要展示「在仓 − 占用 + 在途」的明细）
     *
     * @param warehouseId 仓库编号
     * @param productIds  物料编号集合
     * @return productId -> 可用量明细
     */
    Map<Long, ErpStockAvailableRespDTO> getAvailableSummaryMap(Long warehouseId, Collection<Long> productIds);

}
