package com.lxjl.juling.module.erp.dal.mysql.purchase;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchasePriceItemDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

/**
 * ERP 采购价目表明细 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface ErpPurchasePriceItemMapper extends BaseMapperX<ErpPurchasePriceItemDO> {

    default List<ErpPurchasePriceItemDO> selectListByPriceId(Long priceId) {
        return selectList(ErpPurchasePriceItemDO::getPriceId, priceId);
    }

    default List<ErpPurchasePriceItemDO> selectListByPriceIds(Collection<Long> priceIds) {
        return selectList(new LambdaQueryWrapperX<ErpPurchasePriceItemDO>()
                .in(ErpPurchasePriceItemDO::getPriceId, priceIds));
    }

    default List<ErpPurchasePriceItemDO> selectListByProductId(Long productId) {
        return selectList(ErpPurchasePriceItemDO::getProductId, productId);
    }

    default void deleteByPriceId(Long priceId) {
        delete(ErpPurchasePriceItemDO::getPriceId, priceId);
    }

    default void deleteByPriceIds(Collection<Long> priceIds) {
        delete(new LambdaQueryWrapperX<ErpPurchasePriceItemDO>()
                .in(ErpPurchasePriceItemDO::getPriceId, priceIds));
    }

}
