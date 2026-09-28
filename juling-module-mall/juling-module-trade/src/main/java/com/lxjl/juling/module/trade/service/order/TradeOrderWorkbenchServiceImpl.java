package com.lxjl.juling.module.trade.service.order;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.erp.api.customer.ErpCustomerApi;
import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerRespDTO;
import com.lxjl.juling.module.erp.api.customer.enums.StoreTypeEnum;
import com.lxjl.juling.module.erp.api.product.ErpProductApi;
import com.lxjl.juling.module.erp.api.product.dto.ErpProductRespDTO;
import com.lxjl.juling.module.erp.api.storealloc.ErpStoreAllocApi;
import com.lxjl.juling.module.erp.api.storealloc.dto.ErpCentralDeliveryPushReqDTO;
import com.lxjl.juling.module.erp.api.storealloc.dto.ErpDirectPurchasePushReqDTO;
import com.lxjl.juling.module.erp.api.storealloc.dto.ErpStoreAllocItemDTO;
import com.lxjl.juling.module.erp.api.storealloc.dto.ErpStoreAllocPushedDTO;
import com.lxjl.juling.module.erp.api.storealloc.dto.ErpStoreAllocPushRespDTO;
import com.lxjl.juling.module.product.api.sku.ProductSkuApi;
import com.lxjl.juling.module.product.api.sku.dto.ProductSkuRespDTO;
import com.lxjl.juling.module.trade.controller.admin.workbench.vo.TradeOrderWorkbenchItemRespVO;
import com.lxjl.juling.module.trade.controller.admin.workbench.vo.TradeOrderWorkbenchPageReqVO;
import com.lxjl.juling.module.trade.controller.admin.workbench.vo.TradeOrderWorkbenchPushReqVO;
import com.lxjl.juling.module.trade.controller.admin.workbench.vo.TradeOrderWorkbenchPushRespVO;
import com.lxjl.juling.module.trade.controller.admin.workbench.vo.TradeOrderWorkbenchRespVO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderItemDO;
import com.lxjl.juling.module.trade.dal.mysql.order.TradeOrderItemMapper;
import com.lxjl.juling.module.trade.dal.mysql.order.TradeOrderMapper;
import com.lxjl.juling.module.trade.enums.order.TradeOrderAuditStatusEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderItemAllocModeEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderStatusEnum;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertMap;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertSet;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.*;

/**
 * 订单工作台 Service 实现类
 *
 * 设计取舍（详见 docs/store-ordering-flow-design.md 第 3 段）：
 *   · 工作台放在 trade 模块：要货单（trade_order）是它的主数据，跨模块只经 erp-api 下推；
 *   · 「商城 SKU ↔ ERP 物料」用 {@code product_sku.bar_code = erp_product.bar_code} 对齐
 *     （种子数据 29_seed_demo_data.sql 就是这么建的），不新增映射表；
 *   · 幂等：以「订单行 → 目标单」的行级 bill_relation 为准，重复下推直接报错，
 *     见 {@link #validateItemCanPush}（bill_relation 唯一索引兜底并发）。
 *
 * @author 亚特
 */
@Slf4j
@Service
@Validated
public class TradeOrderWorkbenchServiceImpl implements TradeOrderWorkbenchService {

    /** 可下推数量提示：未分料 */
    private static final String HINT_UNALLOCATED = "可下推 %s（未分料）";
    /** 可下推数量提示：已下推 */
    private static final String HINT_PUSHED = "已下推 %s → %s";

    @Resource
    private TradeOrderMapper tradeOrderMapper;
    @Resource
    private TradeOrderItemMapper tradeOrderItemMapper;

    @Resource
    private ErpCustomerApi erpCustomerApi;
    @Resource
    private ErpProductApi erpProductApi;
    @Resource
    private ErpStoreAllocApi erpStoreAllocApi;
    @Resource
    private ProductSkuApi productSkuApi;

    // ==================== 查询 ====================

    @Override
    public PageResult<TradeOrderWorkbenchRespVO> getWorkbenchPage(TradeOrderWorkbenchPageReqVO pageReqVO) {
        // 1. 待处理要货单（口径见 Mapper）
        PageResult<TradeOrderDO> pageResult = tradeOrderMapper.selectWorkbenchPage(pageReqVO);
        if (CollUtil.isEmpty(pageResult.getList())) {
            return PageResult.empty();
        }
        // 2. 订单行：统计行数与未分料行数
        List<Long> orderIds = pageResult.getList().stream().map(TradeOrderDO::getId).toList();
        List<TradeOrderItemDO> items = tradeOrderItemMapper.selectListByOrderId(orderIds);
        Map<Long, List<TradeOrderItemDO>> itemMap = items.stream()
                .collect(Collectors.groupingBy(TradeOrderItemDO::getOrderId));
        // 3. 门店名称（跨模块只走 erp-api）
        Map<Long, ErpCustomerRespDTO> customerMap = convertMap(
                erpCustomerApi.getCustomerList(convertSet(pageResult.getList(), TradeOrderDO::getCustomerId)),
                ErpCustomerRespDTO::getId);
        // 4. 组装
        List<TradeOrderWorkbenchRespVO> list = BeanUtils.toBean(pageResult.getList(), TradeOrderWorkbenchRespVO.class, vo -> {
            ErpCustomerRespDTO customer = customerMap.get(vo.getCustomerId());
            if (customer != null) {
                vo.setCustomerName(customer.getName());
            }
            List<TradeOrderItemDO> orderItems = itemMap.getOrDefault(vo.getId(), List.of());
            vo.setItemCount(orderItems.size());
            vo.setPendingItemCount((int) orderItems.stream()
                    .filter(item -> StrUtil.isBlank(item.getAllocMode())).count());
        });
        return new PageResult<>(list, pageResult.getTotal());
    }

    @Override
    public List<TradeOrderWorkbenchItemRespVO> getWorkbenchItemList(Long orderId) {
        TradeOrderDO order = tradeOrderMapper.selectById(orderId);
        if (order == null) {
            throw exception(ORDER_NOT_FOUND);
        }
        List<TradeOrderItemDO> items = tradeOrderItemMapper.selectListByOrderId(orderId);
        if (CollUtil.isEmpty(items)) {
            return List.of();
        }
        // 1. SKU → 条码（商城商品 ↔ ERP 物料的对应关系）
        Map<Long, ProductSkuRespDTO> skuMap = productSkuApi.getSkuMap(convertSet(items, TradeOrderItemDO::getSkuId));
        Map<String, ErpProductRespDTO> productMap = getProductMapBySku(items, skuMap);
        // 2. 已下推记录（bill_relation，行级）
        Map<Long, ErpStoreAllocPushedDTO> pushedMap = erpStoreAllocApi.getPushedList(orderId).stream()
                .filter(pushed -> pushed.getSourceItemId() != null)
                .collect(Collectors.toMap(ErpStoreAllocPushedDTO::getSourceItemId, Function.identity(), (a, b) -> a));
        // 3. 组装
        return items.stream().map(item -> {
            TradeOrderWorkbenchItemRespVO vo = BeanUtils.toBean(item, TradeOrderWorkbenchItemRespVO.class);
            ProductSkuRespDTO sku = skuMap.get(item.getSkuId());
            ErpProductRespDTO product = sku != null ? productMap.get(sku.getBarCode()) : null;
            if (product != null) {
                vo.setErpProductId(product.getId());
                vo.setErpProductName(product.getName());
                vo.setErpProductBarCode(product.getBarCode());
                // 分料属性缺省视为允许（历史物料未维护时不要把工作台卡死）
                vo.setAllowCentral(!Boolean.FALSE.equals(product.getAllowCentral()));
                vo.setAllowDirect(!Boolean.FALSE.equals(product.getAllowDirect()));
            } else {
                vo.setAllowCentral(false);
                vo.setAllowDirect(false);
            }
            // 可下推数量 = 要货数量 − 已下推数量
            BigDecimal count = BigDecimal.valueOf(item.getCount() == null ? 0 : item.getCount());
            BigDecimal allocCount = item.getAllocCount() == null ? BigDecimal.ZERO : item.getAllocCount();
            BigDecimal available = count.subtract(allocCount).max(BigDecimal.ZERO);
            vo.setAvailableCount(available);
            ErpStoreAllocPushedDTO pushed = pushedMap.get(item.getId());
            if (pushed != null) {
                vo.setPushedBillType(pushed.getBillType());
                vo.setPushedBillNo(pushed.getBillNo());
                vo.setAvailableHint(String.format(HINT_PUSHED, pushed.getBillNo(), allocModeName(item.getAllocMode())));
            } else if (product == null) {
                vo.setAvailableHint("未对应 ERP 物料（条码 " + (sku != null ? sku.getBarCode() : "-") + "），无法下推");
            } else {
                vo.setAvailableHint(String.format(HINT_UNALLOCATED, available.stripTrailingZeros().toPlainString()));
            }
            return vo;
        }).toList();
    }

    // ==================== 下推 ====================

    @Override
    @Transactional(rollbackFor = Exception.class)
    public TradeOrderWorkbenchPushRespVO pushDown(TradeOrderWorkbenchPushReqVO pushReqVO) {
        // 1. 校验要货单处于"可进工作台"的状态（待发货 + 审核闸门）
        TradeOrderDO order = tradeOrderMapper.selectById(pushReqVO.getOrderId());
        if (order == null) {
            throw exception(ORDER_NOT_FOUND);
        }
        validateOrderCanPush(order);
        // 2. 校验订单行
        Map<Long, TradeOrderItemDO> itemMap = convertMap(
                tradeOrderItemMapper.selectListByOrderId(order.getId()), TradeOrderItemDO::getId);
        Map<Long, ProductSkuRespDTO> skuMap = productSkuApi.getSkuMap(
                convertSet(itemMap.values(), TradeOrderItemDO::getSkuId));
        Map<String, ErpProductRespDTO> productMap = getProductMapBySku(itemMap.values(), skuMap);
        Map<Long, ErpStoreAllocPushedDTO> pushedMap = erpStoreAllocApi.getPushedList(order.getId()).stream()
                .filter(pushed -> pushed.getSourceItemId() != null)
                .collect(Collectors.toMap(ErpStoreAllocPushedDTO::getSourceItemId, Function.identity(), (a, b) -> a));
        // 3. 分料行 → 统配组 / 直拨组（直拨按供应商再分组：一张采购订单一个供应商）
        List<TradeOrderWorkbenchPushReqVO.Item> centralItems = new ArrayList<>();
        Map<Long, List<TradeOrderWorkbenchPushReqVO.Item>> directGroups = new LinkedHashMap<>();
        for (TradeOrderWorkbenchPushReqVO.Item pushItem : pushReqVO.getItems()) {
            TradeOrderItemDO orderItem = validateItemCanPush(pushItem, order, itemMap, pushedMap, skuMap, productMap);
            if (Objects.equals(TradeOrderItemAllocModeEnum.CENTRAL.getMode(), pushItem.getAllocMode())) {
                centralItems.add(pushItem);
            } else {
                Long supplierId = ObjectUtil.defaultIfNull(pushItem.getSupplierId(), pushReqVO.getSupplierId());
                if (supplierId == null) {
                    throw exception(ORDER_WORKBENCH_PUSH_FAIL_SUPPLIER_REQUIRED, spuName(orderItem));
                }
                directGroups.computeIfAbsent(supplierId, k -> new ArrayList<>()).add(pushItem);
            }
        }
        // 4. 下推：统配 → 配送出库单
        List<TradeOrderWorkbenchPushRespVO.Result> results = new ArrayList<>();
        ErpCustomerRespDTO store = erpCustomerApi.getCustomer(order.getCustomerId());
        String storeName = store != null ? store.getName() : String.valueOf(order.getCustomerId());
        if (CollUtil.isNotEmpty(centralItems)) {
            ErpCentralDeliveryPushReqDTO reqDTO = new ErpCentralDeliveryPushReqDTO();
            reqDTO.setSourceOrderId(order.getId()).setSourceOrderNo(order.getNo())
                    .setCustomerId(order.getCustomerId()).setWarehouseId(pushReqVO.getWarehouseId())
                    .setAccountId(pushReqVO.getAccountId())
                    .setRemark(StrUtil.format("门店要货单 {} 统配下推；收货门店：{}", order.getNo(), storeName));
            reqDTO.setItems(buildAllocItems(centralItems, itemMap, skuMap, productMap,
                    TradeOrderItemAllocModeEnum.CENTRAL));
            ErpStoreAllocPushRespDTO resp = erpStoreAllocApi.pushCentralDelivery(reqDTO);
            centralItems.forEach(item -> results.add(new TradeOrderWorkbenchPushRespVO.Result(
                    item.getItemId(), item.getAllocMode(), resp.getBillType(), resp.getBillId(), resp.getBillNo())));
            markItemsAllocated(centralItems);
        }
        // 5. 下推：直拨 → 采购订单（按供应商一张）
        directGroups.forEach((supplierId, group) -> {
            ErpDirectPurchasePushReqDTO reqDTO = new ErpDirectPurchasePushReqDTO();
            reqDTO.setSourceOrderId(order.getId()).setSourceOrderNo(order.getNo()).setSupplierId(supplierId)
                    .setAccountId(pushReqVO.getAccountId())
                    .setRemark(StrUtil.format("门店要货单 {} 直拨下推；供应商直送门店：{}（收货地址：{}）",
                            order.getNo(), storeName,
                            StrUtil.blankToDefault(order.getReceiverDetailAddress(), "见门店档案")));
            reqDTO.setItems(buildAllocItems(group, itemMap, skuMap, productMap,
                    TradeOrderItemAllocModeEnum.DIRECT));
            ErpStoreAllocPushRespDTO resp = erpStoreAllocApi.pushDirectPurchase(reqDTO);
            group.forEach(item -> results.add(new TradeOrderWorkbenchPushRespVO.Result(
                    item.getItemId(), item.getAllocMode(), resp.getBillType(), resp.getBillId(), resp.getBillNo())));
            markItemsAllocated(group);
        });

        TradeOrderWorkbenchPushRespVO respVO = new TradeOrderWorkbenchPushRespVO();
        respVO.setResults(results);
        log.info("[pushDown][要货单({}) 分料下推完成，生成/关联单据 {} 张]", order.getNo(), results.size());
        return respVO;
    }

    /**
     * 校验要货单可进工作台：待发货 + （审核通过 或 直营免审）
     */
    private void validateOrderCanPush(TradeOrderDO order) {
        boolean statusOk = TradeOrderStatusEnum.isUndelivered(order.getStatus());
        boolean auditOk = !StoreTypeEnum.isFranchise(order.getStoreType())
                || TradeOrderAuditStatusEnum.isApprove(order.getAuditStatus());
        if (!statusOk || !auditOk) {
            throw exception(ORDER_WORKBENCH_PUSH_FAIL_ORDER_STATUS);
        }
    }

    /**
     * 校验订单行可下推：属于该单、未下推过、物料存在且允许所选分料方式、数量合法
     */
    private TradeOrderItemDO validateItemCanPush(TradeOrderWorkbenchPushReqVO.Item pushItem, TradeOrderDO order,
                                                 Map<Long, TradeOrderItemDO> itemMap,
                                                 Map<Long, ErpStoreAllocPushedDTO> pushedMap,
                                                 Map<Long, ProductSkuRespDTO> skuMap,
                                                 Map<String, ErpProductRespDTO> productMap) {
        // 1. 行属于该订单
        TradeOrderItemDO orderItem = itemMap.get(pushItem.getItemId());
        if (orderItem == null || !Objects.equals(orderItem.getOrderId(), order.getId())) {
            throw exception(ORDER_WORKBENCH_PUSH_FAIL_ITEM_NOT_BELONG, pushItem.getItemId());
        }
        // 2. 未下推过（幂等）
        ErpStoreAllocPushedDTO pushed = pushedMap.get(orderItem.getId());
        if (pushed != null || StrUtil.isNotBlank(orderItem.getAllocMode())) {
            throw exception(ORDER_WORKBENCH_PUSH_FAIL_ITEM_PUSHED, spuName(orderItem),
                    pushed != null ? pushed.getBillNo() : allocModeName(orderItem.getAllocMode()));
        }
        // 3. 分料方式合法
        TradeOrderItemAllocModeEnum allocMode = TradeOrderItemAllocModeEnum.valueOfMode(pushItem.getAllocMode());
        if (allocMode == null) {
            throw exception(ORDER_WORKBENCH_PUSH_FAIL_ALLOC_MODE_INVALID, pushItem.getAllocMode());
        }
        // 4. 物料存在且允许该方式
        String barCode = skuBarCode(orderItem, skuMap);
        ErpProductRespDTO product = barCode != null ? productMap.get(barCode) : null;
        if (product == null) {
            throw exception(ORDER_WORKBENCH_PUSH_FAIL_PRODUCT_NOT_MATCH, spuName(orderItem),
                    StrUtil.blankToDefault(barCode, "-"));
        }
        boolean allowed = Objects.equals(allocMode, TradeOrderItemAllocModeEnum.CENTRAL)
                ? !Boolean.FALSE.equals(product.getAllowCentral())
                : !Boolean.FALSE.equals(product.getAllowDirect());
        if (!allowed) {
            throw exception(ORDER_WORKBENCH_PUSH_FAIL_MODE_NOT_ALLOWED, product.getName(), allocMode.getName());
        }
        // 5. 数量：0 < 下推数量 ≤ 要货数量（默认整行）
        BigDecimal count = ObjectUtil.defaultIfNull(pushItem.getCount(),
                orderItem.getCount() == null ? null : BigDecimal.valueOf(orderItem.getCount()));
        BigDecimal maxCount = BigDecimal.valueOf(orderItem.getCount() == null ? 0 : orderItem.getCount());
        if (count == null || count.compareTo(BigDecimal.ZERO) <= 0 || count.compareTo(maxCount) > 0) {
            throw exception(ORDER_WORKBENCH_PUSH_FAIL_COUNT_EXCEED, product.getName(), count, maxCount);
        }
        pushItem.setCount(count);
        return orderItem;
    }

    /**
     * 组装下推请求行：数量取校验后的下推数量，单价取要货单行单价（分 → 元），
     * 直拨单价用 ERP 物料的参考进价（采购价），避免把零售价当采购价。
     */
    private List<ErpStoreAllocItemDTO> buildAllocItems(List<TradeOrderWorkbenchPushReqVO.Item> pushItems,
                                                       Map<Long, TradeOrderItemDO> itemMap,
                                                       Map<Long, ProductSkuRespDTO> skuMap,
                                                       Map<String, ErpProductRespDTO> productMap,
                                                       TradeOrderItemAllocModeEnum allocMode) {
        List<ErpStoreAllocItemDTO> list = new ArrayList<>();
        for (TradeOrderWorkbenchPushReqVO.Item pushItem : pushItems) {
            TradeOrderItemDO orderItem = itemMap.get(pushItem.getItemId());
            ErpProductRespDTO product = productMap.get(skuBarCode(orderItem, skuMap));
            ErpStoreAllocItemDTO item = new ErpStoreAllocItemDTO();
            item.setSourceItemId(orderItem.getId());
            item.setProductId(product.getId());
            item.setCount(pushItem.getCount());
            item.setProductPrice(Objects.equals(allocMode, TradeOrderItemAllocModeEnum.DIRECT)
                    ? ObjectUtil.defaultIfNull(product.getPurchasePrice(), unitPriceOf(orderItem))
                    : unitPriceOf(orderItem));
            list.add(item);
        }
        return list;
    }

    /**
     * 回写订单行的分料方式与下推数量（工作台的"未全部下推"口径即由此驱动）
     */
    private void markItemsAllocated(List<TradeOrderWorkbenchPushReqVO.Item> pushItems) {
        pushItems.forEach(pushItem -> tradeOrderItemMapper.updateById(new TradeOrderItemDO()
                .setId(pushItem.getItemId())
                .setAllocMode(pushItem.getAllocMode())
                .setAllocCount(pushItem.getCount())));
    }

    /**
     * 订单行单价（分）→ 元；订单行 price 为单价（分）
     */
    private BigDecimal unitPriceOf(TradeOrderItemDO orderItem) {
        if (orderItem.getPrice() == null) {
            return BigDecimal.ZERO;
        }
        return BigDecimal.valueOf(orderItem.getPrice()).movePointLeft(2);
    }

    private String skuBarCode(TradeOrderItemDO orderItem, Map<Long, ProductSkuRespDTO> skuMap) {
        ProductSkuRespDTO sku = skuMap.get(orderItem.getSkuId());
        return sku != null ? sku.getBarCode() : null;
    }

    private String spuName(TradeOrderItemDO orderItem) {
        return StrUtil.blankToDefault(orderItem.getSpuName(), String.valueOf(orderItem.getSkuId()));
    }

    private String allocModeName(String allocMode) {
        TradeOrderItemAllocModeEnum mode = TradeOrderItemAllocModeEnum.valueOfMode(allocMode);
        return mode != null ? mode.getName() : StrUtil.blankToDefault(allocMode, "分料");
    }

    /**
     * SKU 条码 → ERP 物料
     */
    private Map<String, ErpProductRespDTO> getProductMapBySku(java.util.Collection<TradeOrderItemDO> items,
                                                              Map<Long, ProductSkuRespDTO> skuMap) {
        List<String> barCodes = items.stream()
                .map(item -> skuMap.get(item.getSkuId()))
                .filter(Objects::nonNull)
                .map(ProductSkuRespDTO::getBarCode)
                .filter(StrUtil::isNotBlank)
                .distinct().toList();
        if (CollUtil.isEmpty(barCodes)) {
            return Map.of();
        }
        return erpProductApi.getProductListByBarCodes(barCodes).stream()
                .collect(Collectors.toMap(ErpProductRespDTO::getBarCode, Function.identity(), (a, b) -> a));
    }

}
