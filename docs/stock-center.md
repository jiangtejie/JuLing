# 库存中心（S2 切片一）：多状态 + 批次/效期 + FIFO 成本

> 对应蓝图《重庆亚特餐饮业务蓝图 V3.0》的"存"：把 ERP 库存从"只有在仓数量"升级为
> **多状态 + 批次/效期 + FIFO 成本**的地基，并让门店要货工作台看到**真实可用量**。
> 设计口径见 `docs/supply-chain-rebuild-plan.md` §6；本文是落地说明（表结构 / 规则 / 接入点 / 未做项）。

## 1. 口径（已定，不再讨论）

| 项 | 口径 |
|---|---|
| 库存主键维度 | **仓库 × 物料 × 批次**（`sku_id` 已预留，本切片恒为 0 = 按物料记账） |
| 状态 | 四态：**在仓 / 在途 / 占用 / 待检** |
| 可用量 | **在仓 − 占用 + 在途**（待检不计入可用） |
| 效期 | 启用批次 + 效期（用户 2026-09-28 拍板，蓝图"不启用批号管理"一条不采纳） |
| 成本 | **批次 + 效期，按批次做先进先出（FIFO）**；批次级 `unit_cost / total_cost`，出库按批次成本结转 |
| 物料 | 仍以 ERP `erp_product` 为主体（SKU 统一是后续工作） |

## 2. 表结构（`sql/local/35_stock_center.sql`）

### 2.1 新表 `erp_stock_batch`（批次库存）

| 列 | 说明 |
|---|---|
| `id` | 主键（**必须有主键**，否则 `ON CONFLICT` 失效；本仓库历史上有 453 张表缺主键的坑） |
| `warehouse_id` / `product_id` / `sku_id` | 维度：仓库 × 物料 × SKU（预留，0 = 按物料） |
| `batch_no` | 批次号（来源单据录入；未录入时服务生成 `IN{yyyyMMdd}-{入库单项id}`） |
| `production_date` / `expiry_date` / `in_date` | 生产日期 / 到期日期 / **入库日期（FIFO 主排序键）** |
| `count` | **在仓数量**（含被占用部分，与 `erp_stock.count` 同口径） |
| `transit_count` | 在途数量 |
| `occupied_count` | 占用数量（`count` 的子集：已被单据锁定、尚未出库） |
| `inspecting_count` | 待检数量（已到货、质检未放行） |
| `unit_cost` / `total_cost` | 批次单位成本 / 批次在仓成本（= `count × unit_cost`） |
| `source_biz_type` / `source_biz_id` / `source_biz_item_id` / `source_biz_no` | 来源（业务类型/单据/单据项/单号），是**入库幂等键** |
| `source_reversed` | 来源是否已反审核冲销（0/1，反审核可逆：重新审核会复位） |
| `tenant_id` + `creator/create_time/updater/update_time/deleted` | 租户与审计列 |

唯一索引 `uk_erp_stock_batch (warehouse_id, product_id, sku_id, batch_no, tenant_id) WHERE deleted = 0`；
另有 FIFO 排序索引、效期索引、来源反查索引各一。

### 2.2 既有表新增列（只加列，不改既有列语义）

- `erp_stock_in_item`：`batch_no` / `production_date` / `expiry_date`（入库时按批次录入）；
- `erp_stock_record`：`batch_no` / `stock_state` / `unit_cost` / `total_cost` / `sku_id`（流水带批次与成本）。

### 2.3 回填

把 `erp_stock` 既有余额落成批次号 `OPENING` 的**期初批次**（`in_date` 取该库存行的创建日期），
使批次表从第一天起与老口径对齐（幂等：重复执行 `INSERT 0`）。历史没有成本字段，故期初批次 `unit_cost = 0`。

## 3. 状态口径：为什么用"数量分列"而不是 `stock_state` 单列

两种做法都能表达四态：

- **A. `stock_state` 单列**：主键变成 仓库 × 物料 × 批次 × 状态，一个批次最多 4 行；
- **B. 数量分列**（本切片采用）：一个批次一行，`count / transit_count / occupied_count / inspecting_count` 四列。

选 **B** 的理由：

1. **批次是成本的载体**。`unit_cost / total_cost / expiry_date` 属于批次，不属于"批次+状态"。
   走 A 就要在 4 行里各存一份，必然出现行间漂移（同一批次 4 行的成本不一致）；
2. **可用量是单行算术**。B 下 `可用量 = count − occupied_count + transit_count`，一行算完，
   SQL 直白、好建索引、好断言；A 要跨 4 行聚合 + 外连接补齐缺失状态；
3. **FIFO 只关心在仓行**。B 下 FIFO 就是"筛选 `count > 0` 再排序"，A 下要先按批次聚合再排序；
4. 代价是"再加第 5 个状态要 DDL 加列"。本切片四态已冻结，且加列是幂等 DDL（`ADD COLUMN IF NOT EXISTS`），
   比 A 的"NoSQL 灵活"更可控。

### 3.1 四态定义

| 状态 | 列出 | 计入可用量 | 说明 |
|---|---|---|---|
| 在仓 IN_STOCK | `count` | ✔（正） | 实物在库，含被占用部分 |
| 占用 OCCUPIED | `occupied_count` | ✔（负） | 已被单据锁定、尚未出库；是在仓的**子集** |
| 在途 IN_TRANSIT | `transit_count` | ✔（正） | 已发货未到货；采购在途用 |
| 待检 INSPECTING | `inspecting_count` | ✘ | 已到货、质检未放行，不进可用 |

### 3.2 可用量 SQL / 服务方法

```sql
-- 单物料
SELECT COALESCE(SUM(count) - SUM(occupied_count) + SUM(transit_count), 0) AS available_count
  FROM erp_stock_batch
 WHERE warehouse_id = ? AND product_id = ? AND deleted = 0 AND tenant_id = ?;
```

服务方法（`ErpStockBatchService`）：

- `getAvailableCount(warehouseId, productId)`
- `getAvailableCountMap(warehouseId, productIds)`
- `getAvailableSummaryMap(warehouseId, productIds)`（含在仓/占用/在途/待检四项）
- HTTP：`GET /admin-api/erp/stock-batch/available`、`/available-map`

状态数量登记（在途/占用/待检）：`updateStateCount(...)` / `POST /admin-api/erp/stock-batch/update-state`。
**在仓数量不允许在这里改**——在仓的每一次变动都必须走"批次记账"，否则 `erp_stock` 与流水会不一致。

## 4. FIFO 规则

排序键（`ErpStockBatchMapper#selectListByFifo`）：

```sql
ORDER BY in_date ASC, expiry_date ASC, id ASC
```

- 主键 = `in_date`（**先入库先出**，这是"按批次做先进先出"的落地）；
- 并列规则 = `expiry_date`（**同入库日期时先到期先出**）；PostgreSQL 的 `ASC` 默认 `NULLS LAST`，
  即"没有有效期"的批次排在最后；
- 末位 = `id`，保证顺序稳定可复现。

扣减规则：

1. 每次只取"在仓 > 0"的批次，**可出数量 = 在仓 − 占用**（占用部分是别人的，不能被 FIFO 抢走）；
2. 逐批扣减，`UPDATE ... SET count = count - ?, total_cost = ROUND((count - ?) * unit_cost, 2)`
   `WHERE id = ? AND count - occupied_count >= ?` —— 带上限条件的原子扣减，`0 行`即并发冲突，抛错回滚；
3. **一行一批次**写 `erp_stock_record`（数量为负、带 `batch_no/unit_cost/total_cost`），
   同时增量更新 `erp_stock.count`；
4. 总量不足时抛 `STOCK_BATCH_NOT_ENOUGH`（含"需要 / 实际可出"），**整个事务回滚**，不会扣一半。

反审核（`reverseIssue`）按原出库流水逐批回滚数量与成本；无批次的老流水（启用批次管理之前）跳过。

## 5. 成本结转

- 入库：`unit_cost = 入库单价`（其它入库单取入库项 `product_price`；采购入库接入时取采购单价），
  `total_cost = ROUND(unit_cost × 入库数量, 2)`；
- 出库：`结转成本 = Σ(批次扣减数量 × 批次单位成本)`，逐批写入流水的 `total_cost`（负数）；
- `ErpStockBatchIssueRespBO` 把 FIFO 明细（批次/数量/单位成本/金额）与合计成本返回给调用方，
  供后续"材料出库核算 → 食品成本核算"使用（本期只到结转金额，不生成凭证）。

## 6. 与 `erp_stock` 的兼容策略：**双写（增量）**

- `erp_stock.count` 的语义**完全没有变**（仍是"该物料在该仓库的在仓数量"），既有代码零改动可继续用；
- 批次表是"可用量 / 成本 / 效期"的**真源**；
- 双写的**唯一入口**是 `ErpStockBatchServiceImpl#writeStockRecord`：批次记账的每一次在仓变动都会
  经 `ErpStockRecordService#createStockRecord` 增量更新 `erp_stock.count`（复用既有的负数校验），
  因此两边在同一事务内同步，不会出现"批次表改了、erp_stock 没改"。

**已知缺口（重要）**：只有走批次记账的路径才会双写。目前已接入「其它入库单」「其它出库单」
「**采购入库单**（切片二，见 §7.6）」「**销售出库单 = 配送出库单**（切片二，见 §7.7，
含订单工作台统配下推生成的单）」；**调拨 / 盘点 / 采购退货 / 销售退货**仍然只更新 `erp_stock`，
会出现"入库有库存、批次表没有"的偏差。接入方式见 §7.4，链路清单与一致性判据见 §11。

## 7. 接入点

### 7.1 其它入库单（`ErpStockInServiceImpl`）

- 单号切到单据平台：`billPlatformApi.generateNo(BillTypeConstants.OTHER_IN, null)`（前缀 `QTRK` 不变）；
- 审核：逐行 `ErpStockBatchService#receiveBatch`（批次号/生产日期/到期日期来自入库单项，可空自动生成；
  `in_date` 取单据的入库时间；`unit_cost` 取入库单价），内部写流水 + 双写 `erp_stock`；
- 反审核：`reverseReceive`，按来源项幂等；若该批次已被出库导致余额不足，**明确报错拒绝反审核**
  （不做静默截断）。

### 7.2 其它出库单（`ErpStockOutServiceImpl`）

- 单号切到单据平台：`generateNo(BillTypeConstants.OTHER_OUT, null)`（前缀 `QCKD` 不变）；
- 审核：逐行 `issueByFifo`，按 FIFO 扣减并结转成本；
- 反审核：`reverseIssue`，按原流水逐批回滚。

### 7.3 门店要货工作台（真实可用量）

- 新增 `juling-module-erp-api` 的 `ErpStockQtyApi`（`getDefaultWarehouseId / getDefaultWarehouseName /
  getAvailableCount / getAvailableCountMap / getAvailableSummaryMap`），实现落在
  `juling-module-erp` 的 `api/stock/ErpStockQtyApiImpl`；
- 工作台明细接口（`GET /admin-api/trade/workbench/get-items`）把原来的"可下推 N（未分料）"提示
  改为 **ERP 真实可用量**：`中心库可用 150（在仓 180 − 占用 30 + 在途 0）；可下推 2（未分料）`，
  同时新增 `erpWarehouseId/erpWarehouseName/erpOnHandCount/erpOccupiedCount/erpInTransitCount/erpAvailableCount`
  字段供前端高亮；可用量按**默认发货仓（`default_status = true`，当前为中心库）**统计，
  与工作台下推时的默认发货仓口径一致；
- 前端 `apps/web-antd/src/views/mall/trade/workbench`：明细列标题改为
  "ERP 可用量（在仓 − 占用 + 在途）"，可用量 < 要货数量时标红。

### 7.4 给其它模块调用的服务方法（未接入的链路照这个接）

```java
// 采购入库（ErpPurchaseInServiceImpl，未在本切片目录内）——审核时逐行调用：
ErpStockBatchInReqBO in = new ErpStockBatchInReqBO();
in.setWarehouseId(item.getWarehouseId()).setProductId(item.getProductId())
  .setBatchNo(item.getBatchNo()).setProductionDate(item.getProductionDate()).setExpiryDate(item.getExpiryDate())
  .setInDate(purchaseIn.getInTime().toLocalDate()).setCount(item.getCount())
  .setUnitCost(item.getProductPrice())            // 成本取采购单价
  .setBizType(ErpStockRecordBizTypeEnum.PURCHASE_IN.getType())
  .setBizId(item.getInId()).setBizItemId(item.getId()).setBizNo(purchaseIn.getNo());
stockBatchService.receiveBatch(in);               // 幂等：同来源项只入账一次

// 销售出库 / 调拨出库 / 盘亏出库——审核时逐行调用：
stockBatchService.issueByFifo(new ErpStockBatchOutReqBO()/* ... */);   // 返回 FIFO 明细与结转成本

// 反审核：reverseReceive(...) / reverseIssue(...)
```

### 7.5 单号迁移（顺手做）

`service/stock/**` 里原有的 `ErpNoRedisDAO` 取号已全部切到单据平台（`BillPlatformApi#generateNo`）：
`OTHER_IN`(QTRK) / `OTHER_OUT`(QCKD) / `STOCK_TRANSFER`(QCDB) / `STOCK_CHECK`(QCPD)，
前缀与日期流水格式完全一致（`bill_type` 表里这四类的 `no_prefix` 就是这四个），
因此切换对用户无感，但取号从此是"库内 `bill_no_seq` + 事务级咨询锁"，不再依赖 Redis。

### 7.6 采购入库单（`ErpPurchaseInServiceImpl`，切片二接入）

- 审核：逐行 `receiveBatch`，批次号/生产日期/到期日期取**采购入库项**字段
  （`erp_purchase_in_items.batch_no / production_date / expiry_date`，建列脚本 `sql/local/36_batch_wiring.sql`；
  为空时自动生成 `IN{yyyyMMdd}-{项id}`），`in_date` 取**单据入库时间**（FIFO 主排序键），
  `unit_cost` 取**入库单价**，业务类型 `PURCHASE_IN(70)`；内部写带批次的流水并双写 `erp_stock`；
- 反审核：`reverseReceive`（`PURCHASE_IN_CANCEL(71)`），按来源项幂等；批次已被出库导致余额不足时**明确报错拒绝**；
- 历史兼容：接线**之前**已审核的采购入库单在批次表里没有来源批次，反审核退回旧口径（只写 `erp_stock` 流水）
  并打 WARN 日志——这是双表偏差的来源之一，判据见 §11.3。

### 7.7 销售出库单 / 配送出库单（`ErpSaleOutServiceImpl`，切片二接入）

- 审核：逐行 `issueByFifo`，按批次 **FIFO**（`in_date` 升序 → `expiry_date` 升序 → `id` 兜底）扣减
  「在仓 − 占用」，并按批次成本结转（写「一行一批次」的负数流水 + `total_cost`），业务类型 `SALE_OUT(50)`；
- 反审核：`reverseIssue`（`SALE_OUT_CANCEL(51)`），按原出库流水逐批回滚数量与成本；
- **工作台统配下推自动接上**：门店要货工作台的「统配下推」（`ErpStoreAllocApiImpl#pushCentralDelivery`）落的就是
  `erp_sale_out` / `erp_sale_out_items`，所以工作台生成的配送出库单（XSCK…）在审核时同样按 FIFO 扣批次；
- 历史兼容：接线之前审核的出库单流水无批次号，`reverseIssue` 无从回滚 → 退回旧口径（只回补 `erp_stock`）并打 WARN。

## 8. 幂等与事务

- 所有批次记账方法都是 `@Transactional(rollbackFor = Exception.class)`，与单据状态变更同一事务；
- 入库幂等键 = `(source_biz_type, source_biz_item_id)`：重复审核只入账一次；
- 反审核幂等：`source_reversed` 标记；重复反审核直接跳过；反审核后重新审核会**复位**（数量与成本补回）；
- 唯一索引 `uk_erp_stock_batch` 兜底并发重复插入；
- 扣减用带条件的原子 UPDATE 兜底并发超发。

## 9. 未做项 / 风险

| 项 | 说明 |
|---|---|
| ~~采购入库 / 销售出库未接批次~~ | **切片二已接**（§7.6 / §7.7，含工作台统配下推生成的配送出库单）；实测见 §11.4 |
| 调拨 / 盘点 / 采购退货 / 销售退货未接批次 | 这四条链路仍只更新 `erp_stock`（切片二目录外），是双表偏差的现存来源；接口见 §7.4 |
| 期初批次 `unit_cost = 0` | 历史数据没有成本字段，回填时只能记 0；后续可用"成本调整单"补 |
| 一个入库单项 = 一个批次 | 同源分批到货（一次入库行拆多个批次）暂不支持，幂等键会拦住第二次入账 |
| 状态登记的调用方 | `occupied_count / transit_count` 只是登记能力，**还没有真实业务写入**（订单占用、采购在途是后续切片） |
| 在途批次无成本 | `updateStateCount` 自动创建的批次 `unit_cost = 0`；在途转在仓时应由采购入库带上成本 |
| 期末/成本重算/凭证 | 结转金额只写到流水，未生成会计事件与凭证（§8 财务衔接的下一个切片） |
| 工作台按仓切换 | 可用量固定按"默认发货仓"统计，工作台上的发货仓下拉切换暂不影响可用量文案 |
| 权限菜单 | ~~菜单未加，目前仅超管可用~~ → 已补：`sql/local/37_stock_batch_menu.sql` 建了「批次库存」菜单与三个权限码并授权给 156/157，见 §10.3 |
| 批次库存前端页面 | ~~未做独立页面~~ → 已做：`/erp/stock/batch`「批次库存」页（含效期预警），见 §10 |
| SKU 维度 | `sku_id` 列已预留但恒为 0，SKU 统一是后续工作 |

## 10. 前端页面与菜单权限

### 10.1 页面

| 项 | 值 |
|---|---|
| 前端源码 | `apps/web-antd/src/views/erp/stock/batch/index.vue`（+ `data.ts`、`modules/state-form.vue`） |
| 接口层 | `apps/web-antd/src/api/erp/stock/batch/index.ts` |
| 运行时路由 | `/erp/stock/batch`（父级 `/erp/stock`「库存管理」→ `/erp`「ERP 系统」） |
| 菜单 component | `erp/stock/batch/index`——**必须与源码路径一致**，动态路由用 `import.meta.glob('../views/**/*.vue')` 解析，写错就是 404 |
| component_name | `ErpStockBatch`（页签缓存名，与页面 `defineOptions({ name })` 一致） |

页面能力：

- **列表列**：物料、仓库、批次号、生产日期、效期、在仓/在途/占用/待检、可用量、单位成本、总成本、来源单据号、来源类型（字典 `erp_stock_record_biz_type`）、操作；
- **查询**：物料、仓库、批次号（模糊）、**只看有量（默认，口径 = 在仓 > 0，与 FIFO 的 `onlyPositive` 一致）/ 含零**、
  **效期筛选**（全部 / 临期 N 天内 / 已过期）、**临期天数**（默认 30，只在「临期」时出现）；
- **效期可视化**（沿用页面既有 antd Tag）：`EXPIRED` 红 Tag「已过期 N 天」、`WARNING` 黄（orange）Tag「临期 N 天」、
  `NORMAL` 绿「正常」、`NONE` 灰「无有效期」，到期日期在标签下方；状态由后端 `resolveExpiryStatus` 按「今天」计算；
- **底部合计**：本页在仓/在途/占用/待检/可用量（3 位小数）与总成本（2 位小数）；单位成本不参与合计；
- **状态登记**：行内「状态登记」按钮，登记在途/占用/待检的增量（正数增加、负数减少）；
  在仓数量不提供登记——它只能由出入库产生，否则 `erp_stock` 与流水会不一致（后端会抛 `STOCK_BATCH_STATE_NOT_ADJUSTABLE`）。

### 10.2 页面取数与后端接口的对应

| 页面筛选 | 调用 | 说明 |
|---|---|---|
| 效期筛选 = 全部 | `GET /erp/stock-batch/page` | 后端分页与排序（仓库 → 物料 → 入库日期 → 到期日期 → id），`batchNo` 模糊在 SQL 侧 |
| 效期筛选 = 临期 / 已过期 | `GET /erp/stock-batch/expiry-list` | `expiredOnly=false/true` + `warnDays`；后端只返回「在仓 > 0 且有到期日期」的**完整集合**（无分页），故批次号模糊与「只留临期」（`expiredOnly=false` 会连带返回已过期）在前端完成，再按页切片 |
| 状态登记 | `POST /erp/stock-batch/update-state` | 后端鉴权码是 `erp:stock:update`，不是 `erp:stock:batch:update`（见 10.3） |

### 10.3 菜单与权限（`sql/local/37_stock_batch_menu.sql`）

| id | 名称 | 类型 | 父级 | 权限码 |
|---|---|---|---|---|
| 11570 | 批次库存 | 菜单（type=2） | 2583 库存管理 | — |
| 11571 | 批次库存查询 | 按钮（type=3） | 11570 | `erp:stock:batch:query` |
| 11572 | 批次状态登记 | 按钮（type=3） | 11570 | `erp:stock:batch:update` |
| 11573 | 批次状态登记接口 | 按钮（type=3） | 11570 | `erp:stock:update` |

三个要点：

1. **11573 不是冗余**。`ErpStockBatchController.updateState` 的 `@PreAuthorize` 是 `erp:stock:update`，
   而这个码在库里**没有菜单行**——yudao 的权限集合来自「角色-菜单」映射里的 `system_menu.permission`，
   没有菜单行 → 任何角色都拿不到该码 → 非超管点「状态登记」必然 403。补这条按钮菜单是唯一的前端侧修法
   （全仓库只有该接口用这个码，影响面被限制在批次状态登记）；前端按钮鉴权用 `erp:stock:batch:update`。
2. **祖先菜单必须一起授**。yudao `MenuServiceImpl.isMenuDisabled` 会把"父菜单不在授权集合里"的节点整棵剔除，
   只授深层权限会导致权限与菜单都下不到前端（踩坑记录见 `sql/local/34_role_menu_ancestors.sql`）。
   本脚本用递归 CTE 把 4 个新菜单的全部祖先（2583 / 2563）一并授予 157 供应链 / 156 财务，幂等可重复执行。
3. **查询权限与后端码并存**：列表接口 `/page`、`/expiry-list` 后端校验的是 `erp:stock:query`（供应链/财务已有），
   `erp:stock:batch:query` 是页面级查询权限码，两者一起用。

执行与核对：

```bash
docker cp sql/local/37_stock_batch_menu.sql postgres:/tmp/37.sql
docker exec postgres psql -U root -d yate -f /tmp/37.sql
```

> PowerShell 里不要用 `Get-Content | docker exec -i` 管道：中文会按本地代码页编码，psql 收到乱码（菜单名会变成「鎵规搴撳瓨」）。

### 10.4 已知偏差 / 限制

| 项 | 说明 |
|---|---|
| 「只看有量」是**当前页**行过滤 | 后端 `/page` 没有 `onlyPositive` 参数（`ErpStockBatchPageReqVO` 只有 warehouse/product/batchNo/sourceBizNo），本切片不允许改后端，故前端对返回页做行过滤（合计也跟着只算可见行）。**跨页精确过滤 + 精确 total** 需后端在 `ErpStockBatchPageReqVO` 加 `onlyPositive`、Mapper 加 `gt(ErpStockBatchDO::getCount, BigDecimal.ZERO)`（照抄 `selectListByFifo` 的写法） |
| 效期筛选下没有「含零」 | `/expiry-list` 只返回在仓 > 0 的批次，这是后端口径（没有在仓数量的批次谈不上临期/过期损耗） |
| 效期筛选下的分页在前端 | `/expiry-list` 无分页参数，前端切片；数据量大时（>1000 行）会偏重 |
| 排序 | 沿用后端固定排序（仓库 → 物料 → 入库日期 → 到期日期 → id），未开列头点击排序，与 `stock/index.vue`、`record/index.vue` 一致 |

## 11. 切片二：采购入库 / 销售出库接入批次（已接入 / 仍未接入 / 一致性判据）

> 落地范围：把「采购入库」「销售出库（= 配送出库，含订单工作台统配下推）」两条主链路接到批次库存账；
> 建列脚本 `sql/local/36_batch_wiring.sql`（只加列、幂等）；代码只动 `service/{purchase,sale,stock}`、
> `dal/{dataobject,mysql}/purchase` 与本文档。

### 11.1 已接入批次账的链路

| 链路 | 入口（审核/反审核） | 记账方法 | 业务类型 |
|---|---|---|---|
| 其它入库单 | `ErpStockInServiceImpl#updateStockInStatus` | `receiveBatch` / `reverseReceive` | `OTHER_IN(10)` / `OTHER_IN_CANCEL(11)` |
| 其它出库单 | `ErpStockOutServiceImpl#updateStockOutStatus` | `issueByFifo` / `reverseIssue` | `OTHER_OUT(20)` / `OTHER_OUT_CANCEL(21)` |
| **采购入库单** | `ErpPurchaseInServiceImpl#updatePurchaseInStatus` | `receiveBatch` / `reverseReceive` | `PURCHASE_IN(70)` / `PURCHASE_IN_CANCEL(71)` |
| **销售出库单 / 配送出库单**（含工作台统配下推 `XSCK…`） | `ErpSaleOutServiceImpl#updateSaleOutStatus` | `issueByFifo` / `reverseIssue` | `SALE_OUT(50)` / `SALE_OUT_CANCEL(51)` |

### 11.2 仍未接入批次账的链路（只写 `erp_stock`）

| 链路 | 实现位置 | 影响 |
|---|---|---|
| 调拨入库 / 调拨出库 | `ErpStockMoveServiceImpl` | 调拨不动批次，批次表缺这两类流水 |
| 盘盈入库 / 盘亏出库 | `ErpStockCheckServiceImpl` | 盘点结果不改批次，批次余额与账面会漂移 |
| 采购退货出库 | `ErpPurchaseReturnServiceImpl` | 退货不减批次（实测已产生偏差，见 11.3） |
| 销售退货入库 | `ErpSaleReturnServiceImpl` | 退货不进批次（实测已产生偏差，见 11.3） |

> 采购入库项虽然已能带批次号/生产日期/效期，但 **controller 目录本轮禁改**，因此
> `ErpPurchaseInSaveReqVO.Item` 与 ERP 采购入库表单尚未暴露这三个字段；服务端已按字段读取，
> 字段为空时自动生成批次号（`IN{yyyyMMdd}-{项id}`）。补 VO/前端后即可由用户录入批次。

### 11.3 一致性判据（`erp_stock_batch` ↔ `erp_stock`）

**不变量**：同一（仓库 × 物料）下，`SUM(erp_stock_batch.count)` 应恒等于 `erp_stock.count`。
成立的理由是双写唯一入口 `ErpStockBatchServiceImpl#writeStockRecord` 与单据状态变更同事务；
切片二的采购入库/销售出库同样只经这个入口，不再直接调 `createStockRecord`。

核对 SQL（偏差非空即为不一致）：

```sql
SELECT b.product_id, b.warehouse_id, SUM(b.count) AS batch_count, s.count AS stock_count,
       SUM(b.count) - s.count AS diff
  FROM erp_stock_batch b
  JOIN erp_stock s ON s.product_id = b.product_id AND s.warehouse_id = b.warehouse_id AND s.deleted = 0
 WHERE b.deleted = 0
 GROUP BY b.product_id, b.warehouse_id, s.count
HAVING SUM(b.count) <> s.count;
```

偏差的三个来源（**不是**切片二引入的）：

1. **接线前的历史单据**：切片一/二之前审核的采购入库、其它出入库，批次表里没有来源批次。
   切片二对这类单据的反审核做了**旧口径回退**（只冲 `erp_stock`）并打 WARN 日志，不做静默截断；
2. **未接入链路**（11.2）：采购退货、销售退货、调拨、盘点单边改 `erp_stock`；
3. **手工造数/测试数据**。

实测样本（2026-09-29）：产品 3（午餐肉，中心库）批次合计 121（只有一个 `OPENING` 期初批次），
`erp_stock.count = 123`，偏差 `-2`，逐笔归因为：采购入库 `CGRK20260928000003` **+2**（接线前审核，无批次）
＋ 销售退货 `XSTH20260928000001` **+1**（未接入）＋ 采购退货 `CGTH20260928000001` **−1**（未接入）。

> 口径提醒：「可出量」= `SUM(count − occupied_count)` 比 `erp_stock.count` 小，
> 有占用时两者本来就不相等，**这是口径差异不是偏差**（例如产品 6：在仓 992、占用 120、FIFO 可出 872）。

### 11.4 切片二实测结论（2026-09-29，48081 自起实例）

| 场景 | 断言 | 结果 |
|---|---|---|
| A 采购入库：审核 | 批次表新增 `PA…-A/B`（数量/单价/成本/生产日期/效期正确）、`in_date` = 单据入库时间、来源 `70 + CGRK…`、`erp_stock` +100、批次合计 = `erp_stock`、流水逐行带批次与成本 | PASS |
| A 采购入库：反审核 | 批次数量归零、`total_cost = 0`、`source_reversed = 1`、`erp_stock` 回退、冲销流水 −60/−40 带原批次 | PASS |
| A 采购入库：反审核后重新审核 | 数量补回、`source_reversed` 复位为 0、`erp_stock` 回到审核后水位 | PASS |
| B 工作台统配下推 | 加盟门店要货单 → 收款核验 → 供应链（heling）/财务（qinshanzhu）两级审批 → 工作台统配下推得到 `XSCK20260929000001`（出库行落中心库） | PASS |
| B 配送出库审核（FIFO） | 实际扣减序列 `PA…-B(40@30) → PA…-A(60@20) → STKB×3(100@12)` 与按批次表算出的 FIFO 期望**完全一致**；结转成本合计 6000；`erp_stock` −400 且批次合计 = `erp_stock`；流水「一行一批次」5 行 | PASS |
| B 配送出库反审核 | 按原流水逐批回滚数量与成本，`erp_stock` +400 回滚到审核前 | PASS |
| C 批次不足 | 出库单 2 行（产品 6 充足 10 + 产品 3 不足 130 > 可用 121）→ 审核被拒 `1_030_405_002 批次库存不足：物料(3) 仓库(2) 需要 130.000000，实际可出 121.000000`；**整事务回滚**：单据状态仍 10、两行 `erp_stock` 未变、两张批次表未变、无新增流水 | PASS |

### 11.5 切片二顺带修的缺陷

`ErpStockBatchServiceImpl#reverseReceive` 的冲销数量原本取「该来源项历史入库流水之和」，
在「审核 → 反审核 → 重新审核 → 再反审核」时会把两次入库量叠加（60 + 60 = 120），
去冲一个只有 60 的批次，误报 `STOCK_BATCH_REVERSE_FAIL_ISSUED`（"已发生出库，无法反审核"）。
切片二改为**只统计最后一次审核之后**的入库量（按流水 id 顺序扫描，遇到冲销流水即归零），
单次反审核语义与幂等性不变。实测：修复前 `CGRK20260929000002` 无法二次反审核，修复后可正常冲销。

