package com.lxjl.juling.module.erp.api.storealloc.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 门店要货下推记录 DTO（读 bill_relation）
 *
 * 工作台用它回显"这一行已经下推成了哪张单"，并作为重复下推的判据。
 *
 * @author 亚特
 */
@Data
public class ErpStoreAllocPushedDTO {

    /**
     * 源单行编号（= trade_order_item.id）
     */
    private Long sourceItemId;
    /**
     * 目标单据类型（bill_type.code）
     */
    private String billType;
    /**
     * 目标单据编号
     */
    private Long billId;
    /**
     * 目标单据号
     */
    private String billNo;
    /**
     * 下推数量
     */
    private BigDecimal qty;

}
