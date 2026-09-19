package com.lxjl.juling.module.promotion.job.combination;

import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.framework.common.core.KeyValue;
import com.lxjl.juling.framework.quartz.core.handler.JobHandler;
import com.lxjl.juling.framework.tenant.core.job.TenantJob;
import com.lxjl.juling.module.promotion.service.combination.CombinationRecordService;
import org.springframework.stereotype.Component;

import jakarta.annotation.Resource;

/**
 * 拼团过期 Job
 *
 * @author 棱信矩灵
 */
@Component
public class CombinationRecordExpireJob implements JobHandler {

    @Resource
    private CombinationRecordService combinationRecordService;

    @Override
    @TenantJob
    public String execute(String param) {
        KeyValue<Integer, Integer> keyValue = combinationRecordService.expireCombinationRecord();
        return StrUtil.format("过期拼团 {} 个, 虚拟成团 {} 个", keyValue.getKey(), keyValue.getValue());
    }

}
