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
