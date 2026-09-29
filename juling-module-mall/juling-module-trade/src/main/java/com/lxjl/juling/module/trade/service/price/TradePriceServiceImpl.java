package com.lxjl.juling.module.trade.service.price;

import cn.hutool.core.collection.CollUtil;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.product.api.sku.ProductSkuApi;
import com.lxjl.juling.module.product.api.sku.dto.ProductSkuRespDTO;
import com.lxjl.juling.module.product.api.spu.ProductSpuApi;
import com.lxjl.juling.module.product.api.spu.dto.ProductSpuRespDTO;
import com.lxjl.juling.module.promotion.api.reward.RewardActivityApi;
import com.lxjl.juling.module.promotion.api.reward.dto.RewardActivityMatchRespDTO;
import com.lxjl.juling.module.trade.controller.app.order.vo.AppTradeProductSettlementRespVO;
import com.lxjl.juling.module.trade.service.price.bo.TradePriceCalculateReqBO;
import com.lxjl.juling.module.trade.service.price.bo.TradePriceCalculateRespBO;
import com.lxjl.juling.module.trade.service.price.calculator.TradePriceCalculator;
import com.lxjl.juling.module.trade.service.price.calculator.TradePriceCalculatorHelper;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import java.util.List;
import java.util.Map;

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
    private RewardActivityApi rewardActivityApi;

    @Resource
    private List<TradePriceCalculator> priceCalculators;

    @Override
    public TradePriceCalculateRespBO calculateOrderPrice(TradePriceCalculateReqBO calculateReqBO) {
        // 1.1 获得商品 SKU 数组
        List<ProductSkuRespDTO> skuList = checkSkuList(calculateReqBO);
        // 1.2 获得商品 SPU 数组
        List<ProductSpuRespDTO> spuList = checkSpuList(skuList);

        // 2.1 计算价格
        TradePriceCalculateRespBO calculateRespBO = TradePriceCalculatorHelper
                .buildCalculateResp(calculateReqBO, spuList, skuList);
        priceCalculators.forEach(calculator -> calculator.calculate(calculateReqBO, calculateRespBO));
        // 2.2  如果最终支付金额小于等于 0，则抛出业务异常
        if (calculateReqBO.getPointActivityId() == null // 积分订单，允许支付金额为 0
                && calculateRespBO.getPrice().getPayPrice() <= 0) {
            log.error("[calculatePrice][价格计算不正确，请求 calculateReqDTO({})，结果 priceCalculate({})]",
                    calculateReqBO, calculateRespBO);
            throw exception(PRICE_CALCULATE_PAY_PRICE_ILLEGAL);
        }
        return calculateRespBO;
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
        // 1.1 获得 SPU 与 SKU 的映射
        List<ProductSkuRespDTO> allSkuList = productSkuApi.getSkuListBySpuId(spuIds);
        Map<Long, List<ProductSkuRespDTO>> spuIdAndSkuListMap = convertMultiMap(allSkuList, ProductSkuRespDTO::getSpuId);
        // 1.2 获得满减送活动
        List<RewardActivityMatchRespDTO> rewardActivityMap = rewardActivityApi.getMatchRewardActivityListBySpuIds(spuIds);

        // 2. 价格计算
        return convertList(spuIds, spuId -> {
            AppTradeProductSettlementRespVO spuVO = new AppTradeProductSettlementRespVO().setSpuId(spuId);
            // 2.1 商品 SKU
            List<ProductSkuRespDTO> skuList = spuIdAndSkuListMap.get(spuId);
            spuVO.setSkus(convertList(skuList, sku -> new AppTradeProductSettlementRespVO.Sku().setId(sku.getId())));
            // 2.2 满减送活动
            RewardActivityMatchRespDTO rewardActivity = CollUtil.findOne(rewardActivityMap,
                    activity -> CollUtil.contains(activity.getSpuIds(), spuId));
            spuVO.setRewardActivity(BeanUtils.toBean(rewardActivity, AppTradeProductSettlementRespVO.RewardActivity.class));
            return spuVO;
        });
    }

}
