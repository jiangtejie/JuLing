package com.lxjl.juling.module.wms.dal.mysql.md.item;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.wms.controller.admin.md.item.vo.item.WmsItemListReqVO;
import com.lxjl.juling.module.wms.controller.admin.md.item.vo.item.WmsItemPageReqVO;
import com.lxjl.juling.module.wms.dal.dataobject.md.item.WmsItemDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

/**
 * WMS 商品 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface WmsItemMapper extends BaseMapperX<WmsItemDO> {

    default PageResult<WmsItemDO> selectPage(WmsItemPageReqVO reqVO, Collection<Long> categoryIds) {
        return selectPage(reqVO, new LambdaQueryWrapperX<WmsItemDO>()
                .likeIfPresent(WmsItemDO::getCode, reqVO.getCode())
                .likeIfPresent(WmsItemDO::getName, reqVO.getName())
                .inIfPresent(WmsItemDO::getCategoryId, categoryIds)
                .eqIfPresent(WmsItemDO::getBrandId, reqVO.getBrandId())
                .betweenIfPresent(WmsItemDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(WmsItemDO::getId));
    }

    default List<WmsItemDO> selectList(WmsItemListReqVO reqVO, Collection<Long> categoryIds) {
        return selectList(new LambdaQueryWrapperX<WmsItemDO>()
                .likeIfPresent(WmsItemDO::getCode, reqVO.getCode())
                .likeIfPresent(WmsItemDO::getName, reqVO.getName())
                .inIfPresent(WmsItemDO::getCategoryId, categoryIds)
                .eqIfPresent(WmsItemDO::getBrandId, reqVO.getBrandId())
                .betweenIfPresent(WmsItemDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(WmsItemDO::getId));
    }

    default WmsItemDO selectByName(String name) {
        return selectOne(WmsItemDO::getName, name);
    }

    default WmsItemDO selectByCode(String code) {
        return selectOne(WmsItemDO::getCode, code);
    }

    default Long selectCountByCategoryId(Long categoryId) {
        return selectCount(WmsItemDO::getCategoryId, categoryId);
    }

    default Long selectCountByBrandId(Long brandId) {
        return selectCount(WmsItemDO::getBrandId, brandId);
    }

}
