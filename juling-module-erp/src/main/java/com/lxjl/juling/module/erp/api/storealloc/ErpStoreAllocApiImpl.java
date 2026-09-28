package com.lxjl.juling.module.erp.api.storealloc;

import com.lxjl.juling.framework.common.util.number.MoneyUtils;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.framework.security.core.util.SecurityFrameworkUtils;
import com.lxjl.juling.module.bill.api.BillPlatformApi;
import com.lxjl.juling.module.bill.api.dto.BillLogCreateReqDTO;
import com.lxjl.juling.module.bill.api.dto.BillRelationCreateReqDTO;
import com.lxjl.juling.module.bill.enums.BillTypeConstants;
import com.lxjl.juling.module.erp.api.storealloc.dto.ErpCentralDeliveryPushReqDTO;
import com.lxjl.juling.module.erp.api.storealloc.dto.ErpDirectPurchasePushReqDTO;
import com.lxjl.juling.module.erp.api.storealloc.dto.ErpStoreAllocItemDTO;
import com.lxjl.juling.module.erp.api.storealloc.dto.ErpStoreAllocPushedDTO;
import com.lxjl.juling.module.erp.api.storealloc.dto.ErpStoreAllocPushRespDTO;
import com.lxjl.juling.module.erp.dal.dataobject.product.ErpProductDO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchaseOrderDO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchaseOrderItemDO;
import com.lxjl.juling.module.erp.dal.dataobject.sale.ErpSaleOutDO;
import com.lxjl.juling.module.erp.dal.dataobject.sale.ErpSaleOutItemDO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpWarehouseDO;
import com.lxjl.juling.module.erp.dal.mysql.purchase.ErpPurchaseOrderItemMapper;
import com.lxjl.juling.module.erp.dal.mysql.purchase.ErpPurchaseOrderMapper;
import com.lxjl.juling.module.erp.dal.mysql.sale.ErpSaleOutItemMapper;
import com.lxjl.juling.module.erp.dal.mysql.sale.ErpSaleOutMapper;
import com.lxjl.juling.module.erp.dal.mysql.stock.ErpWarehouseMapper;
import com.lxjl.juling.module.erp.enums.ErpAuditStatus;
import com.lxjl.juling.module.erp.service.finance.ErpAccountService;
import com.lxjl.juling.module.erp.service.product.ErpProductService;
import com.lxjl.juling.module.erp.service.purchase.ErpSupplierService;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertList;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertMap;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertSet;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.getSumValue;
import static com.lxjl.juling.module.erp.enums.ErrorCodeConstants.*;

/**
 * 门店要货「分料下推」API 实现（订单工作台 → ERP 单据）
 *
 * 为什么落这两张表（设计取舍，见 docs/store-ordering-flow-design.md 第 3 段）：
 *   · 统配 → {@code erp_sale_out}（销售出库）：单据平台里「配送出库单 DELIVERY_OUT」的编号前缀
 *     就是 XSCK（31_bill_platform_fix.sql 已把二者对齐），ERP 侧对应的实体正是销售出库单，
 *     审核后即按 {@code ErpStockRecordBizTypeEnum.SALE_OUT} 扣中心库在仓数量 —— 天然就是"中心库配送出库"。
 *   · 直拨 → {@code erp_purchase_order}（采购订单）：中心库向供应商下单、供应商直送门店；
 *     本切片**不生成**采购入库单，故入库仓（门店）与库存留到后续切片。
 *
 * 与既有 {@code ErpSaleOutServiceImpl#createSaleOut} 的差异（有意为之，最小改动）：
 *   既有入口要求先有一张**已审核**的 ERP 销售订单，且单号走 Redis（ErpNoRedisDAO）；
 *   本切片的要求是「要货单直接下推、单号走单据平台」，因此这里独立插入出库单/采购订单，
 *   复用同一批 DO/Mapper 与金额口径，但不引入中间销售订单。
 *   注意：单号口径与既有 Redis 生成器**不共用一个序列**，同日两种入口并存时理论上可能撞号
 *   （下推前已做 selectByNo 唯一性兜底并报错），彻底统一留待「销售出库单号迁移到单据平台」时处理。
 *
 * @author 亚特
 */
@Slf4j
@Service
@Validated
public class ErpStoreAllocApiImpl implements ErpStoreAllocApi {

    @Resource
    private ErpSaleOutMapper saleOutMapper;
    @Resource
    private ErpSaleOutItemMapper saleOutItemMapper;
    @Resource
    private ErpPurchaseOrderMapper purchaseOrderMapper;
    @Resource
    private ErpPurchaseOrderItemMapper purchaseOrderItemMapper;

    @Resource
    private ErpProductService productService;
    @Resource
    private ErpSupplierService supplierService;
    @Resource
    private ErpAccountService accountService;
    @Resource
    private ErpWarehouseMapper warehouseMapper;

    @Resource
    private BillPlatformApi billPlatformApi;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ErpStoreAllocPushRespDTO pushCentralDelivery(ErpCentralDeliveryPushReqDTO reqDTO) {
        // 1.1 校验物料（存在 + 启用）
        List<ErpProductDO> products = productService.validProductList(
                convertSet(reqDTO.getItems(), ErpStoreAllocItemDTO::getProductId));
        Map<Long, ErpProductDO> productMap = convertMap(products, ErpProductDO::getId);
        // 1.2 校验结算账户
        if (reqDTO.getAccountId() != null) {
            accountService.validateAccount(reqDTO.getAccountId());
        }
        // 1.3 发货仓库：未指定时取默认仓库（中心库）
        Long warehouseId = resolveWarehouseId(reqDTO.getWarehouseId());
        // 1.4 生成配送出库单号（单据平台：DELIVERY_OUT → XSCK + yyyyMMdd + 6 位流水）
        String no = billPlatformApi.generateNo(BillTypeConstants.DELIVERY_OUT, null);
        if (saleOutMapper.selectByNo(no) != null) {
            throw exception(SALE_OUT_NO_EXISTS);
        }

        // 2.1 插入出库单（状态 = 待审核：本切片不动库存，审核出库时才扣减）
        ErpSaleOutDO saleOut = new ErpSaleOutDO()
                .setNo(no).setStatus(ErpAuditStatus.PROCESS.getStatus())
                .setCustomerId(reqDTO.getCustomerId())
                .setAccountId(reqDTO.getAccountId())
                .setSaleUserId(reqDTO.getSaleUserId())
                .setOutTime(LocalDateTime.now())
                // 不关联 ERP 销售订单：来源是要货单（trade_order），单号冗余到 orderNo 便于 ERP 列表追溯
                .setOrderNo(reqDTO.getSourceOrderNo())
                .setReceiptPrice(BigDecimal.ZERO)
                .setRemark(reqDTO.getRemark());
        List<ErpSaleOutItemDO> saleOutItems = convertList(reqDTO.getItems(), item ->
                BeanUtils.toBean(item, ErpSaleOutItemDO.class, o -> {
                    ErpProductDO product = validateProduct(productMap, item.getProductId());
                    o.setWarehouseId(warehouseId).setProductUnitId(product.getUnitId());
                    o.setTotalPrice(MoneyUtils.priceMultiply(o.getProductPrice(), o.getCount()));
                    if (o.getTotalPrice() != null && o.getTaxPercent() != null) {
                        o.setTaxPrice(MoneyUtils.priceMultiplyPercent(o.getTotalPrice(), o.getTaxPercent()));
                    }
                }));
        calculateSaleOutTotalPrice(saleOut, saleOutItems);
        saleOutMapper.insert(saleOut);
        saleOutItems.forEach(item -> item.setOutId(saleOut.getId()));
        saleOutItemMapper.insertBatch(saleOutItems);

        // 3. 单据平台：行级关联（要货单行 → 配送出库单）+ 创建日志
        writeRelations(BillTypeConstants.STORE_REQUISITION, reqDTO.getSourceOrderId(), reqDTO.getSourceOrderNo(),
                reqDTO.getItems(), BillTypeConstants.DELIVERY_OUT, saleOut.getId(), no);
        billPlatformApi.log(new BillLogCreateReqDTO()
                .setBillType(BillTypeConstants.DELIVERY_OUT).setBillId(saleOut.getId()).setBillNo(no)
                .setOperateType("CREATE").setAfterStatus(saleOut.getStatus())
                .setOperatorId(SecurityFrameworkUtils.getLoginUserId())
                .setOperatorName(operatorName())
                .setRemark("由门店要货单 " + reqDTO.getSourceOrderNo() + " 统配下推"));
        log.info("[pushCentralDelivery][要货单({}) 统配下推生成配送出库单({})]", reqDTO.getSourceOrderNo(), no);
        return new ErpStoreAllocPushRespDTO(BillTypeConstants.DELIVERY_OUT, saleOut.getId(), no);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ErpStoreAllocPushRespDTO pushDirectPurchase(ErpDirectPurchasePushReqDTO reqDTO) {
        // 1.1 校验物料
        List<ErpProductDO> products = productService.validProductList(
                convertSet(reqDTO.getItems(), ErpStoreAllocItemDTO::getProductId));
        Map<Long, ErpProductDO> productMap = convertMap(products, ErpProductDO::getId);
        // 1.2 校验供应商
        supplierService.validateSupplier(reqDTO.getSupplierId());
        // 1.3 校验结算账户
        if (reqDTO.getAccountId() != null) {
            accountService.validateAccount(reqDTO.getAccountId());
        }
        // 1.4 生成采购订单号（单据平台：PURCHASE_ORDER → CGDD + yyyyMMdd + 6 位流水）
        String no = billPlatformApi.generateNo(BillTypeConstants.PURCHASE_ORDER, null);
        if (purchaseOrderMapper.selectByNo(no) != null) {
            throw exception(PURCHASE_ORDER_NO_EXISTS);
        }

        // 2.1 插入采购订单（待审核；供应商直送门店，入库仓与门店库存不在本切片）
        ErpPurchaseOrderDO purchaseOrder = new ErpPurchaseOrderDO()
                .setNo(no).setStatus(ErpAuditStatus.PROCESS.getStatus())
                .setSupplierId(reqDTO.getSupplierId())
                .setAccountId(reqDTO.getAccountId())
                .setOrderTime(LocalDateTime.now())
                .setInCount(BigDecimal.ZERO).setReturnCount(BigDecimal.ZERO)
                .setRemark(reqDTO.getRemark());
        List<ErpPurchaseOrderItemDO> purchaseOrderItems = convertList(reqDTO.getItems(), item ->
                BeanUtils.toBean(item, ErpPurchaseOrderItemDO.class, o -> {
                    ErpProductDO product = validateProduct(productMap, item.getProductId());
                    o.setProductUnitId(product.getUnitId());
                    o.setInCount(BigDecimal.ZERO).setReturnCount(BigDecimal.ZERO);
                    o.setTotalPrice(MoneyUtils.priceMultiply(o.getProductPrice(), o.getCount()));
                    if (o.getTotalPrice() != null && o.getTaxPercent() != null) {
                        o.setTaxPrice(MoneyUtils.priceMultiplyPercent(o.getTotalPrice(), o.getTaxPercent()));
                    }
                }));
        calculatePurchaseOrderTotalPrice(purchaseOrder, purchaseOrderItems);
        purchaseOrderMapper.insert(purchaseOrder);
        purchaseOrderItems.forEach(item -> item.setOrderId(purchaseOrder.getId()));
        purchaseOrderItemMapper.insertBatch(purchaseOrderItems);

        // 3. 单据平台：行级关联 + 创建日志
        writeRelations(BillTypeConstants.STORE_REQUISITION, reqDTO.getSourceOrderId(), reqDTO.getSourceOrderNo(),
                reqDTO.getItems(), BillTypeConstants.PURCHASE_ORDER, purchaseOrder.getId(), no);
        billPlatformApi.log(new BillLogCreateReqDTO()
                .setBillType(BillTypeConstants.PURCHASE_ORDER).setBillId(purchaseOrder.getId()).setBillNo(no)
                .setOperateType("CREATE").setAfterStatus(purchaseOrder.getStatus())
                .setOperatorId(SecurityFrameworkUtils.getLoginUserId())
                .setOperatorName(operatorName())
                .setRemark("由门店要货单 " + reqDTO.getSourceOrderNo() + " 直拨下推（供应商直送门店）"));
        log.info("[pushDirectPurchase][要货单({}) 直拨下推生成采购订单({})]", reqDTO.getSourceOrderNo(), no);
        return new ErpStoreAllocPushRespDTO(BillTypeConstants.PURCHASE_ORDER, purchaseOrder.getId(), no);
    }

    @Override
    public List<ErpStoreAllocPushedDTO> getPushedList(Long sourceOrderId) {
        if (sourceOrderId == null) {
            return List.of();
        }
        return billPlatformApi.getDownstreamList(BillTypeConstants.STORE_REQUISITION, sourceOrderId).stream()
                .map(relation -> {
                    ErpStoreAllocPushedDTO dto = new ErpStoreAllocPushedDTO();
                    dto.setSourceItemId(relation.getSourceItemId());
                    dto.setBillType(relation.getTargetType());
                    dto.setBillId(relation.getTargetId());
                    dto.setBillNo(relation.getTargetNo());
                    dto.setQty(relation.getQty());
                    return dto;
                }).toList();
    }

    // ==================== 内部方法 ====================

    /**
     * 单据平台行级关联：源（要货单行）→ 目标单行，唯一索引防同一行重复下推
     */
    private void writeRelations(String sourceType, Long sourceOrderId, String sourceOrderNo,
                                List<ErpStoreAllocItemDTO> items,
                                String targetType, Long targetId, String targetNo) {
        for (ErpStoreAllocItemDTO item : items) {
            boolean success = billPlatformApi.addRelation(new BillRelationCreateReqDTO()
                    .setSourceType(sourceType).setSourceId(sourceOrderId).setSourceNo(sourceOrderNo)
                    .setSourceItemId(item.getSourceItemId())
                    .setTargetType(targetType).setTargetId(targetId).setTargetNo(targetNo)
                    .setQty(item.getCount()));
            if (!success) {
                // addRelation 只在"完全相同的关联"已存在时返回 false，属异常分支，交由上层事务回滚
                throw exception(STORE_ALLOC_RELATION_DUPLICATE);
            }
        }
    }

    private Long resolveWarehouseId(Long warehouseId) {
        if (warehouseId != null) {
            ErpWarehouseDO warehouse = warehouseMapper.selectById(warehouseId);
            if (warehouse == null) {
                throw exception(WAREHOUSE_NOT_EXISTS);
            }
            return warehouse.getId();
        }
        ErpWarehouseDO warehouse = warehouseMapper.selectByDefaultStatus();
        if (warehouse == null) {
            throw exception(WAREHOUSE_NOT_EXISTS);
        }
        return warehouse.getId();
    }

    private ErpProductDO validateProduct(Map<Long, ErpProductDO> productMap, Long productId) {
        ErpProductDO product = productMap.get(productId);
        if (product == null) {
            throw exception(PRODUCT_NOT_EXISTS);
        }
        return product;
    }

    private void calculateSaleOutTotalPrice(ErpSaleOutDO saleOut, List<ErpSaleOutItemDO> items) {
        saleOut.setTotalCount(getSumValue(items, ErpSaleOutItemDO::getCount, BigDecimal::add));
        saleOut.setTotalProductPrice(getSumValue(items, ErpSaleOutItemDO::getTotalPrice, BigDecimal::add, BigDecimal.ZERO));
        saleOut.setTotalTaxPrice(getSumValue(items, ErpSaleOutItemDO::getTaxPrice, BigDecimal::add, BigDecimal.ZERO));
        saleOut.setTotalPrice(saleOut.getTotalProductPrice().add(saleOut.getTotalTaxPrice()));
        saleOut.setDiscountPercent(BigDecimal.ZERO);
        saleOut.setDiscountPrice(BigDecimal.ZERO);
        saleOut.setOtherPrice(BigDecimal.ZERO);
    }

    private void calculatePurchaseOrderTotalPrice(ErpPurchaseOrderDO purchaseOrder, List<ErpPurchaseOrderItemDO> items) {
        purchaseOrder.setTotalCount(getSumValue(items, ErpPurchaseOrderItemDO::getCount, BigDecimal::add));
        purchaseOrder.setTotalProductPrice(getSumValue(items, ErpPurchaseOrderItemDO::getTotalPrice, BigDecimal::add, BigDecimal.ZERO));
        purchaseOrder.setTotalTaxPrice(getSumValue(items, ErpPurchaseOrderItemDO::getTaxPrice, BigDecimal::add, BigDecimal.ZERO));
        purchaseOrder.setTotalPrice(purchaseOrder.getTotalProductPrice().add(purchaseOrder.getTotalTaxPrice()));
        purchaseOrder.setDiscountPercent(BigDecimal.ZERO);
        purchaseOrder.setDiscountPrice(BigDecimal.ZERO);
    }

    private String operatorName() {
        return SecurityFrameworkUtils.getLoginUserNickname();
    }

}
