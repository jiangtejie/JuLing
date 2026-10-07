package com.lxjl.juling.module.system.dal.mysql.code;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.module.system.dal.dataobject.code.SystemCodeRuleDO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 编码规则 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface SystemCodeRuleMapper extends BaseMapperX<SystemCodeRuleDO> {

    default SystemCodeRuleDO selectByRuleKey(String ruleKey) {
        return selectOne(SystemCodeRuleDO::getRuleKey, ruleKey);
    }

    /**
     * 按规则标识取规则行并**加行级锁**
     *
     * <p>取号必须串行：两个并发建档若同时读到同一个 current_value，就会发出同一个编码
     * （唯一索引会拦下其中一个，但那是「建档失败」而不是「取到不同号」）。
     * 调用方必须在事务内使用。
     */
    @Select("SELECT * FROM system_code_rule WHERE rule_key = #{ruleKey} AND deleted = 0 FOR UPDATE")
    SystemCodeRuleDO selectByRuleKeyForUpdate(@Param("ruleKey") String ruleKey);

}