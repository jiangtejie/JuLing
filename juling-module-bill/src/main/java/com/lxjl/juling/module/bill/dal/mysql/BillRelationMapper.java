package com.lxjl.juling.module.bill.dal.mysql;

import com.lxjl.juling.module.bill.dal.dataobject.BillRelationDO;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 单据关联 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface BillRelationMapper extends BaseMapperX<BillRelationDO> {

}
