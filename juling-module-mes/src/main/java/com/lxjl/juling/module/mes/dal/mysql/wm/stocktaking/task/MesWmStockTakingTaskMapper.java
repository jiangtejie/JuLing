package com.lxjl.juling.module.mes.dal.mysql.wm.stocktaking.task;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.mes.controller.admin.wm.stocktaking.task.vo.MesWmStockTakingTaskPageReqVO;
import com.lxjl.juling.module.mes.dal.dataobject.wm.stocktaking.task.MesWmStockTakingTaskDO;
import org.apache.ibatis.annotations.Mapper;

/**
 * MES 盘点任务 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface MesWmStockTakingTaskMapper extends BaseMapperX<MesWmStockTakingTaskDO> {

    default MesWmStockTakingTaskDO selectByCode(String code) {
        return selectOne(MesWmStockTakingTaskDO::getCode, code);
    }

    default PageResult<MesWmStockTakingTaskDO> selectPage(MesWmStockTakingTaskPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<MesWmStockTakingTaskDO>()
                .likeIfPresent(MesWmStockTakingTaskDO::getCode, reqVO.getCode())
                .likeIfPresent(MesWmStockTakingTaskDO::getName, reqVO.getName())
                .eqIfPresent(MesWmStockTakingTaskDO::getType, reqVO.getType())
                .eqIfPresent(MesWmStockTakingTaskDO::getStatus, reqVO.getStatus())
                .eqIfPresent(MesWmStockTakingTaskDO::getUserId, reqVO.getUserId())
                .eqIfPresent(MesWmStockTakingTaskDO::getPlanId, reqVO.getPlanId())
                .betweenIfPresent(MesWmStockTakingTaskDO::getTakingDate, reqVO.getTakingDate())
                .orderByDesc(MesWmStockTakingTaskDO::getId));
    }

}
