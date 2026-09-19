package com.lxjl.juling.module.fms.dal.mysql.config;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.fms.dal.dataobject.config.FmsAuxiliaryTypeDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

/**
 * FMS 辅助核算类别 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface FmsAuxiliaryTypeMapper extends BaseMapperX<FmsAuxiliaryTypeDO> {

    default List<FmsAuxiliaryTypeDO> selectListByAccountSetId(Long accountSetId) {
        return selectList(new LambdaQueryWrapperX<FmsAuxiliaryTypeDO>()
                .eq(FmsAuxiliaryTypeDO::getAccountSetId, accountSetId)
                .orderByAsc(FmsAuxiliaryTypeDO::getType)
                .orderByAsc(FmsAuxiliaryTypeDO::getId));
    }

    default List<FmsAuxiliaryTypeDO> selectListByIdsAndAccountSetId(
            Collection<Long> ids, Long accountSetId) {
        return selectList(new LambdaQueryWrapperX<FmsAuxiliaryTypeDO>()
                .in(FmsAuxiliaryTypeDO::getId, ids)
                .eq(FmsAuxiliaryTypeDO::getAccountSetId, accountSetId));
    }

    default FmsAuxiliaryTypeDO selectByAccountSetIdAndName(Long accountSetId, String name) {
        return selectOne(new LambdaQueryWrapperX<FmsAuxiliaryTypeDO>()
                .eq(FmsAuxiliaryTypeDO::getAccountSetId, accountSetId)
                .eq(FmsAuxiliaryTypeDO::getName, name));
    }

}
