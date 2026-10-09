package com.lxjl.juling.module.erp.api.customer;

import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerAccountRecordReqDTO;

import java.math.BigDecimal;

/**
 * ERP 门店往来台账 API（门店应收 / 收款 / 差异调整）
 *
 * 口径（见 docs/store-receipt-and-receivables-design.md）：
 *   · 台账按「客户（门店）」记账，amount 正数 = 门店欠总部增加（应收），负数 = 减少（收款/冲销/少收）；
 *   · 每个客户串行记账（pg_advisory_xact_lock），每行落一个余额快照 balance，便于逐笔对账；
 *   · (bizType, sourceType, sourceId) 唯一，保证「审核 → 反审核 → 重新审核」不重复挂账。
 *
 * @author 亚特
 */
public interface ErpCustomerAccountApi {

    /**
     * 记一笔门店往来（幂等：同 bizType + sourceType + sourceId 只记一次）
     *
     * @param reqDTO 记账请求
     * @return 是否真正记账（false = 幂等命中，已存在）
     */
    boolean record(ErpCustomerAccountRecordReqDTO reqDTO);

    /**
     * 门店往来余额（正数 = 门店欠总部）
     *
     * @param customerId 门店客户编号
     * @return 余额（无记录返回 0）
     */
    BigDecimal getBalance(Long customerId);

    /**
     * 某来源单据在台账上的**已挂账净额**（SUM(amount)）
     *
     * 用途：审核 / 反审核这类可反复切换的动作，按「目标净额 − 已挂账净额」补差额记账，
     * 而不是靠唯一键去重 —— 否则「审核 → 反审核 → 重新审核」第三步会被当成重复而漏记。
     *
     * @param sourceType 来源单据类型，例如 DELIVERY_OUT
     * @param sourceId   来源单据编号
     * @return 净额（无记录返回 0）
     */
    BigDecimal getPostedAmount(String sourceType, Long sourceId);

}
