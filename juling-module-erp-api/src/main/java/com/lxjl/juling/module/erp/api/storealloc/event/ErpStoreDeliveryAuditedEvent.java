package com.lxjl.juling.module.erp.api.storealloc.event;

import lombok.Data;
import lombok.experimental.Accessors;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 「门店要货 · 配送出库单审核通过」事件
 *
 * 发布方：ERP 销售出库审核（{@code ErpSaleOutServiceImpl#updateSaleOutStatus}），
 * 只在出库单能追溯到门店要货单（bill_relation：STORE_REQUISITION → DELIVERY_OUT）时发布。
 * 订阅方：商城交易模块（更新订单为已发货 + 生成门店收货单）。
 *
 * 为什么用同步 Spring 事件而不是 RPC：两个模块在同一个 JVM、同一个事务里，
 * 同步 {@code @EventListener} 让「出库扣库存」与「订单转已发货 + 建收货单」同事务提交，
 * 任一步失败整体回滚，不会出现「货发了但订单没转」的中间态。
 *
 * @author 亚特
 */
@Data
@Accessors(chain = true)
public class ErpStoreDeliveryAuditedEvent {

    /**
     * 配送出库单编号（erp_sale_out.id）
     */
    private Long saleOutId;
    /**
     * 配送出库单号（XSCK…）
     */
    private String saleOutNo;
    /**
     * 门店客户编号
     */
    private Long customerId;
    /**
     * 门店要货单编号（trade_order.id）
     */
    private Long sourceOrderId;
    /**
     * 门店要货单号
     */
    private String sourceOrderNo;
    /**
     * 出库金额合计（= 门店应付）
     */
    private BigDecimal totalPrice;
    /**
     * 出库（发货）时间
     */
    private LocalDateTime deliveryTime;
    /**
     * 出库明细
     */
    private List<Item> items;

    /**
     * 出库明细行
     */
    @Data
    @Accessors(chain = true)
    public static class Item {

        /**
         * 门店要货单行编号（trade_order_item.id；手工出库单为空）
         */
        private Long sourceItemId;
        /**
         * 物料编号
         */
        private Long productId;
        /**
         * 物料名称
         */
        private String productName;
        /**
         * 发货数量
         */
        private BigDecimal count;
        /**
         * 配送单价（门店进货成本）
         */
        private BigDecimal unitPrice;

    }

}
