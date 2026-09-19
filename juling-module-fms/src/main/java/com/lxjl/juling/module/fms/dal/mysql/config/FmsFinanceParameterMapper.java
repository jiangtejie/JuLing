package com.lxjl.juling.module.fms.dal.mysql.config;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.module.fms.dal.dataobject.config.FmsFinanceParameterDO;
import org.apache.ibatis.annotations.Mapper;

/**
 * FMS 财务参数 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface FmsFinanceParameterMapper extends BaseMapperX<FmsFinanceParameterDO> {

    default FmsFinanceParameterDO selectByAccountSetId(Long accountSetId) {
        return selectOne(FmsFinanceParameterDO::getAccountSetId, accountSetId);
    }

}
