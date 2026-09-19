package com.lxjl.juling.module.system.framework.operatelog.core;

import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.framework.dict.core.DictFrameworkUtils;
import com.lxjl.juling.module.infra.enums.DictTypeConstants;
import com.mzt.logapi.service.IParseFunction;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 是否类型的 {@link IParseFunction} 实现类
 *
 * @author 棱信矩灵
 */
@Component
@Slf4j
public class BooleanParseFunction implements IParseFunction {

    public static final String NAME = "getBoolean";

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
        return DictFrameworkUtils.parseDictDataLabel(DictTypeConstants.BOOLEAN_STRING, value.toString());
    }

}
