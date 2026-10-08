package com.lxjl.juling.module.erp.service.finance;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.lang.Assert;
import cn.hutool.core.util.ObjectUtil;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.collection.CollectionUtils;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.framework.security.core.util.SecurityFrameworkUtils;
import com.lxjl.juling.module.bill.api.BillPlatformApi;
import com.lxjl.juling.module.bill.api.dto.BillLogCreateReqDTO;
import com.lxjl.juling.module.bill.enums.BillTypeConstants;
import com.lxjl.juling.module.erp.controller.admin.finance.vo.receipt.ErpFinanceReceiptPageReqVO;
import com.lxjl.juling.module.erp.controller.admin.finance.vo.receipt.ErpFinanceReceiptSaveReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.finance.ErpFinanceReceiptDO;
import com.lxjl.juling.module.erp.dal.dataobject.finance.ErpFinanceReceiptItemDO;
import com.lxjl.juling.module.erp.dal.dataobject.sale.ErpSaleOutDO;
import com.lxjl.juling.module.erp.dal.dataobject.sale.ErpSaleReturnDO;
import com.lxjl.juling.module.erp.dal.mysql.finance.ErpFinanceReceiptItemMapper;
import com.lxjl.juling.module.erp.dal.mysql.finance.ErpFinanceReceiptMapper;
import com.lxjl.juling.module.erp.enums.ErpAuditStatus;
import com.lxjl.juling.module.erp.enums.common.ErpBizTypeEnum;
import com.lxjl.juling.module.erp.service.sale.ErpCustomerService;
import com.lxjl.juling.module.erp.service.sale.ErpSaleOutService;
import com.lxjl.juling.module.erp.service.sale.ErpSaleReturnService;
import com.lxjl.juling.module.system.api.user.AdminUserApi;
import com.lxjl.juling.module.erp.service.support.BillAuditSupport;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.Collections;
import java.util.List;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.*;
import static com.lxjl.juling.module.erp.enums.ErrorCodeConstants.*;


/**
 * ERP 收款单 Service 实现类
 *
 * @author 亚特
 */
@Service
@Validated
public class ErpFinanceReceiptServiceImpl implements ErpFinanceReceiptService {

    @Resource
    private ErpFinanceReceiptMapper financeReceiptMapper;
    @Resource
    private ErpFinanceReceiptItemMapper financeReceiptItemMapper;

    @Resource
    private BillPlatformApi billPlatformApi;

    @Resource
    private ErpCustomerService customerService;
    @Resource
    private ErpAccountService accountService;
    @Resource
    private ErpSaleOutService saleOutService;
    @Resource
    private ErpSaleReturnService saleReturnService;

    @Resource
    private AdminUserApi adminUserApi;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createFinanceReceipt(ErpFinanceReceiptSaveReqVO createReqVO) {
        // 1.1 校验订单项的有效性
        List<ErpFinanceReceiptItemDO> receiptItems = validateFinanceReceiptItems(
                createReqVO.getCustomerId(), createReqVO.getItems());
        // 1.2 校验客户
        customerService.validateCustomer(createReqVO.getCustomerId());
        // 1.3 校验结算账户
        if (createReqVO.getAccountId() != null) {
            accountService.validateAccount(createReqVO.getAccountId());
        }
        // 1.4 校验财务人员
        if (createReqVO.getFinanceUserId() != null) {
            adminUserApi.validateUser(createReqVO.getFinanceUserId());
        }
        // 1.5 生成收款单号（单据平台：bill_type 为唯一真相来源，前缀 + yyyyMMdd + 6 位流水），并校验唯一性
        String no = billPlatformApi.generateNo(BillTypeConstants.FINANCE_RECEIPT, null);
        if (financeReceiptMapper.selectByNo(no) != null) {
            throw exception(FINANCE_RECEIPT_NO_EXISTS);
        }

        // 2.1 插入收款单
        ErpFinanceReceiptDO receipt = BeanUtils.toBean(createReqVO, ErpFinanceReceiptDO.class, in -> in
                .setNo(no).setStatus(ErpAuditStatus.PROCESS.getStatus()));
        calculateTotalPrice(receipt, receiptItems);
        financeReceiptMapper.insert(receipt);
        // 2.2 插入收款单项
        receiptItems.forEach(o -> o.setReceiptId(receipt.getId()));
        financeReceiptItemMapper.insertBatch(receiptItems);

        // 2.3 单据平台：写创建日志（留痕）
        billPlatformApi.log(new BillLogCreateReqDTO()
                .setBillType(BillTypeConstants.FINANCE_RECEIPT).setBillId(receipt.getId()).setBillNo(no)
                .setOperateType("CREATE").setAfterStatus(receipt.getStatus())
                .setOperatorId(SecurityFrameworkUtils.getLoginUserId()));

        // 3. 更新销售出库、退货的收款金额情况
        updateSalePrice(receiptItems);
        return receipt.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateFinanceReceipt(ErpFinanceReceiptSaveReqVO updateReqVO) {
        // 1.1 校验存在
        ErpFinanceReceiptDO receipt = validateFinanceReceiptExists(updateReqVO.getId());
        if (ErpAuditStatus.APPROVE.getStatus().equals(receipt.getStatus())) {
            throw exception(FINANCE_RECEIPT_UPDATE_FAIL_APPROVE, receipt.getNo());
        }
        // 1.2 校验客户
        customerService.validateCustomer(updateReqVO.getCustomerId());
        // 1.3 校验结算账户
        if (updateReqVO.getAccountId() != null) {
            accountService.validateAccount(updateReqVO.getAccountId());
        }
        // 1.4 校验财务人员
        if (updateReqVO.getFinanceUserId() != null) {
            adminUserApi.validateUser(updateReqVO.getFinanceUserId());
        }
        // 1.5 校验收款单项的有效性
        List<ErpFinanceReceiptItemDO> receiptItems = validateFinanceReceiptItems(
                updateReqVO.getCustomerId(), updateReqVO.getItems());

        // 2.1 更新收款单
        ErpFinanceReceiptDO updateObj = BeanUtils.toBean(updateReqVO, ErpFinanceReceiptDO.class);
        calculateTotalPrice(updateObj, receiptItems);
        financeReceiptMapper.updateById(updateObj);
        // 2.2 更新收款单项
        updateFinanceReceiptItemList(updateReqVO.getId(), receiptItems);
    }

    private void calculateTotalPrice(ErpFinanceReceiptDO receipt, List<ErpFinanceReceiptItemDO> receiptItems) {
        receipt.setTotalPrice(getSumValue(receiptItems, ErpFinanceReceiptItemDO::getReceiptPrice, BigDecimal::add, BigDecimal.ZERO));
        receipt.setReceiptPrice(receipt.getTotalPrice().subtract(receipt.getDiscountPrice()));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateFinanceReceiptStatus(Long id, Integer status) {
        boolean approve = BillAuditSupport.isApprove(status);
        // 1.1 校验存在
        ErpFinanceReceiptDO receipt = validateFinanceReceiptExists(id);
        // 1.2 校验状态
        BillAuditSupport.validateStatusChange(receipt.getStatus(), status, FINANCE_RECEIPT_APPROVE_FAIL, FINANCE_RECEIPT_PROCESS_FAIL);

        // 2. 更新状态
        BillAuditSupport.casUpdate(
                () -> financeReceiptMapper.updateByIdAndStatus(id, receipt.getStatus(),
                new ErpFinanceReceiptDO().setStatus(status)),
                status, FINANCE_RECEIPT_APPROVE_FAIL, FINANCE_RECEIPT_PROCESS_FAIL);

        // 3. 单据平台：写状态流转日志（留痕；与创建日志同一入口）
        //    beforeStatus 取的是**更新前**读到的值 —— 上面用 updateByIdAndStatus，
        //    不会改动本地对象，所以这里取到的仍是旧状态
        billPlatformApi.log(new BillLogCreateReqDTO()
                .setBillType(BillTypeConstants.FINANCE_RECEIPT).setBillId(id).setBillNo(receipt.getNo())
                .setOperateType(approve ? "APPROVE" : "UNAPPROVE")
                .setBeforeStatus(receipt.getStatus()).setAfterStatus(status)
                .setOperatorId(SecurityFrameworkUtils.getLoginUserId()));
    }

    private List<ErpFinanceReceiptItemDO> validateFinanceReceiptItems(
            Long customerId,
            List<ErpFinanceReceiptSaveReqVO.Item> list) {
        return convertList(list, o -> BeanUtils.toBean(o, ErpFinanceReceiptItemDO.class, item -> {
            if (ObjectUtil.equal(item.getBizType(), ErpBizTypeEnum.SALE_OUT.getType())) {
                ErpSaleOutDO saleOut = saleOutService.validateSaleOut(item.getBizId());
                Assert.equals(saleOut.getCustomerId(), customerId, "客户必须相同");
                item.setTotalPrice(saleOut.getTotalPrice()).setBizNo(saleOut.getNo());
            } else if (ObjectUtil.equal(item.getBizType(), ErpBizTypeEnum.SALE_RETURN.getType())) {
                ErpSaleReturnDO saleReturn = saleReturnService.validateSaleReturn(item.getBizId());
                Assert.equals(saleReturn.getCustomerId(), customerId, "客户必须相同");
                item.setTotalPrice(saleReturn.getTotalPrice().negate()).setBizNo(saleReturn.getNo());
            } else {
                throw new IllegalArgumentException("业务类型不正确：" + item.getBizType());
            }
        }));
    }

    private void updateFinanceReceiptItemList(Long id, List<ErpFinanceReceiptItemDO> newList) {
        // 第一步，对比新老数据，获得添加、修改、删除的列表
        List<ErpFinanceReceiptItemDO> oldList = financeReceiptItemMapper.selectListByReceiptId(id);
        List<List<ErpFinanceReceiptItemDO>> diffList = diffList(oldList, newList, // id 不同，就认为是不同的记录
                (oldVal, newVal) -> oldVal.getId().equals(newVal.getId()));

        // 第二步，批量添加、修改、删除
        if (CollUtil.isNotEmpty(diffList.get(0))) {
            diffList.get(0).forEach(o -> o.setReceiptId(id));
            financeReceiptItemMapper.insertBatch(diffList.get(0));
        }
        if (CollUtil.isNotEmpty(diffList.get(1))) {
            financeReceiptItemMapper.updateBatch(diffList.get(1));
        }
        if (CollUtil.isNotEmpty(diffList.get(2))) {
            financeReceiptItemMapper.deleteByIds(convertList(diffList.get(2), ErpFinanceReceiptItemDO::getId));
        }

        // 第三步，更新销售出库、退货的收款金额情况
        updateSalePrice(CollectionUtils.newArrayList(diffList));
    }

    private void updateSalePrice(List<ErpFinanceReceiptItemDO> receiptItems) {
        receiptItems.forEach(receiptItem -> {
            BigDecimal totalReceiptPrice = financeReceiptItemMapper.selectReceiptPriceSumByBizIdAndBizType(
                    receiptItem.getBizId(), receiptItem.getBizType());
            if (ErpBizTypeEnum.SALE_OUT.getType().equals(receiptItem.getBizType())) {
                saleOutService.updateSaleInReceiptPrice(receiptItem.getBizId(), totalReceiptPrice);
            } else if (ErpBizTypeEnum.SALE_RETURN.getType().equals(receiptItem.getBizType())) {
                saleReturnService.updateSaleReturnRefundPrice(receiptItem.getBizId(), totalReceiptPrice.negate());
            } else {
                throw new IllegalArgumentException("业务类型不正确：" + receiptItem.getBizType());
            }
        });
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteFinanceReceipt(List<Long> ids) {
        // 1. 校验不处于已审批
        List<ErpFinanceReceiptDO> receipts = financeReceiptMapper.selectByIds(ids);
        if (CollUtil.isEmpty(receipts)) {
            return;
        }
        receipts.forEach(receipt -> {
            if (ErpAuditStatus.APPROVE.getStatus().equals(receipt.getStatus())) {
                throw exception(FINANCE_RECEIPT_DELETE_FAIL_APPROVE, receipt.getNo());
            }
        });

        // 2. 遍历删除，并记录操作日志
        receipts.forEach(receipt -> {
            // 2.1 删除收款单
            financeReceiptMapper.deleteById(receipt.getId());
            // 2.2 删除收款单项
            List<ErpFinanceReceiptItemDO> receiptItems = financeReceiptItemMapper.selectListByReceiptId(receipt.getId());
            financeReceiptItemMapper.deleteByIds(convertSet(receiptItems, ErpFinanceReceiptItemDO::getId));

            // 2.3 更新销售出库、退货的收款金额情况
            updateSalePrice(receiptItems);
        });
    }

    private ErpFinanceReceiptDO validateFinanceReceiptExists(Long id) {
        ErpFinanceReceiptDO receipt = financeReceiptMapper.selectById(id);
        if (receipt == null) {
            throw exception(FINANCE_RECEIPT_NOT_EXISTS);
        }
        return receipt;
    }

    @Override
    public ErpFinanceReceiptDO getFinanceReceipt(Long id) {
        return financeReceiptMapper.selectById(id);
    }

    @Override
    public PageResult<ErpFinanceReceiptDO> getFinanceReceiptPage(ErpFinanceReceiptPageReqVO pageReqVO) {
        return financeReceiptMapper.selectPage(pageReqVO);
    }

    // ==================== 收款单项 ====================

    @Override
    public List<ErpFinanceReceiptItemDO> getFinanceReceiptItemListByReceiptId(Long receiptId) {
        return financeReceiptItemMapper.selectListByReceiptId(receiptId);
    }

    @Override
    public List<ErpFinanceReceiptItemDO> getFinanceReceiptItemListByReceiptIds(Collection<Long> receiptIds) {
        if (CollUtil.isEmpty(receiptIds)) {
            return Collections.emptyList();
        }
        return financeReceiptItemMapper.selectListByReceiptIds(receiptIds);
    }

}
