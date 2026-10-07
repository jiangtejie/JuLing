# 组织架构与门店类型设计（「部门管理」→「组织架构管理」）

> 目标：把 `system_dept` 从一棵**无类型的部门树**升级为**组织架构树** —— 节点区分「组织」与「门店」，
> 门店再分加盟/直营，并支持**开店 / 闭店**；后台「部门管理」更名为「组织架构管理」。
>
> 状态：**设计待确认**（§7 有 5 个待拍板项），未动代码。
> 相关：[organization-model.md](./organization-model.md)（组织与一店三面）、
> [ordering-account-authorization-design.md](./ordering-account-authorization-design.md)（订货账号授权门店）。

## 1. 为什么改

今天 `system_dept` 只是一棵**没有类型的树**。实测 `DeptDO` 的全部字段是：
`name` / `parentId` / `sort` / `leaderUserId` / `phone` / `email` / `status` ——
**没有任何字段说明「这个节点是部门还是门店」**。

但库里已经在把门店当部门节点用了（见 [organization-model.md](./organization-model.md) 实测）：
品牌 119-122、公司 123-133、门店 134-146（13 家）、仓库 121→127。

于是产生三个问题：

1. **门店与部门不可区分**：「这家店是加盟还是直营」「这个节点能不能下单」只能绕道 `erp_customer.store_type` 查；
2. **同一件事有三个 status**：`system_dept.status`、`erp_customer.status`，而门店「营业 / 闭店」今天**无处表达**；
3. **建门店是三个互不相干的手工动作**：建组织节点、建 `erp_customer` 档案、把两者互绑
   （`ErpCustomerServiceImpl` 里**零 dept 逻辑**，`erp_customer.dept_id` 纯手工填、不校验）。

## 2. 目标模型

`system_dept` 升级为组织架构树，新增两类信息：

### 2.1 节点类型

| 方案 | 取值 | 说明 |
|---|---|---|
| **A（推荐）** | `dept_type`：`ORG` 组织 / `STORE` 门店，店型另存 | 与 `erp_store_type` 字典（DIRECT 直营 / FRANCHISE 加盟）正交 |
| B | 三值枚举：组织 / 加盟门店 / 直营门店 | 一次表达完，但把「是不是门店」和「什么店型」耦合成一个字段 |

推荐 A，理由：判断「能否下单」只需看 `dept_type = STORE`，判断「是否免审」才需要店型 —— 两件事不该挤在一个字段里。

### 2.2 营业状态（开店 / 闭店）

门店节点需要「营业 / 已闭店」状态，且**与 `status`（启用/停用）语义不同**：
`status` 是「这条主数据是否可用」，闭店是「这家店当前是否经营」。建议新增 `business_status`
或直接给门店节点加 `closed_at` / `closed_reason`，保留完整的开关店历史。

### 2.3 门店必须在组织架构里（已确认）

**门店必须挂在组织架构里且未闭店，才能被订货账号授权、才能下单。** 这条口径是订货链的硬前提，
落地与迁移顺序见 [ordering-account-authorization-design.md](./ordering-account-authorization-design.md) §5.3。

## 3. 「部门管理」→「组织架构管理」

| 位置 | 说明 |
|---|---|
| 菜单名 | `system_menu` 里的「部门管理」，在基线 [juling-baseline.sql](../sql/postgresql/juling-baseline.sql) 第 2140 行的 `system_menu` INSERT 中 → 需要一个 `UPDATE` 补丁脚本 |
| 后台页面 | [apps/web-antd/src/views/system/dept/](../juling-ui/juling-ui-admin-vben/apps/web-antd/src/views/system/dept/)（`index.vue` / `data.ts` / `form.vue` / `tree-select.vue` / `select-modal.vue` / `components/` / `modules/`）：页面标题、表单标签、树选择器的 placeholder 与文案 |
| 其它引用 | 用户管理的「所属部门」、数据权限的「部门数据权限」、BPM 审批人的「部门负责人」策略等 |

**建议只改「菜单名 + 组织架构管理页自己的文案」**，其它模块里「部门」这个词保持不动 ——
在用户管理、审批人策略这类语境下「部门」本来就该叫部门，全面改名会把改动面炸开且收益很低。

## 4. 术语冲突：`DIRECT` 有两个含义（顺手要修）

既然目标是「清晰好理解」，这个必须先说：

| `DIRECT` | 出处 | 含义 |
|---|---|---|
| `erp_customer.store_type = 'DIRECT'` | [sql/local/26](../sql/local/26_store_order_org_audit.sql) 第 81 行（字典 `erp_store_type`） | **直营门店**（免审） |
| `trade_order_item.alloc_mode = 'DIRECT'` | [sql/local/33](../sql/local/33_workbench_alloc.sql) 第 13、75 行（字典 `trade_order_item_alloc_mode`） | **直拨**（分料方式，与「统配 CENTRAL」相对） |

同一个字符串在同一个系统里既表示店型又表示分料方式，读代码的人必然踩坑。建议改名其中之一
（例如分料用 `DIRECT_SHIP` / `CENTRAL_ALLOC`，或店型改 `OWN` / `FRANCHISE`），
**改字典值 + 常量 + 已有数据**；字典项改名成本低，越早越好。

## 5. 影响面

| 面 | 影响 |
|---|---|
| 订货账号授权（`member_user_store`） | 授权与下单校验增加「目标节点 `dept_type = STORE` 且未闭店」 |
| 订单快照 | `trade_order.dept_id` 含义不变（仍是组织节点快照） |
| 门店建档 | 从「三个手工动作」收敛为「一个建店动作」：建组织节点 + 建 `erp_customer` + 互绑 |
| 数据权限 / BPM | 若给组织节点加了类型，需确认**组织节点**（非门店）仍正常参与数据权限与审批人策略 |
| 现有数据 | 13 家门店节点（134-146）、品牌/公司/仓库节点都要**回填 `dept_type`**；`erp_customer` 里真实门店尚未建档（[as-is-process-and-gaps.md](./as-is-process-and-gaps.md) G9） |
| H5 | 无直接影响（只消费授权门店列表） |

## 6. 落地顺序建议

1. `system_dept` 加 `dept_type`（+ 门店营业状态字段），**回填**现有 47 个节点的类型；
2. 后台「组织架构管理」页面加类型/状态展示与开店闭店操作；菜单改名；
3. 「建门店」收敛为一个动作（组织节点 + `erp_customer` 互绑）；
4. 打开订货链的硬校验（门店类型 + 未闭店）。

第 1、2 步与订货账号授权改造**互不阻塞**，可以先做；第 4 步依赖前 3 步完成。

## 7. 需要拍板（5 项）

1. **店型放哪**：`system_dept` 上再存一份店型，还是以 `erp_customer.store_type` 为唯一权威？
   （两处都存必然漂移 —— 这是本文最关键的一项）
2. **节点类型用 2 值（组织/门店）+ 独立店型，还是 3 值枚举**？（§2.1 推荐前者）
3. **闭店是状态还是删除**？闭店可逆吗？已闭店门店的历史订单与授权怎么处理？
4. **一个门店节点是否强制绑定 `erp_customer` 档案**（一对一）？还是允许只建组织节点先不建档？
5. **改名范围**：只改菜单名与组织架构管理页文案，还是连带用户管理/数据权限等处的「部门」一起改？（§3 建议只改前者）
