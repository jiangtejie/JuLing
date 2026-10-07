# 订货账号「授权门店」模型重构设计

> 目标：把订货账号从「**绑定一个客户主体 + 抄一个部门**」改成「**授权一组门店**」，
> 并彻底移除由此产生的四处冗余字段/关系。改造后「加盟店账号」与「片区订货管理人账号」
> 走**完全同一条代码路径**，不再有「代理账号」这第二套分支。
>
> 相关：[organization-model.md](./organization-model.md)（组织与一店三面）、
> [store-ordering-flow-design.md](./store-ordering-flow-design.md)（订货链全局）。
> 状态：**设计待确认**，未动代码。

## 1. 一句话结论

订货账号只需要表达一件事：**这个账号能给哪些门店下单**。它不需要「所属部门」，也不需要
「所属客户」，更不需要在订单上记一个「代理客户」。这四处信息今天全部存在，且全部是冗余或错误的。

| 今天的东西 | 处置 |
|---|---|
| `member_user.dept_id` | **删除** —— 账号没有也不该有部门 |
| `member_user.customer_id` | **删除** —— 账号没有「自己的主体」，它有的是一组授权门店 |
| `trade_order.agent_customer_id` | **删除** —— 只写不读；「谁操作的」`user_id` 已经记了 |
| `erp_customer.parent_customer_id` | **删除** —— 唯一的真实用途是下单授权，被授权表取代 |
| （新增）`member_user_store` | 账号 → 可下单门店，多对多 + 默认门店 |

## 2. 现状与问题（全部实测）

### 2.1 今天的模型：三条轴被压成两条

| 轴 | 承载 |
|---|---|
| 账号面 | `member_user.customer_id` = 账号绑定的「订货主体」（门店 or 代理） |
| 组织面 | `member_user.dept_id` + `erp_customer.dept_id` |
| 经营面 | `erp_customer`（`parent_customer_id` / `store_type` / `settlement_mode` / 账期 / 信用） |

**「可下单门店」没有自己的轴，它从客户树推导出来**（`TradeOrderStoreServiceImpl` 第 50、106 行）：

```
member_user.customer_id → erp_customer
   ├─ 有下级子客户 → 代理账号，可下单门店 = 全部 child（parent_customer_id 指向它）
   └─ 无下级       → 门店账号，可下单门店 = 自己
```

### 2.2 问题

**P1 账号被强加了它不可能拥有的「部门」。** 后台 [order-account-form.vue](../juling-ui/juling-ui-admin-vben/apps/web-antd/src/views/member/user/modules/order-account-form.vue)
第 84-109 行有一段「选中订货主体后带出所属部门」的联动——选完客户，把客户的 `deptId` 抄进账号。
这段联动的存在本身就证明：账号自己给不出部门，只能从门店身上抄。

**P2（最严重）兜底逻辑把错误数据静默沉进账里。** `TradeOrderStoreServiceImpl` 第 76、118 行：

```java
bo.setDeptId(store.getDeptId() != null ? store.getDeptId() : member.getDeptId());
```

门店没建部门时，订单 dept **继承下单账号的部门**。它会顺着
`trade_order.dept_id` → `trade_order_receipt.dept_id` → `ErpStoreReceiptInReqDTO.deptId`
**沉进门店仓库存与门店往来台账**。全程无日志、无告警。

**P3 授权关系不可独立配置，因为「授权」= 客户主数据。** 想动授权就得动客户档案（上面挂着账期、
信用、结算模式）。做不到的事：一个片区下 3 家店，想让 A 店账号只看自己；一家门店想让两个账号
都能下单。「代理本身不能下单」这条规则今天靠「有下级 ⇒ 推断是代理」实现，是**推断不是约束**。

**P4 部门与门店主数据脱节。** `ErpCustomerServiceImpl` 里**没有任何 dept 逻辑**，
`erp_customer.dept_id` 是手工填、不校验、不自动建节点。这决定了 P2 怎么修：去掉兜底后，
门店没建部门时订单 dept 会为空，必须有个明确行为（见 §5.3）。

**P5 「代理」这个概念在业务上不存在。** 业务口径：代理人只是**帮忙下单**，相当于片区门店订货
管理人，不承担账期/信用/结算，也不是收货方。所以它不该是一个 `erp_customer`，
更不该出现在订单上。

### 2.3 风险评估：地雷比看起来少（实测依据）

| 检查项 | 结论 |
|---|---|
| `member_user.dept_id` 的消费者 | **全仓只有 2 行**，就是 P2 那两处兜底。其余 `getDeptId()` 命中都是系统用户 `AdminUserRespDTO` 的路径 |
| `member_user.customer_id` 的消费者 | 同样只有 `TradeOrderStoreServiceImpl` 一处 |
| 是否有 SQL 读 `member_user.dept_id` | **没有**。无 SELECT / JOIN / WHERE，无测试引用 |
| `parent_customer_id` 的消费者 | `getChildCustomerIds` 全仓 2 个调用点，都在订货授权；ERP 自身不读它做结算 |
| `trade_order.agent_customer_id` | **只写不读**：无业务逻辑消费，后台前端 grep 无渲染 |
| BPM | **无影响**。BPM 的部门逻辑（`BpmTaskAssignLeaderExpression`、`AbstractBpmTaskCandidateDeptLeaderStrategy`、流程定义 `startDeptIds` 校验）用的都是系统用户；门店要货流程发起人是系统账号（`juling.trade.order-audit.start-user-id:1`） |
| 数据权限 | **无影响**。member 模块 0 处 `@DataPermission`，`MemberUserPageReqVO` 无 dept 筛选 |
| H5 | **无影响**。`deptId` 只有 4 处类型透传，0 处渲染 |
| uniapp | **无影响**。其 `MemberUser` 接口没有这两个字段 |
| 数据量 | 极小。`erp_customer` 只有 1 条「门店」+ 3 条 E2E 测试；订货账号 3 个；**13 家真实门店尚未建档**——这是改模型的最佳窗口 |

## 3. 目标模型

**「代理」「所属部门」在数据模型里消失。** 概念各归其位：

| 概念 | 落在哪 |
|---|---|
| 片区 / 门店的组织归属 | `system_dept` 组织树（门店建到部门节点下） |
| 门店的经营属性 | `erp_customer`（店型 / 结算模式 / 账期 / 信用 / 收货信息） |
| **账号能给哪些门店订货** | **`member_user_store`**（一账号 → 多门店 + 默认门店） |
| 订单归属 | 门店（`trade_order.customer_id` + `dept_id` 快照） |
| 订单操作人 | `user_id`（已有） |

一句话：**加盟店账号 = 只有一条授权的普通账号；片区订货管理人 = 有多条授权的同一个东西。**

## 4. 数据模型变更

### 4.1 新增 `member_user_store`

```sql
CREATE TABLE member_user_store (
  id           bigserial PRIMARY KEY,
  user_id      bigint   NOT NULL,                 -- member_user.id（订货账号）
  customer_id  bigint   NOT NULL,                 -- erp_customer.id（可下单门店）
  is_default   boolean  NOT NULL DEFAULT false,   -- 账号默认门店（H5 首次进入用它）
  sort         integer  NOT NULL DEFAULT 0,
  status       smallint NOT NULL DEFAULT 0,       -- 0 启用 / 1 停用
  creator, create_time, updater, update_time, deleted, tenant_id   -- BaseDO
);
COMMENT ON TABLE  member_user_store IS '订货账号授权门店（账号可给哪些门店下单）';
COMMENT ON COLUMN member_user_store.customer_id IS '被授权门店（erp_customer.id；必须是组织架构里的门店节点，且未闭店）';

-- 同一账号对同一门店只允许一条有效授权
CREATE UNIQUE INDEX uk_member_user_store ON member_user_store (user_id, customer_id) WHERE deleted = 0;
-- 一个账号只允许一个默认门店
CREATE UNIQUE INDEX uk_member_user_store_default ON member_user_store (user_id) WHERE deleted = 0 AND is_default = true;
CREATE INDEX idx_member_user_store_user ON member_user_store (user_id);
```

**放 member 模块**：它只存 `erp_customer.id` 裸 id，不引入对 erp 的依赖
（`member_user.customer_id` 今天就是这么做的；实测 [member/pom.xml](../juling-module-member/pom.xml)
依赖 system、infra、trade-api，不依赖 erp）。
**门店是否存在/启用**的校验留在 trade（已经通过 `ErpCustomerApi` 做这件事）。

### 4.2 删除清单

| 字段 | DDL 出处 | Java / 前端落点 |
|---|---|---|
| `member_user.dept_id` | `sql/local/26` 第 36、39 行 | `MemberUserDO:134`、`MemberUserBaseVO:67`、`MemberUserCreateReqVO:41`、`MemberUserRespDTO:52`、`MemberUserServiceImpl:90`；后台 5 处 UI（见 §7） |
| `member_user.customer_id` | `sql/local/26` 第 37、40 行 | 同上 VO/DO/DTO；`MemberUserServiceImpl:82` 的 `USER_STORE_NOT_BOUND` 校验；索引 `idx_member_user_customer_id` |
| `trade_order.agent_customer_id` | `sql/local/26` 第 47、57 行 | `TradeOrderDO:163`、`TradeOrderBaseVO:106`、`TradeOrderStoreBO:30`、`TradeOrderUpdateServiceImpl:188`、`TradeOrderStoreServiceImpl:78-79 / 119-120`；前端 `api/mall/trade/order/index.ts:35` |
| `erp_customer.parent_customer_id` | `sql/local/26` 第 19、26 行 | `ErpCustomerDO:97`、`ErpCustomerSaveReqVO:65`、`ErpCustomerRespVO:83`、`ErpCustomerPageReqVO:32`、`ErpCustomerRespDTO:45`、`ErpCustomerApi:41` + `ErpCustomerApiImpl:36-40`（`getChildCustomerIds` 整体删除）、`ErpCustomerController:86-93`（simple-list 透出）、客户表单 `views/erp/sale/customer/data.ts:98`；索引 `idx_erp_customer_parent_id` |

### 4.3 错误码调整

| 错误码 | 现值 | 调整 |
|---|---|---|
| `ORDER_CREATE_FAIL_STORE_NOT_BOUND` (1_011_000_041) | 「订货账号未绑定门店」 | 文案改「该账号未授权任何门店，请联系管理员配置」 |
| `ORDER_CREATE_FAIL_STORE_REQUIRED` (1_011_000_072) | 「该账号是代理人账号（管理多家门店），请先选择下单门店」 | 文案改「请先选择下单门店」（去掉"代理人"措辞） |
| `ORDER_CREATE_FAIL_STORE_NOT_BELONG` (1_011_000_042) | 「所选门店不属于当前订货账号」 | 文案改「该门店未授权给当前账号」 |
| `ORDER_CREATE_FAIL_STORE_NOT_EXISTS` (1_011_000_043) | 「门店不存在或已停用」 | 不变 |
| `USER_STORE_NOT_BOUND` (1_004_001_007) | 「订货账号必须绑定门店（所属客户不能为空）」 | **删除**（member 建号不再校验 customerId） |

> 只改文案、不复用已删模块的码段，符合 `ServiceErrorCodeRange` 的「区间保留、含义不漂移」约定。

## 5. 后端重构

### 5.1 `TradeOrderStoreService` 塌缩

现在 `resolveStore` 有 4 个分支、`getStoreList` 有 2 个分支，全靠「有下级 ⇒ 代理」推断。
改造后**两个方法共用一段逻辑**：

```java
/** 账号的授权门店（结果缓存到本次请求即可，量很小） */
private List<ErpCustomerRespDTO> getAuthorizedStores(Long userId) {
    List<Long> ids = memberUserStoreApi.getStoreIds(userId);          // 只取 status=启用
    if (CollUtil.isEmpty(ids)) {
        throw exception(ORDER_CREATE_FAIL_STORE_NOT_BOUND);
    }
    return erpCustomerApi.getCustomerList(ids).stream()
            .filter(c -> !CommonStatusEnum.isDisable(c.getStatus()))  // 门店停用或已闭店即不可下单（见 §5.5）
            .toList();
}

public TradeOrderStoreBO resolveStore(Long userId, Long storeCustomerId) {
    List<ErpCustomerRespDTO> stores = getAuthorizedStores(userId);
    ErpCustomerRespDTO store;
    if (storeCustomerId == null) {
        // 只有一家授权门店 = 加盟店账号，直接用；多家 = 片区管理人，必须显式选
        if (stores.size() > 1) {
            throw exception(ORDER_CREATE_FAIL_STORE_REQUIRED);
        }
        store = stores.get(0);
    } else {
        store = stores.stream().filter(s -> s.getId().equals(storeCustomerId)).findFirst()
                .orElseThrow(() -> exception(ORDER_CREATE_FAIL_STORE_NOT_BELONG));
    }
    return TradeOrderStoreBO.of(store);   // 见 5.2
}

public List<TradeOrderStoreBO> getStoreList(Long userId) {
    return getAuthorizedStores(userId).stream().map(TradeOrderStoreBO::of).toList();
}
```

删掉的东西：`getChildCustomerIds`、`agentAccount` 推断、「代理不能给自己下单」分支、
`ORDER_CREATE_FAIL_STORE_NOT_EXISTS` 的独立校验（门店停用已在过滤里处理）、两处 dept 兜底。

### 5.2 `TradeOrderStoreBO` 收敛

```java
public static TradeOrderStoreBO of(ErpCustomerRespDTO store) {
    TradeOrderStoreBO bo = new TradeOrderStoreBO();
    bo.setCustomerId(store.getId());
    bo.setCustomerName(store.getName());
    bo.setDeptId(store.getDeptId());                 // 只来自门店，账号永不参与
    bo.setSettlementMode(store.getSettlementMode() != null
            ? store.getSettlementMode() : TradeSettlementModeEnum.DEFAULT_MODE);
    bo.setStoreType(store.getStoreType());
    return bo;                                        // agentCustomerId 字段整体删除
}
```

### 5.3 门店必须在组织架构里（硬前提）

**已确认口径：门店必须挂在组织架构（`system_dept`）里，且未闭店，才能被授权、才能下单。**
所以去掉兜底之后不存在「dept 为空怎么下单」这个问题——dept 为空的门店根本就不该出现在授权列表里。

落地顺序（避免迁移期下不了单）：

1. 先把 13 家真实门店在组织架构里建好（含门店类型与营业状态），并回填 `erp_customer.dept_id`；
2. 授权与下单的校验随之启用硬校验（门店存在 + 是门店类型节点 + 未闭店 + 已挂 `erp_customer`）；
3. 迁移窗口内如仍有门店未建档，用后台可见提示暴露，而不是回退到账号部门。

**配套（必要）**：门店建档应是一个动作 —— 建组织节点 + 建 `erp_customer` 档案 + 互绑，
而不是今天这样三个互不相干的手工步骤（`ErpCustomerServiceImpl` 零 dept 逻辑）。
详见 [organization-architecture-design.md](./organization-architecture-design.md)。

### 5.4 账号维护的原子性

开账号应该是一个原子动作（建账号 + 落授权），不该让前端分两步调。做法：
`MemberUserCreateReqVO` / `UpdateReqVO` 增加 `storeCustomerIds` 与 `defaultStoreCustomerId`，
member 模块经 **trade-api** 调用新增的 `TradeOrderAccountStoreApi` 落库（member 已依赖 trade-api）。

> 备选：把授权表放 trade 模块。语义上更贴（订货域），但要新增一个跨模块 API 给 member 的建号事务用。
> 本设计选 member 落表 + trade 校验，依赖方向不变、改动最小。

## 6. 接口变更

### App（`/app-api`）
| 接口 | 变更 |
|---|---|
| `GET /trade/order/store-list` | 数据源改为授权表；**返回体删掉 `deptId`**（`AppTradeOrderStoreRespVO:24`），新增 `isDefault` |
| `POST /trade/order/create` | `storeCustomerId` 语义不变（选中的授权门店）；校验改为「是否在授权内」 |
| `GET /trade/store-account/summary\|page` | **整体删除**（H5「我的账」下线，见 §8） |

### Admin（`/admin-api`）
| 接口 | 变更 |
|---|---|
| `POST /member/user/create`、`PUT /member/user/update` | VO 去掉 `deptId`/`customerId`，新增 `storeCustomerIds` + `defaultStoreCustomerId` |
| `GET /member/user/get\|page` | RespVO 去掉 `deptId`/`customerId`；如需展示门店名，由前端按 id 查客户列表拼装（现状本来就是裸 id） |
| `GET /erp/sale/customer/simple-list` | 去掉 `deptId` / `parentCustomerId` 透出（`ErpCustomerController:86-93`）；保留 `storeType` 供「直营/加盟」标注 |
| `GET /erp/sale/customer/*` | `parentCustomerId` 字段整体移除（Save/Resp/Page VO） |

**无新增 admin 授权接口**——授权随账号的 create/update 一起提交。

## 7. 后台 UI 变更（web-antd）

| 位置 | 变更 |
|---|---|
| `views/member/user/data.ts:17-168`（编辑表单 `useFormSchema`） | 删 `deptId`、`customerId`；加 `storeCustomerIds`（多选）+ `defaultStoreCustomerId` |
| `views/member/user/data.ts:363-510`（开账号表单 `useOrderAccountFormSchema`） | 同上；placeholder 从「请选择订货主体（门店 / 代理客户）」改成「请选择授权门店（可多选）」 |
| `views/member/user/data.ts:231-290`（列表列） | 删「所属客户」「所属部门」两列；建议改为「授权门店」列显示门店名（顺手修掉裸 id 的问题） |
| `views/member/user/detail/modules/account-info.vue:40-49` | 同上；两个 alternate shell（`web-antdv-next`、`web-ele`）的同名文件一并清理 |
| `views/member/user/modules/order-account-form.vue:30-109` | 删 `markAgentCustomers` / `collectAgentIds` / `handleCustomerChange`（带出部门联动） |
| `views/member/user/data.ts:305-336` | 删 `OrderAccountCustomer.isAgent` / `parentCustomerId` / `formatOrderSubjectLabel`；下拉项只按 `storeType` 标「（直营）/（加盟）」 |
| `api/member/user/index.ts` | `User` / `UserCreateReqVO` 类型去 `deptId`/`customerId`，加授权门店字段 |
| `views/erp/sale/customer/data.ts:98` | 删「上级代理」字段 |

> 只有 `web-antd` 是生产在用的（`scripts/deploy/Dockerfile` 显式排除其余 shell；
> nginx `/jl` 指向 `apps/web-antd/dist`）。其余 shell 按仓库既有的下线改造惯例一并清理。

## 8. H5 变更

**页面基本零改动**，但语义与默认值有变化：

| 位置 | 变更 |
|---|---|
| `src/api/order.ts` `getStoreList` | 数据源语义从「名下门店」变「授权门店」（同一个接口） |
| `src/stores/store.ts` | 首次进入优先用后端下发的 `isDefault`；用户手动切换后本地记忆覆盖（现状 `currentStoreId` 持久化保留） |
| `src/types/order.ts:136`、`types/backend.ts:459`、`types/storeAccount:21`、`api/storeAccount:40` | 删掉 `deptId` 类型透传（4 处） |
| 门店选择器（`views/order/confirm.vue`、`views/order/list.vue`） | 建议加**搜索** —— 片区管理人可能被授权十几家店，纯列表会很长 |

### 8.1 删除「我的账」（已确认）

业务口径：H5 只是**订货渠道**，不涉及代理商账期，所以门店往来台账不应在 H5 出现。
**后台的门店往来台账保留**（财务页面、门店收货差异调整仍在写它），只删 H5 这一条展示链路。

| # | 要删的东西 | 说明 |
|---|---|---|
| 1 | `src/views/user/account`（.vue，已删除） | 整页 454 行 |
| 2 | `src/api/storeAccount`（.ts，已删除） | 整个 API 模块（`/trade/store-account/summary`、`/page`） |
| 3 | `src/types/storeAccount`（.ts，已删除） | 整个领域模型模块 |
| 4 | `src/types/backend.ts` 的 `AppStoreAccountSummaryRespVO` / `AppStoreAccountDetailRespVO` | 两个后端 VO 类型 |
| 5 | `src/router/routes.ts` 的 `/user/account` 路由 | 含 `meta.title: '我的账'` |
| 6 | `src/views/user/index.vue` 的「我的账」菜单项 | 第 40-41 行 |
| 7 | `AppStoreAccountController`（`/trade/store-account/**`） | app-api 后端接口，唯一消费者就是 H5；删除后 `getStoreList` 只剩门店切换器一个调用方 |

**保留（不要误删）**：`erp_customer_account` 台账表、`ErpCustomerAccountApi` / `ErpCustomerAccountService`、
后台「财务 → 门店往来」页面与权限（`sql/local/38`）、门店收货差异调整对台账的写入。
另外 `sql/local/49`、`50` 是历史清理脚本，提到台账属正常，不动。

**已核实无副作用**：H5 单测（`tests/*.test.ts`）零引用；`types/index.ts` 未做 barrel 导出；
H5 页面不是 `system_menu`，无需清菜单权限。

**顺链清理掉的死代码**（2026-10 执行，实测零调用方）：被删的 `AppStoreAccountController`
是 `ErpCustomerAccountApi` 两个跨模块只读方法的**唯一调用者**，因此按闭包一并删除：

| 删除对象 | 位置 |
|---|---|
| `getSummaryList(Collection)`、`getAccountPage(Collection, ...)` | `ErpCustomerAccountApi`（erp-api） |
| 上述两个方法的实现 + 2 个分页常量 + `customerService` 字段 + 18 处无用 import | `ErpCustomerAccountApiImpl`（erp），该文件 **115 行 → 43 行** |
| `ErpCustomerAccountSummaryRespDTO`、`ErpCustomerAccountDetailRespDTO` | erp-api 的 `dto` 包（整文件删除） |
| `ErpCustomerAccountService.getSummaryListByCustomerIds` 及其实现 | erp 模块 |

**保留（仍在使用，不要误删）**：后台走的是 `ErpCustomerAccountService.getSummaryList(customerId, deptId)`
与 `getPage(...)`；Mapper 的 `selectSummaryGroupByCustomer` 被后台 `/summary` 使用；
台账写入侧（`record` / `getPostedAmount` / `getBalance`）不受影响。
相关 4 处误导性注释已同步改准。

## 9. 迁移

数据量极小，可无损迁移。**分两个脚本，先加后删**：

### `sql/local/53_member_user_store.sql`（建表 + 回填，不删列）
1. 建 `member_user_store` 表与索引；
2. 回填：对每个 `customer_id` 非空的订货账号 ——
   - 该客户**有下级** → 授权 = 全部下级，`is_default` = 列表首个；
   - 该客户**无下级** → 授权 = 自身，`is_default` = 它；
3. 打印回填统计（账号数 / 授权行数），供人工核对；
4. 幂等：`CREATE TABLE IF NOT EXISTS` + 回填前先清空本表。

> 此时旧字段仍在、旧代码仍能跑，是**可回退**的状态。

### `sql/local/54_drop_legacy_store_columns.sql`（代码切换并验证后再跑）
1. 把待删列的值备份到 `bak_ordering_account_<日期>` schema（对齐 `sql/local/27` 的既有做法）；
2. 删列：`member_user.dept_id`、`member_user.customer_id`、`trade_order.agent_customer_id`、`erp_customer.parent_customer_id`；
3. 删索引：`idx_member_user_customer_id`、`idx_erp_customer_parent_id`；
4. 清理菜单/字典中与「上级代理」相关的项（如有）；
5. 幂等：`DROP COLUMN IF EXISTS`。

### 同步改写 `sql/local/29_seed_demo_data.sql`
它今天显式 INSERT `member_user.dept_id`/`customer_id`（第 117-120、132-136 行），
并从 `erp_customer.dept_id` 复制——正是「账号部门是抄门店的」的病根。改为：种子数据直接写授权表，
不再设 `parent_customer_id`。

> 执行顺序安全：`29 < 52 < 53 < 54`（`52` 是组织架构脚本），全新环境按序重建不会失败。

## 10. 连带要改的文档

| 文档 | 要改什么 |
|---|---|
| [organization-model.md](./organization-model.md) | §3.1「代理商（母）→ 门店（子），代理商层面管账期、信用额度与结算」——**该业务不存在**（代理只是帮忙下单）；§5「加盟店订货的履约路径」中依赖代理的部分 |
| [store-ordering-flow-design.md](./store-ordering-flow-design.md) | §第 1 段与「数据模型变更清单」里的 `agent_customer_id`；§第 0 段的「代理商」表述 |
| [as-is-process-and-gaps.md](./as-is-process-and-gaps.md) | G1 之后的「代理商多门店 + 门店切换器」相关表述 |

## 11. 实施顺序（每步可独立验证）

| 步 | 内容 | 验证 |
|---|---|---|
| 1 | 脚本 53：建表 + 回填 | 查授权表行数与人工核对一致；旧功能不受影响 |
| 2 | 后端重构：`TradeOrderStoreService` 塌缩 + VO/错误码 + member 建号带授权 | H5 下单、门店切换、门店往来可见范围；加盟/直营分流不受影响 |
| 3 | 后台 UI + H5 | 开账号能选多家门店；H5 默认门店正确 |
| 4 | 脚本 54：备份 + 删列；改写脚本 29；清理文档 | 全新环境重建走通；旧字段在代码里零引用 |

## 12. 风险与回滚

- **删列不可逆** → 脚本 54 先备份到 `bak_` schema；代码切换完成并验证后才执行。
- **门店未挂部门会暴露出来** → 这是**有意的**：静默写错值比留空并提示更危险。配套要尽快把 13 家门店建档 + 挂部门节点。
- **授权配错会让门店看到不属于自己的往来账** → 门店往来可见范围与下单门店是同一个开关（都走 `getStoreList`）。建议授权变更加留痕（谁在何时改了哪个账号的授权）。
- **回滚**：脚本 53 阶段直接回退代码即可；脚本 54 之后需从 `bak_` schema 恢复列。

## 13. 结论与剩余待确认

### 13.1 已确认（2026-10）

| # | 结论 | 落在本文哪一节 |
|---|---|---|
| 1 | **门店必须在组织架构（`system_dept`）里**；组织节点区分「组织 / 门店」，门店再分加盟与直营；「部门管理」更名为「组织架构管理」；门店支持**开店 / 闭店** | §5.3；模型细节见 [organization-architecture-design.md](./organization-architecture-design.md) |
| 2 | **已闭店的门店不能被授权，也不能被下单** | §4.1 注释、§5.1 过滤、§9 校验 |
| 3 | **H5 删除「我的账」**（只是订货渠道，不涉及代理商账期）；后台门店往来台账保留 | §8.1 |

### 13.2 剩余待确认

1. 账号的**历史授权行**遇到门店闭店怎么处理？本设计取「隐藏但保留」，门店复开后自动恢复；
   如业务希望闭店即解除授权，需要明确是否留痕。
2. 组织架构里的**店型（直营/加盟）与 `erp_customer.store_type` 谁权威**？两处都存会漂移，
   这是 [organization-architecture-design.md](./organization-architecture-design.md) 的核心待决项。
