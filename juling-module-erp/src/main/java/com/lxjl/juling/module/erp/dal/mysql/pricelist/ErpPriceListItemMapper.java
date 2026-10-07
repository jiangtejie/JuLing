package com.lxjl.juling.module.erp.dal.mysql.pricelist;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.erp.dal.dataobject.pricelist.ErpPriceListItemDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

/**
 * ERP 价目表明细 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface ErpPriceListItemMapper extends BaseMapperX<ErpPriceListItemDO> {

    default List<ErpPriceListItemDO> selectListByPriceId(Long priceId) {
        return selectList(ErpPriceListItemDO::getPriceId, priceId);
    }

    default List<ErpPriceListItemDO> selectListByPriceIds(Collection<Long> priceIds) {
        if (priceIds == null || priceIds.isEmpty()) {
            return List.of();
        }
        return selectList(new LambdaQueryWrapperX<ErpPriceListItemDO>()
                .in(ErpPriceListItemDO::getPriceId, priceIds));
    }

    /** 取价用：这些价目表里该物料的行 */
    default List<ErpPriceListItemDO> selectListByPriceIdsAndProductId(Collection<Long> priceIds, Long productId) {
        if (priceIds == null || priceIds.isEmpty()) {
            return List.of();
        }
        return selectList(new LambdaQueryWrapperX<ErpPriceListItemDO>()
                .in(ErpPriceListItemDO::getPriceId, priceIds)
                .eq(ErpPriceListItemDO::getProductId, productId));
    }

    default void deleteByPriceId(Long priceId) {
        delete(ErpPriceListItemDO::getPriceId, priceId);
    }

    default void deleteByPriceIds(Collection<Long> priceIds) {
        if (priceIds == null || priceIds.isEmpty()) {
            return;
        }
        delete(new LambdaQueryWrapperX<ErpPriceListItemDO>()
                .in(ErpPriceListItemDO::getPriceId, priceIds));
    }

}
