package com.lxjl.juling.module.erp.api.storealloc.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 门店要货下推行 DTO（配送出库 / 采购订单共用）
 *
 * @author 亚特
 */
@Data
public class ErpStoreAllocItemDTO {

    /**
     * 源单行编号（= trade_order_item.id）
     *
     * 用于写 bill_relation 的行级关联，实现"同一要货单行只能下推一次"。
     */
    private Long sourceItemId;
    /**
     * ERP 物料编号
     */
    private Long productId;
    /**
     * 数量
     */
    private BigDecimal count;
    /**
     * 单价，单位：元
     */
    private BigDecimal productPrice;
    /**
     * 税率，百分比
     */
    private BigDecimal taxPercent;

}
