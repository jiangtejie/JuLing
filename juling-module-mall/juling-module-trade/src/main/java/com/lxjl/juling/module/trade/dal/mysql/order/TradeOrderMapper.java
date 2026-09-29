package com.lxjl.juling.module.trade.dal.mysql.order;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.framework.mybatis.core.query.MPJLambdaWrapperX;
import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeOrderPageReqVO;
import com.lxjl.juling.module.trade.controller.admin.workbench.vo.TradeOrderWorkbenchPageReqVO;
import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeOrderPageReqVO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderDO;
import com.lxjl.juling.module.trade.enums.order.TradeOrderAuditStatusEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderStatusEnum;
import com.lxjl.juling.module.erp.api.customer.enums.StoreTypeEnum;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import org.apache.ibatis.annotations.Mapper;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Mapper
public interface TradeOrderMapper extends BaseMapperX<TradeOrderDO> {

    default int updateByIdAndStatus(Long id, Integer status, TradeOrderDO update) {
        return update(update, new LambdaUpdateWrapper<TradeOrderDO>()
                .eq(TradeOrderDO::getId, id).eq(TradeOrderDO::getStatus, status));
    }

    default TradeOrderDO selectByIdAndUserId(Long id, Long userId) {
        return selectOne(TradeOrderDO::getId, id, TradeOrderDO::getUserId, userId);
    }

    default PageResult<TradeOrderDO> selectPage(TradeOrderPageReqVO reqVO, Set<Long> userIds) {
        return selectPage(reqVO, new LambdaQueryWrapperX<TradeOrderDO>()
                .likeIfPresent(TradeOrderDO::getNo, reqVO.getNo())
                .eqIfPresent(TradeOrderDO::getUserId, reqVO.getUserId())
                .eqIfPresent(TradeOrderDO::getDeliveryType, reqVO.getDeliveryType())
                .inIfPresent(TradeOrderDO::getUserId, userIds)
                .eqIfPresent(TradeOrderDO::getType, reqVO.getType())
                .eqIfPresent(TradeOrderDO::getStatus, reqVO.getStatus())
                .eqIfPresent(TradeOrderDO::getPayChannelCode, reqVO.getPayChannelCode())
                .eqIfPresent(TradeOrderDO::getPaymentProofStatus, reqVO.getPaymentProofStatus())
                .eqIfPresent(TradeOrderDO::getAuditStatus, reqVO.getAuditStatus())
                .eqIfPresent(TradeOrderDO::getCustomerId, reqVO.getCustomerId())
                .eqIfPresent(TradeOrderDO::getDeptId, reqVO.getDeptId())
                .eqIfPresent(TradeOrderDO::getTerminal, reqVO.getTerminal())
                .eqIfPresent(TradeOrderDO::getLogisticsId, reqVO.getLogisticsId())
                .betweenIfPresent(TradeOrderDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(TradeOrderDO::getId));
    }

    /**
     * 订单工作台：待处理要货单分页
     *
     * 口径：待发货(10) + 审核闸门（加盟店须 audit_status=20，直营店免审）+ 至少一行未分料。
     * 「未分料」用 exists 子查询而不是 join：join 会让分页总数被行数放大。
     */
    default PageResult<TradeOrderDO> selectWorkbenchPage(TradeOrderWorkbenchPageReqVO reqVO) {
        LambdaQueryWrapperX<TradeOrderDO> query = new LambdaQueryWrapperX<>();
        query.eq(TradeOrderDO::getStatus, TradeOrderStatusEnum.UNDELIVERED.getStatus())
                .likeIfPresent(TradeOrderDO::getNo, reqVO.getNo())
                .eqIfPresent(TradeOrderDO::getCustomerId, reqVO.getCustomerId())
                .betweenIfPresent(TradeOrderDO::getCreateTime, reqVO.getCreateTime());
        // 审核闸门：加盟店须审核通过；直营（或历史订单未快照店型）免审 —— 与发货闸门口径一致
        query.and(w -> w.ne(TradeOrderDO::getStoreType, StoreTypeEnum.FRANCHISE.getType())
                .or().isNull(TradeOrderDO::getStoreType)
                .or().eq(TradeOrderDO::getAuditStatus, TradeOrderAuditStatusEnum.APPROVE.getStatus()));
        // 至少一行未分料（用 exists 而不是 join，避免分页总数被行数放大）
        query.exists("SELECT 1 FROM trade_order_item i WHERE i.order_id = trade_order.id"
                + " AND i.deleted = 0 AND i.alloc_mode IS NULL");
        query.orderByDesc(TradeOrderDO::getId);
        return selectPage(reqVO, query);
    }

    // TODO @疯狂：如果用 map 返回，要不这里直接用 TradeOrderSummaryRespVO 返回？也算合理，就当  sql 查询出这么个玩意~~
    default List<Map<String, Object>> selectOrderSummaryGroupByRefundStatus(TradeOrderPageReqVO reqVO, Set<Long> userIds) {
        return selectMaps(new MPJLambdaWrapperX<TradeOrderDO>()
                .selectAs(TradeOrderDO::getRefundStatus, TradeOrderDO::getRefundStatus)  // 售后状态
                .selectCount(TradeOrderDO::getId, "count") // 售后状态对应的数量
                .selectSum(TradeOrderDO::getPayPrice, "price")  // 售后状态对应的支付金额
                .likeIfPresent(TradeOrderDO::getNo, reqVO.getNo())
                .eqIfPresent(TradeOrderDO::getUserId, reqVO.getUserId())
                .eqIfPresent(TradeOrderDO::getDeliveryType, reqVO.getDeliveryType())
                .inIfPresent(TradeOrderDO::getUserId, userIds)
                .eqIfPresent(TradeOrderDO::getType, reqVO.getType())
                .eqIfPresent(TradeOrderDO::getStatus, reqVO.getStatus())
                .eqIfPresent(TradeOrderDO::getPayChannelCode, reqVO.getPayChannelCode())
                .eqIfPresent(TradeOrderDO::getTerminal, reqVO.getTerminal())
                .eqIfPresent(TradeOrderDO::getLogisticsId, reqVO.getLogisticsId())
                .betweenIfPresent(TradeOrderDO::getCreateTime, reqVO.getCreateTime())
                .groupBy(TradeOrderDO::getRefundStatus)); // 按售后状态分组
    }

    default PageResult<TradeOrderDO> selectPage(AppTradeOrderPageReqVO reqVO, Long userId) {
        LambdaQueryWrapperX<TradeOrderDO> query = new LambdaQueryWrapperX<TradeOrderDO>()
                .eq(TradeOrderDO::getUserId, userId)
                .eqIfPresent(TradeOrderDO::getStatus, reqVO.getStatus());
        // 门店要货：审核通过（audit_status=20，含直营免审）才是真正「待发货」；
        // 其余（待提交 0 / 审核中 10 / 已驳回 30）在门店端归入「处理中」
        if (reqVO.getAuditPassed() != null) {
            if (Boolean.TRUE.equals(reqVO.getAuditPassed())) {
                query.eq(TradeOrderDO::getAuditStatus, TradeOrderAuditStatusEnum.APPROVE.getStatus());
            } else {
                query.ne(TradeOrderDO::getAuditStatus, TradeOrderAuditStatusEnum.APPROVE.getStatus());
            }
        }
        return selectPage(reqVO, query.orderByDesc(TradeOrderDO::getId)); // TODO 亚特：未来不同的 status，不同的排序
    }

    /** 该会员（订货账号）的订单总数：删除订货账号前校验用 */
    default Long selectCountByUserId(Long userId) {
        return selectCount(new LambdaQueryWrapperX<TradeOrderDO>()
                .eq(TradeOrderDO::getUserId, userId));
    }

    default Long selectCountByUserIdAndStatus(Long userId, Integer status) {
        return selectCount(new LambdaQueryWrapperX<TradeOrderDO>()
                .eq(TradeOrderDO::getUserId, userId)
                .eqIfPresent(TradeOrderDO::getStatus, status));
    }

    default TradeOrderDO selectOrderByIdAndUserId(Long orderId, Long loginUserId) {
        return selectOne(new LambdaQueryWrapperX<TradeOrderDO>()
                .eq(TradeOrderDO::getId, orderId)
                .eq(TradeOrderDO::getUserId, loginUserId));
    }

    default List<TradeOrderDO> selectListByStatusAndCreateTimeLt(Integer status, LocalDateTime createTime) {
        return selectList(new LambdaUpdateWrapper<TradeOrderDO>()
                .eq(TradeOrderDO::getStatus, status)
                .lt(TradeOrderDO::getCreateTime, createTime));
    }

    default List<TradeOrderDO> selectListByStatusAndDeliveryTimeLt(Integer status, LocalDateTime deliveryTime) {
        return selectList(new LambdaUpdateWrapper<TradeOrderDO>()
                .eq(TradeOrderDO::getStatus, status)
                .lt(TradeOrderDO::getDeliveryTime, deliveryTime));
    }

}
