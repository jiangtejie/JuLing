package com.lxjl.juling.module.erp.api.customer;

import cn.hutool.core.collection.CollUtil;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerAccountDetailRespDTO;
import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerAccountRecordReqDTO;
import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerAccountSummaryRespDTO;
import com.lxjl.juling.module.erp.api.customer.enums.CustomerAccountBizTypeEnum;
import com.lxjl.juling.module.erp.controller.admin.finance.vo.customeraccount.ErpCustomerAccountPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.finance.ErpCustomerAccountDO;
import com.lxjl.juling.module.erp.dal.dataobject.sale.ErpCustomerDO;
import com.lxjl.juling.module.erp.service.finance.ErpCustomerAccountService;
import com.lxjl.juling.module.erp.service.finance.bo.ErpCustomerAccountSummaryBO;
import com.lxjl.juling.module.erp.service.sale.ErpCustomerService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertMap;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertSet;

/**
 * ERP 门店往来台账 API 实现
 *
 * 除记账外，还对外提供只读查询（订货 H5 的「我的账」）：
 *   · getSummaryList   —— 一个账号名下门店的余额汇总（欠多少 / 已付多少 / 余款多少）
 *   · getAccountPage   —— 逐笔明细（含门店名与业务类型名，前端直接展示）
 *
 * @author 亚特
 */
@Service
@Validated
public class ErpCustomerAccountApiImpl implements ErpCustomerAccountApi {

    /**
     * 明细分页缺省值（与 PageParam 的默认口径一致）
     */
    private static final Integer DEFAULT_PAGE_NO = 1;
    private static final Integer DEFAULT_PAGE_SIZE = 10;

    @Resource
    private ErpCustomerAccountService customerAccountService;
    @Resource
    private ErpCustomerService customerService;

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

    @Override
    public List<ErpCustomerAccountSummaryRespDTO> getSummaryList(Collection<Long> customerIds) {
        List<ErpCustomerAccountSummaryBO> list = customerAccountService.getSummaryListByCustomerIds(customerIds);
        if (CollUtil.isEmpty(list)) {
            return List.of();
        }
        Map<Long, ErpCustomerDO> customerMap = convertMap(
                customerService.getCustomerList(convertSet(list, ErpCustomerAccountSummaryBO::getCustomerId)),
                ErpCustomerDO::getId);
        return BeanUtils.toBean(list, ErpCustomerAccountSummaryRespDTO.class, vo -> {
            ErpCustomerDO customer = customerMap.get(vo.getCustomerId());
            if (customer != null) {
                vo.setCustomerName(customer.getName());
            }
        });
    }

    @Override
    public PageResult<ErpCustomerAccountDetailRespDTO> getAccountPage(Collection<Long> customerIds,
                                                                     Integer pageNo, Integer pageSize) {
        if (CollUtil.isEmpty(customerIds)) {
            return PageResult.empty();
        }
        ErpCustomerAccountPageReqVO reqVO = new ErpCustomerAccountPageReqVO();
        reqVO.setCustomerIds(new ArrayList<>(customerIds));
        reqVO.setPageNo(pageNo == null ? DEFAULT_PAGE_NO : pageNo);
        reqVO.setPageSize(pageSize == null ? DEFAULT_PAGE_SIZE : pageSize);
        PageResult<ErpCustomerAccountDO> pageResult = customerAccountService.getPage(reqVO);
        if (CollUtil.isEmpty(pageResult.getList())) {
            return PageResult.empty(pageResult.getTotal());
        }
        Map<Long, ErpCustomerDO> customerMap = convertMap(
                customerService.getCustomerList(convertSet(pageResult.getList(), ErpCustomerAccountDO::getCustomerId)),
                ErpCustomerDO::getId);
        return new PageResult<>(BeanUtils.toBean(pageResult.getList(), ErpCustomerAccountDetailRespDTO.class, vo -> {
            ErpCustomerDO customer = customerMap.get(vo.getCustomerId());
            if (customer != null) {
                vo.setCustomerName(customer.getName());
            }
            Arrays.stream(CustomerAccountBizTypeEnum.values())
                    .filter(item -> item.getType().equals(vo.getBizType()))
                    .findFirst().ifPresent(item -> vo.setBizTypeName(item.getName()));
        }), pageResult.getTotal());
    }

}
