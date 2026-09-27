package com.lxjl.juling.module.trade.service.order;

import cn.hutool.core.util.ObjectUtil;
import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeOrderPaymentProofAuditReqVO;
import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeOrderPaymentProofCreateReqVO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderPaymentProofDO;
import com.lxjl.juling.module.trade.dal.mysql.order.TradeOrderMapper;
import com.lxjl.juling.module.trade.dal.mysql.order.TradeOrderPaymentProofMapper;
import com.lxjl.juling.module.trade.enums.order.TradeOrderPaymentProofStatusEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderReceiveStatusEnum;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.*;

/**
 * 交易订单付款凭证 Service 实现类
 *
 * @author 亚特
 */
@Service
@Validated
@Slf4j
public class TradeOrderPaymentProofServiceImpl implements TradeOrderPaymentProofService {

    @Resource
    private TradeOrderPaymentProofMapper paymentProofMapper;

    @Resource
    private TradeOrderMapper tradeOrderMapper;

    @Resource
    private TradeOrderUpdateService tradeOrderUpdateService;

    @Override
    public Long createPaymentProof(Long userId, AppTradeOrderPaymentProofCreateReqVO createReqVO) {
        // 1. 校验订单存在，且属于当前会员
        TradeOrderDO order = validateOrderOwner(userId, createReqVO.getOrderId());
        // 2. 已收齐的订单不再接受上传（避免重复收款）
        if (TradeOrderReceiveStatusEnum.isPaid(order.getPaymentProofStatus())) {
            throw exception(ORDER_PAYMENT_PROOF_ORDER_ALREADY_PAID);
        }
        // 3. 落库：一次上传 = 一行，保留历史，支持驳回重传
        TradeOrderPaymentProofDO proof = TradeOrderPaymentProofDO.builder()
                .orderId(order.getId())
                .urls(createReqVO.getUrls())
                .amount(createReqVO.getAmount())
                .payerName(createReqVO.getPayerName())
                .payChannelCode(createReqVO.getPayChannelCode())
                .transferTime(createReqVO.getTransferTime())
                .remark(createReqVO.getRemark())
                .status(TradeOrderPaymentProofStatusEnum.PENDING.getStatus())
                .build();
        paymentProofMapper.insert(proof);
        // 4. 订单收款状态进入「待核验」，后台订单列表据此筛选
        tradeOrderMapper.updateById(new TradeOrderDO().setId(order.getId())
                .setPaymentProofStatus(TradeOrderReceiveStatusEnum.PENDING.getStatus()));
        return proof.getId();
    }

    @Override
    public List<TradeOrderPaymentProofDO> getPaymentProofListByOrderId(Long userId, Long orderId) {
        validateOrderOwner(userId, orderId);
        return paymentProofMapper.selectListByOrderId(orderId);
    }

    @Override
    public List<TradeOrderPaymentProofDO> getPaymentProofList(Long orderId) {
        return paymentProofMapper.selectListByOrderId(orderId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void auditPaymentProof(Long auditUserId, TradeOrderPaymentProofAuditReqVO auditReqVO) {
        // 1. 校验凭证存在且仍待核验（避免重复核验）
        TradeOrderPaymentProofDO proof = paymentProofMapper.selectById(auditReqVO.getId());
        if (proof == null) {
            throw exception(ORDER_PAYMENT_PROOF_NOT_EXISTS);
        }
        if (!TradeOrderPaymentProofStatusEnum.isPending(proof.getStatus())) {
            throw exception(ORDER_PAYMENT_PROOF_STATUS_NOT_PENDING);
        }
        // 2. 认定金额：金额不符时以后台核定的金额为准
        Integer confirmedAmount = ObjectUtil.defaultIfNull(auditReqVO.getConfirmedAmount(), proof.getAmount());
        // 3. 更新凭证：确认 / 驳回
        paymentProofMapper.updateById(new TradeOrderPaymentProofDO().setId(proof.getId())
                .setStatus(auditReqVO.getApproved() ? TradeOrderPaymentProofStatusEnum.CONFIRMED.getStatus()
                        : TradeOrderPaymentProofStatusEnum.REJECTED.getStatus())
                .setConfirmedAmount(auditReqVO.getApproved() ? confirmedAmount : null)
                .setAuditUserId(auditUserId).setAuditTime(LocalDateTime.now())
                .setAuditRemark(auditReqVO.getAuditRemark()));
        // 4. 重算订单的收款进度
        refreshOrderReceiveStatus(proof.getOrderId());
    }

    /**
     * 重算并回写订单的收款进度；收满应收金额时触发线下「订单已收款」流程
     */
    private void refreshOrderReceiveStatus(Long orderId) {
        TradeOrderDO order = tradeOrderMapper.selectById(orderId);
        if (order == null) {
            return;
        }
        List<TradeOrderPaymentProofDO> proofs = paymentProofMapper.selectListByOrderId(orderId);
        int paidAmount = proofs.stream()
                .filter(proof -> TradeOrderPaymentProofStatusEnum.isConfirmed(proof.getStatus()))
                .map(TradeOrderPaymentProofDO::getConfirmedAmount)
                .filter(Objects::nonNull)
                .reduce(0, Integer::sum);
        boolean hasPending = proofs.stream().anyMatch(proof -> TradeOrderPaymentProofStatusEnum.isPending(proof.getStatus()));
        boolean hasRejected = proofs.stream().anyMatch(proof -> TradeOrderPaymentProofStatusEnum.isRejected(proof.getStatus()));

        // 未收满时，收款状态体现「当前最需要处理的事」：待核验 > 部分收款 > 已驳回 > 未上传
        int receiveStatus;
        boolean paid = order.getPayPrice() != null && paidAmount >= order.getPayPrice();
        if (paid) {
            receiveStatus = TradeOrderReceiveStatusEnum.PAID.getStatus();
        } else if (hasPending) {
            receiveStatus = TradeOrderReceiveStatusEnum.PENDING.getStatus();
        } else if (paidAmount > 0) {
            receiveStatus = TradeOrderReceiveStatusEnum.PARTIAL.getStatus();
        } else if (hasRejected) {
            receiveStatus = TradeOrderReceiveStatusEnum.REJECTED.getStatus();
        } else {
            receiveStatus = TradeOrderReceiveStatusEnum.NONE.getStatus();
        }
        tradeOrderMapper.updateById(new TradeOrderDO().setId(orderId)
                .setPaidAmount(paidAmount).setPaymentProofStatus(receiveStatus));

        // 收满且订单尚未支付 → 置为「已收款、待发货」，并执行与线上支付一致的后置处理
        if (paid && !Boolean.TRUE.equals(order.getPayStatus())) {
            String payChannelCode = proofs.stream()
                    .filter(proof -> TradeOrderPaymentProofStatusEnum.isConfirmed(proof.getStatus()))
                    .map(TradeOrderPaymentProofDO::getPayChannelCode)
                    .filter(ObjectUtil::isNotEmpty)
                    .findFirst().orElse(null);
            log.info("[refreshOrderReceiveStatus][订单({}) 收款已满（{} 分），置为已收款待发货]", orderId, paidAmount);
            tradeOrderUpdateService.updateOrderPaidByOffline(orderId, paidAmount, payChannelCode);
        }
    }

    /**
     * 校验订单存在且属于当前会员
     */
    private TradeOrderDO validateOrderOwner(Long userId, Long orderId) {
        TradeOrderDO order = tradeOrderMapper.selectById(orderId);
        if (order == null) {
            throw exception(ORDER_NOT_FOUND);
        }
        if (!Objects.equals(order.getUserId(), userId)) {
            throw exception(ORDER_PAYMENT_PROOF_NOT_BELONG_TO_USER);
        }
        return order;
    }

}
