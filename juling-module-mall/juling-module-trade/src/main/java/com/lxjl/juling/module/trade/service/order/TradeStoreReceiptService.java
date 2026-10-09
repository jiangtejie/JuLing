package com.lxjl.juling.module.trade.service.order;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.erp.api.storealloc.event.ErpStoreDeliveryAuditedEvent;
import com.lxjl.juling.module.erp.api.storealloc.event.ErpStoreDeliveryCancelledEvent;
import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeStoreReceiptPageReqVO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderReceiptDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderReceiptItemDO;
import com.lxjl.juling.module.trade.service.order.bo.TradeStoreReceiptSubmitReqBO;

import java.util.List;

/**
 * 门店收货 Service 接口
 *
 * 覆盖「配送出库 → 门店收货 → 门店库存 → 门店往来」这一段闭环（见 docs/store-receipt-and-receivables-design.md）：
 *   1) 配送出库单审核 → 订单转「已发货」+ 生成「待确认」收货单（应收数量 = 实际发货数量）；
 *   2) 门店在 H5 逐行填实收数量（可多收 / 少收 / 破损，必须填差异原因）→ 提交；
 *   3) 提交时：实收数量按批次记入门店仓（门店库存账），差异金额调整门店往来台账，订单聚合收货状态；
 *   4) 配送出库单反审核 → 作废待确认收货单并把订单退回「待发货」（已确认则拒绝，必须先走退货）。
 *
 * @author 亚特
 */
public interface TradeStoreReceiptService {

    /**
     * 配送出库单审核：订单转已发货 + 生成待确认收货单（幂等：同一出库单只建一张）
     *
     * @param event 配送出库事件
     */
    void createReceiptByDelivery(ErpStoreDeliveryAuditedEvent event);

    /**
     * 配送出库单反审核：作废待确认收货单 + 订单退回待发货；已确认收货则抛业务异常阻止反审核
     */
    void cancelReceiptByDelivery(ErpStoreDeliveryCancelledEvent event);

    /**
     * 提交门店收货确认：实收入门店仓 + 差异调整门店往来 + 订单收货状态聚合
     *
     * @param reqBO 提交内容
     * @return 收货单编号
     */
    Long submitReceipt(TradeStoreReceiptSubmitReqBO reqBO);

    /**
     * 作废收货单（只允许「待确认」状态；已确认的必须走门店退货流程）
     */
    void cancelReceipt(Long id, String reason);

    /**
     * 获得收货单
     */
    TradeOrderReceiptDO getReceipt(Long id);

    /**
     * 获得订单当前有效的收货单（未作废）
     */
    TradeOrderReceiptDO getReceiptByOrderId(Long orderId);

    /**
     * 获得收货单明细
     */
    List<TradeOrderReceiptItemDO> getReceiptItemList(Long receiptId);

    /**
     * 后台收货单分页
     */
    PageResult<TradeOrderReceiptDO> getReceiptPage(TradeStoreReceiptPageReqVO pageReqVO);

    /**
     * 会员的待收货分页（H5）
     */
    PageResult<TradeOrderReceiptDO> getPendingPageByMember(Long memberUserId, Integer pageNo, Integer pageSize);

}
