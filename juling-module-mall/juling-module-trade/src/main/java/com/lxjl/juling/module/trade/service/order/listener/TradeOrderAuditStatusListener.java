package com.lxjl.juling.module.trade.service.order.listener;

import com.lxjl.juling.module.bpm.api.event.BpmProcessInstanceStatusEvent;
import com.lxjl.juling.module.bpm.api.event.BpmProcessInstanceStatusEventListener;
import com.lxjl.juling.module.trade.service.order.TradeOrderAuditService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Component;

/**
 * 门店要货审核结果的监听器
 *
 * @author 亚特
 */
@Component
public class TradeOrderAuditStatusListener extends BpmProcessInstanceStatusEventListener {

    @Resource
    private TradeOrderAuditService tradeOrderAuditService;

    @Override
    public String getProcessDefinitionKey() {
        return TradeOrderAuditService.BPM_PROCESS_DEFINITION_KEY;
    }

    @Override
    protected void onEvent(BpmProcessInstanceStatusEvent event) {
        tradeOrderAuditService.updateAuditStatus(Long.parseLong(event.getBusinessKey()), event.getStatus());
    }

}
