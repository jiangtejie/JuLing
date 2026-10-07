package com.lxjl.juling.module.erp.service.purchase;

import cn.hutool.core.collection.CollUtil;
import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.erp.controller.admin.purchase.vo.price.ErpPurchasePriceMatchRespVO;
import com.lxjl.juling.module.erp.controller.admin.purchase.vo.price.ErpPurchasePricePageReqVO;
import com.lxjl.juling.module.erp.controller.admin.purchase.vo.price.ErpPurchasePriceSaveReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.product.ErpProductDO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchasePriceDO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchasePriceItemDO;
import com.lxjl.juling.module.erp.dal.mysql.product.ErpProductMapper;
import com.lxjl.juling.module.erp.dal.mysql.purchase.ErpPurchasePriceItemMapper;
import com.lxjl.juling.module.erp.dal.mysql.purchase.ErpPurchasePriceMapper;
import com.lxjl.juling.module.system.api.code.CodeRuleApi;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.*;
import static com.lxjl.juling.module.erp.enums.ErrorCodeConstants.*;

/**
 * ERP 采购价目表 Service 实现类
 *
 * @author 亚特
 */
@Service
@Validated
public class ErpPurchasePriceServiceImpl implements ErpPurchasePriceService {

    /** 价格来源：价目表命中 */
    private static final String SOURCE_PRICE_LIST = "PRICE_LIST";
    /** 价格来源：物料主数据兜底 */
    private static final String SOURCE_PRODUCT = "PRODUCT";

    @Resource
    private ErpPurchasePriceMapper purchasePriceMapper;
    @Resource
    private ErpPurchasePriceItemMapper purchasePriceItemMapper;
    @Resource
    private ErpProductMapper productMapper;
    @Resource
    private CodeRuleApi codeRuleApi;

    @Override
    @Transactional(rollbackFor = Exception.class) // 与编码取号同事务，避免建档失败却消耗号段
    public Long createPurchasePrice(ErpPurchasePriceSaveReqVO createReqVO) {
        validateItems(createReqVO.getItems());
        ErpPurchasePriceDO price = BeanUtils.toBean(createReqVO, ErpPurchasePriceDO.class);
        price.setCode(codeRuleApi.generateCode("erp_purchase_price"));
        purchasePriceMapper.insert(price);
        insertItems(price.getId(), createReqVO.getItems());
        return price.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updatePurchasePrice(ErpPurchasePriceSaveReqVO updateReqVO) {
        validatePurchasePriceExists(updateReqVO.getId());
        validateItems(updateReqVO.getItems());
        // 1. 更新表头
        purchasePriceMapper.updateById(BeanUtils.toBean(updateReqVO, ErpPurchasePriceDO.class));
        // 2. 明细整体替换：先删后插。明细行没有外部引用，整体替换比 diff 更简单可靠
        purchasePriceItemMapper.deleteByPriceId(updateReqVO.getId());
        insertItems(updateReqVO.getId(), updateReqVO.getItems());
    }

    private void insertItems(Long priceId, List<ErpPurchasePriceSaveReqVO.Item> items) {
        List<ErpPurchasePriceItemDO> list = BeanUtils.toBean(items, ErpPurchasePriceItemDO.class);
        list.forEach(item -> {
            item.setId(null); // 前端可能回传旧行 id，与「先删后插」冲突，统一置空走新主键
            item.setPriceId(priceId);
        });
        purchasePriceItemMapper.insertBatch(list);
    }

    @Override
    public void deletePurchasePrice(Long id) {
        validatePurchasePriceExists(id);
        // 采购订单只存快照价、不引用价目表，所以这里不需要引用校验
        purchasePriceMapper.deleteById(id);
        purchasePriceItemMapper.deleteByPriceId(id);
    }

    @Override
    public void deletePurchasePriceList(List<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return;
        }
        purchasePriceMapper.deleteByIds(ids);
        purchasePriceItemMapper.deleteByPriceIds(ids);
    }

    /**
     * 校验明细
     *
     * <p>除了区间本身要 起 &lt; 止，还要求**同一物料的两行区间不重叠** ——
     * 重叠会让取价结果取决于排序细节，属于「配置错了但表现随机」的坑，所以保存在这里就拦下。
     */
    private void validateItems(List<ErpPurchasePriceSaveReqVO.Item> items) {
        items.forEach(item -> {
            if (item.getFromQty() != null && item.getToQty() != null
                    && item.getFromQty().compareTo(item.getToQty()) >= 0) {
                throw exception(PURCHASE_PRICE_ITEM_QTY_RANGE_ILLEGAL, item.getFromQty(), item.getToQty());
            }
        });
        Map<Long, List<ErpPurchasePriceSaveReqVO.Item>> byProduct =
                convertMultiMap(items, ErpPurchasePriceSaveReqVO.Item::getProductId);
        byProduct.forEach((productId, list) -> {
            for (int i = 0; i < list.size(); i++) {
                for (int j = i + 1; j < list.size(); j++) {
                    if (isOverlap(list.get(i), list.get(j))) {
                        throw exception(PURCHASE_PRICE_ITEM_QTY_OVERLAP, productId);
                    }
                }
            }
        });
    }

    /** 两个数量区间是否重叠（半开区间 [from, to)；null 表示无界） */
    private boolean isOverlap(ErpPurchasePriceSaveReqVO.Item a, ErpPurchasePriceSaveReqVO.Item b) {
        boolean aUpperGtBLower = a.getToQty() == null || b.getFromQty() == null
                || a.getToQty().compareTo(b.getFromQty()) > 0;
        boolean bUpperGtALower = b.getToQty() == null || a.getFromQty() == null
                || b.getToQty().compareTo(a.getFromQty()) > 0;
        return aUpperGtBLower && bUpperGtALower;
    }

    private void validatePurchasePriceExists(Long id) {
        if (purchasePriceMapper.selectById(id) == null) {
            throw exception(PURCHASE_PRICE_NOT_EXISTS);
        }
    }

    @Override
    public ErpPurchasePriceDO getPurchasePrice(Long id) {
        return purchasePriceMapper.selectById(id);
    }

    @Override
    public List<ErpPurchasePriceItemDO> getPurchasePriceItemList(Long priceId) {
        return purchasePriceItemMapper.selectListByPriceId(priceId);
    }

    @Override
    public List<ErpPurchasePriceItemDO> getPurchasePriceItemListByPriceIds(Collection<Long> priceIds) {
        if (CollUtil.isEmpty(priceIds)) {
            return List.of();
        }
        return purchasePriceItemMapper.selectListByPriceIds(priceIds);
    }

    @Override
    public PageResult<ErpPurchasePriceDO> getPurchasePricePage(ErpPurchasePricePageReqVO pageReqVO) {
        return purchasePriceMapper.selectPage(pageReqVO);
    }

    @Override
    public List<ErpPurchasePriceDO> getPurchasePriceList(Collection<Long> ids) {
        return purchasePriceMapper.selectByIds(ids);
    }

    @Override
    public ErpPurchasePriceMatchRespVO matchPrice(Long supplierId, Long productId, BigDecimal quantity, LocalDate date) {
        if (productId == null) {
            return null;
        }
        LocalDate day = date != null ? date : LocalDate.now();
        BigDecimal qty = quantity != null ? quantity : BigDecimal.ONE;

        // 1. 该物料在所有价目表里的候选行
        List<ErpPurchasePriceItemDO> candidates = purchasePriceItemMapper.selectListByProductId(productId);
        if (CollUtil.isEmpty(candidates)) {
            return fallbackToProduct(productId);
        }
        // 2. 一次取回这些行的表头，在内存里过滤（数据量小，避免拼复杂 join SQL）
        Map<Long, ErpPurchasePriceDO> headerMap = convertMap(
                purchasePriceMapper.selectByIds(convertSet(candidates, ErpPurchasePriceItemDO::getPriceId)),
                ErpPurchasePriceDO::getId);
        // 3. 过滤
        List<ErpPurchasePriceItemDO> hits = convertList(candidates, item -> {
            ErpPurchasePriceDO header = headerMap.get(item.getPriceId());
            if (header == null || !CommonStatusEnum.ENABLE.getStatus().equals(header.getStatus())) {
                return null;
            }
            if (header.getEffectiveDate() != null && header.getEffectiveDate().isAfter(day)) {
                return null;
            }
            if (header.getExpiryDate() != null && header.getExpiryDate().isBefore(day)) {
                return null;
            }
            // 供应商：专项价目表要求精确匹配；通用价目表（supplierId 为空）谁都适用
            if (header.getSupplierId() != null && !header.getSupplierId().equals(supplierId)) {
                return null;
            }
            // 数量区间 [fromQty, toQty)
            if (item.getFromQty() != null && qty.compareTo(item.getFromQty()) < 0) {
                return null;
            }
            if (item.getToQty() != null && qty.compareTo(item.getToQty()) >= 0) {
                return null;
            }
            return item;
        });
        if (CollUtil.isEmpty(hits)) {
            return fallbackToProduct(productId);
        }
        // 4. 按优先级排序取第一条
        hits.sort((a, b) -> {
            ErpPurchasePriceDO ha = headerMap.get(a.getPriceId());
            ErpPurchasePriceDO hb = headerMap.get(b.getPriceId());
            // 供应商专项 优先于 通用
            int c = Boolean.compare(ha.getSupplierId() == null, hb.getSupplierId() == null);
            if (c != 0) {
                return c;
            }
            // 默认价目表优先
            c = Boolean.compare(Boolean.TRUE.equals(hb.getIsDefault()), Boolean.TRUE.equals(ha.getIsDefault()));
            if (c != 0) {
                return c;
            }
            // 生效日期新的优先
            c = compareNullableDesc(ha.getEffectiveDate(), hb.getEffectiveDate());
            if (c != 0) {
                return c;
            }
            // 阶梯档位高的优先
            return compareNullableDesc(a.getFromQty(), b.getFromQty());
        });
        ErpPurchasePriceItemDO best = hits.get(0);
        ErpPurchasePriceDO bestHeader = headerMap.get(best.getPriceId());
        return new ErpPurchasePriceMatchRespVO()
                .setPriceId(best.getPriceId()).setItemId(best.getId())
                .setPriceCode(bestHeader.getCode()).setPriceName(bestHeader.getName())
                .setPrice(best.getPrice()).setTaxPercent(best.getTaxPercent())
                .setSource(SOURCE_PRICE_LIST);
    }

    /** 价目表没命中时的兜底：物料主数据上的 purchase_price */
    private ErpPurchasePriceMatchRespVO fallbackToProduct(Long productId) {
        ErpProductDO product = productMapper.selectById(productId);
        if (product == null || product.getPurchasePrice() == null) {
            return null;
        }
        // 物料主数据上没有税率字段，税率交给供应商的开票税点兜底（见采购订单的 validatePurchaseOrderItems）
        return new ErpPurchasePriceMatchRespVO()
                .setPrice(product.getPurchasePrice())
                .setSource(SOURCE_PRODUCT);
    }

    /** 降序比较；null 视为最小（排最后） */
    private static <T extends Comparable<T>> int compareNullableDesc(T a, T b) {
        if (a == null && b == null) {
            return 0;
        }
        if (a == null) {
            return 1;
        }
        if (b == null) {
            return -1;
        }
        return b.compareTo(a);
    }

}
