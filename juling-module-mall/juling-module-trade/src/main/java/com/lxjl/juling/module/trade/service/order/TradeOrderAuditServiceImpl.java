package com.lxjl.juling.module.trade.service.order;

import com.lxjl.juling.module.bpm.api.task.BpmProcessInstanceApi;
import com.lxjl.juling.module.bpm.api.task.dto.BpmProcessInstanceCreateReqDTO;
import com.lxjl.juling.module.bpm.enums.task.BpmProcessInstanceStatusEnum;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderDO;
import com.lxjl.juling.module.trade.dal.mysql.order.TradeOrderMapper;
import com.lxjl.juling.module.trade.enums.order.TradeOrderAuditStatusEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderStatusEnum;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import java.time.LocalDateTime;
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

    @Override
    public void submitAudit(Long orderId, Long userId) {
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
        tradeOrderMapper.updateById(new TradeOrderDO().setId(orderId)
                .setAuditStatus(auditStatus).setAuditTime(LocalDateTime.now()));
    }

    @Override
    public void validateCanDelivery(TradeOrderDO order) {
        if (!TradeOrderAuditStatusEnum.isApprove(order.getAuditStatus())) {
            throw exception(ORDER_DELIVERY_FAIL_AUDIT_NOT_APPROVE);
        }
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
