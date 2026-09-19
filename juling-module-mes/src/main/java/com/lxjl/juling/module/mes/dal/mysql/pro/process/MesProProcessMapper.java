package com.lxjl.juling.module.mes.dal.mysql.pro.process;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.mes.controller.admin.pro.process.vo.MesProProcessPageReqVO;
import com.lxjl.juling.module.mes.dal.dataobject.pro.process.MesProProcessDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * MES 生产工序 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface MesProProcessMapper extends BaseMapperX<MesProProcessDO> {

    default PageResult<MesProProcessDO> selectPage(MesProProcessPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<MesProProcessDO>()
                .likeIfPresent(MesProProcessDO::getCode, reqVO.getCode())
                .likeIfPresent(MesProProcessDO::getName, reqVO.getName())
                .eqIfPresent(MesProProcessDO::getStatus, reqVO.getStatus())
                .betweenIfPresent(MesProProcessDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(MesProProcessDO::getId));
    }

    default List<MesProProcessDO> selectList(MesProProcessPageReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<MesProProcessDO>()
                .likeIfPresent(MesProProcessDO::getCode, reqVO.getCode())
                .likeIfPresent(MesProProcessDO::getName, reqVO.getName())
                .eqIfPresent(MesProProcessDO::getStatus, reqVO.getStatus())
                .betweenIfPresent(MesProProcessDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(MesProProcessDO::getId));
    }

    default MesProProcessDO selectByCode(String code) {
        return selectOne(MesProProcessDO::getCode, code);
    }

    default MesProProcessDO selectByName(String name) {
        return selectOne(MesProProcessDO::getName, name);
    }

    default List<MesProProcessDO> selectListByStatus(Integer status) {
        return selectList(MesProProcessDO::getStatus, status);
    }

}
