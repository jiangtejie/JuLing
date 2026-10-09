package com.lxjl.juling.module.trade.service.message;

import com.lxjl.juling.module.trade.service.message.bo.TradeOrderMessageWhenDeliveryOrderReqBO;

/**
 * Trade 消息 service 接口
 *
 * @author 亚特
 */
public interface TradeMessageService {

    /**
     * 订单发货时发送通知
     *
     * @param reqBO 发送消息
     */
    void sendMessageWhenDeliveryOrder(TradeOrderMessageWhenDeliveryOrderReqBO reqBO);

}
