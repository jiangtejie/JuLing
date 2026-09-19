package com.lxjl.juling.module.fms.dal.mysql.closing;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.fms.dal.dataobject.closing.FmsClosingPeriodDO;
import org.apache.ibatis.annotations.Mapper;

import java.time.LocalDateTime;

/**
 * FMS 结账期间 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface FmsClosingPeriodMapper extends BaseMapperX<FmsClosingPeriodDO> {

    default FmsClosingPeriodDO selectByPeriod(Long accountSetId,
            LocalDateTime beginTime, LocalDateTime endTime) {
        return selectOne(new LambdaQueryWrapperX<FmsClosingPeriodDO>()
                .eq(FmsClosingPeriodDO::getAccountSetId, accountSetId)
                .between(FmsClosingPeriodDO::getClosingTime, beginTime, endTime));
    }

    default FmsClosingPeriodDO selectLatestByAccountSetId(Long accountSetId) {
        return selectLastOne(new LambdaQueryWrapperX<FmsClosingPeriodDO>()
                .eq(FmsClosingPeriodDO::getAccountSetId, accountSetId)
                .orderByAsc(FmsClosingPeriodDO::getClosingTime)
                .orderByAsc(FmsClosingPeriodDO::getId));
    }

}
