package com.lxjl.juling.module.erp.dal.mysql.purchase;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.erp.controller.admin.purchase.vo.price.ErpPurchasePricePageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchasePriceDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * ERP 采购价目表 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface ErpPurchasePriceMapper extends BaseMapperX<ErpPurchasePriceDO> {

    default PageResult<ErpPurchasePriceDO> selectPage(ErpPurchasePricePageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<ErpPurchasePriceDO>()
                .likeIfPresent(ErpPurchasePriceDO::getCode, reqVO.getCode())
                .likeIfPresent(ErpPurchasePriceDO::getName, reqVO.getName())
                .eqIfPresent(ErpPurchasePriceDO::getSupplierId, reqVO.getSupplierId())
                .eqIfPresent(ErpPurchasePriceDO::getStatus, reqVO.getStatus())
                .orderByDesc(ErpPurchasePriceDO::getId));
    }

    /** 取价用：一次把所有启用中的价目表捞出来，在内存里按优先级挑（数据量小，避免拼复杂 SQL） */
    default List<ErpPurchasePriceDO> selectListByStatus(Integer status) {
        return selectList(ErpPurchasePriceDO::getStatus, status);
    }

}
