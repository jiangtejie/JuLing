package com.lxjl.juling.module.mes.dal.mysql.wm.returnsales;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.mes.controller.admin.wm.returnsales.vo.line.MesWmReturnSalesLinePageReqVO;
import com.lxjl.juling.module.mes.dal.dataobject.wm.returnsales.MesWmReturnSalesLineDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * MES 销售退货单行 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface MesWmReturnSalesLineMapper extends BaseMapperX<MesWmReturnSalesLineDO> {

    default PageResult<MesWmReturnSalesLineDO> selectPage(MesWmReturnSalesLinePageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<MesWmReturnSalesLineDO>()
                .eqIfPresent(MesWmReturnSalesLineDO::getReturnId, reqVO.getReturnId())
                .eqIfPresent(MesWmReturnSalesLineDO::getItemId, reqVO.getItemId())
                .orderByDesc(MesWmReturnSalesLineDO::getId));
    }

    default List<MesWmReturnSalesLineDO> selectListByReturnId(Long returnId) {
        return selectList(new LambdaQueryWrapperX<MesWmReturnSalesLineDO>()
                .eq(MesWmReturnSalesLineDO::getReturnId, returnId));
    }

    default void deleteByReturnId(Long returnId) {
        delete(new LambdaQueryWrapperX<MesWmReturnSalesLineDO>()
                .eq(MesWmReturnSalesLineDO::getReturnId, returnId));
    }

}
