package com.lxjl.juling.module.hrm.dal.mysql.recruit.post;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.hrm.dal.dataobject.recruit.post.HrmRecruitPostTypeDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface HrmRecruitPostTypeMapper extends BaseMapperX<HrmRecruitPostTypeDO> {

    default List<HrmRecruitPostTypeDO> selectListByStatus(Integer status) {
        return selectList(new LambdaQueryWrapperX<HrmRecruitPostTypeDO>()
                .eqIfPresent(HrmRecruitPostTypeDO::getStatus, status)
                .orderByAsc(HrmRecruitPostTypeDO::getSort)
                .orderByAsc(HrmRecruitPostTypeDO::getId));
    }

}
