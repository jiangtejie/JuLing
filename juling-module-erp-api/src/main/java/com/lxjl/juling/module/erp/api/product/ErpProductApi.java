package com.lxjl.juling.module.erp.api.product;

import com.lxjl.juling.module.erp.api.product.dto.ErpProductRespDTO;

import java.util.Collection;
import java.util.List;

/**
 * ERP 物料（产品）API
 *
 * 门店订货链「订单工作台」：订单行只有商城 SKU（sku/spu），
 * 需要按 product_sku.bar_code = erp_product.bar_code 找到 ERP 物料，
 * 才能知道该物料「允许统配 / 允许直拨」以及参考进价。
 *
 * @author 亚特
 */
public interface ErpProductApi {

    /**
     * 按条码批量获得物料
     *
     * @param barCodes 条码列表
     * @return 物料列表（不存在的条码不会返回，由调用方兜底）
     */
    List<ErpProductRespDTO> getProductListByBarCodes(Collection<String> barCodes);

    /**
     * 获得物料
     *
     * @param id 物料编号
     * @return 物料；不存在时返回 null
     */
    ErpProductRespDTO getProduct(Long id);

    /**
     * 批量获得物料（按编号，用于列表页回显物料名称）
     *
     * @param ids 物料编号集合
     * @return 物料列表（不存在的编号不会返回）
     */
    List<ErpProductRespDTO> getProductList(Collection<Long> ids);

}
