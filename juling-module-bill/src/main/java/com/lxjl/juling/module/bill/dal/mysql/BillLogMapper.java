package com.lxjl.juling.module.bill.dal.mysql;

import com.lxjl.juling.module.bill.dal.dataobject.BillLogDO;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 单据操作日志 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface BillLogMapper extends BaseMapperX<BillLogDO> {

}
