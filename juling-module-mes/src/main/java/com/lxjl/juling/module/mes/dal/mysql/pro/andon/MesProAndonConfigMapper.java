package com.lxjl.juling.module.mes.dal.mysql.pro.andon;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.mes.controller.admin.pro.andon.vo.config.MesProAndonConfigPageReqVO;
import com.lxjl.juling.module.mes.dal.dataobject.pro.andon.MesProAndonConfigDO;
import org.apache.ibatis.annotations.Mapper;

/**
 * MES 安灯呼叫配置 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface MesProAndonConfigMapper extends BaseMapperX<MesProAndonConfigDO> {

    default PageResult<MesProAndonConfigDO> selectPage(MesProAndonConfigPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<MesProAndonConfigDO>()
                .likeIfPresent(MesProAndonConfigDO::getReason, reqVO.getReason())
                .eqIfPresent(MesProAndonConfigDO::getLevel, reqVO.getLevel())
                .orderByDesc(MesProAndonConfigDO::getId));
    }

}
