package com.lxjl.juling.module.hrm.job.performance;

import com.lxjl.juling.framework.quartz.core.handler.JobHandler;
import com.lxjl.juling.framework.tenant.core.job.TenantJob;
import com.lxjl.juling.module.hrm.dal.dataobject.performance.assessment.HrmPerformanceAssessmentStageDO;
import com.lxjl.juling.module.hrm.service.performance.assessment.HrmPerformanceAssessmentProcessService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

/**
 * HRM 绩效申诉超期处理 Job
 *
 * @author 棱信矩灵
 */
@Component
public class HrmPerformanceAppealTimeoutJob implements JobHandler {

    @Resource
    private HrmPerformanceAssessmentProcessService performanceAssessmentProcessService;

    @Override
    @TenantJob
    public String execute(String param) {
        // 1. 查询超时的绩效申诉阶段
        List<HrmPerformanceAssessmentStageDO> stages =
                performanceAssessmentProcessService.getAppealTimeoutStageList(LocalDateTime.now());

        // 2. 逐个处理，确保每个申诉使用独立事务
        int successCount = 0;
        for (HrmPerformanceAssessmentStageDO stage : stages) {
            if (performanceAssessmentProcessService.processAppealTimeout(stage.getId())) {
                successCount++;
            }
        }

        // 3. 返回执行结果
        return String.format("HRM 绩效申诉超期处理：待处理 %s 条，成功 %s 条", stages.size(), successCount);
    }

}
