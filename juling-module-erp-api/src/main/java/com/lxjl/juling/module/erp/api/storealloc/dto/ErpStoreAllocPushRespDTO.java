package com.lxjl.juling.module.erp.api.storealloc.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 门店要货下推结果 DTO
 *
 * @author 亚特
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ErpStoreAllocPushRespDTO {

    /**
     * 目标单据类型（bill_type.code，如 DELIVERY_OUT 配送出库 / PURCHASE_ORDER 采购订单）
     */
    private String billType;
    /**
     * 目标单据编号
     */
    private Long billId;
    /**
     * 目标单据号（如 XSCK20260928000001）
     */
    private String billNo;

}
