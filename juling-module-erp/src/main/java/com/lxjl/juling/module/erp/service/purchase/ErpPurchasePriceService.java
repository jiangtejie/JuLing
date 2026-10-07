package com.lxjl.juling.module.erp.service.purchase;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.erp.controller.admin.purchase.vo.price.ErpPurchasePriceMatchRespVO;
import com.lxjl.juling.module.erp.controller.admin.purchase.vo.price.ErpPurchasePricePageReqVO;
import com.lxjl.juling.module.erp.controller.admin.purchase.vo.price.ErpPurchasePriceSaveReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchasePriceDO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchasePriceItemDO;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;

/**
 * ERP 采购价目表 Service 接口
 *
 * @author 亚特
 */
public interface ErpPurchasePriceService {

    Long createPurchasePrice(ErpPurchasePriceSaveReqVO createReqVO);

    void updatePurchasePrice(ErpPurchasePriceSaveReqVO updateReqVO);

    void deletePurchasePrice(Long id);

    void deletePurchasePriceList(List<Long> ids);

    ErpPurchasePriceDO getPurchasePrice(Long id);

    List<ErpPurchasePriceItemDO> getPurchasePriceItemList(Long priceId);

    /** 分页列表用：一次取回多张价目表的明细，避免 N+1 */
    List<ErpPurchasePriceItemDO> getPurchasePriceItemListByPriceIds(Collection<Long> priceIds);

    PageResult<ErpPurchasePriceDO> getPurchasePricePage(ErpPurchasePricePageReqVO pageReqVO);

    /** 取价用：一次取回多张价目表 */
    List<ErpPurchasePriceDO> getPurchasePriceList(Collection<Long> ids);

    /**
     * 取价：给定「供应商 + 物料 + 数量 + 日期」，返回适用的单价与税率
     *
     * <p>优先级（详见 sql/local/65_purchase_price.sql）：
     * <ol>
     *   <li>供应商专项价目表 优先于 通用价目表（supplier_id 为空）</li>
     *   <li>同层级内：默认价目表 优先</li>
     *   <li>再：生效日期新 优先</li>
     *   <li>再：数量区间档位高 优先（阶梯价取中到的那一档）</li>
     * </ol>
     * 过滤条件：价目表已启用 + 当日落在有效期内 + 物料匹配 + 数量落在 [fromQty, toQty)。
     *
     * <p>价目表都没命中时，兜底取物料主数据的 purchase_price（老数据不失效），
     * 此时返回结果的 source 为 PRODUCT。
     *
     * @return 命中的价格；物料不存在或没有任何价格来源时返回 null
     */
    ErpPurchasePriceMatchRespVO matchPrice(Long supplierId, Long productId, BigDecimal quantity, LocalDate date);

}
