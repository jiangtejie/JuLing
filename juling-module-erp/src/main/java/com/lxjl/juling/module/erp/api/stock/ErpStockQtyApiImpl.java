package com.lxjl.juling.module.erp.api.stock;

import com.lxjl.juling.module.erp.api.stock.dto.ErpStockAvailableRespDTO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpWarehouseDO;
import com.lxjl.juling.module.erp.dal.mysql.stock.ErpWarehouseMapper;
import com.lxjl.juling.module.erp.service.stock.ErpStockBatchService;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockAvailableRespBO;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * ERP 库存可用量查询 API 实现
 *
 * @author 亚特
 */
@Service
@Validated
public class ErpStockQtyApiImpl implements ErpStockQtyApi {

    @Resource
    private ErpStockBatchService stockBatchService;

    @Resource
    private ErpWarehouseMapper warehouseMapper;

    @Override
    public Long getDefaultWarehouseId() {
        ErpWarehouseDO warehouse = warehouseMapper.selectByDefaultStatus();
        return warehouse == null ? null : warehouse.getId();
    }

    @Override
    public String getDefaultWarehouseName() {
        ErpWarehouseDO warehouse = warehouseMapper.selectByDefaultStatus();
        return warehouse == null ? null : warehouse.getName();
    }

    @Override
    public BigDecimal getAvailableCount(Long warehouseId, Long productId) {
        return stockBatchService.getAvailableCount(warehouseId, productId);
    }

    @Override
    public Map<Long, BigDecimal> getAvailableCountMap(Long warehouseId, Collection<Long> productIds) {
        return stockBatchService.getAvailableCountMap(warehouseId, productIds);
    }

    @Override
    public Map<Long, ErpStockAvailableRespDTO> getAvailableSummaryMap(Long warehouseId, Collection<Long> productIds) {
        Map<Long, ErpStockAvailableRespBO> summaryMap = stockBatchService.getAvailableSummaryMap(warehouseId, productIds);
        Map<Long, ErpStockAvailableRespDTO> result = new LinkedHashMap<>();
        summaryMap.forEach((productId, summary) -> result.put(productId, new ErpStockAvailableRespDTO(
                summary.getProductId(), summary.getWarehouseId(), summary.getOnHandCount(),
                summary.getOccupiedCount(), summary.getTransitCount(), summary.getInspectingCount(),
                summary.getAvailableCount())));
        return result;
    }

}
