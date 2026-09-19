package com.lxjl.juling.module.fms.dal.mysql.config;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.fms.dal.dataobject.config.FmsVoucherTemplateCategoryDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * FMS 凭证模板分类 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface FmsVoucherTemplateCategoryMapper extends BaseMapperX<FmsVoucherTemplateCategoryDO> {

    default List<FmsVoucherTemplateCategoryDO> selectListByAccountSetId(Long accountSetId) {
        return selectList(new LambdaQueryWrapperX<FmsVoucherTemplateCategoryDO>()
                .eq(FmsVoucherTemplateCategoryDO::getAccountSetId, accountSetId)
                .orderByAsc(FmsVoucherTemplateCategoryDO::getId));
    }

    default FmsVoucherTemplateCategoryDO selectByAccountSetIdAndName(Long accountSetId, String name) {
        return selectOne(FmsVoucherTemplateCategoryDO::getAccountSetId, accountSetId,
                FmsVoucherTemplateCategoryDO::getName, name);
    }

}
