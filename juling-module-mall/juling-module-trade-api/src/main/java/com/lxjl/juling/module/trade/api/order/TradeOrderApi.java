package com.lxjl.juling.module.trade.api.order;

import com.lxjl.juling.module.trade.api.order.dto.TradeOrderRespDTO;

import java.util.Collection;
import java.util.List;

/**
 * 订单 API 接口
 *
 * @author 亚特
 */
public interface TradeOrderApi {

    /**
     * 获得订单列表
     *
     * @param ids 订单编号数组
     * @return 订单列表
     */
    List<TradeOrderRespDTO> getOrderList(Collection<Long> ids);

    /**
     * 获得订单
     *
     * @param id 订单编号
     * @return 订单
     */
    TradeOrderRespDTO getOrder(Long id);

    /**
     * 取消支付订单
     *
     * @param userId 用户编号
     * @param orderId 订单编号
     * @param cancelType 取消类型
     */
    void cancelPaidOrder(Long userId, Long orderId, Integer cancelType);

    /**
     * 获得指定会员（订货账号）的订单数量
     *
     * 用途：删除订货账号前的校验——已经有订单的账号删掉会让历史订单失去归属，应改用「停用」。
     *
     * @param userId 会员编号
     * @return 订单数量
     */
    Long getOrderCountByUserId(Long userId);

}
