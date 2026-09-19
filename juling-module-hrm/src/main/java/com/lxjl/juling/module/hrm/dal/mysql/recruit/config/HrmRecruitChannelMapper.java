package com.lxjl.juling.module.hrm.dal.mysql.recruit.config;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.hrm.controller.admin.recruit.vo.channel.HrmRecruitChannelPageReqVO;
import com.lxjl.juling.module.hrm.dal.dataobject.recruit.config.HrmRecruitChannelDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface HrmRecruitChannelMapper extends BaseMapperX<HrmRecruitChannelDO> {

    default PageResult<HrmRecruitChannelDO> selectPage(HrmRecruitChannelPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<HrmRecruitChannelDO>()
                .likeIfPresent(HrmRecruitChannelDO::getName, reqVO.getName())
                .eqIfPresent(HrmRecruitChannelDO::getStatus, reqVO.getStatus())
                .orderByAsc(HrmRecruitChannelDO::getSort)
                .orderByDesc(HrmRecruitChannelDO::getId));
    }

    default List<HrmRecruitChannelDO> selectListByStatus(Integer status) {
        return selectList(new LambdaQueryWrapperX<HrmRecruitChannelDO>()
                .eq(HrmRecruitChannelDO::getStatus, status)
                .orderByAsc(HrmRecruitChannelDO::getSort)
                .orderByDesc(HrmRecruitChannelDO::getId));
    }

}
