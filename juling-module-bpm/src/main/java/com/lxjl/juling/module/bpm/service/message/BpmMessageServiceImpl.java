package com.lxjl.juling.module.bpm.service.message;

import com.lxjl.juling.framework.web.config.WebProperties;
import com.lxjl.juling.module.bpm.convert.message.BpmMessageConvert;
import com.lxjl.juling.module.bpm.enums.message.BpmMessageEnum;
import com.lxjl.juling.module.bpm.service.message.dto.BpmMessageSendWhenProcessInstanceApproveReqDTO;
import com.lxjl.juling.module.bpm.service.message.dto.BpmMessageSendWhenProcessInstanceRejectReqDTO;
import com.lxjl.juling.module.bpm.service.message.dto.BpmMessageSendWhenTaskCreatedReqDTO;
import com.lxjl.juling.module.bpm.service.message.dto.BpmMessageSendWhenTaskTimeoutReqDTO;
import com.lxjl.juling.module.system.api.sms.SmsSendApi;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import jakarta.annotation.Resource;
import java.util.HashMap;
import java.util.Map;

/**
 * BPM 消息 Service 实现类
 *
 * @author 亚特
 */
@Service
@Validated
@Slf4j
public class BpmMessageServiceImpl implements BpmMessageService {

    @Resource
    private SmsSendApi smsSendApi;

    @Resource
    private WebProperties webProperties;

    @Override
    public void sendMessageWhenProcessInstanceApprove(BpmMessageSendWhenProcessInstanceApproveReqDTO reqDTO) {
        Map<String, Object> templateParams = new HashMap<>();
        templateParams.put("processInstanceName", reqDTO.getProcessInstanceName());
        templateParams.put("detailUrl", getProcessInstanceDetailUrl(reqDTO.getProcessInstanceId()));
        sendSmsQuietly("流程审批通过通知", () -> smsSendApi.sendSingleSmsToAdmin(
                BpmMessageConvert.INSTANCE.convert(reqDTO.getStartUserId(),
                        BpmMessageEnum.PROCESS_INSTANCE_APPROVE.getSmsTemplateCode(), templateParams)));
    }

    @Override
    public void sendMessageWhenProcessInstanceReject(BpmMessageSendWhenProcessInstanceRejectReqDTO reqDTO) {
        Map<String, Object> templateParams = new HashMap<>();
        templateParams.put("processInstanceName", reqDTO.getProcessInstanceName());
        templateParams.put("reason", reqDTO.getReason());
        templateParams.put("detailUrl", getProcessInstanceDetailUrl(reqDTO.getProcessInstanceId()));
        sendSmsQuietly("流程审批驳回通知", () -> smsSendApi.sendSingleSmsToAdmin(
                BpmMessageConvert.INSTANCE.convert(reqDTO.getStartUserId(),
                        BpmMessageEnum.PROCESS_INSTANCE_REJECT.getSmsTemplateCode(), templateParams)));
    }

    @Override
    public void sendMessageWhenTaskAssigned(BpmMessageSendWhenTaskCreatedReqDTO reqDTO) {
        Map<String, Object> templateParams = new HashMap<>();
        templateParams.put("processInstanceName", reqDTO.getProcessInstanceName());
        templateParams.put("taskName", reqDTO.getTaskName());
        templateParams.put("startUserNickname", reqDTO.getStartUserNickname());
        templateParams.put("detailUrl", getProcessInstanceDetailUrl(reqDTO.getProcessInstanceId()));
        sendSmsQuietly("任务待办通知", () -> smsSendApi.sendSingleSmsToAdmin(
                BpmMessageConvert.INSTANCE.convert(reqDTO.getAssigneeUserId(),
                        BpmMessageEnum.TASK_ASSIGNED.getSmsTemplateCode(), templateParams)));
    }

    @Override
    public void sendMessageWhenTaskTimeout(BpmMessageSendWhenTaskTimeoutReqDTO reqDTO) {
        Map<String, Object> templateParams = new HashMap<>();
        templateParams.put("processInstanceName", reqDTO.getProcessInstanceName());
        templateParams.put("taskName", reqDTO.getTaskName());
        templateParams.put("detailUrl", getProcessInstanceDetailUrl(reqDTO.getProcessInstanceId()));
        sendSmsQuietly("任务超时通知", () -> smsSendApi.sendSingleSmsToAdmin(
                BpmMessageConvert.INSTANCE.convert(reqDTO.getAssigneeUserId(),
                        BpmMessageEnum.TASK_TIMEOUT.getSmsTemplateCode(), templateParams)));
    }

    /**
     * 发送短信通知（旁路，失败只记录日志）
     *
     * 背景：短信渠道/模板未配置时 {@link SmsSendApi} 会抛异常。通知属于旁路能力，
     * 不能因为"没配短信"把审批事务整体回滚（亚特：门店要货审核通过后必须能落状态）。
     */
    private void sendSmsQuietly(String scene, Runnable action) {
        try {
            action.run();
        } catch (Throwable e) {
            log.warn("[sendSmsQuietly][{} 发送失败，已忽略：{}]", scene, e.getMessage());
        }
    }

    private String getProcessInstanceDetailUrl(String taskId) {
        return webProperties.getAdminUi().getUrl() + "/bpm/process-instance/detail?id=" + taskId;
    }

}
