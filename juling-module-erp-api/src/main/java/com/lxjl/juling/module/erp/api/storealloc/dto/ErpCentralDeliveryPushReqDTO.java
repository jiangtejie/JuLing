package com.lxjl.juling.module.erp.api.storealloc.dto;

import lombok.Data;

import java.util.List;

/**
 * 统配下推请求：门店要货单 → 配送出库单（ERP 销售出库）
 *
 * @author 亚特
 */
@Data
public class ErpCentralDeliveryPushReqDTO {

    /**
     * 源单编号（= trade_order.id）
     */
    private Long sourceOrderId;
    /**
     * 源单号（= trade_order.no）
     */
    private String sourceOrderNo;
    /**
     * 收货门店客户编号（erp_customer.id）
     */
    private Long customerId;
    /**
     * 发货仓库编号（中心库）；为空时取默认仓库
     */
    private Long warehouseId;
    /**
     * 结算账户编号
     */
    private Long accountId;
    /**
     * 销售员编号（AdminUserDO.id）
     */
    private Long saleUserId;
    /**
     * 备注
     */
    private String remark;
    /**
     * 出库行
     */
    private List<ErpStoreAllocItemDTO> items;

}
