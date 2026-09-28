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

**已知缺口（重要）**：只有走批次记账的路径才会双写。目前接入的是
「其它入库单（审核/反审核）」「其它出库单（审核/反审核）」；**采购入库 / 销售出库 / 调拨 / 盘点**
（不在这批目录里）仍然只更新 `erp_stock`，会出现"入库有库存、批次表没有"的偏差。
接入方式见 §7.4，本次已把能力做成**给其它模块调用的服务方法**。

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

## 8. 幂等与事务

- 所有批次记账方法都是 `@Transactional(rollbackFor = Exception.class)`，与单据状态变更同一事务；
- 入库幂等键 = `(source_biz_type, source_biz_item_id)`：重复审核只入账一次；
- 反审核幂等：`source_reversed` 标记；重复反审核直接跳过；反审核后重新审核会**复位**（数量与成本补回）；
- 唯一索引 `uk_erp_stock_batch` 兜底并发重复插入；
- 扣减用带条件的原子 UPDATE 兜底并发超发。

## 9. 未做项 / 风险

| 项 | 说明 |
|---|---|
| 采购入库 / 销售出库 / 调拨 / 盘点未接批次 | 这几条链路不在本切片目录内，仍只更新 `erp_stock`；接口见 §7.4，**接入后批次表才是全量真源** |
| 期初批次 `unit_cost = 0` | 历史数据没有成本字段，回填时只能记 0；后续可用"成本调整单"补 |
| 一个入库单项 = 一个批次 | 同源分批到货（一次入库行拆多个批次）暂不支持，幂等键会拦住第二次入账 |
| 状态登记的调用方 | `occupied_count / transit_count` 只是登记能力，**还没有真实业务写入**（订单占用、采购在途是后续切片） |
| 在途批次无成本 | `updateStateCount` 自动创建的批次 `unit_cost = 0`；在途转在仓时应由采购入库带上成本 |
| 期末/成本重算/凭证 | 结转金额只写到流水，未生成会计事件与凭证（§8 财务衔接的下一个切片） |
| 工作台按仓切换 | 可用量固定按"默认发货仓"统计，工作台上的发货仓下拉切换暂不影响可用量文案 |
| 权限菜单 | 批次库存接口复用 `erp:stock:query`；状态登记用 `erp:stock:update`（菜单未加，目前仅超管可用） |
| 批次库存前端页面 | 本切片只改工作台文案，未做"批次库存/效期预警"的独立页面与菜单 |
| SKU 维度 | `sku_id` 列已预留但恒为 0，SKU 统一是后续工作 |
