package com.lxjl.juling.module.system.service.code;

import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.module.system.dal.dataobject.code.SystemCodeRuleDO;
import com.lxjl.juling.module.system.dal.mysql.code.SystemCodeRuleMapper;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.module.system.enums.ErrorCodeConstants.CODE_RULE_NOT_EXISTS;

/**
 * 编码规则 Service 实现类
 *
 * @author 亚特
 */
@Service
@Validated
public class CodeRuleServiceImpl implements CodeRuleService {

    @Resource
    private SystemCodeRuleMapper codeRuleMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public String generateCode(String ruleKey) {
        // 1. 行级锁取规则：同一规则的并发取号在这里排队
        SystemCodeRuleDO rule = codeRuleMapper.selectByRuleKeyForUpdate(ruleKey);
        if (rule == null) {
            throw exception(CODE_RULE_NOT_EXISTS, ruleKey);
        }
        // 2. 自增并落库（与调用方的建档同一事务：建档失败则号一起回滚，不留空洞）
        long next = (rule.getCurrentValue() == null ? 0L : rule.getCurrentValue()) + 1;
        SystemCodeRuleDO updateObj = new SystemCodeRuleDO();
        updateObj.setId(rule.getId());
        updateObj.setCurrentValue(next);
        codeRuleMapper.updateById(updateObj);
        // 3. 前缀 + 左补零流水
        return rule.getPrefix() + StrUtil.padPre(String.valueOf(next), rule.getSeqLength(), '0');
    }

}