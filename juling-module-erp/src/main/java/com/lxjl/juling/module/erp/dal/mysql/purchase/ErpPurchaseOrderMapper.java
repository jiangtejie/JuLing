package com.lxjl.juling.module.erp.dal.mysql.purchase;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.MPJLambdaWrapperX;
import com.lxjl.juling.module.erp.controller.admin.purchase.vo.order.ErpPurchaseOrderPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchaseOrderDO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchaseOrderItemDO;
import com.lxjl.juling.module.erp.enums.ErpAuditStatus;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import org.apache.ibatis.annotations.Mapper;

import java.util.Objects;

/**
 * ERP 采购订单 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface ErpPurchaseOrderMapper extends BaseMapperX<ErpPurchaseOrderDO> {

    default PageResult<ErpPurchaseOrderDO> selectPage(ErpPurchaseOrderPageReqVO reqVO) {
        MPJLambdaWrapperX<ErpPurchaseOrderDO> query = new MPJLambdaWrapperX<ErpPurchaseOrderDO>()
                .likeIfPresent(ErpPurchaseOrderDO::getNo, reqVO.getNo())
                .eqIfPresent(ErpPurchaseOrderDO::getSupplierId, reqVO.getSupplierId())
                .betweenIfPresent(ErpPurchaseOrderDO::getOrderTime, reqVO.getOrderTime())
                .eqIfPresent(ErpPurchaseOrderDO::getStatus, reqVO.getStatus())
                .likeIfPresent(ErpPurchaseOrderDO::getRemark, reqVO.getRemark())
                .eqIfPresent(ErpPurchaseOrderDO::getCreator, reqVO.getCreator())
                .orderByDesc(ErpPurchaseOrderDO::getId);
        // 入库状态。为什么需要 t. 的原因，是因为联表查询时，需要指定表名，不然会报 in_count 错误。
        // 注意：入库/退货数量历史数据可能为 NULL，而 SQL 中 NULL 参与比较恒为 NULL（即不成立），
        // 会导致“可采购入库/可采购退货”的订单一条都查不出来，因此统一用 COALESCE(x, 0) 兜底
        if (Objects.equals(reqVO.getInStatus(), ErpPurchaseOrderPageReqVO.IN_STATUS_NONE)) {
            query.apply("COALESCE(t.in_count, 0) = 0");
        } else if (Objects.equals(reqVO.getInStatus(), ErpPurchaseOrderPageReqVO.IN_STATUS_PART)) {
            query.apply("COALESCE(t.in_count, 0) > 0 AND COALESCE(t.in_count, 0) < t.total_count");
        } else if (Objects.equals(reqVO.getInStatus(), ErpPurchaseOrderPageReqVO.IN_STATUS_ALL)) {
            query.apply("COALESCE(t.in_count, 0) = t.total_count");
        }
        // 退货状态
        if (Objects.equals(reqVO.getReturnStatus(), ErpPurchaseOrderPageReqVO.RETURN_STATUS_NONE)) {
            query.apply("COALESCE(t.return_count, 0) = 0");
        } else if (Objects.equals(reqVO.getReturnStatus(), ErpPurchaseOrderPageReqVO.RETURN_STATUS_PART)) {
            query.apply("COALESCE(t.return_count, 0) > 0 AND COALESCE(t.return_count, 0) < t.total_count");
        } else if (Objects.equals(reqVO.getReturnStatus(), ErpPurchaseOrderPageReqVO.RETURN_STATUS_ALL)) {
            query.apply("COALESCE(t.return_count, 0) = t.total_count");
        }
        // 可采购入库
        if (Boolean.TRUE.equals(reqVO.getInEnable())) {
            query.eq(ErpPurchaseOrderDO::getStatus, ErpAuditStatus.APPROVE.getStatus())
                    .apply("COALESCE(t.in_count, 0) < t.total_count");
        }
        // 可采购退货
        if (Boolean.TRUE.equals(reqVO.getReturnEnable())) {
            query.eq(ErpPurchaseOrderDO::getStatus, ErpAuditStatus.APPROVE.getStatus())
                    .apply("COALESCE(t.return_count, 0) < COALESCE(t.in_count, 0)");
        }
        if (reqVO.getProductId() != null) {
            query.leftJoin(ErpPurchaseOrderItemDO.class, ErpPurchaseOrderItemDO::getOrderId, ErpPurchaseOrderDO::getId)
                    .eq(reqVO.getProductId() != null, ErpPurchaseOrderItemDO::getProductId, reqVO.getProductId())
                    .groupBy(ErpPurchaseOrderDO::getId); // 避免 1 对多查询，产生相同的 1
        }
        return selectJoinPage(reqVO, ErpPurchaseOrderDO.class, query);
    }

    default int updateByIdAndStatus(Long id, Integer status, ErpPurchaseOrderDO updateObj) {
        return update(updateObj, new LambdaUpdateWrapper<ErpPurchaseOrderDO>()
                .eq(ErpPurchaseOrderDO::getId, id).eq(ErpPurchaseOrderDO::getStatus, status));
    }

    default ErpPurchaseOrderDO selectByNo(String no) {
        return selectOne(ErpPurchaseOrderDO::getNo, no);
    }

}