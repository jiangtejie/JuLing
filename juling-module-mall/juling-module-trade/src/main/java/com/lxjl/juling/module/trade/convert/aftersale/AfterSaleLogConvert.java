package com.lxjl.juling.module.trade.convert.aftersale;

import com.lxjl.juling.module.trade.dal.dataobject.aftersale.AfterSaleLogDO;
import com.lxjl.juling.module.trade.service.aftersale.bo.AfterSaleLogCreateReqBO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

@Mapper
public interface AfterSaleLogConvert {

    AfterSaleLogConvert INSTANCE = Mappers.getMapper(AfterSaleLogConvert.class);

    AfterSaleLogDO convert(AfterSaleLogCreateReqBO bean);

}
