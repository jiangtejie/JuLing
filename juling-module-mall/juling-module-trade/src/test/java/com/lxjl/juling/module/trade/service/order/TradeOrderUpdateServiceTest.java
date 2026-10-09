package com.lxjl.juling.module.trade.service.order;

import cn.hutool.core.util.IdUtil;
import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.framework.test.core.ut.BaseDbUnitTest;
import com.lxjl.juling.module.member.api.user.MemberUserApi;
import com.lxjl.juling.module.product.api.sku.ProductSkuApi;
import com.lxjl.juling.module.product.api.spu.ProductSpuApi;
import com.lxjl.juling.module.system.api.notify.NotifyMessageSendApi;
import com.lxjl.juling.module.trade.controller.admin.delivery.vo.express.DeliveryExpressCreateReqVO;
import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeOrderDeliveryReqVO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderDO;
import com.lxjl.juling.module.trade.dal.mysql.order.TradeOrderItemMapper;
import com.lxjl.juling.module.trade.dal.mysql.order.TradeOrderMapper;
import com.lxjl.juling.module.trade.dal.redis.no.TradeNoRedisDAO;
import com.lxjl.juling.module.trade.enums.delivery.DeliveryTypeEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderRefundStatusEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderStatusEnum;
import com.lxjl.juling.module.trade.framework.order.config.TradeOrderConfig;
import com.lxjl.juling.module.trade.framework.order.config.TradeOrderProperties;
import com.lxjl.juling.module.trade.service.cart.CartServiceImpl;
import com.lxjl.juling.module.trade.service.delivery.DeliveryExpressService;
import com.lxjl.juling.module.trade.service.delivery.DeliveryExpressServiceImpl;
import com.lxjl.juling.module.trade.service.message.TradeMessageServiceImpl;
import com.lxjl.juling.module.trade.service.order.handler.TradeOrderHandler;
import com.lxjl.juling.module.trade.service.price.TradePriceServiceImpl;
import jakarta.annotation.Resource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import java.time.Duration;

import static com.lxjl.juling.framework.test.core.util.AssertUtils.assertPojoEquals;
import static com.lxjl.juling.framework.test.core.util.RandomUtils.randomPojo;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

/**
 * {@link TradeOrderUpdateServiceImpl} 的单元测试类
 *
 * @author 亚特
 * @since 2022-09-07
 */
@Disabled // TODO 亚特：后续 fix 补充的单测
@Import({TradeOrderUpdateServiceImpl.class, TradeOrderConfig.class, CartServiceImpl.class, TradePriceServiceImpl.class,
        DeliveryExpressServiceImpl.class, TradeMessageServiceImpl.class
})
public class TradeOrderUpdateServiceTest extends BaseDbUnitTest {

    @Resource
    private TradeOrderUpdateServiceImpl tradeOrderUpdateService;

    @Resource
    private TradeOrderMapper tradeOrderMapper;
    @Resource
    private TradeOrderItemMapper tradeOrderItemMapper;

    @MockitoBean
    private MemberUserApi memberUserApi;
    @MockitoBean
    private ProductSpuApi productSpuApi;
    @MockitoBean
    private ProductSkuApi productSkuApi;
    @MockitoBean
    private TradeOrderProperties tradeOrderProperties;
    @MockitoBean
    private TradeNoRedisDAO tradeNoRedisDAO;
    @MockitoBean
    private TradeOrderHandler tradeOrderHandler;
    @MockitoBean
    private NotifyMessageSendApi notifyMessageSendApi;
    @MockitoBean
    private DeliveryExpressService deliveryExpressService;

    @BeforeEach
    public void setUp() {
        when(tradeOrderProperties.getPayExpireTime()).thenReturn(Duration.ofDays(1));
        when(tradeNoRedisDAO.generate(anyString())).thenReturn(IdUtil.randomUUID());
    }

    // 说明：原 testUpdateOrderPaid 针对线上支付回调（PayOrderApi）编写，
    // 本分支已切除线上支付，改用「付款凭证核验 → updateOrderPaidByOffline」的线下流程，
    // 覆盖见 e2e 线下收款用例（下单 → 上传凭证 → 后台核验 → 已收齐转待发货）。

    @Test
    public void testDeliveryOrder() {
        // mock 数据（TradeOrder）
        TradeOrderDO order = randomPojo(TradeOrderDO.class, o -> {
            o.setId(1L).setStatus(TradeOrderStatusEnum.UNDELIVERED.getStatus());
            o.setLogisticsId(null).setLogisticsNo(null).setDeliveryTime(null);
            o.setRefundStatus(TradeOrderRefundStatusEnum.NONE.getStatus());
            o.setDeliveryType(DeliveryTypeEnum.EXPRESS.getType());
        });
        tradeOrderMapper.insert(order);

        DeliveryExpressCreateReqVO expressCreateReqVO = new DeliveryExpressCreateReqVO();
        expressCreateReqVO.setCode("code").setName("Name").setLogo("logo").setSort(0).setStatus(CommonStatusEnum.ENABLE.getStatus());
        Long deliveryExpressId = deliveryExpressService.createDeliveryExpress(expressCreateReqVO);
        // 准备参数
        TradeOrderDeliveryReqVO deliveryReqVO = new TradeOrderDeliveryReqVO().setId(1L)
                .setLogisticsId(deliveryExpressId).setLogisticsNo("100");

        // mock 方法（支付单）

        // 调用
        tradeOrderUpdateService.deliveryOrder(deliveryReqVO);
        // 断言
        TradeOrderDO dbOrder = tradeOrderMapper.selectById(1L);
        assertEquals(dbOrder.getStatus(), TradeOrderStatusEnum.DELIVERED.getStatus());
        assertPojoEquals(dbOrder, deliveryReqVO);
        assertNotNull(dbOrder.getDeliveryTime());
    }

    @Test
    public void testReceiveOrder() {
        // mock 数据（TradeOrder）
        TradeOrderDO order = randomPojo(TradeOrderDO.class, o -> {
            o.setId(1L).setUserId(10L).setStatus(TradeOrderStatusEnum.DELIVERED.getStatus());
            o.setReceiveTime(null);
        });
        tradeOrderMapper.insert(order);
        // 准备参数
        Long id = 1L;
        Long userId = 10L;
        // mock 方法（支付单）

        // 调用
        tradeOrderUpdateService.receiveOrderByMember(userId, id);
        // 断言
        TradeOrderDO dbOrder = tradeOrderMapper.selectById(1L);
        assertEquals(dbOrder.getStatus(), TradeOrderStatusEnum.COMPLETED.getStatus());
        assertNotNull(dbOrder.getReceiveTime());
    }

}
