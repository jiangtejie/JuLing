package com.lxjl.juling.module.erp.api.storealloc.event;

import lombok.Data;
import lombok.experimental.Accessors;

/**
 * 「门店要货 · 配送出库单反审核」事件
 *
 * 用途：交易模块据此作废门店收货单并把订单退回「待发货」。
 * 若门店已经确认收货，订阅方抛业务异常 → 整个事务回滚 → 出库单一并反审核失败（会计上不允许先收货再撤发货）。
 *
 * @author 亚特
 */
@Data
@Accessors(chain = true)
public class ErpStoreDeliveryCancelledEvent {

    /**
     * 配送出库单编号
     */
    private Long saleOutId;
    /**
     * 配送出库单号
     */
    private String saleOutNo;
    /**
     * 门店要货单编号（trade_order.id）
     */
    private Long sourceOrderId;
    /**
     * 门店要货单号
     */
    private String sourceOrderNo;

}
