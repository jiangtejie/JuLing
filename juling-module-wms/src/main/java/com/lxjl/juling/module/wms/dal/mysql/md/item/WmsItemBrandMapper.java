package com.lxjl.juling.module.wms.dal.mysql.md.item;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.wms.controller.admin.md.item.vo.brand.WmsItemBrandPageReqVO;
import com.lxjl.juling.module.wms.dal.dataobject.md.item.WmsItemBrandDO;
import org.apache.ibatis.annotations.Mapper;

/**
 * WMS 商品品牌 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface WmsItemBrandMapper extends BaseMapperX<WmsItemBrandDO> {

    default PageResult<WmsItemBrandDO> selectPage(WmsItemBrandPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<WmsItemBrandDO>()
                .likeIfPresent(WmsItemBrandDO::getCode, reqVO.getCode())
                .likeIfPresent(WmsItemBrandDO::getName, reqVO.getName())
                .orderByDesc(WmsItemBrandDO::getId));
    }

    default WmsItemBrandDO selectByCode(String code) {
        return selectOne(WmsItemBrandDO::getCode, code);
    }

    default WmsItemBrandDO selectByName(String name) {
        return selectOne(WmsItemBrandDO::getName, name);
    }

}
