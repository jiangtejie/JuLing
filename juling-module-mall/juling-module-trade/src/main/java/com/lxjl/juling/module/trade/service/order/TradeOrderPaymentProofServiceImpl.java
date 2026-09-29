package com.lxjl.juling.module.trade.service.order;

import cn.hutool.core.util.ObjectUtil;
import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeOrderPaymentProofCreateReqVO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderPaymentProofDO;
import com.lxjl.juling.module.trade.dal.mysql.order.TradeOrderMapper;
import com.lxjl.juling.module.trade.dal.mysql.order.TradeOrderPaymentProofMapper;
import com.lxjl.juling.module.trade.enums.order.TradeOrderAuditStatusEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderPaymentProofStatusEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderReceiveStatusEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderStatusEnum;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.util.List;
import java.util.Objects;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.*;

/**
 * 交易订单付款凭证 Service 实现类
 *
 * <p>门店订货链（不再有「收款核验」这一步）：门店在 H5 提交付款凭证后，直接按<strong>凭证申报金额</strong>
 * 把订单置为「已收款、待发货」，加盟门店随后自动提交 BPM 两级审批（供应链 → 财务出纳），
 * 原来后台人工「核验收款」的职责由<strong>财务审批节点</strong>承接：
 * <ul>
 *   <li>审批通过 → 凭证置「已认定」（confirmed_amount = 申报金额），订单收款状态按申报金额重算；</li>
 *   <li>审批驳回 → 凭证置「已驳回」，订单 paid_amount 归零，门店可在 H5 重新上传后自动再次提交审批。</li>
 * </ul>
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

    @Resource
    private TradeOrderAuditService tradeOrderAuditService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createPaymentProof(Long userId, AppTradeOrderPaymentProofCreateReqVO createReqVO) {
        // 1. 校验订单存在，且属于当前会员
        TradeOrderDO order = validateOrderOwner(userId, createReqVO.getOrderId());
        // 2. 审核通过（或已发货）之后不再接受补传，避免重复收款；待支付 / 审核中 / 已驳回都可以传
        if (!canUploadProof(order)) {
            throw exception(ORDER_PAYMENT_PROOF_ORDER_ALREADY_PAID);
        }
        // 3. 落库：一次上传 = 一行，保留历史；状态「待审核」，由审批结果驱动为已认定 / 已驳回
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
        // 4. 按申报金额推进订单（首次上传即置「已收款、待发货」并进入审批）
        refreshOrderPaidAmount(order.getId());
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

    /**
     * 是否允许上传 / 补传付款凭证
     *
     * <p>待支付：可以（首次上传）；待发货：仅当审核尚未通过时（待提交 / 审核中 / 已驳回）可以补传。
     */
    private boolean canUploadProof(TradeOrderDO order) {
        if (TradeOrderStatusEnum.isUnpaid(order.getStatus())) {
            return true;
        }
        // 待发货阶段只有「待提交 / 已驳回」允许补传：审核中不允许追加（否则重复上传会把申报金额叠高，
        // 财务看到的是一个虚高的应收），审批通过后同样不再接受上传
        return Objects.equals(order.getStatus(), TradeOrderStatusEnum.UNDELIVERED.getStatus())
                && (isDraft(order.getAuditStatus()) || isReject(order.getAuditStatus()));
    }

    private static boolean isDraft(Integer auditStatus) {
        return auditStatus == null || Objects.equals(auditStatus, TradeOrderAuditStatusEnum.DRAFT.getStatus());
    }

    private static boolean isReject(Integer auditStatus) {
        return Objects.equals(auditStatus, TradeOrderAuditStatusEnum.REJECT.getStatus());
    }

    /**
     * 按「未被驳回的凭证申报金额」重算订单收款进度，并在首次上传时把订单推进到「待发货」
     *
     * <p>注意：这里不再有「待核验」这个需要人工处理的状态；申报金额 ≥ 应收 = 已收齐，否则部分收款，
     * 差额由财务在审批节点决定「通过（差额挂门店往来）」或「驳回（要求门店补传）」。
     */
    private void refreshOrderPaidAmount(Long orderId) {
        TradeOrderDO order = tradeOrderMapper.selectById(orderId);
        if (order == null) {
            return;
        }
        List<TradeOrderPaymentProofDO> proofs = paymentProofMapper.selectListByOrderId(orderId);
        int declaredAmount = proofs.stream()
                .filter(proof -> !TradeOrderPaymentProofStatusEnum.isRejected(proof.getStatus()))
                .map(TradeOrderPaymentProofDO::getAmount)
                .filter(Objects::nonNull)
                .reduce(0, Integer::sum);

        // 1. 首次上传（订单还停在「待支付」）：按申报金额置「已收款、待发货」；
        //    加盟门店会在事务提交后自动提交两级审批，直营门店免审直接进订单工作台
        if (!Boolean.TRUE.equals(order.getPayStatus()) && declaredAmount > 0) {
            String payChannelCode = proofs.stream()
                    .map(TradeOrderPaymentProofDO::getPayChannelCode)
                    .filter(ObjectUtil::isNotEmpty)
                    .findFirst().orElse(null);
            log.info("[refreshOrderPaidAmount][订单({}) 门店提交付款凭证申报 {} 分，直接置为已收款待发货]", orderId, declaredAmount);
            tradeOrderUpdateService.updateOrderPaidByOffline(orderId, declaredAmount, payChannelCode);
        }

        // 2. 收款状态：申报金额 ≥ 应收 = 已收齐，否则部分收款；被驳回后申报金额归零
        boolean paid = order.getPayPrice() != null && declaredAmount >= order.getPayPrice();
        int receiveStatus = paid ? TradeOrderReceiveStatusEnum.PAID.getStatus()
                : declaredAmount > 0 ? TradeOrderReceiveStatusEnum.PARTIAL.getStatus()
                : TradeOrderReceiveStatusEnum.NONE.getStatus();
        tradeOrderMapper.updateById(new TradeOrderDO().setId(orderId)
                .setPaidAmount(declaredAmount).setPaymentProofStatus(receiveStatus));

        // 3. 审核被驳回后门店重新上传：自动再次提交审批（订单已收款待发货，无需重新推进状态）
        if (Boolean.TRUE.equals(order.getPayStatus())
                && Objects.equals(order.getStatus(), TradeOrderStatusEnum.UNDELIVERED.getStatus())
                && Objects.equals(order.getAuditStatus(), TradeOrderAuditStatusEnum.REJECT.getStatus())) {
            log.info("[refreshOrderPaidAmount][订单({}) 门店重新提交凭证，自动再次提交门店要货审核]", orderId);
            tradeOrderAuditService.submitAuditAutoAfterCommit(orderId);
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
