package com.lxjl.juling.module.system.api.code;

import com.lxjl.juling.module.system.service.code.CodeRuleService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

/**
 * 编码规则 API 实现类
 *
 * @author 亚特
 */
@Service
@Validated
public class CodeRuleApiImpl implements CodeRuleApi {

    @Resource
    private CodeRuleService codeRuleService;

    @Override
    public String generateCode(String ruleKey) {
        return codeRuleService.generateCode(ruleKey);
    }

}