package com.lxjl.juling.module.erp.api.storealloc.dto;

import lombok.Data;

import java.util.List;

/**
 * 直拨下推请求：门店要货单 → 采购订单（供应商直送门店，不入中心库）
 *
 * @author 亚特
 */
@Data
public class ErpDirectPurchasePushReqDTO {

    /**
     * 源单编号（= trade_order.id）
     */
    private Long sourceOrderId;
    /**
     * 源单号（= trade_order.no）
     */
    private String sourceOrderNo;
    /**
     * 供应商编号（erp_supplier.id）
     */
    private Long supplierId;
    /**
     * 结算账户编号
     */
    private Long accountId;
    /**
     * 备注（含收货门店与地址，供供应商直送）
     */
    private String remark;
    /**
     * 采购行
     */
    private List<ErpStoreAllocItemDTO> items;

}
