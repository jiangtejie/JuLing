package com.lxjl.juling.module.erp.service.purchase;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.lxjl.juling.module.system.api.code.CodeRuleApi;

import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.erp.controller.admin.purchase.vo.supplier.ErpSupplierPageReqVO;
import com.lxjl.juling.module.erp.controller.admin.purchase.vo.supplier.ErpSupplierSaveReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.finance.ErpFinancePaymentDO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchaseInDO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchaseOrderDO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchaseReturnDO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpSupplierDO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockInDO;
import com.lxjl.juling.module.erp.dal.mysql.finance.ErpFinancePaymentMapper;
import com.lxjl.juling.module.erp.dal.mysql.purchase.ErpPurchaseInMapper;
import com.lxjl.juling.module.erp.dal.mysql.purchase.ErpPurchaseOrderMapper;
import com.lxjl.juling.module.erp.dal.mysql.purchase.ErpPurchaseReturnMapper;
import com.lxjl.juling.module.erp.dal.mysql.purchase.ErpSupplierMapper;
import com.lxjl.juling.module.erp.dal.mysql.stock.ErpStockInMapper;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.util.Collection;
import java.util.List;
import java.util.Set;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.module.erp.enums.ErrorCodeConstants.*;

/**
 * ERP 供应商 Service 实现类
 *
 * @author 亚特
 */
@Service
@Validated
public class ErpSupplierServiceImpl implements ErpSupplierService {

    /** 开票情况：按销售额比例开票（其余取值时开票比例无意义） */
    private static final String INVOICE_MODE_RATIO = "RATIO";

    /** 结账方式：需要账期的两种（其余取值时账期天数无意义） */
    private static final Set<String> SETTLEMENT_MODES_WITH_CREDIT_DAYS = Set.of("MONTHLY", "HALF_MONTH");

    @Resource
    private ErpSupplierMapper supplierMapper;

    @Resource
    private CodeRuleApi codeRuleApi;

    /** 以下 5 张单据表通过 supplier_id 引用供应商，删除前需校验（见 validateSupplierReference） */
    @Resource
    private ErpPurchaseOrderMapper purchaseOrderMapper;
    @Resource
    private ErpPurchaseInMapper purchaseInMapper;
    @Resource
    private ErpPurchaseReturnMapper purchaseReturnMapper;
    @Resource
    private ErpFinancePaymentMapper financePaymentMapper;
    @Resource
    private ErpStockInMapper stockInMapper;

    @Override
    @Transactional(rollbackFor = Exception.class) // 与编码取号同事务，避免建档失败却消耗号段
    public Long createSupplier(ErpSupplierSaveReqVO createReqVO) {
        validateSupplierNameUnique(null, createReqVO.getName());
        ErpSupplierDO supplier = BeanUtils.toBean(createReqVO, ErpSupplierDO.class);
        normalizeConditionalFields(supplier);
        // 业务编码：由编码规则统一发号（见 docs/master-data-unified-design.md §4.2）
        supplier.setCode(codeRuleApi.generateCode("erp_supplier"));
        supplierMapper.insert(supplier);
        return supplier.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateSupplier(ErpSupplierSaveReqVO updateReqVO) {
        // 校验存在 + 名称不与他人重复
        validateSupplierExists(updateReqVO.getId());
        validateSupplierNameUnique(updateReqVO.getId(), updateReqVO.getName());
        // 更新
        ErpSupplierDO updateObj = BeanUtils.toBean(updateReqVO, ErpSupplierDO.class);
        normalizeConditionalFields(updateObj);
        supplierMapper.updateById(updateObj);
        // updateById 会忽略 null 字段，而归一化的目的恰恰是「把不再适用的字段清空」，
        // 所以必须用 UpdateWrapper 显式 set（与 DeptServiceImpl#clearDeptClosedFields 同一手法）
        clearNormalizedFields(updateReqVO.getId(), updateObj);
    }

    @Override
    public void deleteSupplier(Long id) {
        // 校验存在
        ErpSupplierDO supplier = validateSupplierExists(id);
        // 校验没有被业务单据引用 —— 否则历史单据的供应商名会解析不出来（列表显示空白）
        String referencedBy = findReferenceBizName(id);
        if (referencedBy != null) {
            throw exception(SUPPLIER_HAS_REFERENCE, supplier.getName(), referencedBy);
        }
        // 删除
        supplierMapper.deleteById(id);
    }

    /**
     * 名称唯一校验
     *
     * <p>供应商是「全公司唯一实体」，同名档案会让下单/付款选错对象。
     * 与 {@code ErpProductUnitServiceImpl#validateProductUnitNameUnique} 同一口径。
     * 确实需要两个同名主体时，用编码区分。
     */
    private void validateSupplierNameUnique(Long id, String name) {
        if (StrUtil.isBlank(name)) {
            return;
        }
        ErpSupplierDO supplier = supplierMapper.selectByName(name);
        if (supplier == null) {
            return;
        }
        if (id == null || !supplier.getId().equals(id)) {
            throw exception(SUPPLIER_NAME_DUPLICATE, name);
        }
    }

    /**
     * 条件字段归一化：把当前取值下**没有意义**的字段清空，避免留下自相矛盾的历史值
     *
     * <p>例：某供应商先设「月结 / 账期 30 天」，后改为「次结」，若不清理，账期会一直留 30 天，
     * 列表、导出与下游读数都会看到这个矛盾值。与 {@code DeptServiceImpl#normalizeDeptBusiness} 同一思路。
     */
    private void normalizeConditionalFields(ErpSupplierDO supplier) {
        if (!INVOICE_MODE_RATIO.equals(supplier.getInvoiceMode())) {
            supplier.setInvoiceRatio(null);
        }
        if (!Boolean.TRUE.equals(supplier.getContractSigned())) {
            supplier.setContractEntity(null);
        }
        if (!SETTLEMENT_MODES_WITH_CREDIT_DAYS.contains(supplier.getSettlementType())) {
            supplier.setCreditDays(null);
        }
    }

    /** 显式把归一化涉及的三列写成目标值（含 null）—— updateById 做不到 */
    private void clearNormalizedFields(Long id, ErpSupplierDO normalized) {
        supplierMapper.update(null, new LambdaUpdateWrapper<ErpSupplierDO>()
                .eq(ErpSupplierDO::getId, id)
                .set(ErpSupplierDO::getInvoiceRatio, normalized.getInvoiceRatio())
                .set(ErpSupplierDO::getContractEntity, normalized.getContractEntity())
                .set(ErpSupplierDO::getCreditDays, normalized.getCreditDays()));
    }

    /** 返回第一个引用该供应商的单据中文名；没有引用则返回 null */
    private String findReferenceBizName(Long supplierId) {
        if (purchaseOrderMapper.selectCount(ErpPurchaseOrderDO::getSupplierId, supplierId) > 0) {
            return "采购订单";
        }
        if (purchaseInMapper.selectCount(ErpPurchaseInDO::getSupplierId, supplierId) > 0) {
            return "采购入库单";
        }
        if (purchaseReturnMapper.selectCount(ErpPurchaseReturnDO::getSupplierId, supplierId) > 0) {
            return "采购退货单";
        }
        if (financePaymentMapper.selectCount(ErpFinancePaymentDO::getSupplierId, supplierId) > 0) {
            return "付款单";
        }
        if (stockInMapper.selectCount(ErpStockInDO::getSupplierId, supplierId) > 0) {
            return "其它入库单";
        }
        return null;
    }

    private ErpSupplierDO validateSupplierExists(Long id) {
        ErpSupplierDO supplier = supplierMapper.selectById(id);
        if (supplier == null) {
            throw exception(SUPPLIER_NOT_EXISTS);
        }
        return supplier;
    }

    @Override
    public ErpSupplierDO getSupplier(Long id) {
        return supplierMapper.selectById(id);
    }

    @Override
    public ErpSupplierDO validateSupplier(Long id) {
        ErpSupplierDO supplier = supplierMapper.selectById(id);
        if (supplier == null) {
            throw exception(SUPPLIER_NOT_EXISTS);
        }
        if (CommonStatusEnum.isDisable(supplier.getStatus())) {
            throw exception(SUPPLIER_NOT_ENABLE, supplier.getName());
        }
        return supplier;
    }

    @Override
    public List<ErpSupplierDO> getSupplierList(Collection<Long> ids) {
        return supplierMapper.selectByIds(ids);
    }

    @Override
    public PageResult<ErpSupplierDO> getSupplierPage(ErpSupplierPageReqVO pageReqVO) {
        return supplierMapper.selectPage(pageReqVO);
    }

    @Override
    public List<ErpSupplierDO> getSupplierListByStatus(Integer status) {
        return supplierMapper.selectListByStatus(status);
    }

}
