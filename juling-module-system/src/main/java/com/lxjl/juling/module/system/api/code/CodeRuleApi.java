package com.lxjl.juling.module.system.api.code;

/**
 * 编码规则 API 接口
 *
 * <p>供其它模块在**建档时**取业务编码。跨模块只经本接口，不直连 system_code_rule 表。
 *
 * @author 亚特
 */
public interface CodeRuleApi {

    /**
     * 按规则取下一个业务编码（并发安全）
     *
     * @param ruleKey 规则标识，如 erp_customer
     * @return 业务编码，如 KH000016
     */
    String generateCode(String ruleKey);

}