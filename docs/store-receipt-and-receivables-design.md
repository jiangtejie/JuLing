# 门店收货 · 多收/少收差异 · 门店库存账 · 门店往来台账（S3 切片一）

> 承接 [store-ordering-flow-design.md](./store-ordering-flow-design.md) 第 6 段（签收）与第 7 段（对账结算），
> 把「中心库 → 门店」这一段补齐为可追溯、可对账的闭环：
> **配送出库审核 → 订单已发货 + 生成待确认收货单 → 门店 H5 确认收货（可多收/少收/破损）→ 实收入门店仓（批次/效期/成本）
> → 差异调整门店往来（应收）→ 订单完成。**
> 数据脚本：[sql/local/38_store_receipt_and_receivables.sql](../sql/local/38_store_receipt_and_receivables.sql)

## 1. 这一段原来缺什么

| # | 缺口 | 之前的表现 |
|---|---|---|
| G1 | 出库与订单脱节 | 工作台下推生成配送出库单后，出库单审核只扣中心库库存，**商城订单状态不变**（还停在「待发货」） |
| G2 | 没有签收 | `trade_order.receive_time` 一直是空；门店收到货没有「确认」动作，少货/破损只能靠飞书对账 |
| G3 | 没有门店库存 | 货到了门店就“消失”了：`erp_stock` / `erp_stock_batch` 只有中心库，门店手上还有多少、哪天到期查不到 |
| G4 | 没有门店往来 | 门店欠总部多少钱、付了多少、余款多少，只能翻转账截图；差异金额无处挂账 |

## 2. 设计决策（含取舍）

### 2.1 门店仓 = 一店一仓，复用库存中心

门店库存**不另建一套表**，而是给每家门店建一个「门店仓」（`erp_warehouse.warehouse_type = 'STORE'`，
`store_customer_id` 唯一），收货入库直接走库存中心已有的 `ErpStockBatchService#receiveBatch`。这样门店仓天然具备：

- **批次 / 效期**：门店能看到「这批毛肚还有几天过期」，为后续门店报损、临期预警打底；
- **四态**（在仓 / 在途 / 占用 / 待检）+ 可用量口径与中心库一致；
- **FIFO 成本**：批次单位成本取配送价（门店的进货成本就是配送价），后续门店成本核算（食品成本卡）直接可用；
- **库存流水**：`erp_stock_record` 一行一批次，门店库存可追溯到收货单。

代价：仓库主数据里会多出 N 条门店仓记录（当前 13 家门店 → 13 条）。这是**有意的**——这是「门店库存与中心库库存用同一套账」的前提。

### 2.2 出库 → 订单/收货单：同步 Spring 事件，不用 MQ

ERP 模块**不能**反向依赖商城交易模块（依赖方向是 `trade → erp-api`）。因此：

- 事件类放在 **`juling-module-erp-api`**（`ErpStoreDeliveryAuditedEvent` / `ErpStoreDeliveryCancelledEvent`），
  发布方在 ERP 出库审核内，订阅方在交易模块（`TradeStoreDeliveryListener`）；
- 用**同步** `@EventListener`（不是 `@TransactionalEventListener(AFTER_COMMIT)`）：出库扣库存、订单转已发货、
  建收货单必须**同事务**成败一致，任一步失败整体回滚；MQ / 事务后事件会留下“货发了但订单没转”的中间态；
- 只在出库单能追溯到门店要货单时发布（`bill_relation`：`STORE_REQUISITION → DELIVERY_OUT`），手工出库单不触发。

### 2.3 行级血缘：erp_sale_out_items.source_item_id

`bill_relation` 只到单据级，回答不了「哪条要货单行发了多少」。因此出库单行新增 `source_item_id`
（= `trade_order_item.id`），工作台下推时写入。收货单的明细行就是按它生成的，**应收数量取实际发货数量**
（不是下单数量 —— 工作台可能只下推了一部分）。

### 2.4 门店往来：单表台账 + 余额快照 + 幂等键

`erp_customer_account` 一行一笔，`amount` 正数 = 门店欠总部增加、负数 = 减少：

| bizType | 触发点 | 方向 |
|---|---|---|
| 1 配送应收 | 配送出库单**审核** | + 出库金额 |
| 11 配送应收冲销 | 配送出库单**反审核** | − 出库金额 |
| 4 收货差异调整 | 门店确认收货，差异金额 ≠ 0 | ± 差异金额 |
| 3 收款（含预收） | 付款凭证核验通过（后续切片接入） | − 到账金额 |
| 5 退货冲减 | 门店退货（后续切片） | − 退货金额 |

三条硬约束：

1. **幂等**：唯一索引 `(biz_type, source_type, source_id)` ——「审核 → 反审核 → 重新审核」不会重复挂账
   （反审核用 11 而不是 1，所以不会被幂等键挡住）；
2. **串行**：同门店记账先取 `pg_advisory_xact_lock`，保证 `balance` 余额快照准确；
3. **不可手工改**：后台只提供查询/导出，**没有**新增/编辑入口 —— 台账只能由业务动作产生，保证账实一致。

### 2.5 直拨（供应商直送门店）的应付主体（默认口径）

**默认**：总部是唯一采购主体 —— 总部对供应商挂应付，门店对总部挂应收。
因此门店往来里 `bizType = 2 直拨应收` 表示「直拨给门店的货，门店欠总部」。
本切片未接入直拨的采购入库（直拨目前只生成采购订单），所以 2 号类型暂时不会产生数据。
**若业务实际是「门店直接对供应商付款」，需要改为门店挂应付供应商，届时调整直拨下推的落点即可，本表结构不用动。**

### 2.6 收货确认是强制的，但允许后台代录

- 门店不确认收货，订单不会完成（`receipt_status` 停在 0/10，订单停在「已发货」）；
- 门店不会用手机时，后台「门店收货单」页可**代录**（`POST /trade/store-receipt/create`，权限
  `trade:store-receipt:create`），效果与门店自助确认完全一致（同一 service 方法）；
- 已确认的收货单**不允许作废**（`ORDER_RECEIPT_CANCEL_FAIL_CONFIRMED`）—— 库存与往来账已入账，
  撤销必须走门店退货流程（下一切片），避免“作废了但库存已经入了门店仓”的幽灵数据。

## 3. 状态机

**收货单**（`trade_order_receipt.status`）：`0 待确认 →（门店提交）10 已确认`；`0 →（出库反审核 / 后台作废）20 已作废`。

**订单收货状态**（`trade_order.receipt_status`，聚合）：`0 未收货 → 10 部分收货 →（待确认收货单清零）20 已收货`；
到达 20 时若订单处于「已发货」则自动转「已完成」并写 `receive_time`。

> 注意口径：**「还有没有待确认的收货单」决定订单是否收货完成**，不是「实收 = 发货」。
> 少收是门店验收的最终结论，订单应就此收尾（差额走门店往来调整 + 后续补货/折让）；
> 否则少收订单会永远挂在「已发货」，差异反而被掩盖。

**差异类型**（`trade_order_receipt.diff_type`）：`0 无差异 / 1 少收 / 2 多收 / 3 破损 / 4 混合`。

## 4. 数据模型

| 对象 | 变更 |
|---|---|
| `erp_warehouse` | 新增 `warehouse_type`（CENTER/STORE）、`store_customer_id`（唯一）、`dept_id`；按门店客户生成 13 个门店仓 |
| `erp_sale_out_items` | 新增 `source_item_id`（要货单行 → 出库单行的行级血缘） |
| `trade_order_receipt` | **新表**：收货单头（单号/订单/门店/门店仓/出库单/状态/差异/金额/收货人/凭证图/作废信息） |
| `trade_order_receipt_item` | **新表**：应收 / 实收 / 差异 / 差异原因 / 批次 / 生产日期 / 效期 |
| `erp_customer_account` | **新表**：门店往来台账（业务类型 / 金额 / 余额快照 / 来源单据 / 业务时间） |
| `trade_order` | 新增 `receipt_status` |
| `trade_order_item` | 新增 `delivered_count`（ERP 已发货）、`receipt_count`（门店已收） |

## 5. 接口

**后台**

| 方法 | 路径 | 权限 |
|---|---|---|
| GET | `/trade/store-receipt/page` | `trade:store-receipt:query` |
| GET | `/trade/store-receipt/get?id=` | `trade:store-receipt:query` |
| POST | `/trade/store-receipt/create` | `trade:store-receipt:create` |
| POST | `/trade/store-receipt/cancel?id=&reason=` | `trade:store-receipt:cancel` |
| GET | `/trade/store-receipt/export-excel` | `trade:store-receipt:export` |
| GET | `/erp/stock-batch/page?warehouseType=STORE` | `erp:stock:query` |
| GET | `/erp/stock-batch/store-summary?customerId=` | `erp:stock:store:query` |
| GET | `/erp/customer-account/page` `/summary` `/balance` `/export-excel` | `erp:customer-account:query` / `:export` |

**门店 H5**

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/trade/order/store-receipt/pending-page` | 我的待收货列表 |
| GET | `/trade/order/store-receipt/get?orderId=` | 收货单详情（含应收数量） |
| POST | `/trade/order/store-receipt/create` | 确认收货（实收数量 + 差异原因 + 图片） |

H5 归属校验：收货单 `member_user_id` = 下单账号，不匹配按「订单不存在」处理。

## 6. 关键规则

1. **应收数量 = 实际发货数量**（不是下单数量）；
2. **实收数量 ≥ 0，且允许多收**（实收 > 发货数量）：中心库多发 / 供应商随车多发在餐饮配送里很常见，
   多出部分照实入门店仓并按配送价**增加**门店应收，差异类型记「多收」，总部事后据此核对；
3. **有差异必须填原因**（`ORDER_RECEIPT_DIFF_REASON_REQUIRED`）；
4. **门店仓入库按「收货单行」幂等**（`STORE_RECEIPT` + `receiptItemId`），门店重复点提交只入账一次；
5. **差异金额同步挂账**：少收 → 负数冲减门店应收；多收 → 正数增加门店应收；
6. **中心库出库成本与门店进货成本是两回事**：出库按批次 FIFO 结转中心库成本，门店仓的单位成本取**配送价**。

## 7. 待确认 / 下一片

1. **直拨的应付主体**（见 §2.5）—— 默认「总部挂供应商、门店挂总部」，若业务相反需调整；
2. **门店退货 / 调拨 / 盘点 / 报损**：复用同一套门店仓 + 门店往来，相关单据类型已在单据平台注册；
3. **收款核销**：付款凭证核验通过时按 `bizType = 3` 记收款（含预收余款），并把余款抵扣接到下单流程；
4. **差异自动下推**：少收直接生成「配送补货单」（`DELIVERY_SUPPLEMENT`）或折让单；
5. **到期自动确认收货**：门店长期不确认时的兜底（参考现有的 `SYSTEM_RECEIVE` 定时任务模式）。
