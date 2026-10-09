package com.lxjl.juling.module.erp.api.pricelist;

import com.lxjl.juling.module.erp.api.pricelist.dto.ErpPriceMatchRespDTO;

/**
 * 价目表 API（跨模块）
 *
 * <p>供商城/门店订货链按「配送价目表」定价使用。
 *
 * @author 亚特
 */
public interface ErpPriceApi {

    /**
     * 取价
     *
     * @param priceType 价目表类型：PURCHASE 采购 / DELIVERY 配送
     * @param partnerId 适用对象编号（采购=供应商，配送=门店）；可为空
     * @param productId 物料编号
     * @return 命中的价格；没有命中且无兜底时返回 null
     */
    ErpPriceMatchRespDTO matchPrice(String priceType, Long partnerId, Long productId);

}
