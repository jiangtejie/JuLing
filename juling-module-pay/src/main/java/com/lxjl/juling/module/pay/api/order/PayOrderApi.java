package com.lxjl.juling.module.pay.api.order;

import com.lxjl.juling.module.pay.api.order.dto.PayOrderCreateReqDTO;
import com.lxjl.juling.module.pay.api.order.dto.PayOrderRespDTO;

import jakarta.validation.Valid;

/**
 * 支付单 API 接口
 *
 * @author 棱信矩灵
 * @since 2022-08-26
 */
public interface PayOrderApi {

    /**
     * 创建支付单
     *
     * @param reqDTO 创建请求
     * @return 支付单编号
     */
    Long createOrder(@Valid PayOrderCreateReqDTO reqDTO);

    /**
     * 获得支付单
     *
     * @param id 支付单编号
     * @return 支付单
     */
    PayOrderRespDTO getOrder(Long id);

    /**
     * 更新支付订单价格
     *
     * @param id 支付单编号
     * @param payPrice   支付单价格
     */
    void updatePayOrderPrice(Long id, Integer payPrice);

}
