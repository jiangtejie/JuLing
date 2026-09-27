package com.lxjl.juling.module.trade.service.order;

import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeOrderPaymentProofAuditReqVO;
import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeOrderPaymentProofCreateReqVO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderPaymentProofDO;

import java.util.List;

/**
 * 交易订单付款凭证 Service 接口
 *
 * 线下收款：客户上传付款截图，后台核验；金额可分批、可与申报不一致（以核定金额为准）。
 *
 * @author 亚特
 */
public interface TradeOrderPaymentProofService {

    /**
     * 客户提交付款凭证
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

    /**
     * 后台核验付款凭证：确认收款 / 驳回重传
     *
     * 确认后会重算订单已收金额；收满应收金额时把订单置为「已收款、待发货」。
     *
     * @param auditUserId 核验人编号
     * @param auditReqVO  核验信息
     */
    void auditPaymentProof(Long auditUserId, TradeOrderPaymentProofAuditReqVO auditReqVO);

}
