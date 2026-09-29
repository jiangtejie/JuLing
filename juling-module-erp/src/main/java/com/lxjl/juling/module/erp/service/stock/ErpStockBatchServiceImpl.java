package com.lxjl.juling.module.erp.service.stock;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.IdUtil;
import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.number.MoneyUtils;
import com.lxjl.juling.module.erp.controller.admin.stock.vo.batch.ErpStockBatchPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockBatchDO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockRecordDO;
import com.lxjl.juling.module.erp.dal.mysql.stock.ErpStockBatchMapper;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockAvailableRespBO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchInReqBO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchIssueRespBO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchOutReqBO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchReverseReqBO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchStateReqBO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockRecordCreateReqBO;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.module.erp.service.stock.ErpStockBatchErrorCodeConstants.*;

/**
 * ERP 批次库存 Service 实现类（库存中心 · 多状态 + 批次/效期 + FIFO 成本）
 *
 * 三条硬口径（见 docs/stock-center.md）：
 *   1) 可用量 = 在仓 − 占用 + 在途（{@link #getAvailableCount}）；
 *   2) 出库按批次 FIFO：in_date 升序 → expiry_date 升序（无有效期排最后）→ id 升序；
 *   3) 成本按批次结转：出库写「一行一批次」的流水（负数），total_cost 同额结转。
 *
 * 与 erp_stock 的关系是**双写**：本服务的每一次在仓数量变动都会经
 * {@link ErpStockRecordService#createStockRecord} 增量更新 erp_stock.count（语义不变），
 * 因此老的查询（ErpStockService / ErpStockController）无需改动即可继续工作。
 *
 * @author 亚特
 */
@Slf4j
@Service
@Validated
public class ErpStockBatchServiceImpl implements ErpStockBatchService {

    /**
     * 默认 SKU：0 = 未细分 SKU（本切片按物料记账）
     */
    private static final Long DEFAULT_SKU_ID = 0L;
    /**
     * 临期预警默认天数
     */
    private static final Integer DEFAULT_WARN_DAYS = 30;
    /**
     * 来源是否已冲销：否 / 是
     */
    private static final Integer REVERSED_NO = 0;
    private static final Integer REVERSED_YES = 1;

    private static final DateTimeFormatter BATCH_NO_DATE = DateTimeFormatter.ofPattern("yyyyMMdd");

    @Resource
    private ErpStockBatchMapper batchMapper;

    @Resource
    private ErpStockRecordService stockRecordService;

    // ==================== 入库 ====================

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ErpStockBatchDO receiveBatch(ErpStockBatchInReqBO reqBO) {
        // 1. 参数归一
        Long skuId = ObjectUtil.defaultIfNull(reqBO.getSkuId(), DEFAULT_SKU_ID);
        BigDecimal count = reqBO.getCount();
        if (count == null || count.compareTo(BigDecimal.ZERO) <= 0) {
            throw exception(STOCK_BATCH_COUNT_ILLEGAL, count);
        }
        LocalDate inDate = ObjectUtil.defaultIfNull(reqBO.getInDate(), LocalDate.now());
        BigDecimal unitCost = ObjectUtil.defaultIfNull(reqBO.getUnitCost(), BigDecimal.ZERO);
        String batchNo = StrUtil.blankToDefault(reqBO.getBatchNo(), buildDefaultBatchNo(inDate, reqBO.getBizItemId()));

        // 2. 幂等：同一来源项（业务类型 + 业务项）只入账一次
        ErpStockBatchDO batch = batchMapper.selectBySource(reqBO.getBizType(), reqBO.getBizItemId());
        if (batch != null && !REVERSED_YES.equals(batch.getSourceReversed())) {
            log.info("[receiveBatch][来源({}/{})已入账，幂等跳过]", reqBO.getBizType(), reqBO.getBizItemId());
            return batch;
        }
        // 3.1 反审核后重新审核：复位并补回数量与成本
        if (batch != null) {
            ErpStockBatchDO updateObj = new ErpStockBatchDO();
            updateObj.setId(batch.getId());
            updateObj.setUnitCost(unitCost);
            updateObj.setInDate(inDate);
            updateObj.setProductionDate(reqBO.getProductionDate());
            updateObj.setExpiryDate(reqBO.getExpiryDate());
            updateObj.setSourceReversed(REVERSED_NO);
            batchMapper.updateById(updateObj);
            batchMapper.updateCountIncrement(batch.getId(), count);
            batch = batchMapper.selectById(batch.getId());
            log.info("[receiveBatch][来源({}/{})反审核后重新审核，复位批次({})]",
                    reqBO.getBizType(), reqBO.getBizItemId(), batchNo);
        } else {
            // 3.2 新建批次
            batch = new ErpStockBatchDO();
            batch.setWarehouseId(reqBO.getWarehouseId());
            batch.setProductId(reqBO.getProductId());
            batch.setSkuId(skuId);
            batch.setBatchNo(batchNo);
            batch.setProductionDate(reqBO.getProductionDate());
            batch.setExpiryDate(reqBO.getExpiryDate());
            batch.setInDate(inDate);
            batch.setCount(count);
            batch.setTransitCount(BigDecimal.ZERO);
            batch.setOccupiedCount(BigDecimal.ZERO);
            batch.setInspectingCount(BigDecimal.ZERO);
            batch.setUnitCost(unitCost);
            batch.setTotalCost(MoneyUtils.priceMultiply(unitCost, count));
            batch.setSourceBizType(reqBO.getBizType());
            batch.setSourceBizId(reqBO.getBizId());
            batch.setSourceBizItemId(reqBO.getBizItemId());
            batch.setSourceBizNo(reqBO.getBizNo());
            batch.setSourceReversed(REVERSED_NO);
            batch.setRemark(reqBO.getRemark());
            batchMapper.insert(batch);
        }

        // 4. 库存流水（正数）+ 同步 erp_stock.count
        writeStockRecord(reqBO.getProductId(), reqBO.getWarehouseId(), count, reqBO.getBizType(), reqBO.getBizId(),
                reqBO.getBizItemId(), reqBO.getBizNo(), batch.getBatchNo(), STATE_IN_STOCK, unitCost,
                MoneyUtils.priceMultiply(unitCost, count), skuId);
        log.info("[receiveBatch][物料({})仓库({})批次({})入库 {}，单位成本 {}，来源 {}]",
                reqBO.getProductId(), reqBO.getWarehouseId(), batch.getBatchNo(), count, unitCost, reqBO.getBizNo());
        return batch;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean reverseReceive(ErpStockBatchReverseReqBO reqBO) {
        // 1. 定位来源批次 + 幂等判断
        ErpStockBatchDO batch = batchMapper.selectBySource(reqBO.getSourceBizType(), reqBO.getSourceBizItemId());
        if (batch == null) {
            log.warn("[reverseReceive][来源({}/{})无批次记录，跳过]", reqBO.getSourceBizType(), reqBO.getSourceBizItemId());
            return false;
        }
        if (REVERSED_YES.equals(batch.getSourceReversed())) {
            log.info("[reverseReceive][来源({}/{})已冲销，幂等跳过]", reqBO.getSourceBizType(), reqBO.getSourceBizItemId());
            return false;
        }
        // 2. 冲销数量 = 本次（尚未被冲销的那一次）入库量，而不是该来源项历史入库流水之和：
        //    「审核 → 反审核 → 重新审核 → 再反审核」时，历史入库流水有两条正数，
        //    求和会把两次入库量叠加（120），必然大于批次余额（60）而误报"已发生出库无法反审核"。
        BigDecimal received = calcCurrentReceivedCount(reqBO.getSourceBizType(), reqBO.getTargetBizType(),
                reqBO.getSourceBizItemId());
        if (received.compareTo(BigDecimal.ZERO) <= 0) {
            received = nvl(batch.getCount());
        }
        // 3. 扣回批次；已被出库导致余额不足时明确报错，不做静默截断（会计上不允许）
        int updated = batchMapper.updateCountDecrement(batch.getId(), received);
        if (updated == 0) {
            throw exception(STOCK_BATCH_REVERSE_FAIL_ISSUED, batch.getBatchNo(), batch.getCount(), received);
        }
        ErpStockBatchDO updateObj = new ErpStockBatchDO();
        updateObj.setId(batch.getId());
        updateObj.setSourceReversed(REVERSED_YES);
        batchMapper.updateById(updateObj);

        // 4. 库存流水（负数）+ 同步 erp_stock.count
        writeStockRecord(batch.getProductId(), batch.getWarehouseId(), received.negate(), reqBO.getTargetBizType(),
                reqBO.getBizId(), reqBO.getSourceBizItemId(), reqBO.getBizNo(), batch.getBatchNo(), STATE_IN_STOCK,
                nvl(batch.getUnitCost()), MoneyUtils.priceMultiply(nvl(batch.getUnitCost()), received).negate(),
                batch.getSkuId());
        log.info("[reverseReceive][批次({})冲销 {}，来源 {}/{}]", batch.getBatchNo(), received,
                reqBO.getSourceBizType(), reqBO.getSourceBizItemId());
        return true;
    }

    // ==================== 出库（FIFO） ====================

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ErpStockBatchIssueRespBO issueByFifo(ErpStockBatchOutReqBO reqBO) {
        Long skuId = ObjectUtil.defaultIfNull(reqBO.getSkuId(), DEFAULT_SKU_ID);
        BigDecimal count = reqBO.getCount();
        if (count == null || count.compareTo(BigDecimal.ZERO) <= 0) {
            throw exception(STOCK_BATCH_COUNT_ILLEGAL, count);
        }
        // 1. 取在仓批次，按 FIFO 排序：先入库先出 → 同入库日期先到期先出 → id 兜底
        List<ErpStockBatchDO> batches = batchMapper.selectListByFifo(reqBO.getWarehouseId(), reqBO.getProductId(), true);
        ErpStockBatchIssueRespBO resp = new ErpStockBatchIssueRespBO();
        resp.setTotalCount(BigDecimal.ZERO);
        resp.setTotalCost(BigDecimal.ZERO);
        BigDecimal remain = count;
        BigDecimal issued = BigDecimal.ZERO;
        // 2. 逐批扣减
        for (ErpStockBatchDO batch : batches) {
            if (remain.compareTo(BigDecimal.ZERO) <= 0) {
                break;
            }
            // 可出数量 = 在仓 − 占用
            BigDecimal deductible = nvl(batch.getCount()).subtract(nvl(batch.getOccupiedCount()));
            if (deductible.compareTo(BigDecimal.ZERO) <= 0) {
                continue;
            }
            BigDecimal qty = remain.min(deductible);
            int updated = batchMapper.updateCountDecrement(batch.getId(), qty);
            if (updated == 0) {
                // 并发下被别人先扣走，整个事务回滚，避免超发
                throw exception(STOCK_BATCH_CONCURRENT_MODIFY, batch.getBatchNo());
            }
            BigDecimal cost = MoneyUtils.priceMultiply(nvl(batch.getUnitCost()), qty);
            ErpStockBatchIssueRespBO.Detail detail = new ErpStockBatchIssueRespBO.Detail();
            detail.setBatchId(batch.getId());
            detail.setBatchNo(batch.getBatchNo());
            detail.setExpiryDate(batch.getExpiryDate());
            detail.setInDate(batch.getInDate());
            detail.setCount(qty);
            detail.setUnitCost(nvl(batch.getUnitCost()));
            detail.setTotalCost(cost);
            resp.getDetails().add(detail);
            resp.setTotalCount(resp.getTotalCount().add(qty));
            resp.setTotalCost(MoneyUtils.priceAdd(resp.getTotalCost(), cost));
            // 3. 一行一批次的库存流水（负数）+ 同步 erp_stock.count
            writeStockRecord(reqBO.getProductId(), reqBO.getWarehouseId(), qty.negate(), reqBO.getBizType(),
                    reqBO.getBizId(), reqBO.getBizItemId(), reqBO.getBizNo(), batch.getBatchNo(), STATE_IN_STOCK,
                    nvl(batch.getUnitCost()), cost.negate(), skuId);
            remain = remain.subtract(qty);
            issued = issued.add(qty);
        }
        // 4. 不足则整体回滚
        if (remain.compareTo(BigDecimal.ZERO) > 0) {
            throw exception(STOCK_BATCH_NOT_ENOUGH, reqBO.getProductId(), reqBO.getWarehouseId(), count, issued);
        }
        log.info("[issueByFifo][物料({})仓库({})出库 {}，结转成本 {}，扣减批次 {} 个]",
                reqBO.getProductId(), reqBO.getWarehouseId(), count, resp.getTotalCost(), resp.getDetails().size());
        return resp;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public int reverseIssue(ErpStockBatchReverseReqBO reqBO) {
        // 1. 取原出库流水（一行一批次），逐批回滚
        List<ErpStockRecordDO> records = stockRecordService.getStockRecordListByBizItem(
                reqBO.getSourceBizType(), reqBO.getSourceBizItemId());
        if (CollUtil.isEmpty(records)) {
            log.warn("[reverseIssue][来源({}/{})无出库流水，跳过]", reqBO.getSourceBizType(), reqBO.getSourceBizItemId());
            return 0;
        }
        int rolled = 0;
        for (ErpStockRecordDO record : records) {
            if (nvl(record.getCount()).compareTo(BigDecimal.ZERO) >= 0 || StrUtil.isBlank(record.getBatchNo())) {
                continue; // 只回滚出库行；无批次的老流水（启用批次管理之前）不回滚
            }
            BigDecimal qty = record.getCount().abs();
            Long skuId = ObjectUtil.defaultIfNull(record.getSkuId(), DEFAULT_SKU_ID);
            ErpStockBatchDO batch = batchMapper.selectByUniqueKey(record.getWarehouseId(), record.getProductId(),
                    skuId, record.getBatchNo());
            if (batch == null) {
                log.warn("[reverseIssue][批次({})不存在，跳过回滚]", record.getBatchNo());
                continue;
            }
            batchMapper.updateCountIncrement(batch.getId(), qty);
            writeStockRecord(record.getProductId(), record.getWarehouseId(), qty, reqBO.getTargetBizType(),
                    reqBO.getBizId(), reqBO.getSourceBizItemId(), reqBO.getBizNo(), record.getBatchNo(),
                    STATE_IN_STOCK, record.getUnitCost(), MoneyUtils.priceMultiply(nvl(record.getUnitCost()), qty), skuId);
            rolled++;
        }
        log.info("[reverseIssue][来源({}/{})回滚 {} 个批次]", reqBO.getSourceBizType(), reqBO.getSourceBizItemId(), rolled);
        return rolled;
    }

    // ==================== 状态数量 ====================

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ErpStockBatchDO updateStateCount(ErpStockBatchStateReqBO reqBO) {
        if (!ErpStockBatchService.isValidState(reqBO.getState())) {
            throw exception(STOCK_BATCH_STATE_ILLEGAL, reqBO.getState());
        }
        // 在仓数量只能由出入库产生（要同步 erp_stock 与流水），不允许这里直接改
        if (STATE_IN_STOCK.equals(reqBO.getState())) {
            throw exception(STOCK_BATCH_STATE_NOT_ADJUSTABLE, reqBO.getState());
        }
        BigDecimal delta = reqBO.getDelta();
        if (delta == null || delta.compareTo(BigDecimal.ZERO) == 0) {
            throw exception(STOCK_BATCH_COUNT_ILLEGAL, delta);
        }
        Long skuId = ObjectUtil.defaultIfNull(reqBO.getSkuId(), DEFAULT_SKU_ID);
        if (StrUtil.isBlank(reqBO.getBatchNo())) {
            throw exception(STOCK_BATCH_NOT_EXISTS, reqBO.getWarehouseId(), reqBO.getProductId(), reqBO.getBatchNo());
        }
        // 1. 批次不存在时新建一条空批次（例如「在途」还没有实物批次）
        ErpStockBatchDO batch = batchMapper.selectByUniqueKey(reqBO.getWarehouseId(), reqBO.getProductId(),
                skuId, reqBO.getBatchNo());
        if (batch == null) {
            batch = new ErpStockBatchDO();
            batch.setWarehouseId(reqBO.getWarehouseId());
            batch.setProductId(reqBO.getProductId());
            batch.setSkuId(skuId);
            batch.setBatchNo(reqBO.getBatchNo());
            batch.setInDate(LocalDate.now());
            batch.setCount(BigDecimal.ZERO);
            batch.setTransitCount(BigDecimal.ZERO);
            batch.setOccupiedCount(BigDecimal.ZERO);
            batch.setInspectingCount(BigDecimal.ZERO);
            batch.setUnitCost(BigDecimal.ZERO);
            batch.setTotalCost(BigDecimal.ZERO);
            batch.setSourceReversed(REVERSED_NO);
            batch.setRemark(StrUtil.blankToDefault(reqBO.getRemark(), "状态登记自动创建（无实物在仓）"));
            batchMapper.insert(batch);
        }
        // 2. 只改状态列（列名来自白名单枚举，无注入风险）
        String column = switch (reqBO.getState()) {
            case STATE_IN_TRANSIT -> "transit_count";
            case STATE_OCCUPIED -> "occupied_count";
            case STATE_INSPECTING -> "inspecting_count";
            default -> null;
        };
        if (column == null) {
            throw exception(STOCK_BATCH_STATE_ILLEGAL, reqBO.getState());
        }
        int updated = batchMapper.updateStateCountIncrement(batch.getId(), column, delta);
        if (updated == 0) {
            throw exception(STOCK_BATCH_CONCURRENT_MODIFY, batch.getBatchNo());
        }
        log.info("[updateStateCount][批次({})状态({})登记 {}]", batch.getBatchNo(), reqBO.getState(), delta);
        return batchMapper.selectById(batch.getId());
    }

    // ==================== 查询 ====================

    @Override
    public BigDecimal getAvailableCount(Long warehouseId, Long productId) {
        if (warehouseId == null || productId == null) {
            return BigDecimal.ZERO;
        }
        return nvl(batchMapper.selectAvailableCount(warehouseId, productId));
    }

    @Override
    public Map<Long, BigDecimal> getAvailableCountMap(Long warehouseId, Collection<Long> productIds) {
        Map<Long, ErpStockAvailableRespBO> summaryMap = getAvailableSummaryMap(warehouseId, productIds);
        Map<Long, BigDecimal> result = new LinkedHashMap<>();
        summaryMap.forEach((productId, summary) -> result.put(productId, summary.getAvailableCount()));
        return result;
    }

    @Override
    public Map<Long, ErpStockAvailableRespBO> getAvailableSummaryMap(Long warehouseId, Collection<Long> productIds) {
        Map<Long, ErpStockAvailableRespBO> result = new LinkedHashMap<>();
        if (warehouseId == null || CollUtil.isEmpty(productIds)) {
            return result;
        }
        List<Map<String, Object>> rows = batchMapper.selectAvailableCountGroupByProduct(warehouseId, productIds);
        for (Map<String, Object> row : rows) {
            Long productId = toLong(row.get("product_id"));
            if (productId == null) {
                continue;
            }
            ErpStockAvailableRespBO summary = new ErpStockAvailableRespBO();
            summary.setProductId(productId);
            summary.setWarehouseId(warehouseId);
            summary.setOnHandCount(toDecimal(row.get("on_hand_count")));
            summary.setOccupiedCount(toDecimal(row.get("occupied_count")));
            summary.setTransitCount(toDecimal(row.get("transit_count")));
            summary.setAvailableCount(toDecimal(row.get("available_count")));
            result.put(productId, summary);
        }
        return result;
    }

    @Override
    public List<ErpStockBatchDO> getBatchList(Long warehouseId, Long productId, boolean onlyPositive) {
        return batchMapper.selectListByFifo(warehouseId, productId, onlyPositive);
    }

    @Override
    public List<ErpStockBatchDO> getExpiryBatchList(Long warehouseId, Long productId, Integer warnDays, Boolean expiredOnly) {
        LocalDate today = LocalDate.now();
        LocalDate untilDate = Boolean.TRUE.equals(expiredOnly)
                ? today.minusDays(1)                                                      // 过期：到期日 < 今天
                : today.plusDays(ObjectUtil.defaultIfNull(warnDays, DEFAULT_WARN_DAYS));   // 临期 + 过期
        return batchMapper.selectListByExpiry(warehouseId, productId, untilDate);
    }

    @Override
    public PageResult<ErpStockBatchDO> getBatchPage(ErpStockBatchPageReqVO pageReqVO) {
        return batchMapper.selectPage(pageReqVO);
    }

    // ==================== 内部方法 ====================

    /**
     * 写库存流水：同时增量更新 erp_stock.count（双写的唯一入口，保证两边一致）
     */
    private void writeStockRecord(Long productId, Long warehouseId, BigDecimal count, Integer bizType, Long bizId,
                                  Long bizItemId, String bizNo, String batchNo, String stockState,
                                  BigDecimal unitCost, BigDecimal totalCost, Long skuId) {
        ErpStockRecordCreateReqBO createReqBO = new ErpStockRecordCreateReqBO(productId, warehouseId, count,
                bizType, bizId, bizItemId, bizNo);
        createReqBO.setBatchNo(batchNo);
        createReqBO.setStockState(stockState);
        createReqBO.setUnitCost(unitCost);
        createReqBO.setTotalCost(totalCost);
        createReqBO.setSkuId(skuId);
        stockRecordService.createStockRecord(createReqBO);
    }

    /**
     * 计算「本次入库量」：按流水 id 顺序扫描该来源项的入库（正数）与冲销（负数）记录，
     * 每遇到一条冲销流水就把累计值归零 —— 即只统计**最后一次审核之后**的入库量。
     *
     * 为什么要这样算：反审核是「整单冲销」语义，一次审核对应一次冲销；
     * 若简单把正数流水求和，则「审核 → 反审核 → 重新审核」后会出现两条正数流水（60 + 60 = 120），
     * 第二次反审核会拿 120 去冲一个只有 60 的批次，误报「已发生出库，无法反审核」。
     *
     * @param sourceBizType 原业务类型（入库），例如 PURCHASE_IN
     * @param cancelBizType 冲销业务类型，例如 PURCHASE_IN_CANCEL；为空则只统计入库流水
     */
    private BigDecimal calcCurrentReceivedCount(Integer sourceBizType, Integer cancelBizType, Long sourceBizItemId) {
        List<ErpStockRecordDO> records = new ArrayList<>(
                stockRecordService.getStockRecordListByBizItem(sourceBizType, sourceBizItemId));
        if (cancelBizType != null) {
            records.addAll(stockRecordService.getStockRecordListByBizItem(cancelBizType, sourceBizItemId));
        }
        records.sort(Comparator.comparing(ErpStockRecordDO::getId));
        BigDecimal received = BigDecimal.ZERO;
        for (ErpStockRecordDO record : records) {
            BigDecimal count = nvl(record.getCount());
            received = count.compareTo(BigDecimal.ZERO) > 0 ? received.add(count) : BigDecimal.ZERO;
        }
        return received;
    }

    /**
     * 批次号兜底：IN{yyyyMMdd}-{来源项id}；无来源项时补随机串（避免与既有批次撞唯一键）
     */
    private String buildDefaultBatchNo(LocalDate inDate, Long bizItemId) {
        String suffix = bizItemId != null ? String.valueOf(bizItemId) : IdUtil.fastSimpleUUID().substring(0, 8);
        return "IN" + inDate.format(BATCH_NO_DATE) + "-" + suffix;
    }

    private static BigDecimal nvl(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }

    private static BigDecimal toDecimal(Object value) {
        return value == null ? BigDecimal.ZERO : new BigDecimal(value.toString());
    }

    private static Long toLong(Object value) {
        if (value == null) {
            return null;
        }
        return value instanceof Number number ? number.longValue() : Long.valueOf(value.toString());
    }

}
