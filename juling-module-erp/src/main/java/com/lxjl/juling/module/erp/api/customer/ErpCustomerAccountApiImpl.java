package com.lxjl.juling.module.erp.api.customer;

import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerAccountRecordReqDTO;
import com.lxjl.juling.module.erp.service.finance.ErpCustomerAccountService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import java.math.BigDecimal;

/**
 * ERP 门店往来台账 API 实现
 *
 * 对外只提供**写侧与单点查询**：记账、余额、已挂账净额。
 * 门店维度的只读查询（余额汇总 / 往来明细分页）由后台直接走 {@link ErpCustomerAccountService}，
 * 不经本 API —— 原 H5「我的账」已于 2026-10 下线，其两个只读方法随之删除。
 *
 * @author 亚特
 */
@Service
@Validated
public class ErpCustomerAccountApiImpl implements ErpCustomerAccountApi {

    @Resource
    private ErpCustomerAccountService customerAccountService;

    @Override
    public boolean record(ErpCustomerAccountRecordReqDTO reqDTO) {
        return customerAccountService.record(reqDTO);
    }

    @Override
    public BigDecimal getBalance(Long customerId) {
        return customerAccountService.getBalance(customerId);
    }

    @Override
    public BigDecimal getPostedAmount(String sourceType, Long sourceId) {
        return customerAccountService.getPostedAmount(sourceType, sourceId);
    }

}
