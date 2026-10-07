package com.lxjl.juling.module.erp.api.customer;

import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerRespDTO;

import java.util.Collection;
import java.util.List;

/**
 * ERP 客户（门店 / 代理）API
 *
 * 门店订货链：商城侧校验"订货账号可下单的门店"、取门店所属部门与结算模式。
 *
 * @author 亚特
 */
public interface ErpCustomerApi {

    /**
     * 获得客户（门店）
     *
     * @param id 客户编号
     * @return 客户信息；不存在时返回 null
     */
    ErpCustomerRespDTO getCustomer(Long id);

    /**
     * 获得客户（门店）列表
     *
     * @param ids 客户编号列表
     * @return 客户列表
     */
    List<ErpCustomerRespDTO> getCustomerList(Collection<Long> ids);

}
