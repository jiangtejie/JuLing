# 线下收款改造说明（商城订货 → 线下转账 → 后台核验）

> 适用分支：`custom/yate-catering`。本文说明商城从「线上支付」切换为「线下转账收款」的
> 完整改造：业务闭环、数据模型、接口、前端改动、支付模块切除范围，以及验收与回滚方式。

## 1. 背景与目标

亚特订货商城的真实收款方式是**线下转账**（对公转账 / 微信 / 支付宝 / 现金），不存在线上支付。
原系统沿用 yudao 商城的线上支付链路：下单即创建支付单、等待支付回调、超时自动取消订单，
既跑不通也误导客户。改造目标：

1. 客户提交订货单后，**上传付款截图**（可多次、可分次付款）；
2. 后台财务**核验**凭证：金额对得上就确认收款，对不上可填实际到账金额（部分收款）或驳回重传；
3. 货款收齐后订单**自动进入待发货**，与原有发货流程无缝衔接；
4. 售后退款改为**线下退款登记**，钱包/充值、佣金提现等线上资金能力一并下线，最终物理移除支付模块。

## 2. 业务闭环

### 客户侧（H5 订货商城）

下单成功 → 跳转「上传付款凭证」 → 上传截图 + 填写本次转账金额/付款人/渠道/转账时间 →
提交后订单进入「凭证待核验」 → 后台核验结果实时可见：

| 收款状态 | 含义 | 客户可做什么 |
|---|---|---|
| 0 未上传凭证 | 还没传付款截图 | 上传凭证 |
| 1 待核验 | 已提交，等财务核对 | 等待；可继续补传 |
| 2 已驳回 | 金额不符等原因被驳回 | 看到驳回原因，重新上传 |
| 3 部分收款 | 已确认金额 < 应收金额 | 继续补传尾款 |
| 4 已收齐 | 已确认金额 ≥ 应收金额 | 无需操作，等待发货 |

### 后台侧（vben 管理后台）

订单列表新增「收款状态」列与筛选、「已确认收款」金额列 → 行操作「核验收款」→
弹窗查看凭证大图（可放大）、申报金额、付款人、渠道、备注 → **确认收款**（可填实际到账金额）
或**驳回**（必填原因）→ 列表实时更新；订单详情页另有「收款信息」「付款凭证」区块。

### 状态机（刻意不改 `TradeOrderStatusEnum`）

订单状态仍是 `0 待付款 / 10 待发货 / 20 已发货 / 30 已完成 / 40 已取消`，
线下语义由 `trade_order.payment_proof_status` 承载：**已确认收款金额 ≥ 应付金额** 时，
后端调用 `updateOrderPaidByOffline(...)`，执行与线上支付成功**完全相同**的后置处理
（分销、拼团、积分、库存等 handler 照常），订单转为 `10 待发货`。
好处：发货按钮、后台既有判断、统计口径都不用动。

## 3. 数据模型

| 对象 | 说明 |
|---|---|
| `trade_order_payment_proof`（新表） | 一次上传一行：多图 JSON、申报金额、核定金额、付款人、渠道、转账时间、状态（0 待核验 / 1 已确认 / 2 已驳回）、核验意见。历史全保留，驳回后可新增一行重传 |
| `trade_order.paid_amount` | 已确认收款金额（累计，单位分） |
| `trade_order.payment_proof_status` | 收款状态（0-4，见上表），由凭证聚合而来 |
| `trade_after_sale.refund_channel_code / refund_proof_urls / refund_remark` | 售后线下退款登记：渠道、回执凭证、备注 |
| 字典 `trade_payment_proof_status` | 收款状态 0-4 的中文与颜色（后台列、H5 标签共用） |
| 字典 `pay_channel_code` | **保留**，新增 4 个线下值：offline_transfer / offline_wx / offline_alipay / offline_cash |

> 订单维度与凭证维度是两个不同的状态：订单看「钱收了多少」（聚合），凭证看「这一张单子过没过」。
> 因此「已收部分款 + 最新一张凭证被驳回」时，订单显示「部分收款」，驳回原因在凭证级展示。

## 4. 接口清单

客户（`/app-api`）：

| 方法 | 路径 | 说明 |
|---|---|---|
| POST | `/trade/order/payment-proof/create` | 提交付款凭证（多图 + 申报金额） |
| GET | `/trade/order/payment-proof/list?orderId=` | 我的凭证列表（含驳回原因） |
| GET | `/trade/order/get-detail` | 详情新增 `paidAmount` / `paymentProofStatus` |

后台（`/admin-api`，权限 `trade:order:payment-proof:audit`）：

| 方法 | 路径 | 说明 |
|---|---|---|
| PUT | `/trade/order/payment-proof/audit` | 核验：`{id, approved, confirmedAmount?, auditRemark?}` |
| GET | `/trade/order/payment-proof/list?orderId=` | 订单凭证列表（核验弹窗用） |
| GET | `/trade/order/page` | 新增按 `paymentProofStatus` 筛选 |
| PUT | `/trade/after-sale/refund` | **线下退款登记**：`{id, refundChannelCode, refundProofUrls, refundRemark}`，登记即完成售后 |

## 5. 支付模块切除范围

| 项 | 处理 |
|---|---|
| `juling-module-pay` 后端模块 | 从根 pom / trade / statistics / server 依赖中移除并删除模块目录 |
| 线上支付调用点 | 订单创建不再建支付单；删除支付回调 `/update-paid`、支付状态同步、支付单校验；成交价调整不再同步支付单 |
| 售后线上退款 | 删除 `PayRefundApi` 调用与退款回调，改为线下退款登记 |
| 佣金提现 | 业务无需求，功能整体下线：后端 Controller/Service/Mapper/DO/Convert 与统计计数删除、vben 与 admin-uniapp 页面删除、菜单与提现状态字典清理、`trade_brokerage_withdraw` 表归档（见 `sql/local/20_remove_brokerage_withdraw.sql`）；分销佣金记录/用户与交易配置保留，提现相关字段恒为 0 |
| 钱包/充值 | 随支付模块下线，相关统计与后台入口移除 |
| 后台支付菜单/字典/任务/表 | 见 `sql/local/18_remove_pay_module.sql`：删菜单与 `pay:*` 权限、删支付类字典（保留 `pay_channel_code`）、删 5 个支付定时任务；14 张 `pay_*` 表**重命名**为 `zz_deprecated_pay_*` 归档 |
| `juling-ui-mall-uniapp` | 与 H5 重复，整目录删除 |
| 前端支付入口 | vben 删 `views/pay/**`、`api/pay/**`、支付路由与会员钱包子组件；admin-uniapp 删 `api/pay/**`、提现页面与相关入口（保留返回 0 的统计字段） |

回滚：表只是重命名，`ALTER TABLE zz_deprecated_pay_app RENAME TO pay_app;` 即可恢复；
代码在同一分支的提交历史里，`git revert` 对应提交即可。

## 6. 验收

- 数据库脚本：`sql/local/16_trade_payment_proof.sql`（收款凭证）、`18_remove_pay_module.sql`（支付下线）、
  `19_trade_after_sale_offline_refund.sql`（售后线下退款字段）、`20_remove_brokerage_withdraw.sql`（佣金提现下线），均可重复执行。
- 业务回归：
  - H5 全流程（下单 → 上传 → 待核验 → 部分收款 → 驳回 → 重传 → 收齐 → 自动转待发货）；
  - 后台核验（搜索待核验订单 → 看图 → 确认/驳回 → 列表与详情同步）；
  - 售后线下退款（申请 → 同意 → 登记退款 → 完成 + 重复登记被拒）。

## 7. 已知取舍

1. **不新增订单状态**：线下语义靠收款状态承载，避免改动发货/统计等既有判断（见 §2）。
2. **凭证单条状态不做字典**：凭证状态只有 3 个值且仅后台详情展示，用前端本地映射，
   避免为一个纯展示字段新增字典；订单维度的收款状态有正式字典。
3. **超时自动取消**：仅取消「毫无收款进展」（收款状态 0/2）的待付款订单，
   已上传凭证（待核验/部分收款/已收齐）的订单一律跳过，避免客户已转账却被系统取消。
   `payExpireTime` 窗口是否要按业务放宽/关闭，仍可由业务方在交易配置里决定。
4. **已付款订单被整单取消**（拼团关闭等）：不再自动退款，改为后台人工线下退款；
   订单呈现为「已取消 + 已收金额 > 0」，可据此筛出待退款单据。
5. `trade_order.pay_order_id`、`trade_after_sale.pay_refund_id` 等列保留但不再写入，
   物理删列留待确认无历史数据依赖后再做。
