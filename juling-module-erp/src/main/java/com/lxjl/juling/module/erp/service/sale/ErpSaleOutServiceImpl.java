package com.lxjl.juling.module.erp.service.sale;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.number.MoneyUtils;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.framework.security.core.util.SecurityFrameworkUtils;
import com.lxjl.juling.module.bill.api.BillPlatformApi;
import com.lxjl.juling.module.bill.api.dto.BillLogCreateReqDTO;
import com.lxjl.juling.module.bill.enums.BillTypeConstants;
import com.lxjl.juling.module.erp.controller.admin.sale.vo.out.ErpSaleOutPageReqVO;
import com.lxjl.juling.module.erp.controller.admin.sale.vo.out.ErpSaleOutSaveReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.product.ErpProductDO;
import com.lxjl.juling.module.erp.dal.dataobject.sale.ErpSaleOrderDO;
import com.lxjl.juling.module.erp.dal.dataobject.sale.ErpSaleOutDO;
import com.lxjl.juling.module.erp.dal.dataobject.sale.ErpSaleOutItemDO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockRecordDO;
import com.lxjl.juling.module.erp.dal.mysql.sale.ErpSaleOutItemMapper;
import com.lxjl.juling.module.erp.dal.mysql.sale.ErpSaleOutMapper;
import com.lxjl.juling.module.erp.enums.ErpAuditStatus;
import com.lxjl.juling.module.erp.enums.stock.ErpStockRecordBizTypeEnum;
import com.lxjl.juling.module.erp.service.finance.ErpAccountService;
import com.lxjl.juling.module.erp.service.product.ErpProductService;
import com.lxjl.juling.module.erp.service.stock.ErpStockBatchService;
import com.lxjl.juling.module.erp.service.stock.ErpStockRecordService;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchOutReqBO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchReverseReqBO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockRecordCreateReqBO;
import com.lxjl.juling.module.system.api.user.AdminUserApi;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.*;
import static com.lxjl.juling.module.erp.enums.ErrorCodeConstants.*;

// TODO 亚特：记录操作日志

/**
 * ERP 销售出库 Service 实现类
 *
 * S2 库存中心（切片二）：审核通过时逐行按批次 FIFO 扣减并结转成本（{@link ErpStockBatchService#issueByFifo}），
 * 反审核按原出库流水逐批回滚；批次记账内部会写「一行一批次」的库存流水并增量更新 erp_stock.count（双写），
 * 因此不再直接调用 {@link ErpStockRecordService#createStockRecord}，只有历史单据才退回旧口径。
 *
 * 注意：门店要货工作台的「统配下推」（ErpStoreAllocApiImpl#pushCentralDelivery）生成的正是本表的
 * 配送出库单（XSCK…），所以接入这里等于把工作台下推也接上了批次库存账。
 *
 * @author 亚特
 */
@Slf4j
@Service
@Validated
public class ErpSaleOutServiceImpl implements ErpSaleOutService {

    @Resource
    private ErpSaleOutMapper saleOutMapper;
    @Resource
    private ErpSaleOutItemMapper saleOutItemMapper;

    @Resource
    private BillPlatformApi billPlatformApi;

    @Resource
    private ErpProductService productService;
    @Resource
    @Lazy // 延迟加载，避免循环依赖
    private ErpSaleOrderService saleOrderService;
    @Resource
    private ErpAccountService accountService;
    @Resource
    private ErpStockRecordService stockRecordService;
    @Resource
    private ErpStockBatchService stockBatchService;

    @Resource
    private AdminUserApi adminUserApi;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createSaleOut(ErpSaleOutSaveReqVO createReqVO) {
        // 1.1 校验销售订单已审核
        ErpSaleOrderDO saleOrder = saleOrderService.validateSaleOrder(createReqVO.getOrderId());
        // 1.2 校验出库项的有效性
        List<ErpSaleOutItemDO> saleOutItems = validateSaleOutItems(createReqVO.getItems());
        // 1.3 校验结算账户
        accountService.validateAccount(createReqVO.getAccountId());
        // 1.4 校验销售人员
        if (createReqVO.getSaleUserId() != null) {
            adminUserApi.validateUser(createReqVO.getSaleUserId());
        }
        // 1.5 生成出库单号（单据平台：bill_type 为唯一真相来源，前缀 + yyyyMMdd + 6 位流水），并校验唯一性
        // 注意：ERP 销售出库与「配送出库单」是同一张单（同一张 erp_sale_out、同为 XSCK 前缀），
        // 单据平台里已注册的类型就是 DELIVERY_OUT（31_bill_platform_fix.sql 把前缀对齐为 XSCK），
        // 故此处复用 DELIVERY_OUT，而不是另注册一个 SALE_OUT —— 否则同一张表会有两个序列，重新引入撞号风险。
        String no = billPlatformApi.generateNo(BillTypeConstants.DELIVERY_OUT, null);
        if (saleOutMapper.selectByNo(no) != null) {
            throw exception(SALE_OUT_NO_EXISTS);
        }

        // 2.1 插入出库
        ErpSaleOutDO saleOut = BeanUtils.toBean(createReqVO, ErpSaleOutDO.class, in -> in
                .setNo(no).setStatus(ErpAuditStatus.PROCESS.getStatus())
                // 已收款金额必须初始化为 0（而不是 null）：否则"可收款"的查询条件
                // t.receipt_price < t.total_price 在 SQL 三值逻辑下恒不成立，出库单不会出现在收款单的"选择销售出库单"弹窗里
                .setReceiptPrice(BigDecimal.ZERO))
                .setOrderNo(saleOrder.getNo()).setCustomerId(saleOrder.getCustomerId());
        calculateTotalPrice(saleOut, saleOutItems);
        saleOutMapper.insert(saleOut);
        // 2.2 插入出库项
        saleOutItems.forEach(o -> o.setOutId(saleOut.getId()));
        saleOutItemMapper.insertBatch(saleOutItems);

        // 2.3 单据平台：写创建日志（留痕）
        billPlatformApi.log(new BillLogCreateReqDTO()
                .setBillType(BillTypeConstants.DELIVERY_OUT).setBillId(saleOut.getId()).setBillNo(no)
                .setOperateType("CREATE").setAfterStatus(saleOut.getStatus())
                .setOperatorId(SecurityFrameworkUtils.getLoginUserId()));

        // 3. 更新销售订单的出库数量
        updateSaleOrderOutCount(createReqVO.getOrderId());
        return saleOut.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateSaleOut(ErpSaleOutSaveReqVO updateReqVO) {
        // 1.1 校验存在
        ErpSaleOutDO saleOut = validateSaleOutExists(updateReqVO.getId());
        if (ErpAuditStatus.APPROVE.getStatus().equals(saleOut.getStatus())) {
            throw exception(SALE_OUT_UPDATE_FAIL_APPROVE, saleOut.getNo());
        }
        // 1.2 校验销售订单已审核
        ErpSaleOrderDO saleOrder = saleOrderService.validateSaleOrder(updateReqVO.getOrderId());
        // 1.3 校验结算账户
        accountService.validateAccount(updateReqVO.getAccountId());
        // 1.4 校验销售人员
        if (updateReqVO.getSaleUserId() != null) {
            adminUserApi.validateUser(updateReqVO.getSaleUserId());
        }
        // 1.5 校验订单项的有效性
        List<ErpSaleOutItemDO> saleOutItems = validateSaleOutItems(updateReqVO.getItems());

        // 2.1 更新出库
        ErpSaleOutDO updateObj = BeanUtils.toBean(updateReqVO, ErpSaleOutDO.class)
                .setOrderNo(saleOrder.getNo()).setCustomerId(saleOrder.getCustomerId());
        calculateTotalPrice(updateObj, saleOutItems);
        saleOutMapper.updateById(updateObj);
        // 2.2 更新出库项
        updateSaleOutItemList(updateReqVO.getId(), saleOutItems);

        // 3.1 更新销售订单的出库数量
        updateSaleOrderOutCount(updateObj.getOrderId());
        // 3.2 注意：如果销售订单编号变更了，需要更新“老”销售订单的出库数量
        if (ObjectUtil.notEqual(saleOut.getOrderId(), updateObj.getOrderId())) {
            updateSaleOrderOutCount(saleOut.getOrderId());
        }
    }

    private void calculateTotalPrice(ErpSaleOutDO saleOut, List<ErpSaleOutItemDO> saleOutItems) {
        saleOut.setTotalCount(getSumValue(saleOutItems, ErpSaleOutItemDO::getCount, BigDecimal::add));
        saleOut.setTotalProductPrice(getSumValue(saleOutItems, ErpSaleOutItemDO::getTotalPrice, BigDecimal::add, BigDecimal.ZERO));
        saleOut.setTotalTaxPrice(getSumValue(saleOutItems, ErpSaleOutItemDO::getTaxPrice, BigDecimal::add, BigDecimal.ZERO));
        saleOut.setTotalPrice(saleOut.getTotalProductPrice().add(saleOut.getTotalTaxPrice()));
        // 计算优惠价格
        if (saleOut.getDiscountPercent() == null) {
            saleOut.setDiscountPercent(BigDecimal.ZERO);
        }
        saleOut.setDiscountPrice(MoneyUtils.priceMultiplyPercent(saleOut.getTotalPrice(), saleOut.getDiscountPercent()));
        // 其他费用可能未传值，按 0 处理，避免 NPE
        BigDecimal otherPrice = saleOut.getOtherPrice() != null ? saleOut.getOtherPrice() : BigDecimal.ZERO;
        saleOut.setTotalPrice(saleOut.getTotalPrice().subtract(saleOut.getDiscountPrice().add(otherPrice)));
    }

    private void updateSaleOrderOutCount(Long orderId) {
        // 1.1 查询销售订单对应的销售出库单列表
        List<ErpSaleOutDO> saleOuts = saleOutMapper.selectListByOrderId(orderId);
        // 1.2 查询对应的销售订单项的出库数量
        Map<Long, BigDecimal> returnCountMap = saleOutItemMapper.selectOrderItemCountSumMapByOutIds(
                convertList(saleOuts, ErpSaleOutDO::getId));
        // 2. 更新销售订单的出库数量
        saleOrderService.updateSaleOrderOutCount(orderId, returnCountMap);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateSaleOutStatus(Long id, Integer status) {
        boolean approve = ErpAuditStatus.APPROVE.getStatus().equals(status);
        // 1.1 校验存在
        ErpSaleOutDO saleOut = validateSaleOutExists(id);
        // 1.2 校验状态
        if (saleOut.getStatus().equals(status)) {
            throw exception(approve ? SALE_OUT_APPROVE_FAIL : SALE_OUT_PROCESS_FAIL);
        }
        // 1.3 校验已退款
        if (!approve && saleOut.getReceiptPrice() != null
                && saleOut.getReceiptPrice().compareTo(BigDecimal.ZERO) > 0) {
            throw exception(SALE_OUT_PROCESS_FAIL_EXISTS_RECEIPT);
        }

        // 2. 更新状态
        int updateCount = saleOutMapper.updateByIdAndStatus(id, saleOut.getStatus(),
                new ErpSaleOutDO().setStatus(status));
        if (updateCount == 0) {
            throw exception(approve ? SALE_OUT_APPROVE_FAIL : SALE_OUT_PROCESS_FAIL);
        }

        // 3. 变更库存（S2 库存中心：按批次 FIFO 扣减并结转成本；反审核按原流水逐批回滚）
        List<ErpSaleOutItemDO> saleOutItems = saleOutItemMapper.selectListByOutId(id);
        Integer bizType = approve ? ErpStockRecordBizTypeEnum.SALE_OUT.getType()
                : ErpStockRecordBizTypeEnum.SALE_OUT_CANCEL.getType();
        saleOutItems.forEach(saleOutItem -> {
            if (approve) {
                issueSaleOutItemByFifo(saleOutItem, saleOut);
            } else {
                reverseSaleOutItemStock(saleOutItem, saleOut, bizType);
            }
        });
    }

    /**
     * 销售出库项出库：按批次 FIFO（先入库先出，同入库日期先到期先出）扣减并结转成本
     *
     * 返回值即 FIFO 扣减明细（批次 / 数量 / 单位成本 / 结转金额），供后续成本核算使用；
     * 批次库存不足时抛异常，整个事务回滚（不会出现扣了一半的情况，erp_stock 也一并回滚）。
     */
    private void issueSaleOutItemByFifo(ErpSaleOutItemDO saleOutItem, ErpSaleOutDO saleOut) {
        ErpStockBatchOutReqBO outReqBO = new ErpStockBatchOutReqBO();
        outReqBO.setWarehouseId(saleOutItem.getWarehouseId());
        outReqBO.setProductId(saleOutItem.getProductId());
        outReqBO.setCount(saleOutItem.getCount());
        outReqBO.setBizType(ErpStockRecordBizTypeEnum.SALE_OUT.getType());
        outReqBO.setBizId(saleOutItem.getOutId());
        outReqBO.setBizItemId(saleOutItem.getId());
        outReqBO.setBizNo(saleOut.getNo());
        outReqBO.setRemark(saleOutItem.getRemark());
        stockBatchService.issueByFifo(outReqBO);
    }

    /**
     * 销售出库项反审核：按原出库流水（一行一批次）逐批回滚数量与成本
     *
     * 历史兼容：接批次之前审核的出库单，流水里没有批次号，reverseIssue 无从回滚；
     * 此时退回旧口径只回补 erp_stock，并打告警日志——这是 erp_stock 与 erp_stock_batch
     * 已知偏差的来源之一，判据见 docs/stock-center.md §6。
     */
    private void reverseSaleOutItemStock(ErpSaleOutItemDO saleOutItem, ErpSaleOutDO saleOut, Integer cancelBizType) {
        int rolled = stockBatchService.reverseIssue(new ErpStockBatchReverseReqBO()
                .setSourceBizType(ErpStockRecordBizTypeEnum.SALE_OUT.getType())
                .setSourceBizItemId(saleOutItem.getId())
                .setTargetBizType(cancelBizType)
                .setBizId(saleOutItem.getOutId())
                .setBizNo(saleOut.getNo()));
        if (rolled > 0) {
            return;
        }
        // 判断是「本来就是旧口径的流水」还是「压根没有出库流水」：只有前者才需要按旧口径回补 erp_stock
        List<ErpStockRecordDO> records = stockRecordService.getStockRecordListByBizItem(
                ErpStockRecordBizTypeEnum.SALE_OUT.getType(), saleOutItem.getId());
        boolean legacyIssued = records.stream().anyMatch(record -> record.getCount() != null
                && record.getCount().compareTo(BigDecimal.ZERO) < 0 && StrUtil.isBlank(record.getBatchNo()));
        if (!legacyIssued) {
            log.warn("[updateSaleOutStatus][出库单({}) 出库项({}) 无可回滚的批次流水，跳过库存回滚]",
                    saleOut.getNo(), saleOutItem.getId());
            return;
        }
        stockRecordService.createStockRecord(new ErpStockRecordCreateReqBO(
                saleOutItem.getProductId(), saleOutItem.getWarehouseId(), saleOutItem.getCount(),
                cancelBizType, saleOutItem.getOutId(), saleOutItem.getId(), saleOut.getNo()));
        log.warn("[updateSaleOutStatus][历史单据({}) 出库项({}) 的流水无批次号，反审核按旧口径仅回补 erp_stock({} 个)，"
                        + "不产生批次流水]", saleOut.getNo(), saleOutItem.getId(), saleOutItem.getCount());
    }

    @Override
    public void updateSaleInReceiptPrice(Long id, BigDecimal receiptPrice) {
        ErpSaleOutDO saleOut = saleOutMapper.selectById(id);
        // 历史数据可能为 null，统一按 0 处理；用 compareTo 避免 BigDecimal 精度差异（0 与 0.000000）导致的误判
        BigDecimal oldReceiptPrice = saleOut.getReceiptPrice() != null ? saleOut.getReceiptPrice() : BigDecimal.ZERO;
        if (oldReceiptPrice.compareTo(receiptPrice) == 0) {
            return;
        }
        if (receiptPrice.compareTo(saleOut.getTotalPrice()) > 0) {
            throw exception(SALE_OUT_FAIL_RECEIPT_PRICE_EXCEED, receiptPrice,  saleOut.getTotalPrice());
        }
        saleOutMapper.updateById(new ErpSaleOutDO().setId(id).setReceiptPrice(receiptPrice));
    }

    private List<ErpSaleOutItemDO> validateSaleOutItems(List<ErpSaleOutSaveReqVO.Item> list) {
        // 1. 校验产品存在
        List<ErpProductDO> productList = productService.validProductList(
                convertSet(list, ErpSaleOutSaveReqVO.Item::getProductId));
        Map<Long, ErpProductDO> productMap = convertMap(productList, ErpProductDO::getId);
        // 2. 转化为 ErpSaleOutItemDO 列表
        return convertList(list, o -> BeanUtils.toBean(o, ErpSaleOutItemDO.class, item -> {
            item.setProductUnitId(productMap.get(item.getProductId()).getUnitId());
            item.setTotalPrice(MoneyUtils.priceMultiply(item.getProductPrice(), item.getCount()));
            if (item.getTotalPrice() == null) {
                return;
            }
            if (item.getTaxPercent() != null) {
                item.setTaxPrice(MoneyUtils.priceMultiplyPercent(item.getTotalPrice(), item.getTaxPercent()));
            }
        }));
    }

    private void updateSaleOutItemList(Long id, List<ErpSaleOutItemDO> newList) {
        // 第一步，对比新老数据，获得添加、修改、删除的列表
        List<ErpSaleOutItemDO> oldList = saleOutItemMapper.selectListByOutId(id);
        List<List<ErpSaleOutItemDO>> diffList = diffList(oldList, newList, // id 不同，就认为是不同的记录
                (oldVal, newVal) -> oldVal.getId().equals(newVal.getId()));

        // 第二步，批量添加、修改、删除
        if (CollUtil.isNotEmpty(diffList.get(0))) {
            diffList.get(0).forEach(o -> o.setOutId(id));
            saleOutItemMapper.insertBatch(diffList.get(0));
        }
        if (CollUtil.isNotEmpty(diffList.get(1))) {
            saleOutItemMapper.updateBatch(diffList.get(1));
        }
        if (CollUtil.isNotEmpty(diffList.get(2))) {
            saleOutItemMapper.deleteByIds(convertList(diffList.get(2), ErpSaleOutItemDO::getId));
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteSaleOut(List<Long> ids) {
        // 1. 校验不处于已审批
        List<ErpSaleOutDO> saleOuts = saleOutMapper.selectByIds(ids);
        if (CollUtil.isEmpty(saleOuts)) {
            return;
        }
        saleOuts.forEach(saleOut -> {
            if (ErpAuditStatus.APPROVE.getStatus().equals(saleOut.getStatus())) {
                throw exception(SALE_OUT_DELETE_FAIL_APPROVE, saleOut.getNo());
            }
        });

        // 2. 遍历删除，并记录操作日志
        saleOuts.forEach(saleOut -> {
            // 2.1 删除订单
            saleOutMapper.deleteById(saleOut.getId());
            // 2.2 删除订单项
            saleOutItemMapper.deleteByOutId(saleOut.getId());

            // 2.3 更新销售订单的出库数量
            updateSaleOrderOutCount(saleOut.getOrderId());
        });

    }

    private ErpSaleOutDO validateSaleOutExists(Long id) {
        ErpSaleOutDO saleOut = saleOutMapper.selectById(id);
        if (saleOut == null) {
            throw exception(SALE_OUT_NOT_EXISTS);
        }
        return saleOut;
    }

    @Override
    public ErpSaleOutDO getSaleOut(Long id) {
        return saleOutMapper.selectById(id);
    }

    @Override
    public ErpSaleOutDO validateSaleOut(Long id) {
        ErpSaleOutDO saleOut = validateSaleOutExists(id);
        if (ObjectUtil.notEqual(saleOut.getStatus(), ErpAuditStatus.APPROVE.getStatus())) {
            throw exception(SALE_OUT_NOT_APPROVE);
        }
        return saleOut;
    }

    @Override
    public PageResult<ErpSaleOutDO> getSaleOutPage(ErpSaleOutPageReqVO pageReqVO) {
        return saleOutMapper.selectPage(pageReqVO);
    }

    // ==================== 销售出库项 ====================

    @Override
    public List<ErpSaleOutItemDO> getSaleOutItemListByOutId(Long outId) {
        return saleOutItemMapper.selectListByOutId(outId);
    }

    @Override
    public List<ErpSaleOutItemDO> getSaleOutItemListByOutIds(Collection<Long> outIds) {
        if (CollUtil.isEmpty(outIds)) {
            return Collections.emptyList();
        }
        return saleOutItemMapper.selectListByOutIds(outIds);
    }

}
