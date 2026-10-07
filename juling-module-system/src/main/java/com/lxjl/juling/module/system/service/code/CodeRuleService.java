package com.lxjl.juling.module.system.service.code;

/**
 * 编码规则 Service 接口
 *
 * @author 亚特
 */
public interface CodeRuleService {

    /**
     * 按规则取下一个业务编码（并发安全）
     *
     * <p>必须在事务内调用 —— 内部对规则行加 {@code SELECT … FOR UPDATE} 行级锁，
     * 保证同一规则下的取号串行，不会发出重复编码。
     *
     * @param ruleKey 规则标识，如 erp_customer
     * @return 业务编码，如 KH000016
     */
    String generateCode(String ruleKey);

}