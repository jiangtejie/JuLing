package com.lxjl.juling.module.bill.dal.mysql;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.module.bill.dal.dataobject.BillNoSeqDO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 单号流水 Mapper
 *
 * 并发方案：**事务级咨询锁（pg_advisory_xact_lock）+ 查询 + 插入/更新**。
 *
 * 为什么不用「先 SELECT FOR UPDATE，无行则 INSERT，撞唯一索引再重试」：
 * PostgreSQL 在一条语句失败后会把整个事务置为 aborted（current transaction is aborted），
 * 同一事务里继续发 SQL 一律被拒——"catch 后重试"在 PG 下根本走不通（已实测：10 并发生成
 * 只有 1 个成功）。咨询锁让同一「类型+组织+期间」的取号严格串行，从根上没有冲突路径。
 *
 * @author 亚特
 */
@Mapper
public interface BillNoSeqMapper extends BaseMapperX<BillNoSeqDO> {

    /**
     * 事务级咨询锁：同一 key 串行；事务结束（提交/回滚）自动释放。
     *
     * 写法说明：pg_advisory_xact_lock 返回 void，MyBatis 无法把 void 映射成返回值
     * （会报 "No constructor found in void"），故包一层 SELECT 1 FROM (...) 拿到可映射的整型。
     */
    @Select("SELECT 1 FROM (SELECT pg_advisory_xact_lock(hashtext(#{key}))) t")
    Integer lockByKey(@Param("key") String key);

    @Select("SELECT * FROM bill_no_seq WHERE bill_type = #{billType} AND org_id = #{orgId} AND period = #{period} AND deleted = 0")
    BillNoSeqDO selectByKey(@Param("billType") String billType, @Param("orgId") Long orgId,
                            @Param("period") String period);

}
