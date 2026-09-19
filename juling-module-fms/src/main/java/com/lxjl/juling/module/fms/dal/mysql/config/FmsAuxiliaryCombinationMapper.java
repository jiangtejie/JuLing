package com.lxjl.juling.module.fms.dal.mysql.config;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.fms.dal.dataobject.config.FmsAuxiliaryCombinationDO;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

/**
 * FMS 辅助核算组合 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface FmsAuxiliaryCombinationMapper extends BaseMapperX<FmsAuxiliaryCombinationDO> {

    default List<FmsAuxiliaryCombinationDO> selectListByAccountSetId(Long accountSetId) {
        return selectList(new LambdaQueryWrapperX<FmsAuxiliaryCombinationDO>()
                .eq(FmsAuxiliaryCombinationDO::getAccountSetId, accountSetId));
    }

    default Long selectCountByAccountSetIdAndSubjectIds(
            Long accountSetId, Collection<Long> subjectIds) {
        return selectCount(new LambdaQueryWrapperX<FmsAuxiliaryCombinationDO>()
                .eq(FmsAuxiliaryCombinationDO::getAccountSetId, accountSetId)
                .in(FmsAuxiliaryCombinationDO::getSubjectId, subjectIds));
    }

    default void updateSubject(Long accountSetId, Long subjectId, FmsAuxiliaryCombinationDO updateObj) {
        update(updateObj, new LambdaUpdateWrapper<FmsAuxiliaryCombinationDO>()
                .eq(FmsAuxiliaryCombinationDO::getAccountSetId, accountSetId)
                .eq(FmsAuxiliaryCombinationDO::getSubjectId, subjectId));
    }

}
