package com.lxjl.juling.module.trade.service.order;

import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeOrderPaymentProofCreateReqVO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderPaymentProofDO;

import java.util.List;

/**
 * 交易订单付款凭证 Service 接口
 *
 * 门店订货链（不再有后台「收款核验」）：客户在 H5 提交付款凭证即视为已付款并进入两级审批，
 * 凭证金额按客户申报记账；审批通过 = 认定，审批驳回 = 门店重新上传。
 *
 * @author 亚特
 */
public interface TradeOrderPaymentProofService {

    /**
     * 客户提交付款凭证（提交后直接进入审核，无需后台核验）
     *
     * @param userId      当前会员编号
     * @param createReqVO 凭证信息
     * @return 凭证编号
     */
    Long createPaymentProof(Long userId, AppTradeOrderPaymentProofCreateReqVO createReqVO);

    /**
     * 获得某订单的付款凭证列表（客户侧，会校验订单归属）
     *
     * @param userId  当前会员编号
     * @param orderId 交易订单编号
     * @return 凭证列表
     */
    List<TradeOrderPaymentProofDO> getPaymentProofListByOrderId(Long userId, Long orderId);

    /**
     * 获得某订单的付款凭证列表（后台侧）
     *
     * @param orderId 交易订单编号
     * @return 凭证列表
     */
    List<TradeOrderPaymentProofDO> getPaymentProofList(Long orderId);

}
