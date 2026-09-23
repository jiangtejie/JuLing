package com.lxjl.juling.module.erp.dal.mysql.purchase;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.MPJLambdaWrapperX;
import com.lxjl.juling.module.erp.controller.admin.purchase.vo.returns.ErpPurchaseReturnPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchaseInDO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchaseReturnDO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchaseReturnItemDO;
import com.lxjl.juling.module.erp.enums.ErpAuditStatus;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;
import java.util.Objects;

/**
 * ERP 采购退货 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface ErpPurchaseReturnMapper extends BaseMapperX<ErpPurchaseReturnDO> {

    default PageResult<ErpPurchaseReturnDO> selectPage(ErpPurchaseReturnPageReqVO reqVO) {
        MPJLambdaWrapperX<ErpPurchaseReturnDO> query = new MPJLambdaWrapperX<ErpPurchaseReturnDO>()
                .likeIfPresent(ErpPurchaseReturnDO::getNo, reqVO.getNo())
                .eqIfPresent(ErpPurchaseReturnDO::getSupplierId, reqVO.getSupplierId())
                .betweenIfPresent(ErpPurchaseReturnDO::getReturnTime, reqVO.getReturnTime())
                .eqIfPresent(ErpPurchaseReturnDO::getStatus, reqVO.getStatus())
                .likeIfPresent(ErpPurchaseReturnDO::getRemark, reqVO.getRemark())
                .eqIfPresent(ErpPurchaseReturnDO::getCreator, reqVO.getCreator())
                .eqIfPresent(ErpPurchaseReturnDO::getAccountId, reqVO.getAccountId())
                .likeIfPresent(ErpPurchaseReturnDO::getOrderNo, reqVO.getOrderNo())
                .orderByDesc(ErpPurchaseReturnDO::getId);
        // 退款状态。为什么需要 t. 的原因，是因为联表查询时，需要指定表名，不然会报字段不存在的错误。
        // 注意：已退款金额历史数据可能为 NULL，而 SQL 中 NULL 参与比较恒为 NULL（即不成立），
        // 会导致"可退款"的单据一条都查不出来，因此统一用 COALESCE(x, 0) 兜底
        if (Objects.equals(reqVO.getRefundStatus(), ErpPurchaseReturnPageReqVO.REFUND_STATUS_NONE)) {
            query.apply("COALESCE(t.refund_price, 0) = 0");
        } else if (Objects.equals(reqVO.getRefundStatus(), ErpPurchaseReturnPageReqVO.REFUND_STATUS_PART)) {
            query.apply("COALESCE(t.refund_price, 0) > 0 AND COALESCE(t.refund_price, 0) < t.total_price");
        } else if (Objects.equals(reqVO.getRefundStatus(), ErpPurchaseReturnPageReqVO.REFUND_STATUS_ALL)) {
            query.apply("COALESCE(t.refund_price, 0) = t.total_price");
        }
        if (Boolean.TRUE.equals(reqVO.getRefundEnable())) {
            query.eq(ErpPurchaseInDO::getStatus, ErpAuditStatus.APPROVE.getStatus())
                    .apply("COALESCE(t.refund_price, 0) < t.total_price");
        }
        if (reqVO.getWarehouseId() != null || reqVO.getProductId() != null) {
            query.leftJoin(ErpPurchaseReturnItemDO.class, ErpPurchaseReturnItemDO::getReturnId, ErpPurchaseReturnDO::getId)
                    .eq(reqVO.getWarehouseId() != null, ErpPurchaseReturnItemDO::getWarehouseId, reqVO.getWarehouseId())
                    .eq(reqVO.getProductId() != null, ErpPurchaseReturnItemDO::getProductId, reqVO.getProductId())
                    .groupBy(ErpPurchaseReturnDO::getId); // 避免 1 对多查询，产生相同的 1
        }
        return selectJoinPage(reqVO, ErpPurchaseReturnDO.class, query);
    }

    default int updateByIdAndStatus(Long id, Integer status, ErpPurchaseReturnDO updateObj) {
        return update(updateObj, new LambdaUpdateWrapper<ErpPurchaseReturnDO>()
                .eq(ErpPurchaseReturnDO::getId, id).eq(ErpPurchaseReturnDO::getStatus, status));
    }

    default ErpPurchaseReturnDO selectByNo(String no) {
        return selectOne(ErpPurchaseReturnDO::getNo, no);
    }

    default List<ErpPurchaseReturnDO> selectListByOrderId(Long orderId) {
        return selectList(ErpPurchaseReturnDO::getOrderId, orderId);
    }

}