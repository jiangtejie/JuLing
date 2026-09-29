/**
 * 门店往来（「我的账」）领域模型。
 *
 * 与后端 `/trade/store-account/summary` / `/trade/store-account/page` 对应，
 * 由 `src/api/storeAccount.ts` 从 ERP 台账 DTO 归一而来（不经过 adapters 目录）。
 *
 * 两条口径必须记住：
 * 1. **金额单位是元**（ERP 台账 BigDecimal），不是商城的「分」——不要套 `formatPrice`（它按分→元换算）；
 * 2. **正数 = 门店欠总部**（应收 / 余额），负数 = 冲减 / 已收 / 总部欠门店。
 *
 * 台账只读：数据由业务动作（配送出库审核、收款核验、收货差异调整）自动产生，
 * 前端不提供任何记账 / 修改入口。
 */

/** 门店往来余额汇总（一家门店一行） */
export interface StoreAccountSummary {
  /** 门店客户编号 */
  customerId: number;
  /** 门店名称（后端补客户主数据，缺失时前端兜底「门店 <id>」） */
  customerName: string;
  deptId?: number;
  /** 累计应收（元，正数记账合计） */
  totalReceivable: number;
  /** 累计已收 / 冲减（元，负数记账的绝对值） */
  totalReceived: number;
  /** 当前余额（元，正数 = 门店欠总部） */
  balance: number;
}

/** 门店往来明细（一笔账） */
export interface StoreAccountBill {
  id: number;
  customerId: number;
  /** 门店名称（不传 customerId 查全部门店时用于区分行） */
  customerName: string;
  /** 业务类型：1 配送应收 / 3 收款 / 4 收货差异调整 / 11 配送应收冲销 … */
  bizType?: number;
  /** 业务类型名称（后端字典翻译，缺失时前端兜底「往来记账」） */
  bizTypeName: string;
  /** 金额（元，正数 = 门店欠总部增加，负数 = 冲减） */
  amount: number;
  /** 记账后余额快照（元，正数 = 门店欠总部） */
  balance: number;
  /** 业务时间（毫秒时间戳或格式化字符串） */
  billTime?: string | number;
  /** 来源单据类型（DELIVERY_OUT / STORE_RECEIPT …） */
  sourceType?: string;
  /** 来源单号 */
  sourceNo?: string;
  remark?: string;
}

/** 门店往来明细分页查询参数 */
export interface StoreAccountQuery {
  /** 门店客户编号；不传 = 当前账号名下全部门店 */
  customerId?: number;
  pageNo?: number;
  pageSize?: number;
}
