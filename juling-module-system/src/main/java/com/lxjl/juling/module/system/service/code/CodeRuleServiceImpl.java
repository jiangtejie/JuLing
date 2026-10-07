package com.lxjl.juling.module.system.service.code;

import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.system.controller.admin.code.vo.SystemCodeRulePageReqVO;
import com.lxjl.juling.module.system.controller.admin.code.vo.SystemCodeRuleSaveReqVO;
import com.lxjl.juling.module.system.dal.dataobject.code.SystemCodeRuleDO;
import com.lxjl.juling.module.system.dal.mysql.code.SystemCodeRuleMapper;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.util.List;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.module.system.enums.ErrorCodeConstants.CODE_RULE_KEY_DUPLICATE;
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

    @Override
    public Long createCodeRule(SystemCodeRuleSaveReqVO createReqVO) {
        validateRuleKeyUnique(null, createReqVO.getRuleKey());
        SystemCodeRuleDO rule = BeanUtils.toBean(createReqVO, SystemCodeRuleDO.class);
        if (rule.getCurrentValue() == null) {
            rule.setCurrentValue(0L);
        }
        codeRuleMapper.insert(rule);
        return rule.getId();
    }

    @Override
    public void updateCodeRule(SystemCodeRuleSaveReqVO updateReqVO) {
        validateCodeRuleExists(updateReqVO.getId());
        validateRuleKeyUnique(updateReqVO.getId(), updateReqVO.getRuleKey());
        // 流水值不允许通过本接口改小：改小会让同一个编码被发出两次（唯一索引会拦下，
        // 但那表现为「建档莫名失败」）。要修正请直接改库并同步核对已用编码。
        SystemCodeRuleDO updateObj = BeanUtils.toBean(updateReqVO, SystemCodeRuleDO.class);
        updateObj.setCurrentValue(null);
        codeRuleMapper.updateById(updateObj);
    }

    @Override
    public void deleteCodeRule(Long id) {
        validateCodeRuleExists(id);
        codeRuleMapper.deleteById(id);
    }

    @Override
    public SystemCodeRuleDO getCodeRule(Long id) {
        return codeRuleMapper.selectById(id);
    }

    @Override
    public List<SystemCodeRuleDO> getCodeRuleList() {
        return codeRuleMapper.selectList();
    }

    @Override
    public PageResult<SystemCodeRuleDO> getCodeRulePage(SystemCodeRulePageReqVO pageReqVO) {
        return codeRuleMapper.selectPage(pageReqVO);
    }

    private SystemCodeRuleDO validateCodeRuleExists(Long id) {
        SystemCodeRuleDO rule = codeRuleMapper.selectById(id);
        if (rule == null) {
            throw exception(CODE_RULE_NOT_EXISTS, id);
        }
        return rule;
    }

    private void validateRuleKeyUnique(Long id, String ruleKey) {
        if (StrUtil.isBlank(ruleKey)) {
            return;
        }
        SystemCodeRuleDO rule = codeRuleMapper.selectByRuleKey(ruleKey);
        if (rule == null) {
            return;
        }
        if (id == null || !rule.getId().equals(id)) {
            throw exception(CODE_RULE_KEY_DUPLICATE, ruleKey);
        }
    }

}