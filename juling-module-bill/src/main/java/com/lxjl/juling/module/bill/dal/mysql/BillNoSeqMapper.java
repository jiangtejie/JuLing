package com.lxjl.juling.module.bill.dal.mysql;

import com.lxjl.juling.module.bill.dal.dataobject.BillNoSeqDO;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 单号流水 Mapper
 *
 * 并发安全：先 {@link #selectForUpdate} 行锁，再更新；无行时插入（唯一索引兜底，冲突则重试）。
 *
 * @author 亚特
 */
@Mapper
public interface BillNoSeqMapper extends BaseMapperX<BillNoSeqDO> {

    @Select("SELECT * FROM bill_no_seq WHERE bill_type = #{billType} AND org_id = #{orgId} AND period = #{period} AND deleted = 0 FOR UPDATE")
    BillNoSeqDO selectForUpdate(@Param("billType") String billType, @Param("orgId") Long orgId,
                               @Param("period") String period);

}
