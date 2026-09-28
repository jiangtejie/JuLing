package com.lxjl.juling.module.erp.dal.mysql.stock;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.module.erp.controller.admin.stock.vo.warehouse.ErpWarehousePageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpWarehouseDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * ERP 仓库 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface ErpWarehouseMapper extends BaseMapperX<ErpWarehouseDO> {

    default PageResult<ErpWarehouseDO> selectPage(ErpWarehousePageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<ErpWarehouseDO>()
                .likeIfPresent(ErpWarehouseDO::getName, reqVO.getName())
                .eqIfPresent(ErpWarehouseDO::getStatus, reqVO.getStatus())
                .orderByDesc(ErpWarehouseDO::getId));
    }

    default ErpWarehouseDO selectByDefaultStatus() {
        return selectOne(ErpWarehouseDO::getDefaultStatus, true);
    }

    default List<ErpWarehouseDO> selectListByStatus(Integer status) {
        return selectList(ErpWarehouseDO::getStatus, status);
    }

    /**
     * 按仓库类型查询（CENTER 中心库 / STORE 门店仓）
     */
    default List<ErpWarehouseDO> selectListByType(String warehouseType) {
        return selectList(new LambdaQueryWrapperX<ErpWarehouseDO>()
                .eq(ErpWarehouseDO::getWarehouseType, warehouseType)
                .orderByAsc(ErpWarehouseDO::getId));
    }

    /**
     * 按门店客户查询门店仓（一店一仓，唯一）
     */
    default ErpWarehouseDO selectByStoreCustomerId(Long storeCustomerId) {
        if (storeCustomerId == null) {
            return null;
        }
        return selectOne(new LambdaQueryWrapperX<ErpWarehouseDO>()
                .eq(ErpWarehouseDO::getStoreCustomerId, storeCustomerId)
                .orderByAsc(ErpWarehouseDO::getId)
                .last("LIMIT 1"));
    }

}