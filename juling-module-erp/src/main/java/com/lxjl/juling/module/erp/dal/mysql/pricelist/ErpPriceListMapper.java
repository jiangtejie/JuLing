package com.lxjl.juling.module.erp.dal.mysql.pricelist;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.erp.controller.admin.pricelist.vo.ErpPriceListPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.pricelist.ErpPriceListDO;
import org.apache.ibatis.annotations.Mapper;

/**
 * ERP 价目表 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface ErpPriceListMapper extends BaseMapperX<ErpPriceListDO> {

    default PageResult<ErpPriceListDO> selectPage(ErpPriceListPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<ErpPriceListDO>()
                .eq(ErpPriceListDO::getPriceType, reqVO.getPriceType())
                .likeIfPresent(ErpPriceListDO::getCode, reqVO.getCode())
                .likeIfPresent(ErpPriceListDO::getName, reqVO.getName())
                .eqIfPresent(ErpPriceListDO::getStatus, reqVO.getStatus())
                .orderByDesc(ErpPriceListDO::getId));
    }

}
