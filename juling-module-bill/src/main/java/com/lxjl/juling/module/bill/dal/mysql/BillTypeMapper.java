package com.lxjl.juling.module.bill.dal.mysql;

import com.lxjl.juling.module.bill.dal.dataobject.BillTypeDO;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 单据类型 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface BillTypeMapper extends BaseMapperX<BillTypeDO> {

    default BillTypeDO selectByCode(String code) {
        return selectOne(BillTypeDO::getCode, code);
    }

}
