package com.lxjl.juling.module.bpm.framework.flowable.core.candidate.strategy.dept;

import com.lxjl.juling.framework.common.util.string.StrUtils;
import com.lxjl.juling.module.bpm.framework.flowable.core.candidate.BpmTaskCandidateStrategy;
import com.lxjl.juling.module.bpm.framework.flowable.core.enums.BpmTaskCandidateStrategyEnum;
import com.lxjl.juling.module.system.api.dept.DeptApi;
import com.lxjl.juling.module.system.api.dept.dto.DeptRespDTO;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Set;

import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertSet;

/**
 * 部门的负责人 {@link BpmTaskCandidateStrategy} 实现类
 *
 * @author 棱信矩灵
 */
@Component
public class BpmTaskCandidateDeptLeaderStrategy implements BpmTaskCandidateStrategy {

    @Resource
    private DeptApi deptApi;

    @Override
    public BpmTaskCandidateStrategyEnum getStrategy() {
        return BpmTaskCandidateStrategyEnum.DEPT_LEADER;
    }

    @Override
    public void validateParam(String param) {
        Set<Long> deptIds = StrUtils.splitToLongSet(param);
        deptApi.validateDeptList(deptIds);
    }

    @Override
    public Set<Long> calculateUsers(String param) {
        Set<Long> deptIds = StrUtils.splitToLongSet(param);
        List<DeptRespDTO> depts = deptApi.getDeptList(deptIds);
        return convertSet(depts, DeptRespDTO::getLeaderUserId);
    }

}