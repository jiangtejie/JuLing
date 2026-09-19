package com.lxjl.juling.module.mes.dal.mysql.wm.productsales;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.module.mes.dal.dataobject.wm.productsales.MesWmProductSalesDetailDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * MES 销售出库明细 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface MesWmProductSalesDetailMapper extends BaseMapperX<MesWmProductSalesDetailDO> {

    default List<MesWmProductSalesDetailDO> selectListByLineId(Long lineId) {
        return selectList(MesWmProductSalesDetailDO::getLineId, lineId);
    }

    default List<MesWmProductSalesDetailDO> selectListBySalesId(Long salesId) {
        return selectList(MesWmProductSalesDetailDO::getSalesId, salesId);
    }

    default void deleteByLineId(Long lineId) {
        delete(MesWmProductSalesDetailDO::getLineId, lineId);
    }

    default void deleteBySalesId(Long salesId) {
        delete(MesWmProductSalesDetailDO::getSalesId, salesId);
    }

}
