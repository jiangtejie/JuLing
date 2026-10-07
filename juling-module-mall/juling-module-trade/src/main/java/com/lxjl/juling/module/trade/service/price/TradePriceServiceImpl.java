package com.lxjl.juling.module.trade.service.price;

import com.lxjl.juling.module.erp.api.pricelist.ErpPriceApi;
import com.lxjl.juling.module.erp.api.pricelist.dto.ErpPriceMatchRespDTO;
import com.lxjl.juling.module.erp.api.product.ErpProductApi;
import com.lxjl.juling.module.erp.api.product.dto.ErpProductRespDTO;
import com.lxjl.juling.module.product.api.sku.ProductSkuApi;
import com.lxjl.juling.module.product.api.sku.dto.ProductSkuRespDTO;
import com.lxjl.juling.module.product.api.spu.ProductSpuApi;
import com.lxjl.juling.module.product.api.spu.dto.ProductSpuRespDTO;
import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeProductSettlementRespVO;
import com.lxjl.juling.module.trade.service.price.bo.TradePriceCalculateReqBO;
import com.lxjl.juling.module.trade.service.price.bo.TradePriceCalculateRespBO;
import com.lxjl.juling.module.trade.service.price.calculator.TradePriceCalculatorHelper;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Map;

import cn.hutool.core.util.StrUtil;
import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.*;
import static com.lxjl.juling.module.product.enums.ErrorCodeConstants.SKU_NOT_EXISTS;
import static com.lxjl.juling.module.product.enums.ErrorCodeConstants.SKU_STOCK_NOT_ENOUGH;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.PRICE_CALCULATE_PAY_PRICE_ILLEGAL;

/**
 * 价格计算 Service 实现类
 *
 * @author 亚特
 */
@Service
@Validated
@Slf4j
public class TradePriceServiceImpl implements TradePriceService {

    @Resource
    private ProductSkuApi productSkuApi;
    @Resource
    private ProductSpuApi productSpuApi;
    @Resource
    private ErpPriceApi erpPriceApi;
    @Resource
    private ErpProductApi erpProductApi;

    /** 价目表类型：配送（门店订货的结算价） */
    private static final String PRICE_TYPE_DELIVERY = "DELIVERY";

    @Override
    public TradePriceCalculateRespBO calculateOrderPrice(TradePriceCalculateReqBO calculateReqBO) {
        // 1.1 获得商品 SKU 数组
        List<ProductSkuRespDTO> skuList = checkSkuList(calculateReqBO);
        // 1.2 获得商品 SPU 数组
        List<ProductSpuRespDTO> spuList = checkSpuList(skuList);

        // 2.1 计算价格
        // 说明：原先这里会遍历 {@code List<TradePriceCalculator>} 做营销/会员价/运费等二次计算。
        // 亚特的商城只做私域订货（线下转账、中心库配送、无营销），这些计算器已随营销与会员中心一并物理删除，
        // 价格就是「SKU 单价 × 数量」，因此不再保留空的扩展点。
        TradePriceCalculateRespBO calculateRespBO = TradePriceCalculatorHelper
                .buildCalculateResp(calculateReqBO, spuList, skuList);
        // 2.1.1 配送价目表定价：门店订货的结算价以配送价目表为准，没命中才用 SKU 价
        applyDeliveryPrice(calculateReqBO, skuList, calculateRespBO);
        // 2.2  如果最终支付金额小于等于 0，则抛出业务异常
        if (calculateRespBO.getPrice().getPayPrice() <= 0) {
            log.error("[calculatePrice][价格计算不正确，请求 calculateReqDTO({})，结果 priceCalculate({})]",
                    calculateReqBO, calculateRespBO);
            throw exception(PRICE_CALCULATE_PAY_PRICE_ILLEGAL);
        }
        return calculateRespBO;
    }

    /**
     * 用配送价目表给订单项定价
     *
     * <p>链路：SKU → 条码 → ERP 物料（**这是既有的对应约定**，见 TradeOrderWorkbenchServiceImpl:137）
     * → 按「门店 + 物料 + 日期」取配送价 → 覆盖订单项单价。
     *
     * <p>**任何一步拿不到就保持 SKU 价**（条码没维护、物料不存在、价目表没命中），
     * 保证不会因为价目表没配好就让门店下不了单。
     *
     * <p>单位换算：价目表存的是**元**，订单项的价格是**分**。
     */
    private void applyDeliveryPrice(TradePriceCalculateReqBO reqBO, List<ProductSkuRespDTO> skuList,
                                    TradePriceCalculateRespBO calculateRespBO) {
        Map<Long, ProductSkuRespDTO> skuMap = convertMap(skuList, ProductSkuRespDTO::getId);
        // SKU 条码 → ERP 物料
        List<String> barCodes = skuList.stream().map(ProductSkuRespDTO::getBarCode)
                .filter(StrUtil::isNotBlank).distinct().toList();
        if (barCodes.isEmpty()) {
            return;
        }
        Map<String, Long> barCodeProductIdMap = convertMap(erpProductApi.getProductListByBarCodes(barCodes),
                ErpProductRespDTO::getBarCode, ErpProductRespDTO::getId);
        calculateRespBO.getItems().forEach(item -> {
            ProductSkuRespDTO sku = skuMap.get(item.getSkuId());
            Long productId = sku == null ? null : barCodeProductIdMap.get(sku.getBarCode());
            if (productId == null) {
                return;
            }
            ErpPriceMatchRespDTO match = erpPriceApi.matchPrice(PRICE_TYPE_DELIVERY, reqBO.getCustomerId(), productId);
            if (match == null || match.getPrice() == null) {
                return;
            }
            int priceInCent = match.getPrice().multiply(BigDecimal.valueOf(100))
                    .setScale(0, RoundingMode.HALF_UP).intValueExact();
            item.setPrice(priceInCent).setPayPrice(priceInCent * item.getCount());
        });
        // 单价被覆盖了，合计要重算
        TradePriceCalculatorHelper.recountAllPrice(calculateRespBO);
    }

    private List<ProductSkuRespDTO> checkSkuList(TradePriceCalculateReqBO reqBO) {
        // 获得商品 SKU 数组
        Map<Long, Integer> skuIdCountMap = convertMap(reqBO.getItems(),
                TradePriceCalculateReqBO.Item::getSkuId, TradePriceCalculateReqBO.Item::getCount);
        List<ProductSkuRespDTO> skus = productSkuApi.getSkuList(skuIdCountMap.keySet());

        // 校验商品 SKU
        skus.forEach(sku -> {
            Integer count = skuIdCountMap.get(sku.getId());
            if (count == null) {
                throw exception(SKU_NOT_EXISTS);
            }
            if (count > sku.getStock()) {
                throw exception(SKU_STOCK_NOT_ENOUGH);
            }
        });
        return skus;
    }

    private List<ProductSpuRespDTO> checkSpuList(List<ProductSkuRespDTO> skuList) {
        return productSpuApi.validateSpuList(convertSet(skuList, ProductSkuRespDTO::getSpuId));
    }

    @Override
    public List<AppTradeProductSettlementRespVO> calculateProductPrice(Long userId, List<Long> spuIds) {
        // 1. 获得 SPU 与 SKU 的映射
        List<ProductSkuRespDTO> allSkuList = productSkuApi.getSkuListBySpuId(spuIds);
        Map<Long, List<ProductSkuRespDTO>> spuIdAndSkuListMap = convertMultiMap(allSkuList, ProductSkuRespDTO::getSpuId);

        // 2. 价格计算
        return convertList(spuIds, spuId -> {
            AppTradeProductSettlementRespVO spuVO = new AppTradeProductSettlementRespVO().setSpuId(spuId);
            // 2.1 商品 SKU
            List<ProductSkuRespDTO> skuList = spuIdAndSkuListMap.get(spuId);
            spuVO.setSkus(convertList(skuList, sku -> new AppTradeProductSettlementRespVO.Sku().setId(sku.getId())));
            return spuVO;
        });
    }

}
