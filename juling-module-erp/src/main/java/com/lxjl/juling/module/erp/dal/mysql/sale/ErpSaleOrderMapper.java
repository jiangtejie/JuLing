package com.lxjl.juling.module.erp.dal.mysql.sale;


import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.MPJLambdaWrapperX;
import com.lxjl.juling.module.erp.controller.admin.sale.vo.order.ErpSaleOrderPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.sale.ErpSaleOrderDO;
import com.lxjl.juling.module.erp.dal.dataobject.sale.ErpSaleOrderItemDO;
import com.lxjl.juling.module.erp.enums.ErpAuditStatus;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import org.apache.ibatis.annotations.Mapper;

import java.util.Objects;

/**
 * ERP 销售订单 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface ErpSaleOrderMapper extends BaseMapperX<ErpSaleOrderDO> {

    default PageResult<ErpSaleOrderDO> selectPage(ErpSaleOrderPageReqVO reqVO) {
        MPJLambdaWrapperX<ErpSaleOrderDO> query = new MPJLambdaWrapperX<ErpSaleOrderDO>()
                .likeIfPresent(ErpSaleOrderDO::getNo, reqVO.getNo())
                .eqIfPresent(ErpSaleOrderDO::getCustomerId, reqVO.getCustomerId())
                .betweenIfPresent(ErpSaleOrderDO::getOrderTime, reqVO.getOrderTime())
                .eqIfPresent(ErpSaleOrderDO::getStatus, reqVO.getStatus())
                .likeIfPresent(ErpSaleOrderDO::getRemark, reqVO.getRemark())
                .eqIfPresent(ErpSaleOrderDO::getCreator, reqVO.getCreator())
                .orderByDesc(ErpSaleOrderDO::getId);
        // 入库状态。为什么需要 t. 的原因，是因为联表查询时，需要指定表名，不然会报 out_count 错误。
        // 注意：出库/退货数量历史数据可能为 NULL，而 SQL 中 NULL 参与比较恒为 NULL（即不成立），
        // 会导致“可销售出库/可销售退货”的订单一条都查不出来，因此统一用 COALESCE(x, 0) 兜底
        if (Objects.equals(reqVO.getOutStatus(), ErpSaleOrderPageReqVO.OUT_STATUS_NONE)) {
            query.apply("COALESCE(t.out_count, 0) = 0");
        } else if (Objects.equals(reqVO.getOutStatus(), ErpSaleOrderPageReqVO.OUT_STATUS_PART)) {
            query.apply("COALESCE(t.out_count, 0) > 0 AND COALESCE(t.out_count, 0) < t.total_count");
        } else if (Objects.equals(reqVO.getOutStatus(), ErpSaleOrderPageReqVO.OUT_STATUS_ALL)) {
            query.apply("COALESCE(t.out_count, 0) = t.total_count");
        }
        // 退货状态
        if (Objects.equals(reqVO.getReturnStatus(), ErpSaleOrderPageReqVO.RETURN_STATUS_NONE)) {
            query.apply("COALESCE(t.return_count, 0) = 0");
        } else if (Objects.equals(reqVO.getReturnStatus(), ErpSaleOrderPageReqVO.RETURN_STATUS_PART)) {
            query.apply("COALESCE(t.return_count, 0) > 0 AND COALESCE(t.return_count, 0) < t.total_count");
        } else if (Objects.equals(reqVO.getReturnStatus(), ErpSaleOrderPageReqVO.RETURN_STATUS_ALL)) {
            query.apply("COALESCE(t.return_count, 0) = t.total_count");
        }
        // 可销售出库
        if (Boolean.TRUE.equals(reqVO.getOutEnable())) {
            query.eq(ErpSaleOrderDO::getStatus, ErpAuditStatus.APPROVE.getStatus())
                    .apply("COALESCE(t.out_count, 0) < t.total_count");
        }
        // 可销售退货
        if (Boolean.TRUE.equals(reqVO.getReturnEnable())) {
            query.eq(ErpSaleOrderDO::getStatus, ErpAuditStatus.APPROVE.getStatus())
                    .apply("COALESCE(t.return_count, 0) < COALESCE(t.out_count, 0)");
        }
        if (reqVO.getProductId() != null) {
            query.leftJoin(ErpSaleOrderItemDO.class, ErpSaleOrderItemDO::getOrderId, ErpSaleOrderDO::getId)
                    .eq(reqVO.getProductId() != null, ErpSaleOrderItemDO::getProductId, reqVO.getProductId())
                    .groupBy(ErpSaleOrderDO::getId); // 避免 1 对多查询，产生相同的 1
        }
        return selectJoinPage(reqVO, ErpSaleOrderDO.class, query);
    }

    default int updateByIdAndStatus(Long id, Integer status, ErpSaleOrderDO updateObj) {
        return update(updateObj, new LambdaUpdateWrapper<ErpSaleOrderDO>()
                .eq(ErpSaleOrderDO::getId, id).eq(ErpSaleOrderDO::getStatus, status));
    }

    default ErpSaleOrderDO selectByNo(String no) {
        return selectOne(ErpSaleOrderDO::getNo, no);
    }

}