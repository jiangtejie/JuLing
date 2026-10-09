package com.lxjl.juling.module.erp.api.product.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * ERP 产品 Response DTO
 *
 * 门店订货链「订单工作台」用：商城 SKU → ERP 物料（按 bar_code 对齐），
 * 取物料的分料属性（允许统配/允许直拨）与参考单价。
 *
 * @author 亚特
 */
@Data
public class ErpProductRespDTO {

    /**
     * 产品编号
     */
    private Long id;
    /**
     * 产品名称
     */
    private String name;
    /**
     * 产品条码
     *
     * 与商城 product_sku.bar_code 对齐，是「商城商品 ↔ ERP 物料」的对应关系。
     */
    private String barCode;
    /**
     * 单位编号
     */
    private Long unitId;
    /**
     * 产品状态
     */
    private Integer status;
    /**
     * 采购价格，单位：元
     */
    private BigDecimal purchasePrice;
    /**
     * 销售价格，单位：元
     */
    private BigDecimal salePrice;
    /**
     * 是否允许统配
     */
    private Boolean allowCentral;
    /**
     * 是否允许直拨
     */
    private Boolean allowDirect;

}
