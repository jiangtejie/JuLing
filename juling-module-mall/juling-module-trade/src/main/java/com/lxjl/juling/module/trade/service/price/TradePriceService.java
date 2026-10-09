package com.lxjl.juling.module.trade.service.price;

import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeProductSettlementRespVO;
import com.lxjl.juling.module.trade.service.price.bo.TradePriceCalculateReqBO;
import com.lxjl.juling.module.trade.service.price.bo.TradePriceCalculateRespBO;
import jakarta.validation.Valid;

import java.util.Collection;
import java.util.List;
import java.util.Map;

/**
 * 价格计算 Service 接口
 *
 * @author 亚特
 */
public interface TradePriceService {

    /**
     * 【订单】价格计算
     *
     * @param calculateReqDTO 计算信息
     * @return 计算结果
     */
    TradePriceCalculateRespBO calculateOrderPrice(@Valid TradePriceCalculateReqBO calculateReqDTO);

    /**
     * 门店维度的 SKU 实际下单价（单位：分）
     *
     * <p>**与下单算价同源** —— 商品列表/详情必须用它来展示，否则会出现
     * 「浏览时看到商城价、结算时变成配送价」。两者共用同一个解析函数，不是靠约定对齐。
     *
     * @param customerId 门店（erp_customer.id）；为空时只匹配通用范围的配送价目表
     * @param skuIds     SKU 编号
     * @return skuId → 单价（分）；**未命中的不返回**，调用方回退 SKU 价
     */
    Map<Long, Integer> getStoreSkuPriceMap(Long customerId, Collection<Long> skuIds);

    /**
     * 【商品】价格计算，用于商品列表、商品详情
     *
     * @param userId 用户编号，允许为空
     * @param spuIds 商品 SPU 编号数组
     * @return 计算结果
     */
    List<AppTradeProductSettlementRespVO> calculateProductPrice(Long userId, List<Long> spuIds);

}
