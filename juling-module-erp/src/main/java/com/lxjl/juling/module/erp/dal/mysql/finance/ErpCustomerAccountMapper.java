package com.lxjl.juling.module.erp.dal.mysql.finance;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.erp.controller.admin.finance.vo.customeraccount.ErpCustomerAccountPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.finance.ErpCustomerAccountDO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.List;
import java.util.Map;

/**
 * 门店往来台账 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface ErpCustomerAccountMapper extends BaseMapperX<ErpCustomerAccountDO> {

    default PageResult<ErpCustomerAccountDO> selectPage(ErpCustomerAccountPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<ErpCustomerAccountDO>()
                .eqIfPresent(ErpCustomerAccountDO::getCustomerId, reqVO.getCustomerId())
                .inIfPresent(ErpCustomerAccountDO::getCustomerId, reqVO.getCustomerIds())
                .eqIfPresent(ErpCustomerAccountDO::getDeptId, reqVO.getDeptId())
                .eqIfPresent(ErpCustomerAccountDO::getBizType, reqVO.getBizType())
                .likeIfPresent(ErpCustomerAccountDO::getSourceNo, reqVO.getSourceNo())
                .betweenIfPresent(ErpCustomerAccountDO::getBillTime, reqVO.getBillTime())
                .orderByDesc(ErpCustomerAccountDO::getId));
    }

    /**
     * 某来源单据已挂账净额（SUM(amount)）：审核 / 反审核反复切换时按差额补记，避免漏记
     */
    default BigDecimal sumAmountBySource(String sourceType, Long sourceId) {
        List<Map<String, Object>> rows = selectMaps(new QueryWrapper<ErpCustomerAccountDO>()
                .select("COALESCE(SUM(amount), 0) AS posted_amount")
                .eq("source_type", sourceType)
                .eq("source_id", sourceId));
        if (rows.isEmpty() || rows.get(0) == null || rows.get(0).get("posted_amount") == null) {
            return BigDecimal.ZERO;
        }
        return new BigDecimal(rows.get(0).get("posted_amount").toString());
    }

    /**
     * 门店往来余额（SUM(amount)，正数 = 门店欠总部）
     */
    default BigDecimal selectBalance(Long customerId) {
        List<Map<String, Object>> rows = selectMaps(new QueryWrapper<ErpCustomerAccountDO>()
                .select("COALESCE(SUM(amount), 0) AS balance")
                .eq("customer_id", customerId));
        if (rows.isEmpty() || rows.get(0) == null || rows.get(0).get("balance") == null) {
            return BigDecimal.ZERO;
        }
        return new BigDecimal(rows.get(0).get("balance").toString());
    }

    /**
     * 按门店分组统计：累计应收（正数记账之和）、累计已收（负数记账绝对值之和）、余额
     *
     * @param customerIds 门店编号集合；null = 不限
     * @param deptId      门店部门编号；null = 不限
     */
    default List<Map<String, Object>> selectSummaryGroupByCustomer(Collection<Long> customerIds, Long deptId) {
        QueryWrapper<ErpCustomerAccountDO> wrapper = new QueryWrapper<ErpCustomerAccountDO>()
                .select("customer_id",
                        "MAX(dept_id) AS dept_id",
                        "COALESCE(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END), 0) AS total_receivable",
                        "COALESCE(SUM(CASE WHEN amount < 0 THEN -amount ELSE 0 END), 0) AS total_received",
                        "COALESCE(SUM(amount), 0) AS balance")
                .groupBy("customer_id")
                .orderByAsc("customer_id");
        if (customerIds != null) {
            wrapper.in("customer_id", customerIds);
        }
        if (deptId != null) {
            wrapper.eq("dept_id", deptId);
        }
        return selectMaps(wrapper);
    }

    /**
     * 同一门店的记账串行化：事务级 advisory lock（事务结束自动释放）
     *
     * 为什么需要：balance 是「记账后余额快照」，两个并发记账若同时读到同一个旧余额，
     * 快照就会错乱（金额本身不丢，但余额列不可信，对账要靠 SUM 重算）。
     */
    @Select("SELECT 1 FROM (SELECT pg_advisory_xact_lock(hashtext(CONCAT('erp_customer_account:', #{customerId})))) t")
    int lockCustomer(@Param("customerId") Long customerId);

}
