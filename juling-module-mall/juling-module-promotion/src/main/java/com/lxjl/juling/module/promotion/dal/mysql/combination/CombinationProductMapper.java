package com.lxjl.juling.module.promotion.dal.mysql.combination;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.promotion.controller.admin.combination.vo.product.CombinationProductPageReqVO;
import com.lxjl.juling.module.promotion.dal.dataobject.combination.CombinationProductDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

/**
 * 拼团商品 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface CombinationProductMapper extends BaseMapperX<CombinationProductDO> {

    default PageResult<CombinationProductDO> selectPage(CombinationProductPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<CombinationProductDO>()
                .eqIfPresent(CombinationProductDO::getActivityId, reqVO.getActivityId())
                .eqIfPresent(CombinationProductDO::getSpuId, reqVO.getSpuId())
                .eqIfPresent(CombinationProductDO::getSkuId, reqVO.getSkuId())
                .eqIfPresent(CombinationProductDO::getActivityStatus, reqVO.getActivityStatus())
                .betweenIfPresent(CombinationProductDO::getActivityStartTime, reqVO.getActivityStartTime())
                .betweenIfPresent(CombinationProductDO::getActivityEndTime, reqVO.getActivityEndTime())
                .eqIfPresent(CombinationProductDO::getCombinationPrice, reqVO.getActivePrice())
                .betweenIfPresent(CombinationProductDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(CombinationProductDO::getId));
    }

    default List<CombinationProductDO> selectListByActivityIds(Collection<Long> ids) {
        return selectList(CombinationProductDO::getActivityId, ids);
    }

}
