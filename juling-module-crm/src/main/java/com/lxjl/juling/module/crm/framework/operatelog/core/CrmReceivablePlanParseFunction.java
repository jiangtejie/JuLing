package com.lxjl.juling.module.crm.framework.operatelog.core;

import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.module.crm.dal.dataobject.receivable.CrmReceivablePlanDO;
import com.lxjl.juling.module.crm.service.receivable.CrmReceivablePlanService;
import com.mzt.logapi.service.IParseFunction;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * CRM 回款计划的 {@link IParseFunction} 实现类
 *
 * @author 棱信矩灵
 */
@Component
@Slf4j
public class CrmReceivablePlanParseFunction implements IParseFunction {

    public static final String NAME = "getReceivablePlanServiceById";

    @Resource
    private CrmReceivablePlanService receivablePlanService;

    @Override
    public boolean executeBefore() {
        return true; // 先转换值后对比
    }

    @Override
    public String functionName() {
        return NAME;
    }

    @Override
    public String apply(Object value) {
        if (StrUtil.isEmptyIfStr(value)) {
            return "";
        }
        CrmReceivablePlanDO receivablePlan = receivablePlanService.getReceivablePlan(Long.parseLong(value.toString()));
        return receivablePlan == null ? "" : receivablePlan.getPeriod().toString();
    }

}
