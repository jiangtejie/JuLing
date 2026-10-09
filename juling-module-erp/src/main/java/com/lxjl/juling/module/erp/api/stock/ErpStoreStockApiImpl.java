package com.lxjl.juling.module.erp.api.stock;

import cn.hutool.core.util.ObjectUtil;
import com.lxjl.juling.module.erp.api.stock.dto.ErpStoreReceiptInReqDTO;
import com.lxjl.juling.module.erp.api.stock.dto.ErpStoreStockSummaryRespDTO;
import com.lxjl.juling.module.erp.dal.dataobject.sale.ErpCustomerDO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpWarehouseDO;
import com.lxjl.juling.module.erp.dal.mysql.stock.ErpStockBatchMapper;
import com.lxjl.juling.module.erp.dal.mysql.stock.ErpWarehouseMapper;
import com.lxjl.juling.module.erp.enums.stock.ErpStockRecordBizTypeEnum;
import com.lxjl.juling.module.erp.service.sale.ErpCustomerService;
import com.lxjl.juling.module.erp.service.stock.ErpStockBatchService;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchInReqBO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchReverseReqBO;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertMap;
import static com.lxjl.juling.module.erp.enums.ErrorCodeConstants.STORE_WAREHOUSE_NOT_EXISTS;

/**
 * ERP 门店库存 API 实现（门店收货入库 / 冲销 / 门店库存汇总）
 *
 * 实现要点：
 *   · 门店仓入库直接复用库存中心 {@link ErpStockBatchService#receiveBatch}，
 *     因此门店仓天然带「批次 / 效期 / 四态 / FIFO 成本 / 库存流水」，不必另做一套门店库存表；
 *   · 幂等键 = (STORE_RECEIPT, 收货单行 id)：门店重复提交、前端重试都只入账一次；
 *   · 冲销 = reverseReceive(STORE_RECEIPT → STORE_RECEIPT_CANCEL)，收货单作废时调用。
 *
 * @author 亚特
 */
@Slf4j
@Service
@Validated
public class ErpStoreStockApiImpl implements ErpStoreStockApi {

    @Resource
    private ErpWarehouseMapper warehouseMapper;
    @Resource
    private ErpStockBatchMapper stockBatchMapper;

    @Resource
    private ErpStockBatchService stockBatchService;
    @Resource
    private ErpCustomerService customerService;

    @Override
    public Long getStoreWarehouseId(Long customerId) {
        ErpWarehouseDO warehouse = warehouseMapper.selectByStoreCustomerId(customerId);
        return warehouse == null ? null : warehouse.getId();
    }

    @Override
    public String getStoreWarehouseName(Long customerId) {
        ErpWarehouseDO warehouse = warehouseMapper.selectByStoreCustomerId(customerId);
        return warehouse == null ? null : warehouse.getName();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void receiveStoreReceipt(ErpStoreReceiptInReqDTO reqDTO) {
        // 1. 门店仓必须存在（一店一仓由 sql/local/38 生成）
        Long warehouseId = getStoreWarehouseId(reqDTO.getCustomerId());
        if (warehouseId == null) {
            throw exception(STORE_WAREHOUSE_NOT_EXISTS, reqDTO.getCustomerId());
        }
        // 2. 逐行入库（实收 <= 0 的行跳过：少收到 0 不需要在门店仓留一条空批次）
        LocalDate inDate = ObjectUtil.defaultIfNull(reqDTO.getReceiptTime(), LocalDateTime.now()).toLocalDate();
        for (ErpStoreReceiptInReqDTO.Item item : reqDTO.getItems()) {
            if (item.getProductId() == null || item.getCount() == null
                    || item.getCount().compareTo(BigDecimal.ZERO) <= 0) {
                continue;
            }
            stockBatchService.receiveBatch(new ErpStockBatchInReqBO()
                    .setWarehouseId(warehouseId)
                    .setProductId(item.getProductId())
                    .setCount(item.getCount())
                    .setUnitCost(ObjectUtil.defaultIfNull(item.getUnitCost(), BigDecimal.ZERO))
                    .setBatchNo(item.getBatchNo())
                    .setProductionDate(item.getProductionDate())
                    .setExpiryDate(item.getExpiryDate())
                    .setInDate(inDate)
                    .setBizType(ErpStockRecordBizTypeEnum.STORE_RECEIPT.getType())
                    .setBizId(reqDTO.getReceiptId())
                    .setBizItemId(item.getReceiptItemId())
                    .setBizNo(reqDTO.getReceiptNo())
                    .setRemark(item.getRemark()));
        }
        log.info("[receiveStoreReceipt][收货单({}) 门店({}) 入门店仓({}) 共 {} 行]",
                reqDTO.getReceiptNo(), reqDTO.getCustomerId(), warehouseId,
                reqDTO.getItems() == null ? 0 : reqDTO.getItems().size());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean reverseStoreReceipt(Long receiptItemId, String bizNo) {
        return stockBatchService.reverseReceive(new ErpStockBatchReverseReqBO()
                .setSourceBizType(ErpStockRecordBizTypeEnum.STORE_RECEIPT.getType())
                .setSourceBizItemId(receiptItemId)
                .setTargetBizType(ErpStockRecordBizTypeEnum.STORE_RECEIPT_CANCEL.getType())
                .setBizNo(bizNo));
    }

    @Override
    public List<ErpStoreStockSummaryRespDTO> getStoreStockSummary(Long customerId) {
        // 1. 门店仓（指定门店 = 一个仓；否则全部门店仓）
        List<ErpWarehouseDO> warehouses;
        if (customerId != null) {
            ErpWarehouseDO warehouse = warehouseMapper.selectByStoreCustomerId(customerId);
            warehouses = warehouse == null ? List.of() : List.of(warehouse);
        } else {
            warehouses = warehouseMapper.selectListByType(WAREHOUSE_TYPE_STORE);
        }
        if (warehouses.isEmpty()) {
            return List.of();
        }
        // 2. 库存汇总（按仓库分组）
        List<Long> warehouseIds = warehouses.stream().map(ErpWarehouseDO::getId).toList();
        Map<Long, Map<String, Object>> summaryMap = new LinkedHashMap<>();
        for (Map<String, Object> row : stockBatchMapper.selectStoreSummary(warehouseIds)) {
            Object id = row.get("warehouse_id");
            if (id != null) {
                summaryMap.put(Long.valueOf(id.toString()), row);
            }
        }
        // 3. 门店名称
        Map<Long, ErpCustomerDO> customerMap = convertMap(
                customerService.getCustomerList(warehouses.stream().map(ErpWarehouseDO::getStoreCustomerId).toList()),
                ErpCustomerDO::getId);
        // 4. 组装：没有库存的门店仓也返回一行（数量 0），便于门店列表对齐
        List<ErpStoreStockSummaryRespDTO> result = new ArrayList<>(warehouses.size());
        for (ErpWarehouseDO warehouse : warehouses) {
            Map<String, Object> row = summaryMap.get(warehouse.getId());
            ErpCustomerDO customer = customerMap.get(warehouse.getStoreCustomerId());
            result.add(new ErpStoreStockSummaryRespDTO(
                    warehouse.getStoreCustomerId(),
                    customer == null ? null : customer.getName(),
                    warehouse.getId(), warehouse.getName(),
                    row == null ? 0L : toLong(row.get("product_count")),
                    row == null ? BigDecimal.ZERO : toDecimal(row.get("total_count")),
                    row == null ? BigDecimal.ZERO : toDecimal(row.get("total_amount"))));
        }
        return result;
    }

    /**
     * 仓库类型：门店仓
     */
    private static final String WAREHOUSE_TYPE_STORE = "STORE";

    private static Long toLong(Object value) {
        return value == null ? 0L : Long.valueOf(value.toString());
    }

    private static BigDecimal toDecimal(Object value) {
        return value == null ? BigDecimal.ZERO : new BigDecimal(value.toString());
    }

}
