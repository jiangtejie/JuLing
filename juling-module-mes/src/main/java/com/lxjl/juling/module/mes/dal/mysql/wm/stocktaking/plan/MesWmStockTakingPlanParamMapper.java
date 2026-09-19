package com.lxjl.juling.module.mes.dal.mysql.wm.stocktaking.plan;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.mes.controller.admin.wm.stocktaking.plan.vo.param.MesWmStockTakingPlanParamPageReqVO;
import com.lxjl.juling.module.mes.dal.dataobject.wm.stocktaking.plan.MesWmStockTakingPlanParamDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * MES 盘点方案参数 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface MesWmStockTakingPlanParamMapper extends BaseMapperX<MesWmStockTakingPlanParamDO> {

    default PageResult<MesWmStockTakingPlanParamDO> selectPage(MesWmStockTakingPlanParamPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<MesWmStockTakingPlanParamDO>()
                .eqIfPresent(MesWmStockTakingPlanParamDO::getPlanId, reqVO.getPlanId())
                .orderByAsc(MesWmStockTakingPlanParamDO::getId));
    }

    default List<MesWmStockTakingPlanParamDO> selectListByPlanId(Long planId) {
        return selectList(MesWmStockTakingPlanParamDO::getPlanId, planId);
    }

    default void deleteByPlanId(Long planId) {
        delete(MesWmStockTakingPlanParamDO::getPlanId, planId);
    }

}
