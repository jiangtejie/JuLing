package com.lxjl.juling.module.erp.service.finance;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerAccountRecordReqDTO;
import com.lxjl.juling.module.erp.controller.admin.finance.vo.customeraccount.ErpCustomerAccountPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.finance.ErpCustomerAccountDO;
import com.lxjl.juling.module.erp.service.finance.bo.ErpCustomerAccountSummaryBO;

import java.math.BigDecimal;
import java.util.List;

/**
 * 门店往来台账 Service 接口
 *
 * @author 亚特
 */
public interface ErpCustomerAccountService {

    /**
     * 记一笔门店往来（幂等：同 bizType + sourceType + sourceId 只记一次）
     *
     * @param reqDTO 记账请求
     * @return 是否真正记账（false = 幂等命中）
     */
    boolean record(ErpCustomerAccountRecordReqDTO reqDTO);

    /**
     * 门店往来余额（正数 = 门店欠总部）
     */
    BigDecimal getBalance(Long customerId);

    /**
     * 某来源单据已挂账净额（SUM(amount)）
     */
    BigDecimal getPostedAmount(String sourceType, Long sourceId);

    /**
     * 门店往来分页
     */
    PageResult<ErpCustomerAccountDO> getPage(ErpCustomerAccountPageReqVO pageReqVO);

    /**
     * 门店往来余额汇总（有往来记录的门店各一行）
     *
     * @param customerId 门店编号；null = 不限
     * @param deptId     门店部门；null = 不限
     */
    List<ErpCustomerAccountSummaryBO> getSummaryList(Long customerId, Long deptId);

}
