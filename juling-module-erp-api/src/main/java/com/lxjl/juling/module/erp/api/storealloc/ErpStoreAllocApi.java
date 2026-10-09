package com.lxjl.juling.module.erp.api.storealloc;

import com.lxjl.juling.module.erp.api.storealloc.dto.ErpCentralDeliveryPushReqDTO;
import com.lxjl.juling.module.erp.api.storealloc.dto.ErpDirectPurchasePushReqDTO;
import com.lxjl.juling.module.erp.api.storealloc.dto.ErpStoreAllocPushedDTO;
import com.lxjl.juling.module.erp.api.storealloc.dto.ErpStoreAllocPushRespDTO;

import java.util.List;

/**
 * 门店要货「分料下推」API（订单工作台 → ERP 单据）
 *
 * 统配（CENTRAL）：生成配送出库单（ERP 销售出库，bill_type = DELIVERY_OUT）；
 * 直拨（DIRECT） ：生成采购订单（bill_type = PURCHASE_ORDER），供应商直送门店。
 *
 * 两类下推都会：用单据平台生成单号、写 bill_relation（要货单行 → 目标单）与 bill_log。
 * 单据状态一律落「待审核」，**不动库存**（库存变动仍由 ERP 单据审核触发）。
 *
 * @author 亚特
 */
public interface ErpStoreAllocApi {

    /**
     * 统配下推：生成配送出库单（ERP 销售出库）
     *
     * @param reqDTO 下推请求
     * @return 目标单据（单号/编号/类型）
     */
    ErpStoreAllocPushRespDTO pushCentralDelivery(ErpCentralDeliveryPushReqDTO reqDTO);

    /**
     * 直拨下推：生成采购订单（供应商直送门店）
     *
     * @param reqDTO 下推请求
     * @return 目标单据（单号/编号/类型）
     */
    ErpStoreAllocPushRespDTO pushDirectPurchase(ErpDirectPurchasePushReqDTO reqDTO);

    /**
     * 查询某张要货单已下推的单据（行级）
     *
     * @param sourceOrderId 要货单编号（= trade_order.id）
     * @return 下推记录（含目标单据类型/单号/数量）
     */
    List<ErpStoreAllocPushedDTO> getPushedList(Long sourceOrderId);

}
