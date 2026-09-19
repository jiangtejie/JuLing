package com.lxjl.juling.module.iot.service.rule.scene.action;

import com.lxjl.juling.module.iot.core.mq.message.IotDeviceMessage;
import com.lxjl.juling.module.iot.dal.dataobject.rule.IotSceneRuleDO;
import com.lxjl.juling.module.iot.enums.rule.IotSceneRuleActionTypeEnum;

import javax.annotation.Nullable;

/**
 * IoT 场景联动的执行器接口
 *
 * @author 棱信矩灵
 */
public interface IotSceneRuleAction {

    /**
     * 执行场景联动
     *
     * @param message 消息，允许空
     *                1. 空的情况：定时触发
     *                2. 非空的情况：设备触发
     * @param rule    规则
     * @param actionConfig  执行配置（实际对应规则里的哪条执行配置）
     */
    void execute(@Nullable IotDeviceMessage message,
                 IotSceneRuleDO rule,
                 IotSceneRuleDO.Action actionConfig) throws Exception;

    /**
     * 获得类型
     *
     * @return 类型
     */
    IotSceneRuleActionTypeEnum getType();

}
