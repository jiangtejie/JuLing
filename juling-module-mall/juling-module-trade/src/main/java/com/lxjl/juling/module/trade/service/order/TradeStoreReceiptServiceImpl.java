package com.lxjl.juling.module.trade.service.order;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.framework.common.enums.UserTypeEnum;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.json.JsonUtils;
import com.lxjl.juling.framework.common.util.number.MoneyUtils;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.framework.security.core.util.SecurityFrameworkUtils;
import com.lxjl.juling.module.bill.api.BillPlatformApi;
import com.lxjl.juling.module.bill.enums.BillTypeConstants;
import com.lxjl.juling.module.erp.api.customer.ErpCustomerAccountApi;
import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerAccountRecordReqDTO;
import com.lxjl.juling.module.erp.api.customer.enums.CustomerAccountBizTypeEnum;
import com.lxjl.juling.module.erp.api.stock.ErpStoreStockApi;
import com.lxjl.juling.module.erp.api.stock.dto.ErpStoreReceiptInReqDTO;
import com.lxjl.juling.module.erp.api.storealloc.event.ErpStoreDeliveryAuditedEvent;
import com.lxjl.juling.module.erp.api.storealloc.event.ErpStoreDeliveryCancelledEvent;
import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeStoreReceiptPageReqVO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderItemDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderReceiptDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderReceiptItemDO;
import com.lxjl.juling.module.trade.dal.mysql.order.TradeOrderItemMapper;
import com.lxjl.juling.module.trade.dal.mysql.order.TradeOrderMapper;
import com.lxjl.juling.module.trade.dal.mysql.order.TradeOrderReceiptItemMapper;
import com.lxjl.juling.module.trade.dal.mysql.order.TradeOrderReceiptMapper;
import com.lxjl.juling.module.trade.enums.order.TradeOrderOperateTypeEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderReceiptStatusEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderStatusEnum;
import com.lxjl.juling.module.trade.enums.order.TradeStoreReceiptDiffTypeEnum;
import com.lxjl.juling.module.trade.enums.order.TradeStoreReceiptStatusEnum;
import com.lxjl.juling.module.trade.service.order.bo.TradeOrderLogCreateReqBO;
import com.lxjl.juling.module.trade.service.order.bo.TradeStoreReceiptSubmitReqBO;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertMap;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.*;

/**
 * 门店收货 Service 实现
 *
 * 三段账务口径（见 docs/store-receipt-and-receivables-design.md）：
 *   1) **应收数量**：以 ERP 配送出库单**实际发出的数量**为准（不是下单数量），
 *      因为工作台可能只下推了一部分（alloc_count ≤ 下单量）。
 *   2) **门店库存**：门店确认收货时，按「实收数量」以一行一批次记入门店仓
 *      （bizType = STORE_RECEIPT，bizItemId = 收货单行 id，天然幂等）。
 *   3) **门店往来**：配送出库审核时已按出库金额挂应收；收货出现差异时，
 *      只按差异金额补一笔调整分录（少收冲减、多收增加），不重复挂全额。
 *
 * 事务边界：本服务的每个写方法都是一个事务；由 {@link TradeStoreDeliveryListener}
 * 在 ERP 出库审核的**同一事务**里调用建单逻辑，保证「中心库出库 ↔ 订单已发货 ↔ 收货单」一致。
 *
 * @author 亚特
 */
@Slf4j
@Service
@Validated
public class TradeStoreReceiptServiceImpl implements TradeStoreReceiptService {

    @Resource
    private TradeOrderReceiptMapper receiptMapper;
    @Resource
    private TradeOrderReceiptItemMapper receiptItemMapper;
    @Resource
    private TradeOrderMapper tradeOrderMapper;
    @Resource
    private TradeOrderItemMapper tradeOrderItemMapper;

    @Resource
    private BillPlatformApi billPlatformApi;
    @Resource
    private ErpStoreStockApi erpStoreStockApi;
    @Resource
    private ErpCustomerAccountApi erpCustomerAccountApi;

    @Resource
    private TradeOrderLogService tradeOrderLogService;

    /**
     * H5 待收货列表的默认分页（与 PageParam 的默认值保持一致）
     */
    private static final Integer DEFAULT_PAGE_NO = 1;
    private static final Integer DEFAULT_PAGE_SIZE = 10;

    // ==================== 出库联动 ====================

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void createReceiptByDelivery(ErpStoreDeliveryAuditedEvent event) {
        // 1. 幂等：同一张配送出库单只建一张收货单
        if (receiptMapper.selectBySaleOutId(event.getSaleOutId()) != null) {
            log.info("[createReceiptByDelivery][出库单({}) 已生成收货单，幂等跳过]", event.getSaleOutNo());
            return;
        }
        TradeOrderDO order = tradeOrderMapper.selectById(event.getSourceOrderId());
        if (order == null) {
            log.warn("[createReceiptByDelivery][出库单({}) 关联的要货单({}) 不存在，跳过]",
                    event.getSaleOutNo(), event.getSourceOrderId());
            return;
        }
        if (TradeOrderStatusEnum.isCanceled(order.getStatus())) {
            log.warn("[createReceiptByDelivery][要货单({}) 已取消，跳过生成收货单]", order.getNo());
            return;
        }

        // 2. 订单行：回写已发货数量 + 组装收货明细（应收数量 = 实际发货数量）
        Map<Long, TradeOrderItemDO> orderItemMap = convertMap(
                tradeOrderItemMapper.selectListByOrderId(order.getId()), TradeOrderItemDO::getId);
        List<TradeOrderReceiptItemDO> receiptItems = new ArrayList<>();
        for (ErpStoreDeliveryAuditedEvent.Item eventItem : event.getItems()) {
            TradeOrderItemDO orderItem = eventItem.getSourceItemId() == null
                    ? null : orderItemMap.get(eventItem.getSourceItemId());
            if (orderItem == null) {
                log.warn("[createReceiptByDelivery][出库单({}) 的物料({}) 找不到对应要货单行({})，该行不生成收货明细]",
                        event.getSaleOutNo(), eventItem.getProductId(), eventItem.getSourceItemId());
                continue;
            }
            BigDecimal deliveredCount = nvl(eventItem.getCount());
            tradeOrderItemMapper.updateById(new TradeOrderItemDO().setId(orderItem.getId())
                    .setDeliveredCount(nvl(orderItem.getDeliveredCount()).add(deliveredCount)));
            receiptItems.add(TradeOrderReceiptItemDO.builder()
                    .orderItemId(orderItem.getId())
                    .spuId(orderItem.getSpuId()).skuId(orderItem.getSkuId())
                    .spuName(orderItem.getSpuName()).properties(propertyText(orderItem.getProperties()))
                    .picUrl(orderItem.getPicUrl())
                    .productId(eventItem.getProductId())
                    .price(nvl(eventItem.getUnitPrice()))
                    .expectCount(deliveredCount)
                    .receiptCount(BigDecimal.ZERO).diffCount(BigDecimal.ZERO).diffAmount(BigDecimal.ZERO)
                    .build());
        }
        if (receiptItems.isEmpty()) {
            log.warn("[createReceiptByDelivery][出库单({}) 没有可生成收货明细的行，跳过]", event.getSaleOutNo());
            return;
        }

        // 3. 订单 → 已发货（已经是已发货/已完成时保留原状态：这是同一订单的第二批配送）
        Integer beforeStatus = order.getStatus();
        boolean statusChanged = TradeOrderStatusEnum.isUndelivered(beforeStatus);
        if (statusChanged) {
            tradeOrderMapper.updateById(new TradeOrderDO().setId(order.getId())
                    .setStatus(TradeOrderStatusEnum.DELIVERED.getStatus())
                    .setDeliveryTime(ObjectUtil.defaultIfNull(event.getDeliveryTime(), LocalDateTime.now()))
                    .setReceiptStatus(TradeOrderReceiptStatusEnum.NONE.getStatus()));
        }

        // 4. 生成收货单（待确认）
        String no = generateReceiptNo();
        TradeOrderReceiptDO receipt = TradeOrderReceiptDO.builder()
                .no(no).orderId(order.getId()).orderNo(order.getNo())
                .customerId(event.getCustomerId())
                .deptId(order.getDeptId())
                .memberUserId(order.getUserId())
                .warehouseId(erpStoreStockApi.getStoreWarehouseId(event.getCustomerId()))
                .saleOutId(event.getSaleOutId()).saleOutNo(event.getSaleOutNo())
                .status(TradeStoreReceiptStatusEnum.PENDING.getStatus())
                .diffType(TradeStoreReceiptDiffTypeEnum.NONE.getStatus())
                .totalCount(BigDecimal.ZERO).receiptCount(BigDecimal.ZERO).diffCount(BigDecimal.ZERO)
                .totalPrice(BigDecimal.ZERO).receiptPrice(BigDecimal.ZERO).diffAmount(BigDecimal.ZERO)
                .build();
        receiptMapper.insert(receipt);
        receiptItems.forEach(item -> item.setReceiptId(receipt.getId()));
        receiptItemMapper.insertBatch(receiptItems);

        // 5. 订单日志
        if (statusChanged) {
            tradeOrderLogService.createOrderLog(new TradeOrderLogCreateReqBO()
                    .setUserId(SecurityFrameworkUtils.getLoginUserId())
                    .setUserType(UserTypeEnum.ADMIN.getValue())
                    .setOrderId(order.getId()).setBeforeStatus(beforeStatus)
                    .setAfterStatus(TradeOrderStatusEnum.DELIVERED.getStatus())
                    .setOperateType(TradeOrderOperateTypeEnum.ERP_DELIVERY.getType())
                    .setContent("ERP 配送出库审核，配送出库单：" + event.getSaleOutNo() + "，中心库已发货"));
        }
        log.info("[createReceiptByDelivery][要货单({}) → 收货单({})，共 {} 行，应收合计 {}]",
                order.getNo(), no, receiptItems.size(),
                receiptItems.stream().map(TradeOrderReceiptItemDO::getExpectCount).reduce(BigDecimal.ZERO, BigDecimal::add));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancelReceiptByDelivery(ErpStoreDeliveryCancelledEvent event) {
        TradeOrderReceiptDO receipt = receiptMapper.selectBySaleOutId(event.getSaleOutId());
        if (receipt == null) {
            return;
        }
        // 已确认收货：不允许反审核（会计上「货已到店」不能一笔勾销），必须先走门店退货
        if (TradeStoreReceiptStatusEnum.CONFIRMED.getStatus().equals(receipt.getStatus())) {
            throw exception(ORDER_RECEIPT_DELIVERY_CANCEL_FAIL, event.getSaleOutNo());
        }
        if (TradeStoreReceiptStatusEnum.CANCELED.getStatus().equals(receipt.getStatus())) {
            return;
        }
        // 1. 作废收货单
        receiptMapper.updateById(new TradeOrderReceiptDO().setId(receipt.getId())
                .setStatus(TradeStoreReceiptStatusEnum.CANCELED.getStatus())
                .setCancelUserId(SecurityFrameworkUtils.getLoginUserId())
                .setCancelTime(LocalDateTime.now())
                .setCancelReason("配送出库单(" + event.getSaleOutNo() + ")反审核"));
        // 2. 订单退回待发货 + 回退已发货数量
        TradeOrderDO order = tradeOrderMapper.selectById(receipt.getOrderId());
        List<TradeOrderReceiptItemDO> items = receiptItemMapper.selectListByReceiptId(receipt.getId());
        Map<Long, TradeOrderItemDO> orderItemMap = convertMap(
                tradeOrderItemMapper.selectListByOrderId(receipt.getOrderId()), TradeOrderItemDO::getId);
        for (TradeOrderReceiptItemDO item : items) {
            TradeOrderItemDO orderItem = orderItemMap.get(item.getOrderItemId());
            if (orderItem == null) {
                continue;
            }
            BigDecimal delivered = nvl(orderItem.getDeliveredCount()).subtract(nvl(item.getExpectCount()));
            tradeOrderItemMapper.updateById(new TradeOrderItemDO().setId(orderItem.getId())
                    .setDeliveredCount(delivered.max(BigDecimal.ZERO)));
        }
        if (order != null && TradeOrderStatusEnum.isDelivered(order.getStatus())) {
            tradeOrderMapper.updateById(new TradeOrderDO().setId(order.getId())
                    .setStatus(TradeOrderStatusEnum.UNDELIVERED.getStatus()));
            tradeOrderLogService.createOrderLog(new TradeOrderLogCreateReqBO()
                    .setUserId(SecurityFrameworkUtils.getLoginUserId())
                    .setUserType(UserTypeEnum.ADMIN.getValue())
                    .setOrderId(order.getId())
                    .setBeforeStatus(TradeOrderStatusEnum.DELIVERED.getStatus())
                    .setAfterStatus(TradeOrderStatusEnum.UNDELIVERED.getStatus())
                    .setOperateType(TradeOrderOperateTypeEnum.ERP_DELIVERY_CANCEL.getType())
                    .setContent("ERP 配送出库反审核，配送出库单：" + event.getSaleOutNo() + "，退回待发货"));
        }
        log.info("[cancelReceiptByDelivery][出库单({}) 反审核 → 收货单({}) 已作废]", event.getSaleOutNo(), receipt.getNo());
    }

    // ==================== 门店确认收货 ====================

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long submitReceipt(TradeStoreReceiptSubmitReqBO reqBO) {
        // 1. 定位收货单：订单当前有效（未作废）的那一张
        TradeOrderDO order = tradeOrderMapper.selectById(reqBO.getOrderId());
        if (order == null) {
            throw exception(ORDER_NOT_FOUND);
        }
        TradeOrderReceiptDO receipt = receiptMapper.selectValidByOrderId(order.getId());
        if (receipt == null) {
            throw exception(ORDER_RECEIPT_NOT_EXISTS);
        }
        if (!TradeStoreReceiptStatusEnum.PENDING.getStatus().equals(receipt.getStatus())) {
            throw exception(ORDER_RECEIPT_ALREADY_CONFIRMED);
        }
        if (!TradeOrderStatusEnum.haveDelivered(order.getStatus())) {
            throw exception(ORDER_RECEIPT_ORDER_NOT_DELIVERED);
        }
        // 2. 逐行核算实收与差异
        List<TradeOrderReceiptItemDO> items = receiptItemMapper.selectListByReceiptId(receipt.getId());
        if (CollUtil.isEmpty(items)) {
            throw exception(ORDER_RECEIPT_NO_DELIVERED_ITEM);
        }
        Map<Long, TradeStoreReceiptSubmitReqBO.Item> submitMap = new LinkedHashMap<>();
        if (CollUtil.isNotEmpty(reqBO.getItems())) {
            for (TradeStoreReceiptSubmitReqBO.Item submitItem : reqBO.getItems()) {
                if (submitMap.put(submitItem.getOrderItemId(), submitItem) != null) {
                    throw exception(ORDER_RECEIPT_ITEM_DUPLICATE, submitItem.getOrderItemId());
                }
            }
        }
        BigDecimal totalCount = BigDecimal.ZERO;
        BigDecimal totalPrice = BigDecimal.ZERO;
        BigDecimal receiptCount = BigDecimal.ZERO;
        BigDecimal receiptPrice = BigDecimal.ZERO;
        boolean hasLess = false;
        boolean hasMore = false;
        boolean hasDamaged = false;
        LocalDateTime now = LocalDateTime.now();
        for (TradeOrderReceiptItemDO item : items) {
            TradeStoreReceiptSubmitReqBO.Item submitItem = submitMap.get(item.getOrderItemId());
            BigDecimal expectCount = nvl(item.getExpectCount());
            BigDecimal actualCount = submitItem == null || submitItem.getReceiptCount() == null
                    ? expectCount : submitItem.getReceiptCount();
            // 2.1 数量合法性：只为负数不合法。
            //     **允许多收**（实收 > 应收）：中心库多发 / 供应商随车多发在餐饮配送里很常见，
            //     多出部分照实入门店仓并按配送价增加门店应收；差异类型记「多收」，便于总部事后核对。
            if (actualCount.compareTo(BigDecimal.ZERO) < 0) {
                throw exception(ORDER_RECEIPT_COUNT_ILLEGAL, item.getSpuName(), actualCount);
            }
            BigDecimal diffCount = actualCount.subtract(expectCount);
            if (diffCount.compareTo(BigDecimal.ZERO) > 0) {
                log.warn("[submitReceipt][收货单({}) 行({}) 多收 {}（应收 {} / 实收 {}），已按实收入账并增加门店应收]",
                        receipt.getNo(), item.getSpuName(), diffCount, expectCount, actualCount);
            }
            // 2.2 有差异必须说明原因（对账时最常被追问的就是「为什么少了」）
            String diffReason = submitItem == null ? null : submitItem.getDiffReason();
            if (diffCount.compareTo(BigDecimal.ZERO) != 0 && StrUtil.isBlank(diffReason)) {
                throw exception(ORDER_RECEIPT_DIFF_REASON_REQUIRED, item.getSpuName(), diffCount.toPlainString());
            }
            BigDecimal price = nvl(item.getPrice());
            BigDecimal diffAmount = MoneyUtils.priceMultiply(price, diffCount);
            // 2.3 更新明细（并回填内存对象，供门店仓入库使用）
            TradeOrderReceiptItemDO updateObj = new TradeOrderReceiptItemDO().setId(item.getId())
                    .setReceiptCount(actualCount).setDiffCount(diffCount).setDiffAmount(diffAmount)
                    .setDiffReason(diffReason);
            if (submitItem != null) {
                updateObj.setBatchNo(submitItem.getBatchNo())
                        .setProductionDate(submitItem.getProductionDate())
                        .setExpiryDate(submitItem.getExpiryDate())
                        .setRemark(submitItem.getRemark());
                item.setBatchNo(submitItem.getBatchNo());
                item.setProductionDate(submitItem.getProductionDate());
                item.setExpiryDate(submitItem.getExpiryDate());
            }
            receiptItemMapper.updateById(updateObj);
            item.setReceiptCount(actualCount);
            item.setDiffCount(diffCount);
            // 2.4 合计与差异类型
            totalCount = totalCount.add(expectCount);
            receiptCount = receiptCount.add(actualCount);
            totalPrice = totalPrice.add(MoneyUtils.priceMultiply(price, expectCount));
            receiptPrice = receiptPrice.add(MoneyUtils.priceMultiply(price, actualCount));
            if (diffCount.compareTo(BigDecimal.ZERO) < 0) {
                hasLess = true;
            } else if (diffCount.compareTo(BigDecimal.ZERO) > 0) {
                hasMore = true;
            }
            if (StrUtil.isNotBlank(diffReason) && StrUtil.contains(diffReason, "破损")) {
                hasDamaged = true;
            }
        }

        // 3. 门店仓入库：按实收数量、一行一批次（幂等键 = STORE_RECEIPT + 收货单行 id）
        erpStoreStockApi.receiveStoreReceipt(new ErpStoreReceiptInReqDTO()
                .setReceiptId(receipt.getId()).setReceiptNo(receipt.getNo())
                .setCustomerId(receipt.getCustomerId()).setDeptId(receipt.getDeptId())
                .setReceiptTime(now)
                .setItems(items.stream().map(item -> new ErpStoreReceiptInReqDTO.Item()
                        .setReceiptItemId(item.getId())
                        .setProductId(item.getProductId())
                        .setOrderItemId(item.getOrderItemId())
                        .setCount(nvl(item.getReceiptCount()))
                        .setUnitCost(nvl(item.getPrice()))
                        .setBatchNo(item.getBatchNo())
                        .setProductionDate(item.getProductionDate())
                        .setExpiryDate(item.getExpiryDate())
                        .setRemark("门店收货单 " + receipt.getNo()))
                        .toList()));

        // 4. 门店往来差异调整（少收 → 负数冲减应收；多收 → 正数增加应收）
        BigDecimal diffAmount = receiptPrice.subtract(totalPrice);
        if (diffAmount.compareTo(BigDecimal.ZERO) != 0) {
            erpCustomerAccountApi.record(new ErpCustomerAccountRecordReqDTO()
                    .setCustomerId(receipt.getCustomerId()).setDeptId(receipt.getDeptId())
                    .setBizType(CustomerAccountBizTypeEnum.RECEIPT_ADJUST.getType())
                    .setAmount(diffAmount).setBillTime(now)
                    .setSourceType(BillTypeConstants.STORE_RECEIPT).setSourceId(receipt.getId())
                    .setSourceNo(receipt.getNo())
                    .setRemark(diffAmount.compareTo(BigDecimal.ZERO) < 0 ? "门店收货少收冲减应收" : "门店收货多收增加应收"));
        }

        // 5. 收货单 → 已确认
        receiptMapper.updateById(new TradeOrderReceiptDO().setId(receipt.getId())
                .setStatus(TradeStoreReceiptStatusEnum.CONFIRMED.getStatus())
                .setDiffType(resolveDiffType(hasLess, hasMore, hasDamaged))
                .setTotalCount(totalCount).setReceiptCount(receiptCount)
                .setDiffCount(receiptCount.subtract(totalCount))
                .setTotalPrice(totalPrice).setReceiptPrice(receiptPrice)
                .setDiffAmount(diffAmount)
                .setReceiveTime(now)
                .setReceiverName(reqBO.getReceiverName()).setReceiverMobile(reqBO.getReceiverMobile())
                .setFileUrls(CollUtil.isEmpty(reqBO.getFileUrls()) ? null : JsonUtils.toJsonString(reqBO.getFileUrls()))
                .setRemark(reqBO.getRemark())
                .setMemberUserId(ObjectUtil.defaultIfNull(receipt.getMemberUserId(), reqBO.getOperatorUserId())));

        // 6. 订单行收货数量 + 订单聚合收货状态（全部收齐 → 订单完成）
        for (TradeOrderReceiptItemDO item : items) {
            tradeOrderItemMapper.updateById(new TradeOrderItemDO().setId(item.getOrderItemId())
                    .setReceiptCount(nvl(item.getReceiptCount())));
        }
        refreshOrderReceiptStatus(order);

        // 7. 订单日志
        boolean admin = UserTypeEnum.ADMIN.getValue().equals(reqBO.getOperatorUserType());
        tradeOrderLogService.createOrderLog(new TradeOrderLogCreateReqBO()
                .setUserId(ObjectUtil.defaultIfNull(reqBO.getOperatorUserId(), receipt.getMemberUserId()))
                .setUserType(ObjectUtil.defaultIfNull(reqBO.getOperatorUserType(), UserTypeEnum.MEMBER.getValue()))
                .setOrderId(order.getId()).setBeforeStatus(order.getStatus()).setAfterStatus(order.getStatus())
                .setOperateType(admin ? TradeOrderOperateTypeEnum.ADMIN_STORE_RECEIPT.getType()
                        : TradeOrderOperateTypeEnum.MEMBER_STORE_RECEIPT.getType())
                .setContent("门店确认收货，收货单：" + receipt.getNo()));
        log.info("[submitReceipt][收货单({}) 已确认：应收 {} / 实收 {}，差异 {}，差异金额 {}]",
                receipt.getNo(), totalCount, receiptCount, receiptCount.subtract(totalCount), diffAmount);
        return receipt.getId();
    }

    /**
     * 订单聚合收货状态
     *
     * 口径：**「还有没有待确认的收货单」决定订单是否收货完成**，而不是「实收数量是否等于发货数量」。
     * 为什么：少收（门店验收时确认缺斤少两）是门店的**最终结论**，此时订单就该收尾，
     * 差额通过门店往来调整 + 后续补货/折让去处理；若要求实收 = 发货才算完成，
     * 少收的订单会永远挂在「已发货」，反而掩盖了差异。
     * 一次配送只生成一张收货单，多次配送（分批出库）会生成多张，全部确认完才算收齐。
     */
    private void refreshOrderReceiptStatus(TradeOrderDO order) {
        List<TradeOrderItemDO> orderItems = tradeOrderItemMapper.selectListByOrderId(order.getId());
        boolean anyDelivered = orderItems.stream()
                .anyMatch(orderItem -> nvl(orderItem.getDeliveredCount()).compareTo(BigDecimal.ZERO) > 0);
        boolean allConfirmed = receiptMapper.selectListByOrderId(order.getId()).stream()
                .noneMatch(receipt -> TradeStoreReceiptStatusEnum.PENDING.getStatus().equals(receipt.getStatus()));
        Integer receiptStatus = !anyDelivered ? TradeOrderReceiptStatusEnum.NONE.getStatus()
                : (allConfirmed ? TradeOrderReceiptStatusEnum.ALL.getStatus()
                : TradeOrderReceiptStatusEnum.PART.getStatus());
        TradeOrderDO updateObj = new TradeOrderDO().setId(order.getId()).setReceiptStatus(receiptStatus);
        if (TradeOrderReceiptStatusEnum.ALL.getStatus().equals(receiptStatus)
                && TradeOrderStatusEnum.isDelivered(order.getStatus())) {
            updateObj.setStatus(TradeOrderStatusEnum.COMPLETED.getStatus())
                    .setReceiveTime(LocalDateTime.now());
        }
        tradeOrderMapper.updateById(updateObj);
    }

    private Integer resolveDiffType(boolean hasLess, boolean hasMore, boolean hasDamaged) {
        if (hasDamaged && (hasLess || hasMore)) {
            return TradeStoreReceiptDiffTypeEnum.MIXED.getStatus();
        }
        if (hasDamaged) {
            return TradeStoreReceiptDiffTypeEnum.DAMAGED.getStatus();
        }
        if (hasLess && hasMore) {
            return TradeStoreReceiptDiffTypeEnum.MIXED.getStatus();
        }
        if (hasLess) {
            return TradeStoreReceiptDiffTypeEnum.LESS.getStatus();
        }
        if (hasMore) {
            return TradeStoreReceiptDiffTypeEnum.MORE.getStatus();
        }
        return TradeStoreReceiptDiffTypeEnum.NONE.getStatus();
    }

    // ==================== 作废与查询 ====================

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancelReceipt(Long id, String reason) {
        TradeOrderReceiptDO receipt = validateReceiptExists(id);
        if (TradeStoreReceiptStatusEnum.CONFIRMED.getStatus().equals(receipt.getStatus())) {
            throw exception(ORDER_RECEIPT_CANCEL_FAIL_CONFIRMED);
        }
        if (TradeStoreReceiptStatusEnum.CANCELED.getStatus().equals(receipt.getStatus())) {
            return;
        }
        receiptMapper.updateById(new TradeOrderReceiptDO().setId(id)
                .setStatus(TradeStoreReceiptStatusEnum.CANCELED.getStatus())
                .setCancelUserId(SecurityFrameworkUtils.getLoginUserId())
                .setCancelTime(LocalDateTime.now()).setCancelReason(reason));
        tradeOrderLogService.createOrderLog(new TradeOrderLogCreateReqBO()
                .setUserId(SecurityFrameworkUtils.getLoginUserId())
                .setUserType(UserTypeEnum.ADMIN.getValue())
                .setOrderId(receipt.getOrderId()).setAfterStatus(receipt.getStatus())
                .setOperateType(TradeOrderOperateTypeEnum.ADMIN_STORE_RECEIPT_CANCEL.getType())
                .setContent("门店收货单作废：" + receipt.getNo() + "，原因：" + StrUtil.blankToDefault(reason, "-")));
        log.info("[cancelReceipt][收货单({}) 已作废，原因：{}]", receipt.getNo(), reason);
    }

    @Override
    public TradeOrderReceiptDO getReceipt(Long id) {
        return receiptMapper.selectById(id);
    }

    @Override
    public TradeOrderReceiptDO getReceiptByOrderId(Long orderId) {
        if (orderId == null) {
            return null;
        }
        return receiptMapper.selectValidByOrderId(orderId);
    }

    @Override
    public List<TradeOrderReceiptItemDO> getReceiptItemList(Long receiptId) {
        return receiptItemMapper.selectListByReceiptId(receiptId);
    }

    @Override
    public PageResult<TradeOrderReceiptDO> getReceiptPage(TradeStoreReceiptPageReqVO pageReqVO) {
        return receiptMapper.selectPage(pageReqVO);
    }

    @Override
    public PageResult<TradeOrderReceiptDO> getPendingPageByMember(Long memberUserId, Integer pageNo, Integer pageSize) {
        return receiptMapper.selectPendingPageByMember(memberUserId,
                ObjectUtil.defaultIfNull(pageNo, DEFAULT_PAGE_NO),
                ObjectUtil.defaultIfNull(pageSize, DEFAULT_PAGE_SIZE));
    }

    private TradeOrderReceiptDO validateReceiptExists(Long id) {
        TradeOrderReceiptDO receipt = receiptMapper.selectById(id);
        if (receipt == null) {
            throw exception(ORDER_RECEIPT_NOT_EXISTS);
        }
        return receipt;
    }

    /**
     * 取收货单号（单据平台：STORE_RECEIPT → MDSH + yyyyMMdd + 6 位流水），并做唯一性兜底
     */
    private String generateReceiptNo() {
        String no = billPlatformApi.generateNo(BillTypeConstants.STORE_RECEIPT, null);
        if (receiptMapper.selectByNo(no) != null) {
            throw exception(ORDER_RECEIPT_NO_EXISTS);
        }
        return no;
    }

    private static BigDecimal nvl(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }

    /**
     * 商品属性（"规格:值" 逗号拼接）：trade_order_item.properties 是结构化列表，
     * 收货单明细只做展示快照，因此拍平成字符串。
     */
    private static String propertyText(List<TradeOrderItemDO.Property> properties) {
        if (CollUtil.isEmpty(properties)) {
            return null;
        }
        return properties.stream()
                .map(property -> StrUtil.blankToDefault(property.getPropertyName(), "")
                        + ":" + StrUtil.blankToDefault(property.getValueName(), ""))
                .collect(Collectors.joining(","));
    }

}
