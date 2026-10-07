package com.lxjl.juling.module.member.api.user;

import com.lxjl.juling.module.member.service.user.MemberUserStoreService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import java.util.List;

/**
 * 订货账号「授权门店」API 实现类
 *
 * @author 亚特
 */
@Service
@Validated
public class MemberUserStoreApiImpl implements MemberUserStoreApi {

    @Resource
    private MemberUserStoreService memberUserStoreService;

    @Override
    public List<Long> getStoreIds(Long userId) {
        return memberUserStoreService.getStoreIds(userId);
    }

    @Override
    public Long getDefaultStoreId(Long userId) {
        return memberUserStoreService.getDefaultStoreId(userId);
    }

}