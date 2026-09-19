package com.lxjl.juling.module.wms.dal.mysql.order.check;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.wms.controller.admin.order.check.vo.order.WmsCheckOrderPageReqVO;
import com.lxjl.juling.module.wms.dal.dataobject.order.check.WmsCheckOrderDO;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.apache.ibatis.annotations.Mapper;

/**
 * WMS 盘库单 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface WmsCheckOrderMapper extends BaseMapperX<WmsCheckOrderDO> {

    default PageResult<WmsCheckOrderDO> selectPage(WmsCheckOrderPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<WmsCheckOrderDO>()
                .likeIfPresent(WmsCheckOrderDO::getNo, reqVO.getNo())
                .eqIfPresent(WmsCheckOrderDO::getStatus, reqVO.getStatus())
                .eqIfPresent(WmsCheckOrderDO::getWarehouseId, reqVO.getWarehouseId())
                .betweenIfPresent(WmsCheckOrderDO::getOrderTime, reqVO.getOrderTime())
                .geIfPresent(WmsCheckOrderDO::getTotalQuantity, reqVO.getTotalQuantityMin())
                .leIfPresent(WmsCheckOrderDO::getTotalQuantity, reqVO.getTotalQuantityMax())
                .geIfPresent(WmsCheckOrderDO::getTotalPrice, reqVO.getTotalPriceMin())
                .leIfPresent(WmsCheckOrderDO::getTotalPrice, reqVO.getTotalPriceMax())
                .geIfPresent(WmsCheckOrderDO::getActualPrice, reqVO.getActualPriceMin())
                .leIfPresent(WmsCheckOrderDO::getActualPrice, reqVO.getActualPriceMax())
                .eqIfPresent(WmsCheckOrderDO::getCreator, reqVO.getCreator())
                .eqIfPresent(WmsCheckOrderDO::getUpdater, reqVO.getUpdater())
                .betweenIfPresent(WmsCheckOrderDO::getCreateTime, reqVO.getCreateTime())
                .betweenIfPresent(WmsCheckOrderDO::getUpdateTime, reqVO.getUpdateTime())
                .orderByDesc(WmsCheckOrderDO::getId));
    }

    default WmsCheckOrderDO selectByNo(String no) {
        return selectOne(WmsCheckOrderDO::getNo, no);
    }

    default Long selectCountByWarehouseId(Long warehouseId) {
        return selectCount(WmsCheckOrderDO::getWarehouseId, warehouseId);
    }

    default int updateByIdAndStatus(Long id, Integer status, WmsCheckOrderDO updateObj) {
        return update(updateObj, new LambdaQueryWrapper<WmsCheckOrderDO>()
                .eq(WmsCheckOrderDO::getId, id)
                .eq(WmsCheckOrderDO::getStatus, status));
    }

}
