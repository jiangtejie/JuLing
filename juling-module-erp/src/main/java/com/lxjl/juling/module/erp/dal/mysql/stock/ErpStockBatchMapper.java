package com.lxjl.juling.module.erp.dal.mysql.stock;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.erp.controller.admin.stock.vo.batch.ErpStockBatchPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockBatchDO;
import com.lxjl.juling.framework.common.pojo.PageResult;
import org.apache.ibatis.annotations.Mapper;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Map;

/**
 * ERP 批次库存 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface ErpStockBatchMapper extends BaseMapperX<ErpStockBatchDO> {

    default PageResult<ErpStockBatchDO> selectPage(ErpStockBatchPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<ErpStockBatchDO>()
                .eqIfPresent(ErpStockBatchDO::getWarehouseId, reqVO.getWarehouseId())
                // 门店库存页：Controller 已按 warehouseType 把门店仓编号解析进 warehouseIds
                .inIfPresent(ErpStockBatchDO::getWarehouseId, reqVO.getWarehouseIds())
                .eqIfPresent(ErpStockBatchDO::getProductId, reqVO.getProductId())
                .likeIfPresent(ErpStockBatchDO::getBatchNo, reqVO.getBatchNo())
                .eqIfPresent(ErpStockBatchDO::getSourceBizNo, reqVO.getSourceBizNo())
                .orderByAsc(ErpStockBatchDO::getWarehouseId)
                .orderByAsc(ErpStockBatchDO::getProductId)
                .orderByAsc(ErpStockBatchDO::getInDate)
                .orderByAsc(ErpStockBatchDO::getExpiryDate)
                .orderByAsc(ErpStockBatchDO::getId));
    }

    /**
     * 按唯一键（仓库 × 物料 × SKU × 批次）查询
     */
    default ErpStockBatchDO selectByUniqueKey(Long warehouseId, Long productId, Long skuId, String batchNo) {
        return selectOne(new LambdaQueryWrapperX<ErpStockBatchDO>()
                .eq(ErpStockBatchDO::getWarehouseId, warehouseId)
                .eq(ErpStockBatchDO::getProductId, productId)
                .eq(ErpStockBatchDO::getSkuId, skuId)
                .eq(ErpStockBatchDO::getBatchNo, batchNo));
    }

    /**
     * 按来源（业务类型 + 业务项）查询：入库记账的幂等键
     */
    default ErpStockBatchDO selectBySource(Integer sourceBizType, Long sourceBizItemId) {
        if (sourceBizType == null || sourceBizItemId == null) {
            return null;
        }
        return selectOne(new LambdaQueryWrapperX<ErpStockBatchDO>()
                .eq(ErpStockBatchDO::getSourceBizType, sourceBizType)
                .eq(ErpStockBatchDO::getSourceBizItemId, sourceBizItemId)
                .orderByAsc(ErpStockBatchDO::getId)
                .last("LIMIT 1"));
    }

    /**
     * FIFO 排序取批次：先入库先出（in_date），同入库日期时先到期先出（expiry_date，PostgreSQL 的 ASC 默认 NULLS LAST，
     * 即「没有效期」排在最后），最后按 id 兜底保证顺序稳定。
     *
     * @param onlyPositive 是否只要 在仓数量 > 0 的批次
     */
    default List<ErpStockBatchDO> selectListByFifo(Long warehouseId, Long productId, boolean onlyPositive) {
        return selectList(new LambdaQueryWrapperX<ErpStockBatchDO>()
                .eq(ErpStockBatchDO::getWarehouseId, warehouseId)
                .eq(ErpStockBatchDO::getProductId, productId)
                .gt(onlyPositive, ErpStockBatchDO::getCount, BigDecimal.ZERO)
                .orderByAsc(ErpStockBatchDO::getInDate)
                .orderByAsc(ErpStockBatchDO::getExpiryDate)
                .orderByAsc(ErpStockBatchDO::getId));
    }

    /**
     * 效期查询：在仓数量 > 0、有到期日期、且到期日期 <= 截止日（含）
     *
     * @param untilDate 截止日期：临期 = 今天 + 预警天数；过期 = 今天
     */
    default List<ErpStockBatchDO> selectListByExpiry(Long warehouseId, Long productId, LocalDate untilDate) {
        return selectList(new LambdaQueryWrapperX<ErpStockBatchDO>()
                .eqIfPresent(ErpStockBatchDO::getWarehouseId, warehouseId)
                .eqIfPresent(ErpStockBatchDO::getProductId, productId)
                .gt(ErpStockBatchDO::getCount, BigDecimal.ZERO)
                .isNotNull(ErpStockBatchDO::getExpiryDate)
                .le(ErpStockBatchDO::getExpiryDate, untilDate)
                .orderByAsc(ErpStockBatchDO::getExpiryDate)
                .orderByAsc(ErpStockBatchDO::getId));
    }

    /**
     * 汇总某一物料在某仓库的可用量 = SUM(在仓 − 占用 + 在途)
     */
    default BigDecimal selectAvailableCount(Long warehouseId, Long productId) {
        List<Map<String, Object>> result = selectMaps(new QueryWrapper<ErpStockBatchDO>()
                .select("COALESCE(SUM(count) - SUM(occupied_count) + SUM(transit_count), 0) AS available_count")
                .eq("warehouse_id", warehouseId)
                .eq("product_id", productId));
        return toBigDecimal(result, "available_count");
    }

    /**
     * 汇总某一物料在某仓库的在仓数量
     */
    default BigDecimal selectOnHandCount(Long warehouseId, Long productId) {
        List<Map<String, Object>> result = selectMaps(new QueryWrapper<ErpStockBatchDO>()
                .select("COALESCE(SUM(count), 0) AS on_hand_count")
                .eq("warehouse_id", warehouseId)
                .eq("product_id", productId));
        return toBigDecimal(result, "on_hand_count");
    }

    /**
     * 批量汇总可用量：product_id -> SUM(在仓 − 占用 + 在途)
     */
    default List<Map<String, Object>> selectAvailableCountGroupByProduct(Long warehouseId, Collection<Long> productIds) {
        return selectMaps(new QueryWrapper<ErpStockBatchDO>()
                .select("product_id", "COALESCE(SUM(count) - SUM(occupied_count) + SUM(transit_count), 0) AS available_count",
                        "COALESCE(SUM(count), 0) AS on_hand_count",
                        "COALESCE(SUM(occupied_count), 0) AS occupied_count",
                        "COALESCE(SUM(transit_count), 0) AS transit_count")
                .eq("warehouse_id", warehouseId)
                .in("product_id", productIds)
                .groupBy("product_id"));
    }

    /**
     * 门店库存汇总：按仓库分组统计「有库存的物料数 / 在仓数量 / 在仓成本」
     *
     * @param warehouseIds 仓库编号集合（调用方保证非空，空集合会生成非法的 IN () 语句）
     */
    default List<Map<String, Object>> selectStoreSummary(Collection<Long> warehouseIds) {
        return selectMaps(new QueryWrapper<ErpStockBatchDO>()
                .select("warehouse_id",
                        "COUNT(DISTINCT product_id) AS product_count",
                        "COALESCE(SUM(count), 0) AS total_count",
                        "COALESCE(SUM(total_cost), 0) AS total_amount")
                .in("warehouse_id", warehouseIds)
                .groupBy("warehouse_id")
                .orderByAsc("warehouse_id"));
    }

    /**
     * 扣减在仓数量（含成本重算），并保证「在仓 − 占用 >= 扣减量」：
     * 返回 0 表示库存不足或并发冲突，由上层抛业务异常回滚整个事务。
     *
     * 注意：PostgreSQL 的 UPDATE 中所有 SET 表达式都取「旧值」，故 total_cost 这里用 count − 扣减量 计算是对的。
     */
    default int updateCountDecrement(Long id, BigDecimal count) {
        String qty = count.toPlainString();
        return update(null, new LambdaUpdateWrapper<ErpStockBatchDO>()
                .eq(ErpStockBatchDO::getId, id)
                .apply("count - occupied_count >= {0}", count)
                .setSql("count = count - " + qty)
                .setSql("total_cost = ROUND((count - " + qty + ") * unit_cost, 2)"));
    }

    /**
     * 增加在仓数量（含成本重算）：用于反审核回滚、重新审核复位
     */
    default int updateCountIncrement(Long id, BigDecimal count) {
        String qty = count.toPlainString();
        return update(null, new LambdaUpdateWrapper<ErpStockBatchDO>()
                .eq(ErpStockBatchDO::getId, id)
                .setSql("count = count + " + qty)
                .setSql("total_cost = ROUND((count + " + qty + ") * unit_cost, 2)"));
    }

    /**
     * 状态数量自增：column 必须来自服务层的白名单（transit_count / occupied_count / inspecting_count），
     * 不接受外部传入，避免 SQL 注入。
     */
    default int updateStateCountIncrement(Long id, String column, BigDecimal delta) {
        String qty = delta.toPlainString();
        return update(null, new LambdaUpdateWrapper<ErpStockBatchDO>()
                .eq(ErpStockBatchDO::getId, id)
                .setSql(column + " = " + column + " + " + qty));
    }

    private static BigDecimal toBigDecimal(List<Map<String, Object>> result, String column) {
        if (result == null || result.isEmpty() || result.get(0) == null) {
            return BigDecimal.ZERO;
        }
        Object value = result.get(0).get(column);
        return value == null ? BigDecimal.ZERO : new BigDecimal(value.toString());
    }

}
