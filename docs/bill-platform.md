# 单据基座（Bill Platform）

> 目的：把"每张单据各写一套 CRUD"改为「统一基座 + 单据只声明差异」，支撑后续 20+ 张单据
> （采购/入库/出库/调拨/盘点/报损/门店收货/直配/自采/应收应付…）与后期财务凭证。
> 模块：`juling-module-bill`；表：`bill_type` / `bill_no_seq` / `bill_relation` / `bill_log` / `bill_ext`；
> 建表脚本：`sql/local/30_bill_platform.sql`（含 26 个单据类型种子）。

## 1. 六件套

| 能力 | 表 / 类 | 说明 |
|---|---|---|
| 单据类型注册 | `bill_type` | 编号规则（前缀/日期格式/重置周期/流水位数）、是否审批 + BPM 流程 key、是否影响库存、**是否产生会计事件**（后期凭证引擎据此过滤）、模块与排序 |
| 单号生成 | `bill_no_seq` + `BillPlatformApi#generateNo` | 按「类型 × 组织 × 期间」原子递增：先 `SELECT ... FOR UPDATE` 行锁，无行则插入（唯一索引兜底，撞了重取）。期间按重置周期取值（D/M/Y/N） |
| 状态机 | `BillStatusEnum#canTransfer` | 草稿→提交→审批中→已审核→执行中→已完成/作废；非法迁移抛错。反审核受控（配合下游引用判断） |
| 单据关联（下推） | `bill_relation` | 头级与行级都支持（source/target + item + qty），唯一索引**防重复下推**，行级 qty 用于防超推 |
| 操作日志 | `bill_log` | 单据类型/编号/操作类型/前后状态/操作人/备注；单据全链路可追溯 |
| 扩展字段 | `bill_ext` | key-value，小需求不改表 |

跨模块**只能**通过 `com.lxjl.juling.module.bill.api.BillPlatformApi` 调用（与 erp-api 同一约定）。

## 2. 已注册的 26 类单据（与金蝶蓝图流程对应）

采购：采购申请 / 采购订单 / 采购入库 / 采购退货 / 收料通知 / 检验单；
门店订配：门店要货申请 / 配送出库 / 门店收货 / 配送异常通知 / 配送补货 / 门店退货申请 / 配送退货 / 报损出库 / 门店直拨 / 门店自采；
库存：调拨 / 盘点 / 盘盈 / 盘亏 / 其他入库 / 其他出库；
财务衔接：应付 / 应收 / 付款单 / 收款单。

## 3. 试点接线（已上线并验证）

- **采购订单**（`ErpPurchaseOrderServiceImpl`）：单号改由平台生成（规则 CGDD + yyyyMMdd + 4 位流水），创建后写 `bill_log`；
- **采购入库**（`ErpPurchaseInServiceImpl`）：单号平台生成（CGRK…），带订单下推时写 `bill_relation`（PURCHASE_ORDER → PURCHASE_IN）与日志。

端到端验证（48081 + 真实接口）：
① 试生成单号 CGDD202609280001 → ② 建采购订单得 CGDD202609280002、日志 CREATE →
③ 审核订单 → ④ 由订单建入库单得 CGRK202609280001、关联 PURCHASE_ORDER(CGDD…) → PURCHASE_IN(CGRK…)、
日志备注"由采购订单 CGDD… 下推" → ⑤ `/bill/platform/relation/downstream` 能查到关联 → ⑥ `bill_no_seq` 按类型/期间各记 1、2。

## 4. 还没接的部分（按顺序）

1. **状态机接管各单据的 status 字段**（现在 ERP 单据仍用 `ErpAuditStatus`，日志里的状态值是它）——迁移时一个单据一个单据换，不动历史数据；
2. **审批路由**：`bill_type.bpm_process_key` 已建字段，待把采购/付款/调价等接进 BPM（门店要货已有）；
3. **会计事件**：`bill_type.affect_finance` 已建字段，S6 时由"事件 + 凭证规则"消费；
4. 前端「单据平台」管理页（类型清单/单号预览/关联追溯/日志），菜单权限待补。

## 5. 两个新表/新模块的通用坑（本次踩到并已修）

1. **新表必须显式建主键**：PostgreSQL 的 `INSERT ... ON CONFLICT (id)` 需要唯一约束；
   `bill_*` 五张表首版漏了主键，导致类型种子一行都没进去（报 "no unique or exclusion constraint"）。
   已在建表语句里加 `PRIMARY KEY`，并加了幂等兜底（检测无主键则补）。
2. **新 Maven 模块必须显式声明 lombok**：否则注解处理器不生效，`@Data`/`@Builder`/`@Getter` 全部不生成，
   编译报一片"找不到符号: 方法 getXxx()"。已在 `juling-module-bill/pom.xml` 加 `lombok(provided)`。
