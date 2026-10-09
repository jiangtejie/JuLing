package com.lxjl.juling.module.erp.dal.mysql.pricelist;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.erp.dal.dataobject.pricelist.ErpPriceListItemLogDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 价目表价格变更留痕 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface ErpPriceListItemLogMapper extends BaseMapperX<ErpPriceListItemLogDO> {

    /** 按价目表查变更历史（新的在前） */
    default List<ErpPriceListItemLogDO> selectListByPriceId(Long priceId) {
        return selectList(new LambdaQueryWrapperX<ErpPriceListItemLogDO>()
                .eq(ErpPriceListItemLogDO::getPriceId, priceId)
                .orderByDesc(ErpPriceListItemLogDO::getId));
    }

    /** 按物料查变更历史 —— **核算主要用这个**：某物料历次改价 */
    default List<ErpPriceListItemLogDO> selectListByProductId(Long productId) {
        return selectList(new LambdaQueryWrapperX<ErpPriceListItemLogDO>()
                .eq(ErpPriceListItemLogDO::getProductId, productId)
                .orderByDesc(ErpPriceListItemLogDO::getId));
    }

}
