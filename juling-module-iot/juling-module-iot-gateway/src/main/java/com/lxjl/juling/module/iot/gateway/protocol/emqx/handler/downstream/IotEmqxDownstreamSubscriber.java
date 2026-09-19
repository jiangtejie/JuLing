package com.lxjl.juling.module.iot.gateway.protocol.emqx.handler.downstream;

import com.lxjl.juling.module.iot.core.messagebus.core.IotMessageBus;
import com.lxjl.juling.module.iot.core.mq.message.IotDeviceMessage;
import com.lxjl.juling.module.iot.gateway.protocol.AbstractIotProtocolDownstreamSubscriber;
import com.lxjl.juling.module.iot.gateway.protocol.emqx.IotEmqxProtocol;
import lombok.extern.slf4j.Slf4j;

/**
 * IoT 网关 EMQX 订阅者：接收下行给设备的消息
 *
 * @author 棱信矩灵
 */
@Slf4j
public class IotEmqxDownstreamSubscriber extends AbstractIotProtocolDownstreamSubscriber {

    private final IotEmqxDownstreamHandler downstreamHandler;

    public IotEmqxDownstreamSubscriber(IotEmqxProtocol protocol, IotMessageBus messageBus) {
        super(protocol, messageBus);
        this.downstreamHandler = new IotEmqxDownstreamHandler(protocol);
    }

    @Override
    protected void handleMessage(IotDeviceMessage message) {
        downstreamHandler.handle(message);
    }

}
