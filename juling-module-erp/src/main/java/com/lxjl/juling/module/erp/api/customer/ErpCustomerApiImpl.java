package com.lxjl.juling.module.erp.api.customer;

import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerRespDTO;
import com.lxjl.juling.module.erp.dal.dataobject.sale.ErpCustomerDO;
import com.lxjl.juling.module.erp.dal.mysql.sale.ErpCustomerMapper;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;

import java.util.Collection;
import java.util.Collections;
import java.util.List;

/**
 * ERP 客户（门店 / 代理）API 实现
 *
 * @author 亚特
 */
@Service
public class ErpCustomerApiImpl implements ErpCustomerApi {

    @Resource
    private ErpCustomerMapper customerMapper;

    @Override
    public ErpCustomerRespDTO getCustomer(Long id) {
        return BeanUtils.toBean(customerMapper.selectById(id), ErpCustomerRespDTO.class);
    }

    @Override
    public List<ErpCustomerRespDTO> getCustomerList(Collection<Long> ids) {
        return BeanUtils.toBean(customerMapper.selectList(ErpCustomerDO::getId, ids), ErpCustomerRespDTO.class);
    }

    @Override
    public List<Long> getChildCustomerIds(Long parentCustomerId) {
        if (parentCustomerId == null) {
            return Collections.emptyList();
        }
        return customerMapper.selectList(ErpCustomerDO::getParentCustomerId, parentCustomerId)
                .stream().map(ErpCustomerDO::getId).toList();
    }

}
