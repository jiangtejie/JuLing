package com.lxjl.juling.module.system.service.code;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.system.controller.admin.code.vo.SystemCodeRulePageReqVO;
import com.lxjl.juling.module.system.controller.admin.code.vo.SystemCodeRuleSaveReqVO;
import com.lxjl.juling.module.system.dal.dataobject.code.SystemCodeRuleDO;

import java.util.List;

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

    /**
     * 创建编码规则
     */
    Long createCodeRule(SystemCodeRuleSaveReqVO createReqVO);

    /**
     * 更新编码规则（规则标识不可改）
     */
    void updateCodeRule(SystemCodeRuleSaveReqVO updateReqVO);

    /**
     * 删除编码规则
     */
    void deleteCodeRule(Long id);

    /**
     * 获得编码规则
     */
    SystemCodeRuleDO getCodeRule(Long id);

    /**
     * 获得全部编码规则
     */
    List<SystemCodeRuleDO> getCodeRuleList();

    /**
     * 获得编码规则分页
     */
    PageResult<SystemCodeRuleDO> getCodeRulePage(SystemCodeRulePageReqVO pageReqVO);

}