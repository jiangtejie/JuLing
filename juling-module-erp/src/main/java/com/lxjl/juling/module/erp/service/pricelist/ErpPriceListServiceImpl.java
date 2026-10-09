package com.lxjl.juling.module.erp.service.pricelist;

import cn.hutool.core.collection.CollUtil;
import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.erp.controller.admin.pricelist.vo.ErpPriceListPageReqVO;
import com.lxjl.juling.module.erp.controller.admin.pricelist.vo.ErpPriceListSaveReqVO;
import com.lxjl.juling.module.erp.controller.admin.pricelist.vo.ErpPriceMatchRespVO;
import com.lxjl.juling.module.erp.dal.dataobject.pricelist.ErpPriceListDO;
import com.lxjl.juling.module.erp.dal.dataobject.pricelist.ErpPriceListItemDO;
import com.lxjl.juling.module.erp.dal.dataobject.pricelist.ErpPriceListItemLogDO;
import com.lxjl.juling.module.erp.dal.dataobject.pricelist.ErpPriceListScopeDO;
import com.lxjl.juling.module.erp.dal.dataobject.product.ErpProductDO;
import com.lxjl.juling.module.erp.dal.mysql.pricelist.ErpPriceListItemLogMapper;
import com.lxjl.juling.module.erp.dal.mysql.pricelist.ErpPriceListItemMapper;
import com.lxjl.juling.module.erp.dal.mysql.pricelist.ErpPriceListMapper;
import com.lxjl.juling.module.erp.dal.mysql.pricelist.ErpPriceListScopeMapper;
import com.lxjl.juling.module.erp.dal.mysql.product.ErpProductMapper;
import com.lxjl.juling.module.erp.enums.ErpPriceTypeEnum;
import com.lxjl.juling.module.system.api.code.CodeRuleApi;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.*;
import static com.lxjl.juling.module.erp.enums.ErrorCodeConstants.*;

/**
 * ERP 价目表 Service 实现类
 *
 * @author 亚特
 */
@Service
@Validated
public class ErpPriceListServiceImpl implements ErpPriceListService {

    private static final String SOURCE_PRICE_LIST = "PRICE_LIST";
    private static final String SOURCE_PRODUCT = "PRODUCT";

    @Resource
    private ErpPriceListMapper priceListMapper;
    @Resource
    private ErpPriceListScopeMapper scopeMapper;
    @Resource
    private ErpPriceListItemMapper itemMapper;
    @Resource
    private ErpPriceListItemLogMapper itemLogMapper;
    @Resource
    private ErpProductMapper productMapper;
    @Resource
    private CodeRuleApi codeRuleApi;

    @Override
    @Transactional(rollbackFor = Exception.class) // 与编码取号同事务，避免建档失败却消耗号段
    public Long createPriceList(ErpPriceListSaveReqVO createReqVO) {
        validateScopes(createReqVO.getScopes());
        validateItems(createReqVO.getItems());
        ErpPriceListDO priceList = BeanUtils.toBean(createReqVO, ErpPriceListDO.class);
        priceList.setCode(codeRuleApi.generateCode(ErpPriceTypeEnum.valueOf(createReqVO.getPriceType()).getCodeRuleKey()));
        priceListMapper.insert(priceList);
        insertScopes(priceList.getId(), createReqVO.getScopes());
        insertItems(priceList.getId(), createReqVO.getItems());
        // 价格留痕（见 sql/local/74）：新建即全部 CREATE
        logItemChanges(priceList, List.of(), itemMapper.selectListByPriceId(priceList.getId()));
        return priceList.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updatePriceList(ErpPriceListSaveReqVO updateReqVO) {
        validatePriceListExists(updateReqVO.getId());
        validateScopes(updateReqVO.getScopes());
        validateItems(updateReqVO.getItems());
        // 类型不允许改（编码前缀与之绑定，改了会让编码与类型对不上）
        ErpPriceListDO updateObj = BeanUtils.toBean(updateReqVO, ErpPriceListDO.class);
        updateObj.setPriceType(null);
        priceListMapper.updateById(updateObj);
        // **必须在删除旧明细之前读出来**，否则变更留痕无从对比
        List<ErpPriceListItemDO> beforeItems = itemMapper.selectListByPriceId(updateReqVO.getId());
        // 范围与明细整体替换：它们没有外部引用，整体替换比 diff 更简单可靠
        scopeMapper.deleteByPriceId(updateReqVO.getId());
        itemMapper.deleteByPriceId(updateReqVO.getId());
        insertScopes(updateReqVO.getId(), updateReqVO.getScopes());
        insertItems(updateReqVO.getId(), updateReqVO.getItems());
        // 价格留痕：对比新旧明细，只记价格/税率有变化的行
        logItemChanges(priceListMapper.selectById(updateReqVO.getId()), beforeItems,
                itemMapper.selectListByPriceId(updateReqVO.getId()));
    }

    private void insertScopes(Long priceId, List<ErpPriceListSaveReqVO.Scope> scopes) {
        if (CollUtil.isEmpty(scopes)) {
            return;
        }
        List<ErpPriceListScopeDO> list = BeanUtils.toBean(scopes, ErpPriceListScopeDO.class);
        list.forEach(scope -> {
            scope.setId(null); // 前端可能回传旧行 id，与「先删后插」冲突
            scope.setPriceId(priceId);
        });
        list.forEach(scopeMapper::insert);
    }

    private void insertItems(Long priceId, List<ErpPriceListSaveReqVO.Item> items) {
        List<ErpPriceListItemDO> list = BeanUtils.toBean(items, ErpPriceListItemDO.class);
        list.forEach(item -> {
            item.setId(null);
            item.setPriceId(priceId);
        });
        itemMapper.insertBatch(list);
    }

    /**
     * 写价格变更留痕：对比新旧明细，把**价格或税率有变化**的行记下来
     *
     * <p>这是核算追溯的基础（见 sql/local/74）。**用户操作不变** —— 保存时系统自动 diff，
     * 不要求用户「改价前先新建版本」，否则历史能不能积累就取决于使用者的纪律了。
     *
     * <p>比对用 {@code compareTo} 而不是 {@code equals}：{@code BigDecimal} 的 equals 连标度一起比，
     * {@code 10.0} 与 {@code 10.00} 会被判为不同，从而产生一堆无意义的「变更」记录。
     */
    private void logItemChanges(ErpPriceListDO priceList, List<ErpPriceListItemDO> beforeList,
                                List<ErpPriceListItemDO> afterList) {
        if (priceList == null) {
            return;
        }
        Map<Long, ErpPriceListItemDO> beforeMap = convertMap(beforeList, ErpPriceListItemDO::getProductId);
        Map<Long, ErpPriceListItemDO> afterMap = convertMap(afterList, ErpPriceListItemDO::getProductId);
        List<ErpPriceListItemLogDO> logs = new ArrayList<>();
        afterMap.forEach((productId, after) -> {
            ErpPriceListItemDO before = beforeMap.get(productId);
            if (before == null) {
                logs.add(buildItemLog(priceList, null, after, "CREATE", null, null));
            } else if (!isSameDecimal(before.getPrice(), after.getPrice())
                    || !isSameDecimal(before.getTaxPercent(), after.getTaxPercent())) {
                logs.add(buildItemLog(priceList, before.getId(), after, "UPDATE",
                        before.getPrice(), before.getTaxPercent()));
            }
        });
        beforeMap.forEach((productId, before) -> {
            if (!afterMap.containsKey(productId)) {
                logs.add(buildItemLog(priceList, before.getId(), before, "DELETE",
                        before.getPrice(), before.getTaxPercent()));
            }
        });
        if (!logs.isEmpty()) {
            itemLogMapper.insertBatch(logs);
        }
    }

    private ErpPriceListItemLogDO buildItemLog(ErpPriceListDO priceList, Long itemId, ErpPriceListItemDO item,
                                               String changeType, BigDecimal beforePrice, BigDecimal beforeTaxPercent) {
        return ErpPriceListItemLogDO.builder()
                .priceId(priceList.getId()).itemId(itemId).productId(item.getProductId())
                .changeType(changeType).beforePrice(beforePrice).afterPrice(item.getPrice())
                .beforeTaxPercent(beforeTaxPercent).afterTaxPercent(item.getTaxPercent())
                .priceCode(priceList.getCode()).priceName(priceList.getName())
                .build();
    }

    /** 两个 BigDecimal 数值上是否相等（忽略标度差异） */
    private static boolean isSameDecimal(BigDecimal a, BigDecimal b) {
        if (a == null && b == null) {
            return true;
        }
        if (a == null || b == null) {
            return false;
        }
        return a.compareTo(b) == 0;
    }

    @Override
    public List<ErpPriceListItemLogDO> getItemLogList(Long priceId) {
        return itemLogMapper.selectListByPriceId(priceId);
    }

    @Override
    public List<ErpPriceListItemLogDO> getItemLogListByProductId(Long productId) {
        return itemLogMapper.selectListByProductId(productId);
    }

    /**
     * 校验适用范围
     *
     * <p>同一个对象（含「通用范围」这个 NULL 对象）在一张价目表里只能出现一次 ——
     * 重复会让「是不是默认」变得没有意义。
     */
    private void validateScopes(List<ErpPriceListSaveReqVO.Scope> scopes) {
        if (CollUtil.isEmpty(scopes)) {
            return;
        }
        long distinct = scopes.stream().map(ErpPriceListSaveReqVO.Scope::getPartnerId).distinct().count();
        if (distinct != scopes.size()) {
            throw exception(PRICE_LIST_SCOPE_PARTNER_DUPLICATE);
        }
    }

    /**
     * 校验明细
     *
     * <p>同一价目表里**同一物料只能有一行** —— 否则取价时两条都命中，取哪条取决于排序细节。
     */
    private void validateItems(List<ErpPriceListSaveReqVO.Item> items) {
        Map<Long, List<ErpPriceListSaveReqVO.Item>> byProduct =
                convertMultiMap(items, ErpPriceListSaveReqVO.Item::getProductId);
        byProduct.forEach((productId, list) -> {
            if (list.size() > 1) {
                throw exception(PRICE_LIST_ITEM_PRODUCT_DUPLICATE, productId);
            }
        });
    }

    private void validatePriceListExists(Long id) {
        if (priceListMapper.selectById(id) == null) {
            throw exception(PRICE_LIST_NOT_EXISTS);
        }
    }

    @Override
    public void deletePriceList(Long id) {
        validatePriceListExists(id);
        // 采购订单 / 门店订货单都只存快照价、不引用价目表，所以这里不需要引用校验
        logItemChanges(priceListMapper.selectById(id), itemMapper.selectListByPriceId(id), List.of());
        priceListMapper.deleteById(id);
        scopeMapper.deleteByPriceId(id);
        itemMapper.deleteByPriceId(id);
    }

    @Override
    public void deletePriceListList(List<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return;
        }
        priceListMapper.deleteByIds(ids);
        scopeMapper.deleteByPriceIds(ids);
        itemMapper.deleteByPriceIds(ids);
    }

    @Override
    public ErpPriceListDO getPriceList(Long id) {
        return priceListMapper.selectById(id);
    }

    @Override
    public List<ErpPriceListScopeDO> getScopeList(Long priceId) {
        return scopeMapper.selectListByPriceId(priceId);
    }

    @Override
    public List<ErpPriceListItemDO> getItemList(Long priceId) {
        return itemMapper.selectListByPriceId(priceId);
    }

    @Override
    public List<ErpPriceListItemDO> getItemListByPriceIds(Collection<Long> priceIds) {
        return itemMapper.selectListByPriceIds(priceIds);
    }

    @Override
    public List<ErpPriceListScopeDO> getScopeListByPriceIds(Collection<Long> priceIds) {
        return scopeMapper.selectListByPriceIds(priceIds);
    }

    @Override
    public PageResult<ErpPriceListDO> getPriceListPage(ErpPriceListPageReqVO pageReqVO) {
        return priceListMapper.selectPage(pageReqVO);
    }

    @Override
    public ErpPriceMatchRespVO matchPrice(String priceType, Long partnerId, Long productId, LocalDate date) {
        if (priceType == null || productId == null) {
            return null;
        }
        LocalDate day = date != null ? date : LocalDate.now();

        // 1. 适用于该对象的范围行（含通用范围 partner_id IS NULL）
        List<ErpPriceListScopeDO> scopes = scopeMapper.selectListByPartnerIdOrCommon(partnerId);
        if (CollUtil.isEmpty(scopes)) {
            return fallbackToProduct(priceType, productId);
        }
        // 2. 取回价目表，过滤：类型匹配 + 已启用 + 当日有效
        Map<Long, ErpPriceListDO> headerMap = convertMap(
                priceListMapper.selectByIds(convertSet(scopes, ErpPriceListScopeDO::getPriceId)),
                ErpPriceListDO::getId);
        List<ErpPriceListScopeDO> hitScopes = convertList(scopes, scope -> {
            ErpPriceListDO header = headerMap.get(scope.getPriceId());
            if (header == null || !priceType.equals(header.getPriceType())) {
                return null;
            }
            if (!CommonStatusEnum.ENABLE.getStatus().equals(header.getStatus())) {
                return null;
            }
            if (header.getEffectiveDate() != null && header.getEffectiveDate().isAfter(day)) {
                return null;
            }
            if (header.getExpiryDate() != null && header.getExpiryDate().isBefore(day)) {
                return null;
            }
            return scope;
        });
        if (CollUtil.isEmpty(hitScopes)) {
            return fallbackToProduct(priceType, productId);
        }
        // 3. 这些价目表里该物料的行
        Map<Long, ErpPriceListItemDO> itemMap = convertMap(
                itemMapper.selectListByPriceIdsAndProductId(convertSet(hitScopes, ErpPriceListScopeDO::getPriceId), productId),
                ErpPriceListItemDO::getPriceId);
        hitScopes = convertList(hitScopes, scope -> itemMap.containsKey(scope.getPriceId()) ? scope : null);
        if (CollUtil.isEmpty(hitScopes)) {
            return fallbackToProduct(priceType, productId);
        }
        // 4. 排序取第一条：默认价目表优先 → 生效日期新 → 编号大（保证结果稳定）
        hitScopes.sort((a, b) -> {
            // 「默认价目表」标在**范围行**上（同一张表可只对部分门店默认），不在头上
            int c = Boolean.compare(Boolean.TRUE.equals(b.getIsDefault()), Boolean.TRUE.equals(a.getIsDefault()));
            if (c != 0) {
                return c;
            }
            c = compareNullableDesc(headerMap.get(a.getPriceId()).getEffectiveDate(),
                    headerMap.get(b.getPriceId()).getEffectiveDate());
            if (c != 0) {
                return c;
            }
            return Long.compare(b.getPriceId(), a.getPriceId());
        });
        ErpPriceListScopeDO best = hitScopes.get(0);
        ErpPriceListDO bestHeader = headerMap.get(best.getPriceId());
        ErpPriceListItemDO bestItem = itemMap.get(best.getPriceId());
        return new ErpPriceMatchRespVO()
                .setPriceId(best.getPriceId()).setItemId(bestItem.getId())
                .setPriceCode(bestHeader.getCode()).setPriceName(bestHeader.getName())
                .setPrice(bestItem.getPrice()).setTaxPercent(bestItem.getTaxPercent())
                .setSource(SOURCE_PRICE_LIST);
    }

    /**
     * 价目表没命中时的兜底：取物料主数据上的价格
     *
     * <p>采购取 purchase_price；**配送取 sale_price** —— sale_price 此前是个没有任何消费方的孤儿字段，
     * 正好在这里承担「没维护配送价目表时的默认配送价」，不再是从没人读的摆设。
     */
    private ErpPriceMatchRespVO fallbackToProduct(String priceType, Long productId) {
        ErpProductDO product = productMapper.selectById(productId);
        if (product == null) {
            return null;
        }
        BigDecimal price = ErpPriceTypeEnum.DELIVERY.getType().equals(priceType)
                ? product.getSalePrice() : product.getPurchasePrice();
        if (price == null) {
            return null;
        }
        return new ErpPriceMatchRespVO().setPrice(price).setSource(SOURCE_PRODUCT);
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
