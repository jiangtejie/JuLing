package com.lxjl.juling.module.member.dal.mysql.user;

import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.member.dal.dataobject.user.MemberUserStoreDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

/**
 * 订货账号授权门店 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface MemberUserStoreMapper extends BaseMapperX<MemberUserStoreDO> {

    /**
     * 账号的全部**启用**授权门店（按 sort、id 排序）
     */
    default List<MemberUserStoreDO> selectListByUserId(Long userId) {
        return selectList(new LambdaQueryWrapperX<MemberUserStoreDO>()
                .eq(MemberUserStoreDO::getUserId, userId)
                .eq(MemberUserStoreDO::getStatus, CommonStatusEnum.ENABLE.getStatus())
                .orderByAsc(MemberUserStoreDO::getSort)
                .orderByAsc(MemberUserStoreDO::getId));
    }

    /**
     * 多个账号的启用授权门店（批量，供后台列表拼装门店名）
     */
    default List<MemberUserStoreDO> selectListByUserIds(Collection<Long> userIds) {
        return selectList(new LambdaQueryWrapperX<MemberUserStoreDO>()
                .in(MemberUserStoreDO::getUserId, userIds)
                .eq(MemberUserStoreDO::getStatus, CommonStatusEnum.ENABLE.getStatus())
                .orderByAsc(MemberUserStoreDO::getSort)
                .orderByAsc(MemberUserStoreDO::getId));
    }

    /**
     * 某门店被哪些账号授权（门店闭店/停用时提示影响面）
     */
    default List<MemberUserStoreDO> selectListByCustomerId(Long customerId) {
        return selectList(new LambdaQueryWrapperX<MemberUserStoreDO>()
                .eq(MemberUserStoreDO::getCustomerId, customerId));
    }

}