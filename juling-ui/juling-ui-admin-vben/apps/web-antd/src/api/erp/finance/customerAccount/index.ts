import type { PageParam, PageResult } from '@vben/request';

import { requestClient } from '#/api/request';

export namespace ErpCustomerAccountApi {
  /** 门店往来台账（一条一条的记账流水） */
  export interface CustomerAccount {
    id?: number; // 台账编号
    customerId?: number; // 门店客户编号
    customerName?: string; // 门店名称
    deptId?: number; // 门店所属部门编号
    deptName?: string; // 门店所属部门名称
    // 业务类型：1 配送应收 / 2 直拨应收 / 3 收款（含预收） / 4 收货差异调整
    //           5 退货冲减 / 11 配送应收冲销 / 12 直拨应收冲销
    bizType?: number;
    bizTypeName?: string; // 业务类型名称（后端直接返回中文）
    amount?: number; // 变动金额：正数 = 门店欠总部增加，负数 = 减少，单位：元
    balance?: number; // 记账后余额快照，单位：元
    // LocalDateTime 在后端可能被序列化成时间戳（毫秒）或字符串，展示统一走 formatDateTime
    billTime?: number | string; // 账单时间
    sourceType?: string; // 来源单据类型
    sourceNo?: string; // 来源单号
    remark?: string; // 备注
    createTime?: number | string; // 创建时间
  }

  /** 门店往来台账分页查询参数 */
  export interface CustomerAccountPageReqVO extends PageParam {
    customerId?: number; // 门店客户编号
    deptId?: number; // 门店所属部门编号
    bizType?: number; // 业务类型
    sourceNo?: string; // 来源单号（模糊）
    billTime?: string[]; // 账单时间区间，格式 yyyy-MM-dd HH:mm:ss
  }

  /** 门店往来汇总 */
  export interface CustomerAccountSummary {
    customerId?: number; // 门店客户编号
    customerName?: string; // 门店名称
    deptId?: number; // 门店所属部门编号
    deptName?: string; // 门店所属部门名称
    totalReceivable?: number; // 累计应收，单位：元
    totalReceived?: number; // 累计已收，单位：元
    balance?: number; // 当前余额（正数 = 门店欠总部），单位：元
  }
}

/** 查询门店往来台账分页 */
export function getCustomerAccountPage(
  params: ErpCustomerAccountApi.CustomerAccountPageReqVO,
) {
  return requestClient.get<
    PageResult<ErpCustomerAccountApi.CustomerAccount>
  >('/erp/customer-account/page', { params });
}

/**
 * 查询门店往来汇总
 *
 * @param params customerId / deptId 均可空；为空时返回全部门店的汇总
 */
export function getCustomerAccountSummary(params?: {
  customerId?: number;
  deptId?: number;
}) {
  return requestClient.get<ErpCustomerAccountApi.CustomerAccountSummary[]>(
    '/erp/customer-account/summary',
    { params },
  );
}

/** 导出门店往来台账 Excel */
export function exportCustomerAccount(
  params: ErpCustomerAccountApi.CustomerAccountPageReqVO,
) {
  return requestClient.download('/erp/customer-account/export-excel', {
    params,
  });
}
