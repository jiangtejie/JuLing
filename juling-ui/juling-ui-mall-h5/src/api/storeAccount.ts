import type {
  AppStoreAccountDetailRespVO,
  AppStoreAccountSummaryRespVO,
  BackendPage,
  BackendDecimal,
  PageResult,
} from '@/types';
// 领域类型按路径直接引入：`types/index.ts` 桶文件不在本次多 agent 分工的改动范围内
import type {
  StoreAccountBill,
  StoreAccountQuery,
  StoreAccountSummary,
} from '@/types/storeAccount';
import { http } from '@/utils/request';

/**
 * 门店往来（「我的账」）接口 —— 只读。
 *
 * 后端可见范围 = 当前账号**可下单的门店**（门店账号只有自己，代理人账号是名下所有门店），
 * 指定 customerId 时后端也会校验归属，越权看不到别家门店的账。
 *
 * 两条口径：
 * 1. 台账金额单位是**元**（ERP 侧 BigDecimal），不是商城的「分」，展示时不要再做分→元换算；
 * 2. **正数 = 门店欠总部**（应收 / 余额），负数 = 冲减 / 已收。
 *
 * 数据由业务动作自动产生（配送出库审核挂应收、收款核验冲减、收货差异调整），
 * 因此这里**只提供查询**，没有任何记账 / 修改入口。
 */

/** 后端 decimal → number（正常下发 number，个别出口可能是字符串或 null） */
function toAmount(value: BackendDecimal | undefined): number {
  const num = Number(value ?? 0);
  return Number.isFinite(num) ? num : 0;
}

function adaptSummary(raw: AppStoreAccountSummaryRespVO): StoreAccountSummary {
  return {
    customerId: Number(raw.customerId ?? 0),
    customerName: raw.customerName ?? '',
    deptId: raw.deptId ?? undefined,
    totalReceivable: toAmount(raw.totalReceivable),
    totalReceived: toAmount(raw.totalReceived),
    balance: toAmount(raw.balance),
  };
}

function adaptBill(raw: AppStoreAccountDetailRespVO): StoreAccountBill {
  return {
    id: Number(raw.id ?? 0),
    customerId: Number(raw.customerId ?? 0),
    customerName: raw.customerName ?? '',
    bizType: raw.bizType ?? undefined,
    bizTypeName: raw.bizTypeName ?? '',
    amount: toAmount(raw.amount),
    balance: toAmount(raw.balance),
    billTime: raw.billTime ?? undefined,
    sourceType: raw.sourceType ?? undefined,
    sourceNo: raw.sourceNo ?? undefined,
    remark: raw.remark ?? undefined,
  };
}

/** 门店往来汇总（一家门店一行；正数 = 门店欠总部） */
export async function getStoreAccountSummary(): Promise<StoreAccountSummary[]> {
  const list = await http.get<AppStoreAccountSummaryRespVO[]>('/trade/store-account/summary');
  return (list ?? []).map(adaptSummary);
}

/**
 * 门店往来明细分页。
 * 不传 customerId = 当前账号名下全部门店混排（后端按业务时间倒序），传了就只看该门店。
 */
export async function getStoreAccountPage(
  params: StoreAccountQuery,
): Promise<PageResult<StoreAccountBill>> {
  const page = await http.get<BackendPage<AppStoreAccountDetailRespVO>>(
    '/trade/store-account/page',
    {
      customerId: params.customerId,
      pageNo: params.pageNo,
      pageSize: params.pageSize,
    },
  );
  return {
    list: (page?.list ?? []).map(adaptBill),
    total: page?.total ?? 0,
  };
}
