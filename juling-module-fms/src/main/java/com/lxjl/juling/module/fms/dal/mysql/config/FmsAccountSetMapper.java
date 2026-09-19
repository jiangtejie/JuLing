package com.lxjl.juling.module.fms.dal.mysql.config;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.module.fms.dal.dataobject.config.FmsAccountSetDO;
import org.apache.ibatis.annotations.Mapper;

/**
 * FMS 账套 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface FmsAccountSetMapper extends BaseMapperX<FmsAccountSetDO> {

    default FmsAccountSetDO selectByCompanyCode(String companyCode) {
        return selectOne(FmsAccountSetDO::getCompanyCode, companyCode);
    }

    default FmsAccountSetDO selectByIdForUpdate(Long id) {
        return selectOneForUpdate(FmsAccountSetDO::getId, id);
    }

}
