package com.lxjl.juling.module.erp.service.finance;

import cn.hutool.core.util.ObjectUtil;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerAccountRecordReqDTO;
import com.lxjl.juling.module.erp.api.customer.enums.CustomerAccountBizTypeEnum;
import com.lxjl.juling.module.erp.controller.admin.finance.vo.customeraccount.ErpCustomerAccountPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.finance.ErpCustomerAccountDO;
import com.lxjl.juling.module.erp.dal.mysql.finance.ErpCustomerAccountMapper;
import com.lxjl.juling.module.erp.service.finance.bo.ErpCustomerAccountSummaryBO;
import com.lxjl.juling.module.erp.service.sale.ErpCustomerService;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.module.erp.enums.ErrorCodeConstants.*;

/**
 * 门店往来台账 Service 实现
 *
 * 记账三原则：
 *   1) 幂等：同一 (bizType, sourceType, sourceId) 只记一次，「审核 → 反审核 → 重新审核」不会重复挂账；
 *      反审核用另一个 bizType（xxx_CANCEL）记负数，因此不会被幂等键挡住。
 *   2) 串行：同一门店先取 pg_advisory_xact_lock，保证余额快照准确。
 *   3) 可回溯：金额、余额、来源单号、业务时间全部落库，明细可逐笔查。
 *
 * @author 亚特
 */
@Slf4j
@Service
@Validated
public class ErpCustomerAccountServiceImpl implements ErpCustomerAccountService {

    @Resource
    private ErpCustomerAccountMapper customerAccountMapper;

    @Resource
    private ErpCustomerService customerService;

    /**
     * 幂等说明：本方法**不再**按 (bizType, sourceType, sourceId) 去重 —— 改成调用方按
     * 「目标净额 − 已挂账净额」补差额（见 {@link #getPostedAmount}）。
     * 原因：「审核 → 反审核 → 重新审核」用唯一键去重会在第三步被误判成重复而漏记金额；
     * 差额法下第三步的 delta 正好等于第一次的金额，账自然就对了。
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean record(ErpCustomerAccountRecordReqDTO reqDTO) {
        // 1.1 金额与业务类型校验
        if (reqDTO.getAmount() == null || reqDTO.getAmount().compareTo(BigDecimal.ZERO) == 0) {
            throw exception(CUSTOMER_ACCOUNT_AMOUNT_ILLEGAL);
        }
        boolean bizTypeValid = reqDTO.getBizType() != null && Arrays.stream(CustomerAccountBizTypeEnum.values())
                .anyMatch(item -> item.getType().equals(reqDTO.getBizType()));
        if (!bizTypeValid) {
            throw exception(CUSTOMER_ACCOUNT_BIZ_TYPE_ILLEGAL, reqDTO.getBizType());
        }
        // 1.2 门店必须存在
        customerService.validateCustomer(reqDTO.getCustomerId());

        // 2. 同门店串行记账，取「记账前余额」
        customerAccountMapper.lockCustomer(reqDTO.getCustomerId());
        BigDecimal balanceBefore = customerAccountMapper.selectBalance(reqDTO.getCustomerId());

        // 3. 落账
        ErpCustomerAccountDO account = ErpCustomerAccountDO.builder()
                .customerId(reqDTO.getCustomerId())
                .deptId(reqDTO.getDeptId())
                .bizType(reqDTO.getBizType())
                .amount(reqDTO.getAmount())
                .balance(balanceBefore.add(reqDTO.getAmount()))
                .billTime(ObjectUtil.defaultIfNull(reqDTO.getBillTime(), LocalDateTime.now()))
                .sourceType(reqDTO.getSourceType())
                .sourceId(reqDTO.getSourceId())
                .sourceNo(reqDTO.getSourceNo())
                .remark(reqDTO.getRemark())
                .build();
        customerAccountMapper.insert(account);
        log.info("[record][门店({}) 业务类型({}) 金额 {}，余额 {} → {}，来源 {}({})]",
                reqDTO.getCustomerId(), reqDTO.getBizType(), reqDTO.getAmount(), balanceBefore, account.getBalance(),
                reqDTO.getSourceType(), reqDTO.getSourceNo());
        return true;
    }

    @Override
    public BigDecimal getBalance(Long customerId) {
        if (customerId == null) {
            return BigDecimal.ZERO;
        }
        return customerAccountMapper.selectBalance(customerId);
    }

    @Override
    public BigDecimal getPostedAmount(String sourceType, Long sourceId) {
        if (sourceId == null) {
            return BigDecimal.ZERO;
        }
        return customerAccountMapper.sumAmountBySource(sourceType, sourceId);
    }

    @Override
    public PageResult<ErpCustomerAccountDO> getPage(ErpCustomerAccountPageReqVO pageReqVO) {
        return customerAccountMapper.selectPage(pageReqVO);
    }

    @Override
    public List<ErpCustomerAccountSummaryBO> getSummaryList(Long customerId, Long deptId) {
        List<Long> customerIds = customerId == null ? null : List.of(customerId);
        List<ErpCustomerAccountSummaryBO> result = new ArrayList<>();
        for (Map<String, Object> row : customerAccountMapper.selectSummaryGroupByCustomer(customerIds, deptId)) {
            Object id = row.get("customer_id");
            if (id == null) {
                continue;
            }
            Object rowDeptId = row.get("dept_id");
            result.add(new ErpCustomerAccountSummaryBO(Long.valueOf(id.toString()),
                    rowDeptId == null ? null : Long.valueOf(rowDeptId.toString()),
                    toDecimal(row.get("total_receivable")), toDecimal(row.get("total_received")),
                    toDecimal(row.get("balance"))));
        }
        return result;
    }

    private static BigDecimal toDecimal(Object value) {
        return value == null ? BigDecimal.ZERO : new BigDecimal(value.toString());
    }

}
