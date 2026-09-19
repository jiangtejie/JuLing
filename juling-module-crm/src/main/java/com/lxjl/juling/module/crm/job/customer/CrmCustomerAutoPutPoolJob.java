package com.lxjl.juling.module.crm.job.customer;

import com.lxjl.juling.framework.quartz.core.handler.JobHandler;
import com.lxjl.juling.framework.tenant.core.job.TenantJob;
import com.lxjl.juling.module.crm.service.customer.CrmCustomerService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Component;

/**
 * 客户自动掉入公海 Job
 *
 * @author 棱信矩灵
 */
@Component
public class CrmCustomerAutoPutPoolJob implements JobHandler {

    @Resource
    private CrmCustomerService customerService;

    @Override
    @TenantJob
    public String execute(String param) {
        int count = customerService.autoPutCustomerPool();
        return String.format("掉入公海客户 %s 个", count);
    }

}