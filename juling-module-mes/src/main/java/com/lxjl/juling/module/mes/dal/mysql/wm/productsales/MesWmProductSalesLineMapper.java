package com.lxjl.juling.module.mes.dal.mysql.wm.productsales;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.module.mes.dal.dataobject.wm.productsales.MesWmProductSalesLineDO;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * MES 销售出库单行 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface MesWmProductSalesLineMapper extends BaseMapperX<MesWmProductSalesLineDO> {

    default List<MesWmProductSalesLineDO> selectListBySalesId(Long salesId) {
        return selectList(MesWmProductSalesLineDO::getSalesId, salesId);
    }

    default void deleteBySalesId(Long salesId) {
        delete(MesWmProductSalesLineDO::getSalesId, salesId);
    }

    default com.lxjl.juling.framework.common.pojo.PageResult<MesWmProductSalesLineDO> selectPage(
            com.lxjl.juling.module.mes.controller.admin.wm.productsales.vo.line.MesWmProductSalesLinePageReqVO reqVO) {
        return selectPage(reqVO, new com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX<MesWmProductSalesLineDO>()
                .eqIfPresent(MesWmProductSalesLineDO::getSalesId, reqVO.getSalesId())
                .inIfPresent(MesWmProductSalesLineDO::getSalesId, reqVO.getSalesIds())
                .orderByDesc(MesWmProductSalesLineDO::getId));
    }

    default void updateQualityStatusByIds(List<Long> ids, Integer qualityStatus) {
        update(new MesWmProductSalesLineDO().setQualityStatus(qualityStatus),
                new LambdaUpdateWrapper<MesWmProductSalesLineDO>().in(MesWmProductSalesLineDO::getId, ids));
    }

}
