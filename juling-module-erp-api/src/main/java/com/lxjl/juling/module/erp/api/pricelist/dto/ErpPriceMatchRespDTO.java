package com.lxjl.juling.module.erp.api.pricelist.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 取价结果 DTO（跨模块）
 *
 * @author 亚特
 */
@Data
public class ErpPriceMatchRespDTO {

    /** 命中的价目表编号；为空表示没命中、价格来自物料主数据兜底 */
    private Long priceId;
    /** 命中的价目表名称 */
    private String priceName;
    /** 单价（**不含税，单位：元**）—— 注意订单项的价格是「分」，调用方需自行换算 */
    private BigDecimal price;
    /** 税率(%) */
    private BigDecimal taxPercent;
    /** 价格来源：PRICE_LIST 价目表 / PRODUCT 物料主数据兜底 */
    private String source;

}
