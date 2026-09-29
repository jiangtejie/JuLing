package com.lxjl.juling.module.trade.service.order;

import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeOrderDeliveryReqVO;
import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeOrderRemarkReqVO;
import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeOrderUpdateAddressReqVO;
import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeOrderUpdatePriceReqVO;
import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeOrderCreateReqVO;
import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeOrderSettlementReqVO;
import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeOrderSettlementRespVO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderDO;
import jakarta.validation.constraints.NotNull;

/**
 * 交易订单【写】Service 接口
 *
 * @author 亚特
 * @since 2022-08-26
 */
public interface TradeOrderUpdateService {

    // =================== Order ===================

    /**
     * 获得订单结算信息
     *
     * @param userId          登录用户
     * @param settlementReqVO 订单结算请求
     * @return 订单结算结果
     */
    AppTradeOrderSettlementRespVO settlementOrder(Long userId, AppTradeOrderSettlementReqVO settlementReqVO);

    /**
     * 【会员】创建交易订单
     *
     * @param userId      登录用户
     * @param createReqVO 创建交易订单请求模型
     * @return 交易订单的
     */
    TradeOrderDO createOrder(Long userId, AppTradeOrderCreateReqVO createReqVO);

    /**
     * 【管理员】发货交易订单
     *
     * @param deliveryReqVO 发货请求
     */
    void deliveryOrder(TradeOrderDeliveryReqVO deliveryReqVO);

    /**
     * 【会员】收货交易订单
     *
     * @param userId 用户编号
     * @param id     订单编号
     */
    void receiveOrderByMember(Long userId, Long id);

    /**
     * 【系统】自动收货交易订单
     *
     * @return 收货数量
     */
    int receiveOrderBySystem();

    /**
     * 【会员】取消交易订单
     *
     * @param userId 用户编号
     * @param id     订单编号
     */
    void cancelOrderByMember(Long userId, Long id);

    /**
     * 【系统】自动取消订单
     *
     * @return 取消数量
     */
    int cancelOrderBySystem();

    /**
     * 【会员】删除订单
     *
     * @param userId 用户编号
     * @param id     订单编号
     */
    void deleteOrder(Long userId, Long id);

    /**
     * 【管理员】交易订单备注
     *
     * @param reqVO 请求
     */
    void updateOrderRemark(TradeOrderRemarkReqVO reqVO);

    /**
     * 【管理员】调整价格
     *
     * @param reqVO 请求
     */
    void updateOrderPrice(TradeOrderUpdatePriceReqVO reqVO);

    /**
     * 【管理员】调整地址
     *
     * @param reqVO 请求
     */
    void updateOrderAddress(TradeOrderUpdateAddressReqVO reqVO);

    // =================== Order Item ===================

    /**
     * 当售后申请后，更新交易订单项的售后状态
     *
     * @param id          交易订单项编号
     * @param afterSaleId 售后单编号
     */
    void updateOrderItemWhenAfterSaleCreate(@NotNull Long id, @NotNull Long afterSaleId);

    /**
     * 当售后完成后，更新交易订单项的售后状态
     *
     * @param id          交易订单项编号
     * @param refundPrice 退款金额
     */
    void updateOrderItemWhenAfterSaleSuccess(@NotNull Long id, @NotNull Integer refundPrice);

    /**
     * 当售后取消（用户取消、管理员驳回、管理员拒绝收货）后，更新交易订单项的售后状态
     *
     * @param id 交易订单项编号
     */
    void updateOrderItemWhenAfterSaleCancel(@NotNull Long id);

    /**
     * 取消支付订单
     *
     * @param userId           用户编号
     * @param orderId          订单编号
     * @param cancelType       取消类型
     */
    void cancelPaidOrder(Long userId, Long orderId, Integer cancelType);

    /**
     * 更新订单为「已收款、待发货」（线下收款用）
     *
     * 后台核验付款凭证、累计收款金额达到应收金额时调用；
     * 后置处理与线上支付成功完全一致（订单 handler 照常执行）。
     *
     * @param id             订单编号
     * @param paidAmount     已确认收款金额，单位：分
     * @param payChannelCode 收款渠道（字典 pay_channel_code 的线下值）
     */
    void updateOrderPaidByOffline(Long id, Integer paidAmount, String payChannelCode);

}
