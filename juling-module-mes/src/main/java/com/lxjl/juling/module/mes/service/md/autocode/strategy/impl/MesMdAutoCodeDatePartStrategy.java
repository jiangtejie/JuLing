package com.lxjl.juling.module.mes.service.md.autocode.strategy.impl;

import cn.hutool.core.date.DatePattern;
import cn.hutool.core.date.DateUtil;
import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.module.mes.dal.dataobject.md.autocode.MesMdAutoCodePartDO;
import com.lxjl.juling.module.mes.enums.md.autocode.MesMdAutoCodePartTypeEnum;
import com.lxjl.juling.module.mes.service.md.autocode.strategy.MesMdAutoCodeContext;
import com.lxjl.juling.module.mes.service.md.autocode.strategy.MesMdAutoCodePartStrategy;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * MES 编码规则 - 当前日期策略
 *
 * @author 棱信矩灵
 */
@Component
public class MesMdAutoCodeDatePartStrategy implements MesMdAutoCodePartStrategy {

    @Override
    public Integer getType() {
        return MesMdAutoCodePartTypeEnum.DATE.getType();
    }

    @Override
    public String generate(MesMdAutoCodePartDO part, MesMdAutoCodeContext context) {
        String dateFormat = StrUtil.emptyToDefault(part.getDateFormat(), DatePattern.PURE_DATE_PATTERN);
        return DateUtil.format(LocalDateTime.now(), dateFormat);
    }

}
