package com.lxjl.juling.module.trade.service.order;

import cn.hutool.core.util.ObjectUtil;
import com.lxjl.juling.module.bpm.api.task.BpmProcessInstanceApi;
import com.lxjl.juling.module.bpm.api.task.dto.BpmProcessInstanceCreateReqDTO;
import com.lxjl.juling.module.bpm.enums.task.BpmProcessInstanceStatusEnum;
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
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.ORDER_AUDIT_FAIL_STATUS;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.ORDER_AUDIT_UPDATE_FAIL_NOT_PROCESS;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.ORDER_DELIVERY_FAIL_AUDIT_NOT_APPROVE;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.ORDER_NOT_FOUND;

/**
 * 交易订单（门店要货）审核 Service 实现类
 *
 * @author 亚特
 */
@Slf4j
@Service
@Validated
public class TradeOrderAuditServiceImpl implements TradeOrderAuditService {

    @Resource
    private TradeOrderMapper tradeOrderMapper;
    @Resource
    private BpmProcessInstanceApi bpmProcessInstanceApi;
    @Resource
    private com.lxjl.juling.module.erp.api.customer.ErpCustomerApi erpCustomerApi;
    @Resource
    private TradeOrderPaymentProofMapper paymentProofMapper;

    /**
     * 自动提交审核时的流程发起人编号
     *
     * <p>门店在 H5 提交凭证就触发审批，而门店账号（会员）没有该流程定义的发起权限（定义里 start_user_ids = 1），
     * 所以自动提交统一用这个「系统发起人」，手工提交仍用当前登录的管理员。
     */
    @Value("${juling.trade.order-audit.start-user-id:1}")
    private Long autoSubmitUserId;

    @Override
    public void submitAudit(Long orderId, Long userId) {
        doSubmitAudit(orderId, userId);
    }

    @Override
    @Transactional(propagation = Propagation.REQUIRES_NEW, rollbackFor = Exception.class)
    public void submitAuditAfterCommit(Long orderId, Long userId) {
        try {
            doSubmitAudit(orderId, userId);
        } catch (Throwable e) {
            // 只记日志、不向上抛：收款已经落库，不能因为审核没提交上而回滚收款。
            // 订单此时是「待发货 + 待提交审核」，发货闸门对加盟门店是关闭的，可在后台手工提交。
            log.error("[submitAuditAfterCommit][订单({}) 自动提交门店要货审核失败，请在订单详情页手工提交，"
                    + "或检查 BPM 流程定义({})是否已部署、发起人是否有权限]",
                    orderId, BPM_PROCESS_DEFINITION_KEY, e);
        }
    }

    @Override
    @Transactional(propagation = Propagation.REQUIRES_NEW, rollbackFor = Exception.class)
    public void submitAuditAutoAfterCommit(Long orderId) {
        try {
            doSubmitAudit(orderId, autoSubmitUserId);
        } catch (Throwable e) {
            log.error("[submitAuditAutoAfterCommit][订单({}) 自动提交门店要货审核失败（发起人={}），"
                    + "请在订单详情页手工提交，或检查 BPM 流程定义({})是否已部署]",
                    orderId, autoSubmitUserId, BPM_PROCESS_DEFINITION_KEY, e);
        }
    }

    private void doSubmitAudit(Long orderId, Long userId) {
        // 1. 校验订单存在，且处于「待发货」+「待提交/已驳回」
        TradeOrderDO order = tradeOrderMapper.selectById(orderId);
        if (order == null) {
            throw exception(ORDER_NOT_FOUND);
        }
        if (!Objects.equals(order.getStatus(), TradeOrderStatusEnum.UNDELIVERED.getStatus())
                || (!isDraft(order.getAuditStatus()) && !isReject(order.getAuditStatus()))) {
            throw exception(ORDER_AUDIT_FAIL_STATUS);
        }

        // 2. 创建 BPM 审批流程实例（流程定义 Key：trade-order-store-audit）
        String processInstanceId = bpmProcessInstanceApi.createProcessInstance(userId,
                new BpmProcessInstanceCreateReqDTO().setProcessDefinitionKey(BPM_PROCESS_DEFINITION_KEY)
                        .setBusinessKey(String.valueOf(orderId)));

        // 3. 更新订单审核状态
        tradeOrderMapper.updateById(new TradeOrderDO().setId(orderId)
                .setAuditStatus(TradeOrderAuditStatusEnum.PROCESS.getStatus())
                .setProcessInstanceId(processInstanceId)
                .setAuditRemark(""));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateAuditStatus(Long orderId, Integer bpmStatus) {
        // 1. 校验订单处于审核中
        TradeOrderDO order = tradeOrderMapper.selectById(orderId);
        if (order == null) {
            log.error("[updateAuditStatus][订单({}) 不存在，忽略 BPM 审核结果({})]", orderId, bpmStatus);
            return;
        }
        if (!Objects.equals(order.getAuditStatus(), TradeOrderAuditStatusEnum.PROCESS.getStatus())) {
            log.error("[updateAuditStatus][订单({}) 不处于审核中，无法更新审核结果({})]", orderId, bpmStatus);
            throw exception(ORDER_AUDIT_UPDATE_FAIL_NOT_PROCESS);
        }

        // 2. 映射审核结果：通过 / 驳回 / 发起人撤销（回到待提交，可重新提交）
        Integer auditStatus = convertBpmStatus(bpmStatus);
        if (auditStatus == null) {
            log.warn("[updateAuditStatus][订单({}) 收到不处理的 BPM 状态({})]", orderId, bpmStatus);
            return;
        }
        boolean approved = TradeOrderAuditStatusEnum.isApprove(auditStatus);

        // 3. 审批结果回写付款凭证：通过 = 已认定（按申报金额认定），驳回 = 已驳回（门店需重新上传）
        LocalDateTime now = LocalDateTime.now();
        paymentProofMapper.selectListByOrderId(orderId).stream()
                .filter(proof -> TradeOrderPaymentProofStatusEnum.isPending(proof.getStatus()))
                .forEach(proof -> paymentProofMapper.updateById(new TradeOrderPaymentProofDO().setId(proof.getId())
                        .setStatus(approved ? TradeOrderPaymentProofStatusEnum.CONFIRMED.getStatus()
                                : TradeOrderPaymentProofStatusEnum.REJECTED.getStatus())
                        .setConfirmedAmount(approved ? proof.getAmount() : null)
                        .setAuditTime(now)
                        .setAuditRemark(approved ? "" : ObjectUtil.defaultIfNull(order.getAuditRemark(), ""))));

        // 4. 按「未被驳回的凭证申报金额」重算订单收款进度（驳回后归零，门店可重新上传并自动再提交审批）
        List<TradeOrderPaymentProofDO> proofs = paymentProofMapper.selectListByOrderId(orderId);
        int declaredAmount = proofs.stream()
                .filter(proof -> !TradeOrderPaymentProofStatusEnum.isRejected(proof.getStatus()))
                .map(TradeOrderPaymentProofDO::getAmount)
                .filter(Objects::nonNull)
                .reduce(0, Integer::sum);
        boolean paid = order.getPayPrice() != null && declaredAmount >= order.getPayPrice();
        int receiveStatus = paid ? TradeOrderReceiveStatusEnum.PAID.getStatus()
                : declaredAmount > 0 ? TradeOrderReceiveStatusEnum.PARTIAL.getStatus()
                : approved ? TradeOrderReceiveStatusEnum.NONE.getStatus()
                : TradeOrderReceiveStatusEnum.REJECTED.getStatus();
        tradeOrderMapper.updateById(new TradeOrderDO().setId(orderId)
                .setAuditStatus(auditStatus).setAuditTime(now)
                .setPaidAmount(declaredAmount).setPaymentProofStatus(receiveStatus));
    }

    @Override
    public void validateCanDelivery(TradeOrderDO order) {
        // 直营门店：直接流转，不设审核闸门（CY-001 整体业务流程：加盟门店需财务审核进入订单工作台，直营门店则直接）
        if (!isFranchise(order)) {
            return;
        }
        if (!TradeOrderAuditStatusEnum.isApprove(order.getAuditStatus())) {
            throw exception(ORDER_DELIVERY_FAIL_AUDIT_NOT_APPROVE);
        }
    }

    /**
     * 是否加盟门店（店型取客户主数据；未设置店型时按直营处理，避免历史数据被卡住）
     */
    private boolean isFranchise(TradeOrderDO order) {
        if (order.getCustomerId() == null) {
            return false;
        }
        var customer = erpCustomerApi.getCustomer(order.getCustomerId());
        return customer != null && Objects.equals(customer.getStoreType(), "FRANCHISE");
    }

    private static Integer convertBpmStatus(Integer bpmStatus) {
        if (Objects.equals(bpmStatus, BpmProcessInstanceStatusEnum.APPROVE.getStatus())) {
            return TradeOrderAuditStatusEnum.APPROVE.getStatus();
        }
        if (Objects.equals(bpmStatus, BpmProcessInstanceStatusEnum.REJECT.getStatus())) {
            return TradeOrderAuditStatusEnum.REJECT.getStatus();
        }
        if (Objects.equals(bpmStatus, BpmProcessInstanceStatusEnum.CANCEL.getStatus())) {
            return TradeOrderAuditStatusEnum.DRAFT.getStatus();
        }
        return null;
    }

    private static boolean isDraft(Integer auditStatus) {
        return auditStatus == null || Objects.equals(auditStatus, TradeOrderAuditStatusEnum.DRAFT.getStatus());
    }

    private static boolean isReject(Integer auditStatus) {
        return Objects.equals(auditStatus, TradeOrderAuditStatusEnum.REJECT.getStatus());
    }

}
