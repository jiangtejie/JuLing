package com.lxjl.juling.module.erp.dal.mysql.pricelist;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.erp.dal.dataobject.pricelist.ErpPriceListScopeDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

/**
 * ERP 价目表适用范围 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface ErpPriceListScopeMapper extends BaseMapperX<ErpPriceListScopeDO> {

    default List<ErpPriceListScopeDO> selectListByPriceId(Long priceId) {
        return selectList(ErpPriceListScopeDO::getPriceId, priceId);
    }

    default List<ErpPriceListScopeDO> selectListByPriceIds(Collection<Long> priceIds) {
        if (priceIds == null || priceIds.isEmpty()) {
            return List.of();
        }
        return selectList(new LambdaQueryWrapperX<ErpPriceListScopeDO>()
                .in(ErpPriceListScopeDO::getPriceId, priceIds));
    }

    /** 取价用：适用于该对象的范围行（含通用范围 partner_id IS NULL） */
    default List<ErpPriceListScopeDO> selectListByPartnerIdOrCommon(Long partnerId) {
        return selectList(new LambdaQueryWrapperX<ErpPriceListScopeDO>()
                .and(w -> w.eq(ErpPriceListScopeDO::getPartnerId, partnerId)
                        .or().isNull(ErpPriceListScopeDO::getPartnerId)));
    }

    default void deleteByPriceId(Long priceId) {
        delete(ErpPriceListScopeDO::getPriceId, priceId);
    }

    default void deleteByPriceIds(Collection<Long> priceIds) {
        if (priceIds == null || priceIds.isEmpty()) {
            return;
        }
        delete(new LambdaQueryWrapperX<ErpPriceListScopeDO>()
                .in(ErpPriceListScopeDO::getPriceId, priceIds));
    }

}
