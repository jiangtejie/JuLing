package com.lxjl.juling.module.erp.dal.mysql.purchase;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.module.erp.controller.admin.purchase.vo.supplier.ErpSupplierPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpSupplierDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * ERP 供应商 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface ErpSupplierMapper extends BaseMapperX<ErpSupplierDO> {

    default PageResult<ErpSupplierDO> selectPage(ErpSupplierPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<ErpSupplierDO>()
                .likeIfPresent(ErpSupplierDO::getName, reqVO.getName())
                .likeIfPresent(ErpSupplierDO::getMobile, reqVO.getMobile())
                .likeIfPresent(ErpSupplierDO::getTelephone, reqVO.getTelephone())
                // 采购部门提供的筛选维度（见 sql/local/62_supplier_profile.sql）
                .eqIfPresent(ErpSupplierDO::getSettlementType, reqVO.getSettlementType())
                .eqIfPresent(ErpSupplierDO::getInvoiceMode, reqVO.getInvoiceMode())
                .eqIfPresent(ErpSupplierDO::getInvoiceType, reqVO.getInvoiceType())
                .eqIfPresent(ErpSupplierDO::getContractSigned, reqVO.getContractSigned())
                .orderByDesc(ErpSupplierDO::getId));
    }

    default List<ErpSupplierDO> selectListByStatus(Integer status) {
        return selectList(ErpSupplierDO::getStatus, status);
    }

}