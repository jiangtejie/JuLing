package com.lxjl.juling.module.member.service.user;

import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.module.member.dal.dataobject.user.MemberUserStoreDO;
import com.lxjl.juling.module.member.dal.mysql.user.MemberUserStoreMapper;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertList;
import static com.lxjl.juling.module.member.enums.ErrorCodeConstants.USER_STORE_NOT_GRANTED;

/**
 * 订货账号「授权门店」Service 实现类
 *
 * @author 亚特
 */
@Service
@Validated
@Slf4j
public class MemberUserStoreServiceImpl implements MemberUserStoreService {

    @Resource
    private MemberUserStoreMapper memberUserStoreMapper;

    @Override
    public List<Long> getStoreIds(Long userId) {
        return convertList(memberUserStoreMapper.selectListByUserId(userId), MemberUserStoreDO::getCustomerId);
    }

    @Override
    public Long getDefaultStoreId(Long userId) {
        List<MemberUserStoreDO> list = memberUserStoreMapper.selectListByUserId(userId);
        if (list.isEmpty()) {
            return null;
        }
        // 唯一索引保证最多一条 is_default；查不到时取第一条，避免 H5 首屏无门店可选
        return list.stream().filter(item -> Boolean.TRUE.equals(item.getIsDefault()))
                .findFirst().orElse(list.get(0)).getCustomerId();
    }

    @Override
    public List<MemberUserStoreDO> getStoreListByUserId(Long userId) {
        return memberUserStoreMapper.selectListByUserId(userId);
    }

    @Override
    public List<MemberUserStoreDO> getStoreListByUserIds(Collection<Long> userIds) {
        return memberUserStoreMapper.selectListByUserIds(userIds);
    }

    @Override
    public List<MemberUserStoreDO> getStoreListByCustomerId(Long customerId) {
        return memberUserStoreMapper.selectListByCustomerId(customerId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void replaceGrants(Long userId, Collection<Long> storeCustomerIds, Long defaultStoreCustomerId) {
        // 1. 去重并保序（授权顺序就是 H5 门店切换器的展示顺序）
        Set<Long> storeIds = new LinkedHashSet<>();
        if (storeCustomerIds != null) {
            storeCustomerIds.stream().filter(Objects::nonNull).forEach(storeIds::add);
        }
        if (storeIds.isEmpty()) {
            throw exception(USER_STORE_NOT_GRANTED);
        }
        // 2. 默认门店必须在授权范围内；未指定或越界时回退为第一家
        Long defaultStoreId = storeIds.contains(defaultStoreCustomerId)
                ? defaultStoreCustomerId : storeIds.iterator().next();
        if (defaultStoreCustomerId != null && !storeIds.contains(defaultStoreCustomerId)) {
            log.warn("[replaceGrants][账号({}) 指定的默认门店({}) 不在授权范围内，已回退为({})]",
                    userId, defaultStoreCustomerId, defaultStoreId);
        }
        // 3. 全量替换：先软删旧授权（唯一索引按 deleted = 0 判定，软删后不冲突），再插入新授权
        memberUserStoreMapper.delete(new LambdaQueryWrapper<MemberUserStoreDO>()
                .eq(MemberUserStoreDO::getUserId, userId));
        int sort = 0;
        for (Long customerId : storeIds) {
            memberUserStoreMapper.insert(MemberUserStoreDO.builder()
                    .userId(userId)
                    .customerId(customerId)
                    .isDefault(customerId.equals(defaultStoreId))
                    .sort(sort++)
                    .status(CommonStatusEnum.ENABLE.getStatus())
                    .build());
        }
    }

}