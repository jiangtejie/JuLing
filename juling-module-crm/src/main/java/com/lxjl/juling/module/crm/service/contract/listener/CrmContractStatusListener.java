package com.lxjl.juling.module.crm.service.contract.listener;

import com.lxjl.juling.module.bpm.api.event.BpmProcessInstanceStatusEvent;
import com.lxjl.juling.module.bpm.api.event.BpmProcessInstanceStatusEventListener;
import com.lxjl.juling.module.crm.service.contract.CrmContractService;
import com.lxjl.juling.module.crm.service.contract.CrmContractServiceImpl;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Component;

/**
 * 合同审批的结果的监听器实现类
 *
 * @author 棱信矩灵
 */
@Component
public class CrmContractStatusListener extends BpmProcessInstanceStatusEventListener {

    @Resource
    private CrmContractService contractService;

    @Override
    public String getProcessDefinitionKey() {
        return CrmContractServiceImpl.BPM_PROCESS_DEFINITION_KEY;
    }

    @Override
    protected void onEvent(BpmProcessInstanceStatusEvent event) {
        contractService.updateContractAuditStatus(Long.parseLong(event.getBusinessKey()), event.getStatus());
    }

}
