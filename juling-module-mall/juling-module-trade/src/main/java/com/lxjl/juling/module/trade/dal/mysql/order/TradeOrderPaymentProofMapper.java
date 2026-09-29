package com.lxjl.juling.module.trade.dal.mysql.order;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderPaymentProofDO;
import com.lxjl.juling.module.trade.enums.order.TradeOrderPaymentProofStatusEnum;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;
import java.util.Objects;

/**
 * 交易订单付款凭证 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface TradeOrderPaymentProofMapper extends BaseMapperX<TradeOrderPaymentProofDO> {

    default List<TradeOrderPaymentProofDO> selectListByOrderId(Long orderId) {
        return selectList(new LambdaQueryWrapperX<TradeOrderPaymentProofDO>()
                .eq(TradeOrderPaymentProofDO::getOrderId, orderId)
                .orderByDesc(TradeOrderPaymentProofDO::getId));
    }

    /**
     * 已确认的收款金额合计，单位：分
     *
     * 单个订单的凭证条数很少（几次上传），直接内存聚合即可，免去额外写自定义 SQL。
     */
    default int sumConfirmedAmount(Long orderId) {
        return selectListByOrderId(orderId).stream()
                .filter(proof -> TradeOrderPaymentProofStatusEnum.isConfirmed(proof.getStatus()))
                .map(TradeOrderPaymentProofDO::getConfirmedAmount)
                .filter(Objects::nonNull)
                .reduce(0, Integer::sum);
    }

    default boolean existsByOrderIdAndStatus(Long orderId, Integer status) {
        return selectCount(new LambdaQueryWrapperX<TradeOrderPaymentProofDO>()
                .eq(TradeOrderPaymentProofDO::getOrderId, orderId)
                .eq(TradeOrderPaymentProofDO::getStatus, status)) > 0;
    }

}
