package com.lxjl.juling.module.bpm.framework.flowable.core.candidate.strategy.user;

import com.lxjl.juling.framework.common.util.string.StrUtils;
import com.lxjl.juling.module.bpm.framework.flowable.core.candidate.BpmTaskCandidateStrategy;
import com.lxjl.juling.module.bpm.framework.flowable.core.enums.BpmTaskCandidateStrategyEnum;
import com.lxjl.juling.module.system.api.dept.PostApi;
import com.lxjl.juling.module.system.api.user.AdminUserApi;
import com.lxjl.juling.module.system.api.user.dto.AdminUserRespDTO;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Set;

import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertSet;

/**
 * 岗位 {@link BpmTaskCandidateStrategy} 实现类
 *
 * @author 棱信矩灵
 */
@Component
public class BpmTaskCandidatePostStrategy implements BpmTaskCandidateStrategy {

    @Resource
    private PostApi postApi;
    @Resource
    private AdminUserApi adminUserApi;

    @Override
    public BpmTaskCandidateStrategyEnum getStrategy() {
        return BpmTaskCandidateStrategyEnum.POST;
    }

    @Override
    public void validateParam(String param) {
        Set<Long> postIds = StrUtils.splitToLongSet(param);
        postApi.validPostList(postIds);
    }

    @Override
    public Set<Long> calculateUsers(String param) {
        Set<Long> postIds = StrUtils.splitToLongSet(param);
        List<AdminUserRespDTO> users = adminUserApi.getUserListByPostIds(postIds);
        return convertSet(users, AdminUserRespDTO::getId);
    }

}