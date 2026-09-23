package com.lxjl.juling.module.erp.dal.mysql.sale;


import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.MPJLambdaWrapperX;
import com.lxjl.juling.module.erp.controller.admin.sale.vo.returns.ErpSaleReturnPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.sale.ErpSaleOutDO;
import com.lxjl.juling.module.erp.dal.dataobject.sale.ErpSaleReturnDO;
import com.lxjl.juling.module.erp.dal.dataobject.sale.ErpSaleReturnItemDO;
import com.lxjl.juling.module.erp.enums.ErpAuditStatus;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;
import java.util.Objects;

/**
 * ERP 销售退货 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface ErpSaleReturnMapper extends BaseMapperX<ErpSaleReturnDO> {

    default PageResult<ErpSaleReturnDO> selectPage(ErpSaleReturnPageReqVO reqVO) {
        MPJLambdaWrapperX<ErpSaleReturnDO> query = new MPJLambdaWrapperX<ErpSaleReturnDO>()
                .likeIfPresent(ErpSaleReturnDO::getNo, reqVO.getNo())
                .eqIfPresent(ErpSaleReturnDO::getCustomerId, reqVO.getCustomerId())
                .betweenIfPresent(ErpSaleReturnDO::getReturnTime, reqVO.getReturnTime())
                .eqIfPresent(ErpSaleReturnDO::getStatus, reqVO.getStatus())
                .likeIfPresent(ErpSaleReturnDO::getRemark, reqVO.getRemark())
                .eqIfPresent(ErpSaleReturnDO::getCreator, reqVO.getCreator())
                .eqIfPresent(ErpSaleReturnDO::getAccountId, reqVO.getAccountId())
                .likeIfPresent(ErpSaleReturnDO::getOrderNo, reqVO.getOrderNo())
                .orderByDesc(ErpSaleReturnDO::getId);
        // 退款状态。为什么需要 t. 的原因，是因为联表查询时，需要指定表名，不然会报字段不存在的错误。
        // 注意：已退款金额历史数据可能为 NULL，而 SQL 中 NULL 参与比较恒为 NULL（即不成立），
        // 会导致"可退款"的单据一条都查不出来，因此统一用 COALESCE(x, 0) 兜底
        if (Objects.equals(reqVO.getRefundStatus(), ErpSaleReturnPageReqVO.REFUND_STATUS_NONE)) {
            query.apply("COALESCE(t.refund_price, 0) = 0");
        } else if (Objects.equals(reqVO.getRefundStatus(), ErpSaleReturnPageReqVO.REFUND_STATUS_PART)) {
            query.apply("COALESCE(t.refund_price, 0) > 0 AND COALESCE(t.refund_price, 0) < t.total_price");
        } else if (Objects.equals(reqVO.getRefundStatus(), ErpSaleReturnPageReqVO.REFUND_STATUS_ALL)) {
            query.apply("COALESCE(t.refund_price, 0) = t.total_price");
        }
        if (Boolean.TRUE.equals(reqVO.getRefundEnable())) {
            query.eq(ErpSaleOutDO::getStatus, ErpAuditStatus.APPROVE.getStatus())
                    .apply("COALESCE(t.refund_price, 0) < t.total_price");
        }
        if (reqVO.getWarehouseId() != null || reqVO.getProductId() != null) {
            query.leftJoin(ErpSaleReturnItemDO.class, ErpSaleReturnItemDO::getReturnId, ErpSaleReturnDO::getId)
                    .eq(reqVO.getWarehouseId() != null, ErpSaleReturnItemDO::getWarehouseId, reqVO.getWarehouseId())
                    .eq(reqVO.getProductId() != null, ErpSaleReturnItemDO::getProductId, reqVO.getProductId())
                    .groupBy(ErpSaleReturnDO::getId); // 避免 1 对多查询，产生相同的 1
        }
        return selectJoinPage(reqVO, ErpSaleReturnDO.class, query);
    }

    default int updateByIdAndStatus(Long id, Integer status, ErpSaleReturnDO updateObj) {
        return update(updateObj, new LambdaUpdateWrapper<ErpSaleReturnDO>()
                .eq(ErpSaleReturnDO::getId, id).eq(ErpSaleReturnDO::getStatus, status));
    }

    default ErpSaleReturnDO selectByNo(String no) {
        return selectOne(ErpSaleReturnDO::getNo, no);
    }

    default List<ErpSaleReturnDO> selectListByOrderId(Long orderId) {
        return selectList(ErpSaleReturnDO::getOrderId, orderId);
    }

}