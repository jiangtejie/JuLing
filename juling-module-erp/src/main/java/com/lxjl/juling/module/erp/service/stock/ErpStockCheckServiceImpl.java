package com.lxjl.juling.module.erp.service.stock;

import cn.hutool.core.collection.CollUtil;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.number.MoneyUtils;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.erp.controller.admin.stock.vo.check.ErpStockCheckPageReqVO;
import com.lxjl.juling.module.erp.controller.admin.stock.vo.check.ErpStockCheckSaveReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.product.ErpProductDO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockCheckDO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockCheckItemDO;
import com.lxjl.juling.module.bill.api.BillPlatformApi;
import com.lxjl.juling.module.bill.api.dto.BillLogCreateReqDTO;
import com.lxjl.juling.module.bill.enums.BillTypeConstants;
import com.lxjl.juling.module.erp.dal.mysql.stock.ErpStockCheckItemMapper;
import com.lxjl.juling.module.erp.dal.mysql.stock.ErpStockCheckMapper;
import com.lxjl.juling.module.erp.enums.ErpAuditStatus;
import com.lxjl.juling.module.erp.enums.stock.ErpStockRecordBizTypeEnum;
import com.lxjl.juling.module.erp.service.product.ErpProductService;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockRecordCreateReqBO;
import com.lxjl.juling.framework.security.core.util.SecurityFrameworkUtils;
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


/**
 * ERP 库存盘点单 Service 实现类
 *
 * @author 亚特
 */
@Service
@Validated
public class ErpStockCheckServiceImpl implements ErpStockCheckService {

    @Resource
    private ErpStockCheckMapper stockCheckMapper;
    @Resource
    private ErpStockCheckItemMapper stockCheckItemMapper;

    @Resource
    private BillPlatformApi billPlatformApi;

    @Resource
    private ErpProductService productService;
    @Resource
    private ErpWarehouseService warehouseService;
    @Resource
    private ErpStockRecordService stockRecordService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createStockCheck(ErpStockCheckSaveReqVO createReqVO) {
        // 1.1 校验盘点项的有效性
        List<ErpStockCheckItemDO> stockCheckItems = validateStockCheckItems(createReqVO.getItems());
        // 1.2 生成盘点单号（单据平台：STOCK_CHECK → QCPD + yyyyMMdd + 6 位流水），并校验唯一性
        String no = billPlatformApi.generateNo(BillTypeConstants.STOCK_CHECK, null);
        if (stockCheckMapper.selectByNo(no) != null) {
            throw exception(STOCK_CHECK_NO_EXISTS);
        }

        // 2.1 插入盘点单
        ErpStockCheckDO stockCheck = BeanUtils.toBean(createReqVO, ErpStockCheckDO.class, in -> in
                .setNo(no).setStatus(ErpAuditStatus.PROCESS.getStatus())
                .setTotalCount(getSumValue(stockCheckItems, ErpStockCheckItemDO::getCount, BigDecimal::add))
                .setTotalPrice(getSumValue(stockCheckItems, ErpStockCheckItemDO::getTotalPrice, BigDecimal::add, BigDecimal.ZERO)));
        stockCheckMapper.insert(stockCheck);
        // 2.2 插入盘点单项
        stockCheckItems.forEach(o -> o.setCheckId(stockCheck.getId()));
        stockCheckItemMapper.insertBatch(stockCheckItems);
        // 单据平台：写创建日志（留痕；与采购/销售单据同一入口）
        billPlatformApi.log(new BillLogCreateReqDTO()
                .setBillType(BillTypeConstants.STOCK_CHECK).setBillId(stockCheck.getId()).setBillNo(no)
                .setOperateType("CREATE").setAfterStatus(stockCheck.getStatus())
                .setOperatorId(SecurityFrameworkUtils.getLoginUserId()));
        return stockCheck.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateStockCheck(ErpStockCheckSaveReqVO updateReqVO) {
        // 1.1 校验存在
        ErpStockCheckDO stockCheck = validateStockCheckExists(updateReqVO.getId());
        if (ErpAuditStatus.APPROVE.getStatus().equals(stockCheck.getStatus())) {
            throw exception(STOCK_CHECK_UPDATE_FAIL_APPROVE, stockCheck.getNo());
        }
        // 1.2 校验盘点项的有效性
        List<ErpStockCheckItemDO> stockCheckItems = validateStockCheckItems(updateReqVO.getItems());

        // 2.1 更新盘点单
        ErpStockCheckDO updateObj = BeanUtils.toBean(updateReqVO, ErpStockCheckDO.class, in -> in
                .setTotalCount(getSumValue(stockCheckItems, ErpStockCheckItemDO::getCount, BigDecimal::add))
                .setTotalPrice(getSumValue(stockCheckItems, ErpStockCheckItemDO::getTotalPrice, BigDecimal::add)));
        stockCheckMapper.updateById(updateObj);
        // 2.2 更新盘点单项
        updateStockCheckItemList(updateReqVO.getId(), stockCheckItems);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateStockCheckStatus(Long id, Integer status) {
        boolean approve = ErpAuditStatus.APPROVE.getStatus().equals(status);
        // 1.1 校验存在
        ErpStockCheckDO stockCheck = validateStockCheckExists(id);
        // 1.2 校验状态
        if (stockCheck.getStatus().equals(status)) {
            throw exception(approve ? STOCK_CHECK_APPROVE_FAIL : STOCK_CHECK_PROCESS_FAIL);
        }

        // 2. 更新状态
        int updateCount = stockCheckMapper.updateByIdAndStatus(id, stockCheck.getStatus(),
                new ErpStockCheckDO().setStatus(status));
        if (updateCount == 0) {
            throw exception(approve ? STOCK_CHECK_APPROVE_FAIL : STOCK_CHECK_PROCESS_FAIL);
        }

        // 3. 单据平台：写状态流转日志（留痕；与创建日志同一入口）
        //    beforeStatus 取的是**更新前**读到的值 —— 上面用 updateByIdAndStatus，
        //    不会改动本地对象，所以这里取到的仍是旧状态
        billPlatformApi.log(new BillLogCreateReqDTO()
                .setBillType(BillTypeConstants.STOCK_CHECK).setBillId(id).setBillNo(stockCheck.getNo())
                .setOperateType(approve ? "APPROVE" : "UNAPPROVE")
                .setBeforeStatus(stockCheck.getStatus()).setAfterStatus(status)
                .setOperatorId(SecurityFrameworkUtils.getLoginUserId()));

        // 3. 变更库存
        List<ErpStockCheckItemDO> stockCheckItems = stockCheckItemMapper.selectListByCheckId(id);
        stockCheckItems.forEach(stockCheckItem -> {
            // 没有盈亏，不用出入库
            if (stockCheckItem.getCount().compareTo(BigDecimal.ZERO) == 0) {
                return;
            }
            // 10；12；-2（）
            BigDecimal count = approve ? stockCheckItem.getCount(): stockCheckItem.getCount().negate();
            Integer bizType;
            if (approve) {
                bizType = count.compareTo(BigDecimal.ZERO) > 0 ? ErpStockRecordBizTypeEnum.CHECK_MORE_IN.getType()
                        : ErpStockRecordBizTypeEnum.CHECK_LESS_OUT.getType();
            } else {
                bizType = count.compareTo(BigDecimal.ZERO) > 0 ? ErpStockRecordBizTypeEnum.CHECK_MORE_IN_CANCEL.getType()
                        : ErpStockRecordBizTypeEnum.CHECK_LESS_OUT_CANCEL.getType();
            }
            stockRecordService.createStockRecord(new ErpStockRecordCreateReqBO(
                    stockCheckItem.getProductId(), stockCheckItem.getWarehouseId(), count,
                    bizType, stockCheckItem.getCheckId(), stockCheckItem.getId(), stockCheck.getNo()));
        });
    }

    private List<ErpStockCheckItemDO> validateStockCheckItems(List<ErpStockCheckSaveReqVO.Item> list) {
        // 1.1 校验物料存在
        List<ErpProductDO> productList = productService.validProductList(
                convertSet(list, ErpStockCheckSaveReqVO.Item::getProductId));
        Map<Long, ErpProductDO> productMap = convertMap(productList, ErpProductDO::getId);
        // 1.2 校验仓库存在
        warehouseService.validWarehouseList(convertSet(list, ErpStockCheckSaveReqVO.Item::getWarehouseId));
        // 2. 转化为 ErpStockCheckItemDO 列表
        return convertList(list, o -> BeanUtils.toBean(o, ErpStockCheckItemDO.class, item -> item
                .setProductUnitId(productMap.get(item.getProductId()).getUnitId())
                .setTotalPrice(MoneyUtils.priceMultiply(item.getProductPrice(), item.getCount()))));
    }

    private void updateStockCheckItemList(Long id, List<ErpStockCheckItemDO> newList) {
        // 第一步，对比新老数据，获得添加、修改、删除的列表
        List<ErpStockCheckItemDO> oldList = stockCheckItemMapper.selectListByCheckId(id);
        List<List<ErpStockCheckItemDO>> diffList = diffList(oldList, newList, // id 不同，就认为是不同的记录
                (oldVal, newVal) -> oldVal.getId().equals(newVal.getId()));

        // 第二步，批量添加、修改、删除
        if (CollUtil.isNotEmpty(diffList.get(0))) {
            diffList.get(0).forEach(o -> o.setCheckId(id));
            stockCheckItemMapper.insertBatch(diffList.get(0));
        }
        if (CollUtil.isNotEmpty(diffList.get(1))) {
            stockCheckItemMapper.updateBatch(diffList.get(1));
        }
        if (CollUtil.isNotEmpty(diffList.get(2))) {
            stockCheckItemMapper.deleteByIds(convertList(diffList.get(2), ErpStockCheckItemDO::getId));
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteStockCheck(List<Long> ids) {
        // 1. 校验不处于已审批
        List<ErpStockCheckDO> stockChecks = stockCheckMapper.selectByIds(ids);
        if (CollUtil.isEmpty(stockChecks)) {
            return;
        }
        stockChecks.forEach(stockCheck -> {
            if (ErpAuditStatus.APPROVE.getStatus().equals(stockCheck.getStatus())) {
                throw exception(STOCK_CHECK_DELETE_FAIL_APPROVE, stockCheck.getNo());
            }
        });

        // 2. 遍历删除，并记录操作日志
        stockChecks.forEach(stockCheck -> {
            // 2.1 删除盘点单
            stockCheckMapper.deleteById(stockCheck.getId());
            // 2.2 删除盘点单项
            stockCheckItemMapper.deleteByCheckId(stockCheck.getId());
        });
    }

    private ErpStockCheckDO validateStockCheckExists(Long id) {
        ErpStockCheckDO stockCheck = stockCheckMapper.selectById(id);
        if (stockCheck == null) {
            throw exception(STOCK_CHECK_NOT_EXISTS);
        }
        return stockCheck;
    }

    @Override
    public ErpStockCheckDO getStockCheck(Long id) {
        return stockCheckMapper.selectById(id);
    }

    @Override
    public PageResult<ErpStockCheckDO> getStockCheckPage(ErpStockCheckPageReqVO pageReqVO) {
        return stockCheckMapper.selectPage(pageReqVO);
    }

    // ==================== 盘点项 ====================

    @Override
    public List<ErpStockCheckItemDO> getStockCheckItemListByCheckId(Long checkId) {
        return stockCheckItemMapper.selectListByCheckId(checkId);
    }

    @Override
    public List<ErpStockCheckItemDO> getStockCheckItemListByCheckIds(Collection<Long> checkIds) {
        if (CollUtil.isEmpty(checkIds)) {
            return Collections.emptyList();
        }
        return stockCheckItemMapper.selectListByCheckIds(checkIds);
    }

}
