package com.lxjl.juling.module.trade.service.order.listener;

import com.lxjl.juling.module.erp.api.storealloc.event.ErpStoreDeliveryAuditedEvent;
import com.lxjl.juling.module.erp.api.storealloc.event.ErpStoreDeliveryCancelledEvent;
import com.lxjl.juling.module.trade.service.order.TradeStoreReceiptService;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * 门店配送事件监听（ERP 销售出库审核 / 反审核 → 商城交易侧收货单）
 *
 * 为什么是同步 {@code @EventListener} 而不是 MQ / 事务后事件：
 *   ERP 出库与商城收货单必须**同事务**成败一致 —— 出库扣了中心库库存却建不出收货单，
 *   或者收货单建好了出库又回滚，都会让「中心库 → 门店」这条链对不上账。
 *   两个模块同 JVM 同数据源，同步事件即可获得同事务语义；监听器抛异常会让出库审核整体回滚。
 *
 * @author 亚特
 */
@Slf4j
@Component
public class TradeStoreDeliveryListener {

    @Resource
    private TradeStoreReceiptService storeReceiptService;

    @EventListener
    public void onDeliveryAudited(ErpStoreDeliveryAuditedEvent event) {
        log.info("[onDeliveryAudited][配送出库单({}) 审核，要货单({})]",
                event.getSaleOutNo(), event.getSourceOrderNo());
        storeReceiptService.createReceiptByDelivery(event);
    }

    @EventListener
    public void onDeliveryCancelled(ErpStoreDeliveryCancelledEvent event) {
        log.info("[onDeliveryCancelled][配送出库单({}) 反审核，要货单({})]",
                event.getSaleOutNo(), event.getSourceOrderNo());
        storeReceiptService.cancelReceiptByDelivery(event);
    }

}
