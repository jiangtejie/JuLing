package com.lxjl.juling.module.mes.dal.mysql.pro.workrecord;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.mes.dal.dataobject.pro.workrecord.MesProWorkRecordDO;
import org.apache.ibatis.annotations.Mapper;

/**
 * MES 当前绑定状态（快照） Mapper
 *
 * @author 亚特
 */
@Mapper
public interface MesProWorkRecordMapper extends BaseMapperX<MesProWorkRecordDO> {

    default MesProWorkRecordDO selectByUserId(Long userId) {
        return selectOne(new LambdaQueryWrapperX<MesProWorkRecordDO>()
                .eq(MesProWorkRecordDO::getUserId, userId));
    }

}
