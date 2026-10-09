package com.lxjl.juling.module.erp.service.stock;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.erp.controller.admin.stock.vo.batch.ErpStockBatchPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockBatchDO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockAvailableRespBO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchInReqBO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchIssueRespBO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchOutReqBO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchReverseReqBO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchStateReqBO;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.List;
import java.util.Map;

/**
 * ERP 批次库存 Service 接口（库存中心 · 多状态 + 批次/效期 + FIFO 成本）
 *
 * 口径（见 docs/stock-center.md）：
 *   · 库存维度 = 仓库 × 物料 × 批次（sku_id 预留）；
 *   · 四态：在仓 / 在途 / 占用 / 待检；可用量 = 在仓 − 占用 + 在途；
 *   · 出库按批次 FIFO：先入库先出，同入库日期时先到期先出；
 *   · 成本：批次级 unitCost/totalCost，出库按批次成本结转。
 *
 * 与 erp_stock 的关系：**双写**。批次表是「可用量/成本/效期」的真源；
 * erp_stock.count 仍是「在仓聚合」的既有字段，由本服务的记账/扣减经
 * {@link ErpStockRecordService#createStockRecord} 增量同步，语义不变（老代码零改动可继续用）。
 *
 * 全部方法都在事务内、幂等安全（入库按来源项幂等、反审核按来源项幂等）。
 *
 * @author 亚特
 */
public interface ErpStockBatchService {

    /** 库存状态：在仓 */
    String STATE_IN_STOCK = "IN_STOCK";
    /** 库存状态：在途 */
    String STATE_IN_TRANSIT = "IN_TRANSIT";
    /** 库存状态：占用 */
    String STATE_OCCUPIED = "OCCUPIED";
    /** 库存状态：待检 */
    String STATE_INSPECTING = "INSPECTING";

    /**
     * 是否合法状态（四态）
     */
    static boolean isValidState(String state) {
        return STATE_IN_STOCK.equals(state) || STATE_IN_TRANSIT.equals(state)
                || STATE_OCCUPIED.equals(state) || STATE_INSPECTING.equals(state);
    }

    /**
     * 批次入库：写批次库存 + 库存流水（并增量更新 erp_stock.count）
     *
     * 幂等：以 (bizType, bizItemId) 为键；同一来源项重复调用只入账一次。
     * 若该来源已被反审核冲销（sourceReversed = 1），则复位并补回数量。
     *
     * @param reqBO 入库请求
     * @return 批次库存
     */
    ErpStockBatchDO receiveBatch(ErpStockBatchInReqBO reqBO);

    /**
     * 冲销入库（入库单反审核）：按来源项幂等
     *
     * @param reqBO 冲销请求（sourceBizType + sourceBizItemId 定位来源批次）
     * @return 是否发生冲销（false = 来源不存在或已冲销过）
     */
    boolean reverseReceive(ErpStockBatchReverseReqBO reqBO);

    /**
     * 按 FIFO 扣减指定物料数量：先入库先出，同入库日期时先到期先出
     *
     * 逐批扣减并写「一行一批次」的库存流水（负数），同时按批次成本结转；
     * 数量不足时抛异常并回滚整个事务（不会出现扣了一半的情况）。
     *
     * @param reqBO 出库请求
     * @return 扣减明细（批次 / 数量 / 单位成本 / 结转金额）
     */
    ErpStockBatchIssueRespBO issueByFifo(ErpStockBatchOutReqBO reqBO);

    /**
     * 冲销出库（出库单反审核）：按原出库流水逐批回滚数量与成本
     *
     * @param reqBO 冲销请求（sourceBizType + sourceBizItemId 定位原出库流水）
     * @return 实际回滚的批次行数（0 = 无流水可回滚）
     */
    int reverseIssue(ErpStockBatchReverseReqBO reqBO);

    /**
     * 登记状态数量（在途 / 占用 / 待检）：批次不存在时按 batchNo 新建一条空批次
     *
     * @param reqBO 状态登记请求
     * @return 登记后的批次库存
     */
    ErpStockBatchDO updateStateCount(ErpStockBatchStateReqBO reqBO);

    /**
     * 可用量 = 在仓 − 占用 + 在途
     *
     * @param warehouseId 仓库编号
     * @param productId   物料编号
     * @return 可用量（无批次时返回 0）
     */
    BigDecimal getAvailableCount(Long warehouseId, Long productId);

    /**
     * 批量可用量：productId -> 可用量
     *
     * @param warehouseId 仓库编号
     * @param productIds  物料编号集合
     * @return 可用量 Map（查不到的物料不出现在 Map 中）
     */
    Map<Long, BigDecimal> getAvailableCountMap(Long warehouseId, Collection<Long> productIds);

    /**
     * 批量库存概览：productId -> {在仓, 占用, 在途, 待检, 可用量}
     */
    Map<Long, ErpStockAvailableRespBO> getAvailableSummaryMap(Long warehouseId, Collection<Long> productIds);

    /**
     * 批次列表（按 FIFO 顺序）
     *
     * @param onlyPositive 是否只要在仓数量 > 0 的批次
     */
    List<ErpStockBatchDO> getBatchList(Long warehouseId, Long productId, boolean onlyPositive);

    /**
     * 效期查询：列出临期 / 过期批次（在仓数量 > 0 且有效期）
     *
     * @param warehouseId 仓库编号（可空 = 全部仓库）
     * @param productId   物料编号（可空 = 全部物料）
     * @param warnDays    临期预警天数（可空 = 30 天）
     * @param expiredOnly true 只列已过期；false 列出「已过期 + 临期」
     */
    List<ErpStockBatchDO> getExpiryBatchList(Long warehouseId, Long productId, Integer warnDays, Boolean expiredOnly);

    /**
     * 批次库存分页
     */
    PageResult<ErpStockBatchDO> getBatchPage(ErpStockBatchPageReqVO pageReqVO);

}
