package com.lxjl.juling.module.mes.dal.mysql.wm.productproduce;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.module.mes.dal.dataobject.wm.productproduce.MesWmProductProduceDO;
import org.apache.ibatis.annotations.Mapper;

/**
 * MES 生产入库单 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface MesWmProductProduceMapper extends BaseMapperX<MesWmProductProduceDO> {

    default MesWmProductProduceDO selectByFeedbackId(Long feedbackId) {
        return selectOne(MesWmProductProduceDO::getFeedbackId, feedbackId);
    }

}
