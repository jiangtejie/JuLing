package com.lxjl.juling.module.trade.service.order;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.date.LocalDateTimeUtil;
import cn.hutool.core.lang.Assert;
import cn.hutool.core.map.MapUtil;
import cn.hutool.core.net.NetUtil;
import cn.hutool.core.util.ObjUtil;
import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.extra.spring.SpringUtil;
import com.lxjl.juling.framework.common.enums.UserTypeEnum;
import com.lxjl.juling.framework.common.util.json.JsonUtils;
import com.lxjl.juling.framework.common.util.number.MoneyUtils;
import com.lxjl.juling.module.system.api.social.SocialClientApi;
import com.lxjl.juling.module.system.api.social.dto.SocialWxaSubscribeMessageSendReqDTO;
import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeOrderDeliveryReqVO;
import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeOrderRemarkReqVO;
import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeOrderUpdateAddressReqVO;
import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeOrderUpdatePriceReqVO;
import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeOrderCreateReqVO;
import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeOrderSettlementReqVO;
import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeOrderSettlementRespVO;
import com.lxjl.juling.module.trade.convert.order.TradeOrderConvert;
import com.lxjl.juling.module.trade.dal.dataobject.cart.CartDO;
import com.lxjl.juling.module.trade.dal.dataobject.delivery.DeliveryExpressDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderItemDO;
import com.lxjl.juling.module.trade.dal.mysql.order.TradeOrderItemMapper;
import com.lxjl.juling.module.trade.dal.mysql.order.TradeOrderMapper;
import com.lxjl.juling.module.trade.dal.redis.no.TradeNoRedisDAO;
import com.lxjl.juling.module.trade.enums.delivery.DeliveryTypeEnum;
import com.lxjl.juling.module.trade.enums.order.*;
import com.lxjl.juling.module.trade.framework.order.config.TradeOrderProperties;
import com.lxjl.juling.module.trade.framework.order.core.annotations.TradeOrderLog;
import com.lxjl.juling.module.trade.framework.order.core.utils.TradeOrderLogUtils;
import com.lxjl.juling.module.trade.service.cart.CartService;
import com.lxjl.juling.module.trade.service.delivery.DeliveryExpressService;
import com.lxjl.juling.module.trade.service.message.TradeMessageService;
import com.lxjl.juling.module.trade.service.message.bo.TradeOrderMessageWhenDeliveryOrderReqBO;
import com.lxjl.juling.module.trade.service.order.bo.TradeOrderStoreBO;
import com.lxjl.juling.module.trade.service.order.handler.TradeOrderHandler;
import com.lxjl.juling.module.trade.service.price.TradePriceService;
import com.lxjl.juling.module.trade.service.price.bo.TradePriceCalculateReqBO;
import com.lxjl.juling.module.trade.service.price.bo.TradePriceCalculateRespBO;
import com.lxjl.juling.module.trade.service.price.calculator.TradePriceCalculatorHelper;
import jakarta.annotation.Resource;
import jakarta.validation.constraints.NotNull;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Set;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.*;
import static com.lxjl.juling.framework.common.util.date.LocalDateTimeUtils.minusTime;
import static com.lxjl.juling.framework.common.util.servlet.ServletUtils.getClientIP;
import static com.lxjl.juling.framework.web.core.util.WebFrameworkUtils.getTerminal;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.*;
import static com.lxjl.juling.module.trade.enums.MessageTemplateConstants.WXA_ORDER_DELIVERY;

/**
 * 交易订单【写】Service 实现类
 *
 * @author 亚特
 * @since 2022-08-26
 */
@Service
@Slf4j
public class TradeOrderUpdateServiceImpl implements TradeOrderUpdateService {

    @Resource
    private TradeOrderMapper tradeOrderMapper;
    @Resource
    private TradeOrderItemMapper tradeOrderItemMapper;
    @Resource
    private TradeNoRedisDAO tradeNoRedisDAO;

    @Resource
    private List<TradeOrderHandler> tradeOrderHandlers;

    @Resource
    private CartService cartService;
    @Resource
    private TradePriceService tradePriceService;
    @Resource
    private DeliveryExpressService deliveryExpressService;
    @Resource
    private TradeMessageService tradeMessageService;
    @Resource
    private TradeOrderStoreService tradeOrderStoreService;
    @Resource
    private TradeOrderAuditService tradeOrderAuditService;

    @Resource
    public SocialClientApi socialClientApi;

    @Resource
    private TradeOrderProperties tradeOrderProperties;

    // =================== Order ===================

    @Override
    public AppTradeOrderSettlementRespVO settlementOrder(Long userId, AppTradeOrderSettlementReqVO settlementReqVO) {
        // 1. 计算价格
        TradePriceCalculateRespBO calculateRespBO = calculatePrice(userId, settlementReqVO);

        // 2. 拼接返回
        return TradeOrderConvert.INSTANCE.convert(calculateRespBO);
    }

    /**
     * 计算订单价格
     *
     * @param userId          用户编号
     * @param settlementReqVO 结算信息
     * @return 订单价格
     */
    private TradePriceCalculateRespBO calculatePrice(Long userId, AppTradeOrderSettlementReqVO settlementReqVO) {
        // 1. 如果来自购物车，则获得购物车的商品
        List<CartDO> cartList = cartService.getCartList(userId,
                convertSet(settlementReqVO.getItems(), AppTradeOrderSettlementReqVO.Item::getCartId));

        // 2. 计算价格
        TradePriceCalculateReqBO calculateReqBO = TradeOrderConvert.INSTANCE.convert(userId, settlementReqVO, cartList);
        calculateReqBO.getItems().forEach(item -> Assert.isTrue(item.getSelected(), // 防御性编程，保证都是选中的
                "商品({}) 未设置为选中", item.getSkuId()));
        return tradePriceService.calculateOrderPrice(calculateReqBO);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @TradeOrderLog(operateType = TradeOrderOperateTypeEnum.MEMBER_CREATE)
    public TradeOrderDO createOrder(Long userId, AppTradeOrderCreateReqVO createReqVO) {
        // 1.1 价格计算
        TradePriceCalculateRespBO calculateRespBO = calculatePrice(userId, createReqVO);
        // 1.2 构建订单
        TradeOrderDO order = buildTradeOrder(userId, createReqVO, calculateRespBO);
        List<TradeOrderItemDO> orderItems = buildTradeOrderItems(order, calculateRespBO);

        // 2. 订单创建前的逻辑
        tradeOrderHandlers.forEach(handler -> handler.beforeOrderCreate(order, orderItems));

        // 3. 保存订单
        tradeOrderMapper.insert(order);
        orderItems.forEach(orderItem -> orderItem.setOrderId(order.getId()));
        tradeOrderItemMapper.insertBatch(orderItems);

        // 4. 订单创建后的逻辑
        afterCreateTradeOrder(order, orderItems, createReqVO);
        return order;
    }

    private TradeOrderDO buildTradeOrder(Long userId, AppTradeOrderCreateReqVO createReqVO,
                                         TradePriceCalculateRespBO calculateRespBO) {
        TradeOrderDO order = TradeOrderConvert.INSTANCE.convert(userId, createReqVO, calculateRespBO);
        order.setType(calculateRespBO.getType());
        order.setNo(tradeNoRedisDAO.generate(TradeNoRedisDAO.TRADE_ORDER_NO_PREFIX));
        order.setStatus(TradeOrderStatusEnum.UNPAID.getStatus());
        order.setRefundStatus(TradeOrderRefundStatusEnum.NONE.getStatus());
        order.setProductCount(getSumValue(calculateRespBO.getItems(), TradePriceCalculateRespBO.OrderItem::getCount, Integer::sum));
        order.setUserIp(getClientIP()).setTerminal(getTerminal());
        // 支付 + 退款信息
        order.setAdjustPrice(0).setPayStatus(false);
        order.setRefundStatus(TradeOrderRefundStatusEnum.NONE.getStatus()).setRefundPrice(0);
        // 物流信息
        order.setDeliveryType(createReqVO.getDeliveryType());
        if (Objects.equals(createReqVO.getDeliveryType(), DeliveryTypeEnum.EXPRESS.getType())) {
            // 会员中心（含会员地址簿）已下线：收货信息一律以请求中手填的为准
            if (StrUtil.hasBlank(createReqVO.getReceiverName(), createReqVO.getReceiverMobile(),
                    createReqVO.getReceiverDetailAddress())) {
                throw exception(ORDER_CREATE_FAIL_RECEIVER_INFO_INCOMPLETE);
            }
            order.setReceiverName(createReqVO.getReceiverName()).setReceiverMobile(createReqVO.getReceiverMobile())
                    .setReceiverDetailAddress(createReqVO.getReceiverDetailAddress());
        }
        // 门店订货链 S1：快照下单门店（组织面 deptId + 经营面 customerId / 结算模式），并初始化审核状态
        TradeOrderStoreBO store = tradeOrderStoreService.resolveStore(userId, createReqVO.getStoreCustomerId());
        order.setCustomerId(store.getCustomerId()).setDeptId(store.getDeptId())
                .setSettlementMode(store.getSettlementMode())
                .setStoreType(store.getStoreType())
                .setAuditStatus(TradeOrderAuditStatusEnum.DRAFT.getStatus());
        return order;
    }

    private List<TradeOrderItemDO> buildTradeOrderItems(TradeOrderDO tradeOrderDO,
                                                        TradePriceCalculateRespBO calculateRespBO) {
        return TradeOrderConvert.INSTANCE.convertList(tradeOrderDO, calculateRespBO);
    }

    /**
     * 订单创建后，执行后置逻辑
     * <p>
     * 例如说：支付单的创建等等
     *
     * @param order       订单
     * @param orderItems  订单项
     * @param createReqVO 创建订单请求
     */
    private void afterCreateTradeOrder(TradeOrderDO order, List<TradeOrderItemDO> orderItems,
                                       AppTradeOrderCreateReqVO createReqVO) {
        // 1. 执行订单创建后置处理器
        tradeOrderHandlers.forEach(handler -> handler.afterOrderCreate(order, orderItems));

        // 2. 删除购物车商品
        Set<Long> cartIds = convertSet(createReqVO.getItems(), AppTradeOrderSettlementReqVO.Item::getCartId);
        if (CollUtil.isNotEmpty(cartIds)) {
            cartService.deleteCart(order.getUserId(), cartIds);
        }

        // 3. 线下收款：不创建支付单（本分支已切除线上支付模块）。
        //    客户提交订货单后上传付款截图，提交即调用 updateOrderPaidByOffline 置为已收款并进入两级审批。

        // 4. 插入订单日志
        TradeOrderLogUtils.setOrderInfo(order.getId(), null, order.getStatus());
    }



    @Override
    @Transactional(rollbackFor = Exception.class)
    @TradeOrderLog(operateType = TradeOrderOperateTypeEnum.MEMBER_PAY)
    public void updateOrderPaidByOffline(Long id, Integer paidAmount, String payChannelCode) {
        // 1. 校验订单存在，且仍未支付
        TradeOrderDO order = validateOrderExists(id);
        if (!TradeOrderStatusEnum.isUnpaid(order.getStatus()) || Boolean.TRUE.equals(order.getPayStatus())) {
            throw exception(ORDER_UPDATE_PAID_STATUS_NOT_UNPAID);
        }

        // 2. 更新为「已收款、待发货」，记录收款金额与渠道
        int updateCount = tradeOrderMapper.updateByIdAndStatus(id, order.getStatus(),
                new TradeOrderDO().setStatus(TradeOrderStatusEnum.UNDELIVERED.getStatus()).setPayStatus(true)
                        .setPayTime(LocalDateTime.now()).setPayChannelCode(payChannelCode)
                        .setPaidAmount(paidAmount)
                        .setPaymentProofStatus(TradeOrderReceiveStatusEnum.PAID.getStatus()));
        if (updateCount == 0) {
            throw exception(ORDER_UPDATE_PAID_STATUS_NOT_UNPAID);
        }

        // 3. 执行 TradeOrderHandler 的后置处理（与线上支付成功保持一致）
        List<TradeOrderItemDO> orderItems = tradeOrderItemMapper.selectListByOrderId(id);
        tradeOrderHandlers.forEach(handler -> handler.afterPayOrder(order, orderItems));

        // 4. 记录订单日志
        TradeOrderLogUtils.setOrderInfo(order.getId(), order.getStatus(), TradeOrderStatusEnum.UNDELIVERED.getStatus());
        TradeOrderLogUtils.setUserInfo(order.getUserId(), UserTypeEnum.MEMBER.getValue());

        // 5. 门店订货链 S1：提交付款凭证后直接提交两级审批（供应链 → 财务出纳；BPM 流程定义 key：trade-order-store-audit）
        //    审核未通过前不允许发货（发货闸门见 TradeOrderAuditService#validateCanDelivery）。
        //
        //    ⚠️ 自动提交必须放在**本事务提交之后**执行，不能就地 try/catch：
        //    BPM 创建流程实例内部是嵌套事务，抛错会把当前事务标记成 rollback-only，
        //    就地 catch 吞掉后外层提交时照样抛 UnexpectedRollbackException（操作人只看到"系统异常"，
        //    失败原因还丢了，订单悄悄停在"已收款未提交审核"）。放到提交后执行则：
        //    收款核验一定成功落库；审核提交失败时订单仍是「待发货 + 待提交审核」，
        //    发货闸门关闭，可在订单详情页手工重新提交。
        if (tradeOrderStoreService.isFranchiseStore(order.getCustomerId())) {
            Long orderId = order.getId();
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    // 发起人用系统配置账号：门店在 H5 提交凭证时登录身份是会员，没有该流程定义的发起权限
                    tradeOrderAuditService.submitAuditAutoAfterCommit(orderId);
                }
            });
        } else {
            // 直营门店免审：把审核状态留痕为「已通过」，避免订单永远停在「待提交」看起来像没人处理
            tradeOrderMapper.updateById(new TradeOrderDO().setId(order.getId())
                    .setAuditStatus(TradeOrderAuditStatusEnum.APPROVE.getStatus())
                    .setAuditTime(LocalDateTime.now())
                    .setAuditRemark("直营门店免审：提交付款凭证后直接进入待发货"));
            log.info("[updateOrderPaidByOffline][订单({}) 直营门店免审，直接进入订单工作台待发货]", order.getId());
        }
    }


    /**
     * 校验支付订单的合法性
     *
     * @param order      交易订单
     * @param payOrderId 支付订单编号
     * @return 支付订单
     */

    @Override
    @Transactional(rollbackFor = Exception.class)
    @TradeOrderLog(operateType = TradeOrderOperateTypeEnum.ADMIN_DELIVERY)
    public void deliveryOrder(TradeOrderDeliveryReqVO deliveryReqVO) {
        // 1.1 校验并获得交易订单（可发货）
        TradeOrderDO order = validateOrderDeliverable(deliveryReqVO.getId());
        // 1.15 门店订货链 S1：门店要货必须通过供应链审核，才允许发货
        tradeOrderAuditService.validateCanDelivery(order);
        // 1.2 校验 deliveryType 是否为快递，是快递才可以发货
        if (ObjectUtil.notEqual(order.getDeliveryType(), DeliveryTypeEnum.EXPRESS.getType())) {
            throw exception(ORDER_DELIVERY_FAIL_DELIVERY_TYPE_NOT_EXPRESS);
        }

        // 2. 更新订单为已发货
        TradeOrderDO updateOrderObj = new TradeOrderDO();
        // 2.1 快递发货
        DeliveryExpressDO express = null;
        if (ObjectUtil.notEqual(deliveryReqVO.getLogisticsId(), TradeOrderDO.LOGISTICS_ID_NULL)) {
            express = deliveryExpressService.validateDeliveryExpress(deliveryReqVO.getLogisticsId());
            updateOrderObj.setLogisticsId(deliveryReqVO.getLogisticsId()).setLogisticsNo(deliveryReqVO.getLogisticsNo());
        } else {
            // 2.2 无需发货
            updateOrderObj.setLogisticsId(0L).setLogisticsNo("");
        }
        // 执行更新
        updateOrderObj.setStatus(TradeOrderStatusEnum.DELIVERED.getStatus()).setDeliveryTime(LocalDateTime.now());
        int updateCount = tradeOrderMapper.updateByIdAndStatus(order.getId(), order.getStatus(), updateOrderObj);
        if (updateCount == 0) {
            throw exception(ORDER_DELIVERY_FAIL_STATUS_NOT_UNDELIVERED);
        }

        // 3. 记录订单日志
        TradeOrderLogUtils.setOrderInfo(order.getId(), order.getStatus(), TradeOrderStatusEnum.DELIVERED.getStatus(),
                MapUtil.<String, Object>builder().put("expressName", express != null ? express.getName() : "")
                        .put("logisticsNo", express != null ? deliveryReqVO.getLogisticsNo() : "").build());

        // 4.1 发送站内信
        tradeMessageService.sendMessageWhenDeliveryOrder(new TradeOrderMessageWhenDeliveryOrderReqBO()
                .setOrderId(order.getId()).setUserId(order.getUserId()).setMessage(null));
        // 4.2 发送订阅消息
        getSelf().sendDeliveryOrderMessage(order, deliveryReqVO);

        // 5. 处理订单发货后逻辑
        order.setLogisticsId(updateOrderObj.getLogisticsId()).setLogisticsNo(updateOrderObj.getLogisticsNo())
                .setStatus(updateOrderObj.getStatus()).setDeliveryTime(updateOrderObj.getDeliveryTime());
        tradeOrderHandlers.forEach(handler -> handler.afterDeliveryOrder(order));
    }

    @Async
    public void sendDeliveryOrderMessage(TradeOrderDO order, TradeOrderDeliveryReqVO deliveryReqVO) {
        // 构建并发送模版消息
        Long orderId = order.getId();
        socialClientApi.sendWxaSubscribeMessage(new SocialWxaSubscribeMessageSendReqDTO()
                .setUserId(order.getUserId()).setUserType(UserTypeEnum.MEMBER.getValue())
                .setTemplateTitle(WXA_ORDER_DELIVERY)
                .setPage("pages/order/detail?id=" + orderId) // 订单详情页
                .addMessage("character_string3", String.valueOf(orderId)) // 订单编号
                .addMessage("phrase6", TradeOrderStatusEnum.DELIVERED.getName()) // 订单状态
                .addMessage("date4", LocalDateTimeUtil.formatNormal(LocalDateTime.now()))// 发货时间
                .addMessage("character_string5", StrUtil.blankToDefault(deliveryReqVO.getLogisticsNo(), "-")) // 快递单号
                .addMessage("thing9", order.getReceiverDetailAddress())); // 收货地址
    }

    /**
     * 校验交易订单满足被发货的条件
     * <p>
     * 1. 交易订单未发货
     *
     * @param id 交易订单编号
     * @return 交易订单
     */
    private TradeOrderDO validateOrderDeliverable(Long id) {
        TradeOrderDO order = validateOrderExists(id);
        // 1. 校验订单是否未发货
        if (ObjectUtil.notEqual(TradeOrderRefundStatusEnum.NONE.getStatus(), order.getRefundStatus())) {
            throw exception(ORDER_DELIVERY_FAIL_REFUND_STATUS_NOT_NONE);
        }

        // 2. 执行 TradeOrderHandler 前置处理
        tradeOrderHandlers.forEach(handler -> handler.beforeDeliveryOrder(order));
        return order;
    }

    @NotNull
    private TradeOrderDO validateOrderExists(Long id) {
        // 校验订单是否存在
        TradeOrderDO order = tradeOrderMapper.selectById(id);
        if (order == null) {
            throw exception(ORDER_NOT_FOUND);
        }
        return order;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @TradeOrderLog(operateType = TradeOrderOperateTypeEnum.MEMBER_RECEIVE)
    public void receiveOrderByMember(Long userId, Long id) {
        // 校验并获得交易订单（可收货）
        TradeOrderDO order = validateOrderReceivable(userId, id);

        // 收货订单
        receiveOrder0(order);
    }

    @Override
    public int receiveOrderBySystem() {
        // 1. 查询过期的待支付订单
        LocalDateTime expireTime = minusTime(tradeOrderProperties.getReceiveExpireTime());
        List<TradeOrderDO> orders = tradeOrderMapper.selectListByStatusAndDeliveryTimeLt(
                TradeOrderStatusEnum.DELIVERED.getStatus(), expireTime);
        if (CollUtil.isEmpty(orders)) {
            return 0;
        }

        // 2. 遍历执行，逐个取消
        int count = 0;
        for (TradeOrderDO order : orders) {
            try {
                getSelf().receiveOrderBySystem(order);
                count++;
            } catch (Throwable e) {
                log.error("[receiveOrderBySystem][order({}) 自动收货订单异常]", order.getId(), e);
            }
        }
        return count;
    }

    /**
     * 自动收货单个订单
     *
     * @param order 订单
     */
    @Transactional(rollbackFor = Exception.class)
    @TradeOrderLog(operateType = TradeOrderOperateTypeEnum.SYSTEM_RECEIVE)
    public void receiveOrderBySystem(TradeOrderDO order) {
        receiveOrder0(order);
    }

    /**
     * 收货订单的核心实现
     *
     * @param order 订单
     */
    private void receiveOrder0(TradeOrderDO order) {
        // 1. 更新 TradeOrderDO 状态为已完成
        LocalDateTime receiveTime = LocalDateTime.now();
        int updateCount = tradeOrderMapper.updateByIdAndStatus(order.getId(), order.getStatus(),
                new TradeOrderDO().setStatus(TradeOrderStatusEnum.COMPLETED.getStatus()).setReceiveTime(receiveTime));
        if (updateCount == 0) {
            throw exception(ORDER_RECEIVE_FAIL_STATUS_NOT_DELIVERED);
        }

        // 2. 插入订单日志
        TradeOrderLogUtils.setOrderInfo(order.getId(), order.getStatus(), TradeOrderStatusEnum.COMPLETED.getStatus());

        // 3. 执行 TradeOrderHandler 后置处理
        order.setStatus(TradeOrderStatusEnum.COMPLETED.getStatus()).setReceiveTime(receiveTime);
        tradeOrderHandlers.forEach(handler -> handler.afterReceiveOrder(order));
    }

    /**
     * 校验交易订单满足可售货的条件
     * <p>
     * 1. 交易订单待收货
     *
     * @param userId 用户编号
     * @param id     交易订单编号
     * @return 交易订单
     */
    private TradeOrderDO validateOrderReceivable(Long userId, Long id) {
        // 校验订单是否存在
        TradeOrderDO order = tradeOrderMapper.selectByIdAndUserId(id, userId);
        if (order == null) {
            throw exception(ORDER_NOT_FOUND);
        }
        // 校验订单是否是待收货状态
        if (!TradeOrderStatusEnum.isDelivered(order.getStatus())) {
            throw exception(ORDER_RECEIVE_FAIL_STATUS_NOT_DELIVERED);
        }
        return order;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @TradeOrderLog(operateType = TradeOrderOperateTypeEnum.MEMBER_CANCEL)
    public void cancelOrderByMember(Long userId, Long id) {
        // 1.1 校验存在
        TradeOrderDO order = tradeOrderMapper.selectOrderByIdAndUserId(id, userId);
        if (order == null) {
            throw exception(ORDER_NOT_FOUND);
        }
        // 1.2 校验状态
        if (ObjectUtil.notEqual(order.getStatus(), TradeOrderStatusEnum.UNPAID.getStatus())) {
            throw exception(ORDER_CANCEL_FAIL_STATUS_NOT_UNPAID);
        }
        // 1.3 校验：审核中的订单不允许门店自行取消（可能已转账并进入审批，要走总部或售后处理）。
        //     注：提交付款凭证后订单会立即转为「待发货」，正常走不到这里，此校验用于兜底。
        if (Objects.equals(order.getAuditStatus(), TradeOrderAuditStatusEnum.PROCESS.getStatus())) {
            log.warn("[cancelOrderByMember][order({}) 正在审核中，不支持取消]", order.getId());
            throw exception(ORDER_CANCEL_FAIL_HAS_PENDING_PAYMENT_PROOF);
        }

        // 2. 取消订单
        cancelOrder0(order, TradeOrderCancelTypeEnum.MEMBER_CANCEL);
    }

    @Override
    public int cancelOrderBySystem() {
        // 1. 查询过期的待支付订单
        LocalDateTime expireTime = minusTime(tradeOrderProperties.getPayExpireTime());
        List<TradeOrderDO> orders = tradeOrderMapper.selectListByStatusAndCreateTimeLt(
                TradeOrderStatusEnum.UNPAID.getStatus(), expireTime);
        if (CollUtil.isEmpty(orders)) {
            return 0;
        }

        // 2. 遍历执行，逐个取消
        int count = 0;
        for (TradeOrderDO order : orders) {
            try {
                getSelf().cancelOrderBySystem(order);
                count++;
            } catch (Throwable e) {
                log.error("[cancelOrderBySystem][order({}) 过期订单异常]", order.getId(), e);
            }
        }
        return count;
    }

    /**
     * 自动取消单个订单
     *
     * @param order 订单
     */
    @Transactional(rollbackFor = Exception.class)
    @TradeOrderLog(operateType = TradeOrderOperateTypeEnum.SYSTEM_CANCEL)
    public void cancelOrderBySystem(TradeOrderDO order) {
        // 线下收款：只要门店提交过付款凭证（收款状态不再是「未上传凭证」）就涉及真实货款，不能按超时自动取消
        if (Boolean.TRUE.equals(order.getPayStatus())
                || ObjectUtil.notEqual(order.getPaymentProofStatus(), TradeOrderReceiveStatusEnum.NONE.getStatus())) {
            log.info("[cancelOrderBySystem][order({}) 已有收款进展({})，跳过超时自动取消]", order.getId(), order.getPaymentProofStatus());
            return;
        }

        cancelOrder0(order, TradeOrderCancelTypeEnum.PAY_TIMEOUT);
    }

    /**
     * 取消订单的核心实现
     *
     * @param order      订单
     * @param cancelType 取消类型
     */
    private void cancelOrder0(TradeOrderDO order, TradeOrderCancelTypeEnum cancelType) {
        // 1. 更新 TradeOrderDO 状态为已取消
        int updateCount = tradeOrderMapper.updateByIdAndStatus(order.getId(), order.getStatus(),
                new TradeOrderDO().setStatus(TradeOrderStatusEnum.CANCELED.getStatus())
                        .setCancelType(cancelType.getType()).setCancelTime(LocalDateTime.now()));
        if (updateCount == 0) {
            throw exception(ORDER_CANCEL_FAIL_STATUS_NOT_UNPAID);
        }

        // 2. 执行 TradeOrderHandler 的后置处理
        List<TradeOrderItemDO> orderItems = tradeOrderItemMapper.selectListByOrderId(order.getId());
        tradeOrderHandlers.forEach(handler -> handler.afterCancelOrder(order, orderItems));

        // 3. 增加订单日志
        TradeOrderLogUtils.setOrderInfo(order.getId(), order.getStatus(), TradeOrderStatusEnum.CANCELED.getStatus());
    }

    /**
     * 如果金额全部被退款，则取消订单
     * 如果还有未被退款的金额，则无需取消订单
     *
     * @param order       订单
     * @param refundPrice 退款金额
     */
    @TradeOrderLog(operateType = TradeOrderOperateTypeEnum.ADMIN_CANCEL_AFTER_SALE)
    public void cancelOrderByAfterSale(TradeOrderDO order, Integer refundPrice) {
        // 1. 更新订单
        if (refundPrice < order.getPayPrice()) {
            return;
        }
        tradeOrderMapper.updateById(new TradeOrderDO().setId(order.getId())
                .setStatus(TradeOrderStatusEnum.CANCELED.getStatus())
                .setCancelType(TradeOrderCancelTypeEnum.AFTER_SALE_CLOSE.getType()).setCancelTime(LocalDateTime.now()));

        // 2. 执行 TradeOrderHandler 的后置处理
        List<TradeOrderItemDO> orderItems = tradeOrderItemMapper.selectListByOrderId(order.getId());
        tradeOrderHandlers.forEach(handler -> handler.afterCancelOrder(order, orderItems));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @TradeOrderLog(operateType = TradeOrderOperateTypeEnum.MEMBER_DELETE)
    public void deleteOrder(Long userId, Long id) {
        // 1.1 校验存在
        TradeOrderDO order = tradeOrderMapper.selectOrderByIdAndUserId(id, userId);
        if (order == null) {
            throw exception(ORDER_NOT_FOUND);
        }
        // 1.2 校验状态
        if (ObjectUtil.notEqual(order.getStatus(), TradeOrderStatusEnum.CANCELED.getStatus())) {
            throw exception(ORDER_DELETE_FAIL_STATUS_NOT_CANCEL);
        }
        // 2. 删除订单
        tradeOrderMapper.deleteById(id);

        // 3. 记录日志
        TradeOrderLogUtils.setOrderInfo(order.getId(), order.getStatus(), order.getStatus());
    }

    @Override
    public void updateOrderRemark(TradeOrderRemarkReqVO reqVO) {
        // 校验并获得交易订单
        validateOrderExists(reqVO.getId());

        // 更新
        TradeOrderDO order = TradeOrderConvert.INSTANCE.convert(reqVO);
        tradeOrderMapper.updateById(order);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @TradeOrderLog(operateType = TradeOrderOperateTypeEnum.ADMIN_UPDATE_PRICE)
    public void updateOrderPrice(TradeOrderUpdatePriceReqVO reqVO) {
        // 1.1 校验交易订单
        TradeOrderDO order = validateOrderExists(reqVO.getId());
        if (order.getPayStatus()) {
            throw exception(ORDER_UPDATE_PRICE_FAIL_PAID);
        }
        // 注意：adjustPrice / payPrice 在首次调价前可能是 null（下单时未初始化，历史数据里
        // trade_order_item.adjust_price 就是 NULL），直接相加会 NPE 并对外表现成「系统异常」，
        // 因此这里统一兜底 0
        int oldAdjustPrice = ObjectUtil.defaultIfNull(order.getAdjustPrice(), 0);
        int adjustPrice = ObjectUtil.defaultIfNull(reqVO.getAdjustPrice(), 0);

        // 1.2 校验调价金额是否变化
        if (oldAdjustPrice > 0) {
            throw exception(ORDER_UPDATE_PRICE_FAIL_ALREADY);
        }
        // 1.3 支付价格不能为 0
        int newPayPrice = ObjectUtil.defaultIfNull(order.getPayPrice(), 0) + adjustPrice;
        if (newPayPrice <= 0) {
            throw exception(ORDER_UPDATE_PRICE_FAIL_PRICE_ERROR);
        }

        // 2. 更新订单
        tradeOrderMapper.updateById(new TradeOrderDO().setId(order.getId())
                .setAdjustPrice(adjustPrice + oldAdjustPrice).setPayPrice(newPayPrice));

        // 3. 更新 TradeOrderItem，需要做 adjustPrice 的分摊
        List<TradeOrderItemDO> orderOrderItems = tradeOrderItemMapper.selectListByOrderId(order.getId());
        List<Integer> dividePrices = TradePriceCalculatorHelper.dividePrice2(orderOrderItems, adjustPrice);
        List<TradeOrderItemDO> updateItems = new ArrayList<>();
        for (int i = 0; i < orderOrderItems.size(); i++) {
            TradeOrderItemDO item = orderOrderItems.get(i);
            int dividePrice = ObjectUtil.defaultIfNull(dividePrices.get(i), 0);
            updateItems.add(new TradeOrderItemDO().setId(item.getId())
                    .setAdjustPrice(ObjectUtil.defaultIfNull(item.getAdjustPrice(), 0) + dividePrice)
                    .setPayPrice(ObjectUtil.defaultIfNull(item.getPayPrice(), 0) + dividePrice));
        }
        tradeOrderItemMapper.updateBatch(updateItems);

        // 4. 记录订单日志（线下收款无支付单需要同步价格）
        TradeOrderLogUtils.setOrderInfo(order.getId(), order.getStatus(), order.getStatus(),
                MapUtil.<String, Object>builder().put("oldPayPrice", MoneyUtils.fenToYuanStr(order.getPayPrice()))
                        .put("adjustPrice", MoneyUtils.fenToYuanStr(adjustPrice))
                        .put("newPayPrice", MoneyUtils.fenToYuanStr(newPayPrice)).build());
    }

    @Override
    @TradeOrderLog(operateType = TradeOrderOperateTypeEnum.ADMIN_UPDATE_ADDRESS)
    public void updateOrderAddress(TradeOrderUpdateAddressReqVO reqVO) {
        // 校验交易订单
        TradeOrderDO order = validateOrderExists(reqVO.getId());
        // 只有待发货状态，才可以修改订单收货地址；
        if (!TradeOrderStatusEnum.isUndelivered(order.getStatus())) {
            throw exception(ORDER_UPDATE_ADDRESS_FAIL_STATUS_NOT_DELIVERED);
        }

        // 更新
        tradeOrderMapper.updateById(TradeOrderConvert.INSTANCE.convert(reqVO));

        // 记录订单日志
        TradeOrderLogUtils.setOrderInfo(order.getId(), order.getStatus(), order.getStatus());
    }

    // =================== Order Item ===================

    @Override
    public void updateOrderItemWhenAfterSaleCreate(Long id, Long afterSaleId) {
        // 更新订单项
        updateOrderItemAfterSaleStatus(id, TradeOrderItemAfterSaleStatusEnum.NONE.getStatus(),
                TradeOrderItemAfterSaleStatusEnum.APPLY.getStatus(), afterSaleId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateOrderItemWhenAfterSaleSuccess(Long id, Integer refundPrice) {
        // 1.1 更新订单项
        updateOrderItemAfterSaleStatus(id, TradeOrderItemAfterSaleStatusEnum.APPLY.getStatus(),
                TradeOrderItemAfterSaleStatusEnum.SUCCESS.getStatus(), null);
        // 1.2 执行 TradeOrderHandler 的后置处理
        TradeOrderItemDO orderItem = tradeOrderItemMapper.selectById(id);
        TradeOrderDO order = tradeOrderMapper.selectById(orderItem.getOrderId());
        tradeOrderHandlers.forEach(handler -> handler.afterCancelOrderItem(order, orderItem));

        // 2.1 更新订单的退款金额
        // 注意：refundPrice 在首次售后前可能为 null（下单时不会初始化），
        // 这里必须兜底 0，否则第一笔售后成功时直接 NPE（Cannot invoke "Integer.intValue()"）
        Integer orderRefundPrice = ObjectUtil.defaultIfNull(order.getRefundPrice(), 0)
                + ObjectUtil.defaultIfNull(refundPrice, 0);
        Integer refundStatus = isAllOrderItemAfterSaleSuccess(order.getId()) ?
                TradeOrderRefundStatusEnum.ALL.getStatus() // 如果都售后成功，则需要取消订单
                : TradeOrderRefundStatusEnum.PART.getStatus();
        tradeOrderMapper.updateById(new TradeOrderDO().setId(order.getId())
                .setRefundStatus(refundStatus)
                .setRefundPrice(orderRefundPrice));
        // 2.2 如果全部退款，则进行取消订单
        getSelf().cancelOrderByAfterSale(order, orderRefundPrice);
    }

    @Override
    public void updateOrderItemWhenAfterSaleCancel(Long id) {
        // 更新订单项
        updateOrderItemAfterSaleStatus(id, TradeOrderItemAfterSaleStatusEnum.APPLY.getStatus(),
                TradeOrderItemAfterSaleStatusEnum.NONE.getStatus(), null);
    }

    private void updateOrderItemAfterSaleStatus(Long id, Integer oldAfterSaleStatus, Integer newAfterSaleStatus,
                                                Long afterSaleId) {
        // 更新订单项
        int updateCount = tradeOrderItemMapper.updateAfterSaleStatus(id, oldAfterSaleStatus, newAfterSaleStatus, afterSaleId);
        if (updateCount <= 0) {
            throw exception(ORDER_ITEM_UPDATE_AFTER_SALE_STATUS_FAIL);
        }

    }

    /**
     * 判断指定订单的所有订单项，是不是都售后成功
     *
     * @param id 订单编号
     * @return 是否都售后成功
     */
    private boolean isAllOrderItemAfterSaleSuccess(Long id) {
        List<TradeOrderItemDO> orderItems = tradeOrderItemMapper.selectListByOrderId(id);
        return orderItems.stream().allMatch(orderItem -> Objects.equals(orderItem.getAfterSaleStatus(),
                TradeOrderItemAfterSaleStatusEnum.SUCCESS.getStatus()));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancelPaidOrder(Long userId, Long orderId, Integer cancelType) {
        // 1.1 这里校验下 cancelType 只允许拼团关闭；
        if (ObjUtil.notEqual(TradeOrderCancelTypeEnum.COMBINATION_CLOSE.getType(), cancelType)) {
            return;
        }
        // 1.2 检验订单存在
        TradeOrderDO order = tradeOrderMapper.selectOrderByIdAndUserId(orderId, userId);
        if (order == null) {
            throw exception(ORDER_NOT_FOUND);
        }
        // 1.3 校验订单是否支付
        if (!order.getPayStatus()) {
            throw exception(ORDER_CANCEL_PAID_FAIL, "已支付");
        }
        // 1.4 校验订单是否未退款
        if (ObjUtil.notEqual(TradeOrderRefundStatusEnum.NONE.getStatus(), order.getRefundStatus())) {
            throw exception(ORDER_CANCEL_PAID_FAIL, "未退款");
        }

        // 2.1 取消订单
        cancelOrder0(order, TradeOrderCancelTypeEnum.COMBINATION_CLOSE);
        // 2.2 线下收款：没有线上退款单可发起，已收货款需由商家线下退回。
        //     订单已是「已取消 + 已收金额 > 0」的组合，后台订单列表可直接筛出来人工退款。
        log.warn("[cancelPaidOrder][订单({}) 已取消，已收货款({} 分)需线下退回客户]", order.getId(), order.getPaidAmount());
    }


    /**
     * 获得自身的代理对象，解决 AOP 生效问题
     *
     * @return 自己
     */
    private TradeOrderUpdateServiceImpl getSelf() {
        return SpringUtil.getBean(getClass());
    }

}
