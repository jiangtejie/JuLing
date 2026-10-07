package com.lxjl.juling.module.system.dal.dataobject.code;

import com.lxjl.juling.framework.tenant.core.db.TenantBaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 编码规则 DO
 *
 * <p>对齐金蝶的「编码规则」：每个主数据对象一套前缀 + 流水，业务编码由规则统一发号，
 * 而不是散在各个 service 里拼字符串。见 docs/master-data-unified-design.md §4.2。
 *
 * @author 亚特
 */
@TableName("system_code_rule")
@KeySequence("system_code_rule_seq")
@Data
@EqualsAndHashCode(callSuper = true)
public class SystemCodeRuleDO extends TenantBaseDO {

    /**
     * 编号
     */
    @TableId
    private Long id;
    /**
     * 规则标识，与主数据对象一一对应，如 erp_customer
     */
    private String ruleKey;
    /**
     * 规则名称，如「客户（门店）编码」
     */
    private String name;
    /**
     * 编码前缀，如 KH
     */
    private String prefix;
    /**
     * 流水号长度（左补零），如 6 → KH000001
     */
    private Integer seqLength;
    /**
     * 当前已分配到的流水值
     */
    private Long currentValue;
    /**
     * 备注
     */
    private String remark;

}