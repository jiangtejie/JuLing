package com.lxjl.juling.module.erp.service.stock;

import cn.hutool.core.collection.CollUtil;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.number.MoneyUtils;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.erp.controller.admin.stock.vo.in.ErpStockInPageReqVO;
import com.lxjl.juling.module.erp.controller.admin.stock.vo.in.ErpStockInSaveReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.product.ErpProductDO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockInDO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockInItemDO;
import com.lxjl.juling.module.bill.api.BillPlatformApi;
import com.lxjl.juling.module.bill.enums.BillTypeConstants;
import com.lxjl.juling.module.erp.dal.mysql.stock.ErpStockInItemMapper;
import com.lxjl.juling.module.erp.dal.mysql.stock.ErpStockInMapper;
import com.lxjl.juling.module.erp.enums.ErpAuditStatus;
import com.lxjl.juling.module.erp.enums.stock.ErpStockRecordBizTypeEnum;
import com.lxjl.juling.module.erp.service.product.ErpProductService;
import com.lxjl.juling.module.erp.service.purchase.ErpSupplierService;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchInReqBO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchReverseReqBO;
import jakarta.annotation.Resource;
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
 * ERP 其它入库单 Service 实现类
 *
 * @author 亚特
 */
@Service
@Validated
public class ErpStockInServiceImpl implements ErpStockInService {

    @Resource
    private ErpStockInMapper stockInMapper;
    @Resource
    private ErpStockInItemMapper stockInItemMapper;

    @Resource
    private BillPlatformApi billPlatformApi;

    @Resource
    private ErpProductService productService;
    @Resource
    private ErpWarehouseService warehouseService;
    @Resource
    private ErpSupplierService supplierService;
    @Resource
    private ErpStockBatchService stockBatchService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createStockIn(ErpStockInSaveReqVO createReqVO) {
        // 1.1 校验入库项的有效性
        List<ErpStockInItemDO> stockInItems = validateStockInItems(createReqVO.getItems());
        // 1.2 校验供应商
        supplierService.validateSupplier(createReqVO.getSupplierId());
        // 1.3 生成入库单号（单据平台：OTHER_IN → QTRK + yyyyMMdd + 6 位流水），并校验唯一性
        String no = billPlatformApi.generateNo(BillTypeConstants.OTHER_IN, null);
        if (stockInMapper.selectByNo(no) != null) {
            throw exception(STOCK_IN_NO_EXISTS);
        }

        // 2.1 插入入库单
        ErpStockInDO stockIn = BeanUtils.toBean(createReqVO, ErpStockInDO.class, in -> in
                .setNo(no).setStatus(ErpAuditStatus.PROCESS.getStatus())
                .setTotalCount(getSumValue(stockInItems, ErpStockInItemDO::getCount, BigDecimal::add))
                .setTotalPrice(getSumValue(stockInItems, ErpStockInItemDO::getTotalPrice, BigDecimal::add, BigDecimal.ZERO)));
        stockInMapper.insert(stockIn);
        // 2.2 插入入库单项
        stockInItems.forEach(o -> o.setInId(stockIn.getId()));
        stockInItemMapper.insertBatch(stockInItems);
        return stockIn.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateStockIn(ErpStockInSaveReqVO updateReqVO) {
        // 1.1 校验存在
        ErpStockInDO stockIn = validateStockInExists(updateReqVO.getId());
        if (ErpAuditStatus.APPROVE.getStatus().equals(stockIn.getStatus())) {
            throw exception(STOCK_IN_UPDATE_FAIL_APPROVE, stockIn.getNo());
        }
        // 1.2 校验供应商
        supplierService.validateSupplier(updateReqVO.getSupplierId());
        // 1.3 校验入库项的有效性
        List<ErpStockInItemDO> stockInItems = validateStockInItems(updateReqVO.getItems());

        // 2.1 更新入库单
        ErpStockInDO updateObj = BeanUtils.toBean(updateReqVO, ErpStockInDO.class, in -> in
                .setTotalCount(getSumValue(stockInItems, ErpStockInItemDO::getCount, BigDecimal::add))
                .setTotalPrice(getSumValue(stockInItems, ErpStockInItemDO::getTotalPrice, BigDecimal::add)));
        stockInMapper.updateById(updateObj);
        // 2.2 更新入库单项
        updateStockInItemList(updateReqVO.getId(), stockInItems);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateStockInStatus(Long id, Integer status) {
        boolean approve = ErpAuditStatus.APPROVE.getStatus().equals(status);
        // 1.1 校验存在
        ErpStockInDO stockIn = validateStockInExists(id);
        // 1.2 校验状态
        if (stockIn.getStatus().equals(status)) {
            throw exception(approve ? STOCK_IN_APPROVE_FAIL : STOCK_IN_PROCESS_FAIL);
        }

        // 2. 更新状态
        int updateCount = stockInMapper.updateByIdAndStatus(id, stockIn.getStatus(),
                new ErpStockInDO().setStatus(status));
        if (updateCount == 0) {
            throw exception(approve ? STOCK_IN_APPROVE_FAIL : STOCK_IN_PROCESS_FAIL);
        }

        // 3. 变更库存（S2 库存中心：按批次入账 / 冲销；内部同时写库存流水并增量更新 erp_stock.count）
        List<ErpStockInItemDO> stockInItems = stockInItemMapper.selectListByInId(id);
        Integer bizType = approve ? ErpStockRecordBizTypeEnum.OTHER_IN.getType()
                : ErpStockRecordBizTypeEnum.OTHER_IN_CANCEL.getType();
        stockInItems.forEach(stockInItem -> {
            if (approve) {
                ErpStockBatchInReqBO inReqBO = new ErpStockBatchInReqBO();
                inReqBO.setWarehouseId(stockInItem.getWarehouseId());
                inReqBO.setProductId(stockInItem.getProductId());
                inReqBO.setBatchNo(stockInItem.getBatchNo());
                inReqBO.setProductionDate(stockInItem.getProductionDate());
                inReqBO.setExpiryDate(stockInItem.getExpiryDate());
                // 入库日期取单据的入库时间：FIFO 的「先入库先出」按它排序
                inReqBO.setInDate(stockIn.getInTime() != null ? stockIn.getInTime().toLocalDate() : null);
                inReqBO.setCount(stockInItem.getCount());
                // 成本取入库单价
                inReqBO.setUnitCost(stockInItem.getProductPrice());
                inReqBO.setBizType(bizType);
                inReqBO.setBizId(stockInItem.getInId());
                inReqBO.setBizItemId(stockInItem.getId());
                inReqBO.setBizNo(stockIn.getNo());
                inReqBO.setRemark(stockInItem.getRemark());
                stockBatchService.receiveBatch(inReqBO);
            } else {
                stockBatchService.reverseReceive(new ErpStockBatchReverseReqBO()
                        .setSourceBizType(ErpStockRecordBizTypeEnum.OTHER_IN.getType())
                        .setSourceBizItemId(stockInItem.getId())
                        .setTargetBizType(bizType)
                        .setBizId(stockInItem.getInId())
                        .setBizNo(stockIn.getNo()));
            }
        });
    }

    private List<ErpStockInItemDO> validateStockInItems(List<ErpStockInSaveReqVO.Item> list) {
        // 1.1 校验产品存在
        List<ErpProductDO> productList = productService.validProductList(
                convertSet(list, ErpStockInSaveReqVO.Item::getProductId));
        Map<Long, ErpProductDO> productMap = convertMap(productList, ErpProductDO::getId);
        // 1.2 校验仓库存在
        warehouseService.validWarehouseList(convertSet(
                list, ErpStockInSaveReqVO.Item::getWarehouseId));
        // 2. 转化为 ErpStockInItemDO 列表
        return convertList(list, o -> BeanUtils.toBean(o, ErpStockInItemDO.class, item -> item
                .setProductUnitId(productMap.get(item.getProductId()).getUnitId())
                .setTotalPrice(MoneyUtils.priceMultiply(item.getProductPrice(), item.getCount()))));
    }

    private void updateStockInItemList(Long id, List<ErpStockInItemDO> newList) {
        // 第一步，对比新老数据，获得添加、修改、删除的列表
        List<ErpStockInItemDO> oldList = stockInItemMapper.selectListByInId(id);
        List<List<ErpStockInItemDO>> diffList = diffList(oldList, newList, // id 不同，就认为是不同的记录
                (oldVal, newVal) -> oldVal.getId().equals(newVal.getId()));

        // 第二步，批量添加、修改、删除
        if (CollUtil.isNotEmpty(diffList.get(0))) {
            diffList.get(0).forEach(o -> o.setInId(id));
            stockInItemMapper.insertBatch(diffList.get(0));
        }
        if (CollUtil.isNotEmpty(diffList.get(1))) {
            stockInItemMapper.updateBatch(diffList.get(1));
        }
        if (CollUtil.isNotEmpty(diffList.get(2))) {
            stockInItemMapper.deleteByIds(convertList(diffList.get(2), ErpStockInItemDO::getId));
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteStockIn(List<Long> ids) {
        // 1. 校验不处于已审批
        List<ErpStockInDO> stockIns = stockInMapper.selectByIds(ids);
        if (CollUtil.isEmpty(stockIns)) {
            return;
        }
        stockIns.forEach(stockIn -> {
            if (ErpAuditStatus.APPROVE.getStatus().equals(stockIn.getStatus())) {
                throw exception(STOCK_IN_DELETE_FAIL_APPROVE, stockIn.getNo());
            }
        });

        // 2. 遍历删除，并记录操作日志
        stockIns.forEach(stockIn -> {
            // 2.1 删除入库单
            stockInMapper.deleteById(stockIn.getId());
            // 2.2 删除入库单项
            stockInItemMapper.deleteByInId(stockIn.getId());
        });
    }

    private ErpStockInDO validateStockInExists(Long id) {
        ErpStockInDO stockIn = stockInMapper.selectById(id);
        if (stockIn == null) {
            throw exception(STOCK_IN_NOT_EXISTS);
        }
        return stockIn;
    }

    @Override
    public ErpStockInDO getStockIn(Long id) {
        return stockInMapper.selectById(id);
    }

    @Override
    public PageResult<ErpStockInDO> getStockInPage(ErpStockInPageReqVO pageReqVO) {
        return stockInMapper.selectPage(pageReqVO);
    }

    // ==================== 入库项 ====================

    @Override
    public List<ErpStockInItemDO> getStockInItemListByInId(Long inId) {
        return stockInItemMapper.selectListByInId(inId);
    }

    @Override
    public List<ErpStockInItemDO> getStockInItemListByInIds(Collection<Long> inIds) {
        if (CollUtil.isEmpty(inIds)) {
            return Collections.emptyList();
        }
        return stockInItemMapper.selectListByInIds(inIds);
    }

}
