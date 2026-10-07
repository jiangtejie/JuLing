# sql/local —— 本地补齐脚本(PostgreSQL)

基线 `sql/postgresql/juling-baseline.sql` 缺少部分业务模块的**菜单 / 字典 / 定时任务**数据,
本目录记录本项目补齐这些数据所用的脚本,便于新环境重建时复用。

> **完整重建顺序**:`juling-baseline.sql`(system + infra)→ `module-schema.sql`(业务模块 123 张表)
> → `quartz.sql`(调度表)→ **本目录 01…56**(菜单/字典/表结构补齐)。
> `act_*`/`flw_*` 由 `flowable.database-schema-update: true` 自动创建。

## 执行顺序

```bash
# 在已导入基线 sql/postgresql/juling-baseline.sql + quartz.sql 的库上执行
psql -U root -d juling -f sql/local/01_menu_fms_wms.sql
psql -U root -d juling -f sql/local/02_menu_hrm_im_pms_crm.sql
psql -U root -d juling -f sql/local/03_dict_missing.sql
psql -U root -d juling -f sql/local/04_jobs_missing.sql
psql -U root -d juling -f sql/local/05_patch_iot_ota_permission.sql
# 清理演示数据(演示账号/租户、演示文件存储与邮箱/社交/短信渠道配置)
psql -U root -d juling -f sql/local/06_clean_demo_users_tenants.sql
psql -U root -d juling -f sql/local/07_clean_demo_configs.sql
# FMS 标准科目模板(账套初始化的科目来源);仅在账套尚未初始化成功时执行
psql -U root -d juling -f sql/local/08_fms_subject_template.sql
# 补齐代码引用但基线脚本缺失的字典
psql -U root -d juling -f sql/local/09_dict_baseline_gaps.sql
# T2 改名同步:数据库里存了 Java 类全名/历史域名的地方(文件存储 @class 等)
psql -U root -d juling -f sql/local/10_rename_legacy_identifiers.sql
# 补齐「线上库有、基线+本目录没有」的字典(菜单类型/数据范围/MES 发料状态)
psql -U root -d juling -f sql/local/11_dict_fresh_install_gaps.sql
# 修复 ERP 单据「数量/金额」计数器为 NULL 导致的「关联单据」弹窗查询为空（代码修复见提交 2c8f7f32）
psql -U root -d juling -f sql/local/12_fix_erp_null_counters.sql
# 补齐 pay 模块缺失的支付应用（下单报「App 不存在」的直接原因）
psql -U root -d juling -f sql/local/13_pay_app_seed.sql
# 补齐转换时丢失的主键（缺主键会让 PostgreSQL 的「关联查询 + GROUP BY 主键」直接报错）
psql -U root -d yate -f sql/local/15_add_missing_primary_keys.sql
# 线下收款（付款凭证）改造：建凭证表 + 订单加收款字段 + 字典 + 收款核验按钮权限
#   （注：其中「收款核验」按钮权限已由 48 号脚本停用——提交凭证即进两级审批，不再人工核验）
psql -U root -d yate -f sql/local/16_trade_payment_proof.sql
# 支付模块下线：清理支付菜单/字典/定时任务，pay_* 表重命名归档（pay_channel_code 字典保留）
psql -U root -d yate -f sql/local/18_remove_pay_module.sql
# 佣金提现下线：清理提现菜单/字典，提现表归档
psql -U root -d yate -f sql/local/20_remove_brokerage_withdraw.sql
# 订单金额列兜底：补默认值 + 回填历史 NULL（避免调价/售后 NPE）
psql -U root -d yate -f sql/local/21_trade_amount_defaults.sql
# 商品分销整体下线（物理清除）：清理分销菜单/权限/字典/定时任务，并删除三张分销表与 14 个分销列
psql -U root -d yate -f sql/local/22_remove_brokerage.sql
# 门店自提整体下线：清理自提菜单/权限与配送方式字典项，删除自提门店表与相关列
psql -U root -d yate -f sql/local/23_remove_pick_up.sql
# 修复 system_dept 序列落后导致「新增部门」撞主键（迁移库常见问题）
psql -U root -d yate -f sql/local/24_fix_system_dept_sequence.sql
# 交易配置初始化：库里没有配置行时补一行默认值（否则「交易配置」页是空白）
psql -U root -d yate -f sql/local/25_trade_config_default.sql
# 门店订货链 S2 切片一：物料分料属性（允许统配/允许直拨）+ 订单行 alloc_mode + 订单店型快照 + 「订单工作台」菜单
psql -U root -d yate -f sql/local/33_workbench_alloc.sql
# 门店收货/往来台账 → 订货账号 → 会员中心/营销/支付归档 → 7 个用不到的模块整体下线
psql -U root -d yate -f sql/local/38_store_receipt_and_receivables.sql
psql -U root -d yate -f sql/local/39_member_username_login.sql
psql -U root -d yate -f sql/local/40_remove_member_center.sql
psql -U root -d yate -f sql/local/41_fix_order_account_menu.sql
psql -U root -d yate -f sql/local/42_move_order_account_to_mall.sql
psql -U root -d yate -f sql/local/43_remove_promotion_and_comment.sql
psql -U root -d yate -f sql/local/44_cleanup_archived_pay_and_dead_role.sql
psql -U root -d yate -f sql/local/45_remove_unused_modules.sql
# 组织架构（组织/门店 + 开店闭店）→ 订货账号授权门店（建表回填）→ 基础资料菜单归口 → 统一编码
psql -U root -d yate -f sql/local/52_organization_architecture.sql
psql -U root -d yate -f sql/local/53_member_user_store.sql
psql -U root -d yate -f sql/local/55_master_data_menu.sql
psql -U root -d yate -f sql/local/56_code_rule.sql
psql -U root -d yate -f sql/local/57_code_rule_menu.sql
# ⚠️ 全库测试数据清理：58 先整表备份到 bak_testdata_20261007 再删（可回退）；
#    59 删历史备份 schema（不可回退）
psql -U root -d yate -f sql/local/58_clean_all_test_data.sql
psql -U root -d yate -f sql/local/59_drop_backup_schemas.sql
# 下线用不到的功能：监控中心（含链路追踪）与代码生成
psql -U root -d yate -f sql/local/60_remove_monitor_and_codegen.sql
psql -U root -d yate -f sql/local/61_remove_infra_devtools.sql
# 供应商档案扩展（采购部门需求：账户/开票/结账/交期/合同/证照）
psql -U root -d yate -f sql/local/62_supplier_profile.sql
# 采购订单记住结算方式 / 交期（下单时从供应商带出）
psql -U root -d yate -f sql/local/63_purchase_order_terms.sql
# 术语统一：ERP 主数据「产品」→「物料」
psql -U root -d yate -f sql/local/64_rename_product_to_material.sql
# 采购价目表（头+明细）+ 顺带补齐物料主数据的业务编码
psql -U root -d yate -f sql/local/65_purchase_price.sql
# 隐患收尾：编码前缀冲突 / WMS 菜单术语 / 组织节点名不副实
psql -U root -d yate -f sql/local/66_cleanup_loose_ends.sql
# 采购价目表吸纳金蝶常用字段（含税口径 + 定价员）
psql -U root -d yate -f sql/local/67_purchase_price_kingdee_fields.sql
# ⚠️ 54 会备份后**删除 4 个列**（不可逆）。必须等 53 执行完、且后端已切换到
#    member_user_store 读取之后再执行；确认前保持注释：
# psql -U root -d yate -f sql/local/54_drop_legacy_store_columns.sql
```

> 全新环境按**文件名编号升序**执行一遍即可(当前到 `56`,其中 `54` 需人工确认后再执行);字典覆盖可用
> `python script/tools/check-dict-coverage.py` 复核(应输出「缺失 0 个 / 无数据行 0 个」)。

> 本地库名:切换前为 `juling`,现在 `application-local.yaml` 指向 `yate`(由 `juling` 复制而来);
> 上面命令里的 `-d juling` 是按旧库名写的,按实际库名替换即可。
> 管理员密码已改为自定义强密码,不入库;重置用下方「维护脚本」里的 `admin_password_reset.sql` 模板。

所有脚本均为**幂等**、重复执行安全:数据类靠 `ON CONFLICT (id) DO NOTHING`,结构/回填类靠
`WHERE ... IS NULL` 与 `SET DEFAULT` 的天然幂等。

## 维护脚本(非补丁,按需执行)

| 脚本 | 用途 |
|---|---|
| `admin_password_reset.sql` | 重置 `admin` 密码的**模板**:仓库内只有占位符 `<BCRYPT_HASH>`,真实口令与哈希不入库 |
| `cleanup_smoke_account_set.sql` | 清理联调/冒烟测试产生的临时账套及其全部关联数据(覆盖 27 张带 `account_set_id` 的表) |

## 各脚本内容

| 脚本 | 内容 | id 段 |
|---|---|---|
| 01_menu_fms_wms.sql | FMS 财务 / WMS 仓储 菜单子树 202 条 + 字典 21 类 89 条 | 菜单 6200+、字典 9000/90000+ |
| 02_menu_hrm_im_pms_crm.sql | HRM / IM / PMS 菜单子树 259 条 + CRM 缺失 7 条 | 菜单 8300+ |
| 03_dict_missing.sql | 缺失字典 81 类 / 348 条数据(hrm_*、im_*、pms_*、bpm_comment_type 等) | 字典 9500+、95000+ |
| 04_jobs_missing.sql | 缺失定时任务 4 个(hrm 3 + pms 1) | 沿用基线 id |
| 05_patch_iot_ota_permission.sql | IoT「OTA 任务进度查询」按钮权限 `iot:ota-task:query` | 12000 |
| 06_clean_demo_users_tenants.sql | 清理演示账号(保留 admin)与演示租户(小租户/测试租户)及其角色、部门、菜单关联 | — |
| 07_clean_demo_configs.sql | 清理演示文件存储(仅保留“本地存储”并设为 master,basePath 指向本项目)、演示邮箱/社交登录/短信渠道 | — |
| 08_fms_subject_template.sql | FMS 标准科目模板 79 条(**重构版**,非种子数据导出) | 科目模板 id 1001+ |
| 09_dict_baseline_gaps.sql | 代码引用但基线脚本缺失的字典 4 类(hrm_employee_id_type、mes_auto_code_*) | 字典 11100+、111000+ |
| 10_rename_legacy_identifiers.sql | T2 改名同步:`infra_file_config.config` 的 `@class` 全类名、OAuth2 logo、租户域名、用户头像、历史错误日志的类名/路径 | — |
| 11_dict_fresh_install_gaps.sql | 线上库有、基线+本目录没有的字典 3 类(`system_menu_type`、`system_data_scope`、`mes_wm_issue_status`) | 字典 11200+、112000+ |
| 12_fix_erp_null_counters.sql | 回填 ERP 单据「数量/金额」计数器(`in_count`/`out_count`/`return_count`/`receipt_price`/`payment_price`/`refund_price`)的历史 NULL 为 0,并补 `DEFAULT 0`;修复前快照存入 schema `bak_erp_null_counters` | — |
| 13_pay_app_seed.sql | 补齐 `pay_app` 支付应用(`mall` 商城应用 / `wallet` 钱包应用)。交易订单创建后置逻辑在 `payPrice > 0` 时无条件建支付单,`TradeOrderProperties.payAppKey` 默认 `mall`,库里没有该 `app_key` 时下单直接抛 `APP_NOT_FOUND`(1007000000「App 不存在」) | 用表序列/默认值 |
| 21_trade_amount_defaults.sql | 订单/清单项金额列兜底：给 `trade_order_item.adjust_price` 补默认值 0 并回填历史 NULL（NULL 会让首次调价、售后等路径直接 NPE，对外表现为「系统异常」），同时回填 `trade_order` 的 `adjust_price`/`refund_price`/`refund_point`。幂等 | — |
| 20_remove_brokerage_withdraw.sql | 佣金提现下线：删除提现菜单与 `trade:brokerage-withdraw:*` 权限、删提现状态字典（保留 `brokerage_withdraw_type`，交易配置仍在用）、`trade_brokerage_withdraw` 表重命名为 `zz_deprecated_trade_brokerage_withdraw` 归档。幂等 | — |
| 22_remove_brokerage.sql | 商品分销整体下线（物理清除）：删除分销菜单 11 条与角色关联、分销字典 6 类 23 条、分销定时任务；`DROP TABLE` 三张分销表、`DROP COLUMN` 14 个分销列。幂等 | — |
| 23_remove_pick_up.sql | 门店自提下线（物理清除）：删除自提菜单 9 条与角色关联、`trade_delivery_type` 的「用户自提」字典数据；`DROP TABLE trade_delivery_pick_up_store`；删列 `trade_config.delivery_pick_up_enabled`、`trade_order.pick_up_store_id`/`pick_up_verify_code`、`product_spu.delivery_types`。幂等 | — |
| 24_fix_system_dept_sequence.sql | 修复 `system_dept_seq` 落后于数据（新增部门报 `duplicate key ... pk_system_dept`）：把序列推进到 `max(id)+1`。附全库序列排查脚本（比对 `pg_sequences.last_value` 与各表 `max(id)`） | — |
| 25_trade_config_default.sql | 交易配置（`trade_config`）初始化：表里没有未删除的配置行时插入一行默认值（包邮开关/满额包邮金额、售后理由清单）。幂等 | — |
| 42_move_order_account_to_mall.sql | **把「订货账号」归位到「商城系统」下**：订货账号是门店/代理人的订货身份（谁能下单、以哪家门店下单、订单归属哪家店），与「订单中心 / 订单工作台 / 门店收货单」同属一条订货链，使用者是总部运营而不是 IT，因此把 41 临时给的顶层入口改挂到「商城系统」(2362) 下（path 相对段 `order-account`，sort 62，紧邻订单中心）；并给「已授订货账号但没授商城系统」的角色补商城系统及其祖先链（yudao 会剔除父菜单未授权的节点）。幂等 | 菜单 12140 |
| 41_fix_order_account_menu.sql | **修 40 脚本留下的菜单孤儿**：40 删掉了顶层「会员中心」(2262)，但保留了它的子菜单「会员管理」(2317)，导致 2317 的父菜单不存在、**侧边栏里看不到「订货账号」**。本脚本补一个顶层目录「订货账号」(12140) 把它挂回去并改名「订货账号列表」，授给已有 2317 的角色并补祖先链；同时清掉 2317 下两个指向已下线能力的按钮权限 2335 `member:user:update-level` / 2363 `member:user:update-point`。幂等 | 菜单 12140 |
| 51_order_account_actions.sql | **订货账号列表补「删除」「停用/启用」按钮权限**：后端新增 DELETE /member/user/delete（已有订单的账号拒绝删除，错误码 1_004_001_009 引导改用停用）与 PUT /member/user/update-status（停用后无法登录，历史订单与台账仍可追溯）；脚本在「订货账号列表」(2317) 下补按钮权限 12160 `member:user:delete` / 12161 `member:user:update-status`，授给已拥有该列表的角色（供应链 157）并推进菜单序列。幂等 | 菜单 12160/12161 |
| 50_clean_test_erp_and_bpm_data.sql | **清理测试订货单在 ERP / BPM / 单据平台的关联数据**（与 49 配套）：先整表备份到 schema `bak_test_erp_20260929`，再按待删流水的净影响**回补中心库**（erp_stock + OPENING 批次），然后删门店仓库存与批次、11 条库存流水、2 张配送出库单(+3 行)、单据平台的下推血缘(bill_relation 3 条)与操作日志(bill_log 2 条)、Flowable 22 个实例历史（保留流程定义与模型）。**不动**采购单据与中心库期初批次、主数据。幂等 | schema `bak_test_erp_20260929` |
| 49_clean_test_order_data.sql | **清理门店订货链的测试订单历史数据**：先把 order/item/proof/receipt/receipt_item/log + 门店往来台账 + 门店收货批次整表备份到 schema `bak_test_orders_20260929`，再按外键顺序删除（8 单 / 27 行 / 5 凭证 / 3 收货单 / 4 收货行 / 53 日志 / 7 往来 / 3 批次）；**不动** ERP 期初与中心库批次、BPM/Flowable 审批历史、门店与会员主数据。幂等 | schema `bak_test_orders_20260929` |
| 48_order_flow_drop_payment_verify.sql | **门店订货链去掉「收款核验」**：门店在 H5 提交付款凭证后直接按申报金额置「已收款、待发货」，加盟门店随即自动提交 BPM 两级审批（供应链 → 财务出纳），核收款职责由财务审批节点承接。脚本停用「订单收款核验」按钮权限（菜单 11320 / `trade:order:payment-proof:audit`）及其授权、停用字典 `trade_payment_proof_status` 的「待核验」(113001)、给「订单提交审核」(11530 / `trade:order:audit:submit`) 补授权给财务+供应链（此前 0 授权只有超管能用）、并把唯一一张卡在「待核验」的历史测试单（订单 63 + 凭证 46）按新流程归一。幂等 | 菜单 11320 |
| 47_fix_stale_menus.sql | **清死菜单 + 消除重名**：全量核对「页面菜单 component ↔ 前端 views 文件」后，删掉唯一一条指向已删页面的菜单 2525（基础设施 → WebSocket，component=infra/webSocket/index，演示页已随 websocket 演示移除，授权 0 条）；并把 WMS 侧 3 条与商城/ERP 重名的菜单改名（6510 库存管理→库存台账、6340 商品分类→物料分类、6270 商品品牌→物料品牌），消除前端 `menu name duplicate` 的 console.error。幂等 | 菜单 2525 |
| 46_member_statistics_permission.sql | **补「会员统计」查询权限**：40 脚本删「会员中心/会员统计」页面时把 `statistics:member:query` 权限也删了，而「商城首页」的会员统计卡片仍在调 `/admin-api/statistics/member/*`（后端已随本次修复恢复），除超管外都会 403。补一条隐藏按钮权限（菜单 12150「会员统计查询」，挂统计中心 2358，不恢复独立页面），授给已有 `statistics:trade:query` 的角色（当前为「供应链」157），并把落后的 `system_menu_seq`（12000 < max(id) 12140）推进到 max(id)+1。幂等 | 菜单 12150 |
| 44_cleanup_archived_pay_and_dead_role.sql | **清理全局遗留（一）**：支付/钱包下线时重命名归档的 14 张 `zz_deprecated_pay_*` 表（代码零引用，仅 wallet 剩 21 行历史余额）先整表备份到 `bak_pay_archive_20260929` 再 DROP；顺手删掉 0 用户的种子角色「CRM 管理员」（它给 MES 等模块的授权是死授权）。幂等 | — |
| 45_remove_unused_modules.sql | **物理删除 7 个用不到的 yudao 模块**（MES 133 表/61 页、PMS 33/13、CRM 21/23、HRM 50/36、IM 17/14、IoT 15/11、公众号 8/11）：依据是按菜单授权递归统计——除超管外全库只有「供应链」(3 人) 与「财务」(1 人) 两个真实角色，这 7 个模块的菜单没有授权给任何真实角色（MES 只授给了 0 用户的种子角色）。**277 张表先整表备份到 `bak_unused_modules_20260929` 再 DROP**（实测这 7 个模块的数据量：crm/im/mes/mp 各 0 行、hrm 1、iot 2、pms 4；保留模块指向它们的外键 0 条）；删 7 棵菜单子树共 859 条菜单与 44 条角色授权、字典 188 类型 / 899 数据、6 个定时任务（含 IoT/HRM/PMS 模块任务）。保留 ERP/商城/FMS(财务，替代金蝶)/WMS/AI(deepseek)/BPM/系统/基础设施/单据平台。幂等 | 菜单 5100 等 7 棵 |
| 43_remove_promotion_and_comment.sql | **物理删除 C 端营销体系与商品评价**：24 张营销/评价表（秒杀/拼团/砍价/满减/限时折扣/优惠券/积分商城/装修/文章/Banner/客服 + product_comment）先备份到 `bak_promotion_20260929` 再 DROP；删 `trade_order`(17 列)与 `trade_order_item`(6 列)上的营销/评价字段（实测这 6 张订单里这些值全为 0/NULL）；删「营销中心」(2030)/「客服中心」(2797)/「商品评论」(2336) 三棵菜单子树与角色授权；删 `promotion_*` 字典与 2 个定时任务（拼团过期/优惠券过期）。幂等 | 菜单 2030 子树 |
| 40_remove_member_center.sql | **物理删除「会员中心」，只留「订货账号」**：先整表备份 11 张会员中心表到 schema `bak_member_center_20260929`，再 DROP（`member_user` 保留）；删「会员中心」菜单子树（2262）与「会员统计」（2374）共 34 条 + 对应角色授权，**保留**会员管理 2317 子树并把 2317/2318/2319 改名为「订货账号」；删 `member_*` 字典 15 条数据 + 2 个类型；`member_user` 摘掉只服务于会员中心的 5 列（`level_id`/`experience`/`point`/`group_id`/`tag_ids`）。幂等 | 菜单沿用 2317 |
| 39_member_username_login.sql | **订货账号（会员登录名）**：`member_user` 加 `username`（订货账号，独立列，不复用 mobile）+ 部分唯一索引；按「绑了门店的用门店名（去掉『（门店）』后缀）、其余用手机号」回填历史账号；配套登录改造（账号优先、手机号兜底）与后台「开订货账号」「重置密码」两个按钮权限 `member:user:create` / `member:user:reset-password`（菜单 12130/12131，挂在会员管理 2317 下并授给已有该父菜单的角色）。幂等 | 菜单 12130+ |
| 38_store_receipt_and_receivables.sql | **门店收货 + 多收/少收差异 + 门店库存账 + 门店往来台账**：`erp_warehouse` 加 `warehouse_type`/`store_customer_id`/`dept_id` 并按门店客户生成「一店一仓」（13 个门店仓，历史空的「门店虚拟仓-双碑店」软删）；`erp_sale_out_items` 加 `source_item_id`（要货单行→出库单行的行级血缘）；新表 `trade_order_receipt`/`trade_order_receipt_item`（应收/实收/差异/批次效期/图片）；新表 `erp_customer_account`（门店往来：正数=门店欠总部，含余额快照与 (biz_type,source_type,source_id) 幂等唯一键）；`trade_order` 加 `receipt_status`、`trade_order_item` 加 `delivered_count`/`receipt_count`；菜单 12100「门店收货单」/12110「门店库存」/12120「门店往来」+ 对应按钮权限并授给已有同级菜单的角色。幂等 | 菜单 12100+ |
| 37_stock_batch_menu.sql | 批次库存页面配套菜单与权限：菜单 11570「批次库存」(erp/stock/batch/index) + 按钮 11571 `erp:stock:batch:query` / 11572 `erp:stock:batch:update` / 11573 `erp:stock:update`（后者原先**没有菜单行**，导致非超管点"状态登记"必 403，因为 yudao 权限集来自角色-菜单映射）；并按递归 CTE 把新菜单**与全部祖先菜单**授给 156 财务 / 157 供应链 | 菜单 11570+ |
| 36_batch_wiring.sql | 采购入库项加批次字段（`batch_no`/`production_date`/`expiry_date`），使采购入库审核能按批次入账（FIFO 才有批次可扣）；仅加列、幂等，附双表一致性核对 SQL | 仅加列 |
| 35_stock_center.sql | **S2 库存中心切片一**：新表 `erp_stock_batch`（仓库×物料×批次，数量**分列**表达四态 在仓/在途/占用/待检，含 unit_cost/total_cost、效期、in_date 作 FIFO 主键、来源与 source_reversed、主键+唯一索引+序列）；`erp_stock_in_item` 加批次/生产日期/效期列，`erp_stock_record` 加 batch_no/stock_state/unit_cost/total_cost/sku_id；把 `erp_stock` 既有余额回填为 OPENING 期初批次（与老表一致）。与 `erp_stock` **双写（增量）**，老表语义不变 | 序列 erp_stock_batch_seq |
| 34_role_menu_ancestors.sql | 递归补全角色的**祖先菜单**授权：yudao 会剔除"父菜单未授权"的节点（MenuServiceImpl.isMenuDisabled），只授深层权限会导致该权限不出现在 /system/auth/get-permission-info — 前端拿不到权限、菜单无入口，但后端 @PreAuthorize 仍能通过（"接口能调、界面看不到"）。当前默认对 156 财务 / 157 供应链 生效 | 沿用角色菜单 id |
| 32_bpm_approver_permissions.sql | 门店要货两级审批（供应链 → 财务出纳）配套授权：给「供应链(157)」「财务(156)」角色授 BPM 菜单与按钮权限（含 `bpm:task:query`/`bpm:task:update`）。此前这两个角色**没有任何 bpm 权限**，任务虽分派到人、成员一审批即 403。脚本幂等；直接执行后需重启或走一次 `/system/permission/assign-role-menu` 刷新权限缓存 | 沿用角色菜单 id |
| 31_bill_platform_fix.sql | 单据基座修复：流水位数与旧生成器对齐（统一 6 位）；ERP 已有单据的前缀与旧口径对齐（XSCK/QCDB/QCPD/QCKD/FKD/SKD）并补注册销售订单(XSDD)/销售退货(XSTH)；**按当天已有单号回填 `bill_no_seq` 流水起点**（防切换日"单号已存在"，GREATEST 幂等）；注册权限 `bill:platform:query` | 菜单 11540、类型 27/28 |
| 30_bill_platform.sql | **单据基座**：新建 5 张平台表（`bill_type` 类型注册 / `bill_no_seq` 单号流水 / `bill_relation` 单据关联防重复下推 / `bill_log` 操作日志 / `bill_ext` 扩展字段）+ 5 个序列，并注册 26 类单据（与金蝶蓝图流程一一对应，含编号规则、是否审批、是否影响库存/核算）。含主键幂等兜底 | 类型 id 1–26 |
| 33_workbench_alloc.sql | **门店订货链 S2 切片一（订单工作台 + 分料）**：`erp_product` 加 `allow_central`/`allow_direct`（物料是否允许统配/直拨），`trade_order_item` 加 `alloc_mode`（CENTRAL 统配 / DIRECT 直拨，空=未分料）与 `alloc_count`，`trade_order` 加 `store_type` 快照（工作台判定"直营免审"）；回填 demo 物料分料属性（一次性用品只统配、鲜货只直拨，其余都允许）；字典 `trade_order_item_alloc_mode`；菜单「订单工作台」+ `trade:workbench:query`/`trade:workbench:push` 并授权供应链/财务角色。幂等 | 字典 11560、菜单 11550+ |
| 29_seed_demo_data.sql | **P0 模拟测试数据**（全带 `demo-seed` 标记、可重复执行）：组织树对齐组织架构图（恢复根节点「重庆亚特餐饮发展有限公司」并把萍姐/直营门店/中心库/卤校长四支挂上去）；主数据 20 个餐饮食材商品（含规格/保质期/进价/售价/最低价）、6 单位、5 分类、3 家供应商；13 家门店客户（8 直营 / 5 加盟）+ 1 个代理客户（名下 3 家门店）；4 个订货账号（手机号 190000001xx）；中心库 + 门店虚拟仓与期初库存；10 个商城 SPU/SKU 使 H5 可下单 | 用表内 max(id)+n |
| 27_merge_tenant123_into_yate.sql | 合并历史租户「亚特餐饮(123)」到「亚特(1)」：47 个真实部门（萍姐/卤校长/直营门店/中心库及下属公司、职能部门、13 家门店）与贺玲/张新宇账号（含亚特的「供应链」角色）、2 个供应链岗位转为亚特数据；清除 123 的角色/菜单绑定/账号/日志/重复分类品牌、tenant_id=0 的全局残留、租户本体与套餐。受影响行先备份到 schema `bak_tenant123_20260928`。幂等 | 用现有 id |
| 28_fix_all_sequences.sql | 全库序列体检与修复：补丁脚本用"显式 id 插入"不推进序列，会让之后的界面新增报 `duplicate key ... pk_xxx`（「新增部门」踩过）。脚本遍历所有 `表名_seq`，把落后于 `max(id)` 的推进到位并打印明细。幂等 | — |
| 26_store_order_org_audit.sql | 门店订货链 S1（一店三面 + 订单归属 + 供应链审核）：`erp_customer` 加 所属部门/上级代理/店型/结算模式/账期/信用额度，`member_user` 加 所属部门/所属客户，`trade_order` 加 部门/客户/代理快照 + 结算模式 + 审核状态(0/10/20/30) + BPM 实例号；字典 `trade_settlement_mode`/`erp_store_type`/`trade_order_audit_status`；按钮权限 `trade:order:audit:submit`；存量订单回填为"已通过"以免新审核闸门卡住历史数据。幂等 | 字典 11500+、菜单 11530 |
| 19_trade_after_sale_offline_refund.sql | 售后线下退款：`trade_after_sale` 增加 `refund_channel_code`/`refund_proof_urls`/`refund_remark`，配合后台「确认线下退款」登记（原 `pay_refund_id` 保留但不再写入）。幂等 | — |
| 18_remove_pay_module.sql | 支付模块下线（本分支只走线下转账）：清理「支付管理」菜单树与 `pay:*` 权限、删除支付类字典（**保留 `pay_channel_code`**，线下收款渠道仍在用）与 5 个支付定时任务；14 张 `pay_*` 表**重命名**为 `zz_deprecated_pay_*` 归档（可回滚，确认无误后按脚本注释执行 DROP）。幂等 | — |
| 16_trade_payment_proof.sql | 线下收款改造：新表 `trade_order_payment_proof`（一次上传一行，支持多图/多次上传/驳回重传/金额核定）、`trade_order` 增加 `paid_amount`\+`payment_proof_status`、字典 `trade_payment_proof_status`、`pay_channel_code` 增加 4 个线下渠道、按钮权限 `trade:order:payment-proof:audit` | — |
| 15_add_missing_primary_keys.sql | 给「缺主键 + 有 id 列 + id 无 NULL 且唯一」的表补 `PRIMARY KEY (id)`。yate 库 552 张表里曾有 453 张没有主键(转换时丢失,id 数据本身干净),导致 PostgreSQL 无法做主键函数依赖推断,关联查询 + `GROUP BY` 主键时报 `column "t.xxx" must appear in the GROUP BY clause`(MySQL 宽松模式不报)。脚本幂等,id 有 NULL/重复的表会跳过并打印 NOTICE | — |
| 67_purchase_price_kingdee_fields.sql | **采购价目表吸纳金蝶常用字段**：\`erp_purchase_price\` 加 \`price_includes_tax\`（报价口径，只影响录入方向，行上的单价恒为不含税）与 \`pricer_user_id\`（定价员，与 creator 区分 —— 常见是采购经理定价、文员录入）。**刻意不吸纳 5 项**并写明理由（币别无汇率支撑、采购组织依赖未定的多组织模型、单据状态一期不做审批流、价格类型冗余、价目表对象一期只支持按物料）。幂等 | — |
| 66_cleanup_loose_ends.sql | **隐患收尾（三处尾巴）**：① `product_spu`（商城商品）与 `erp_product`（ERP 物料）都用 `WL` 前缀，两套目录合并后编码肉眼无法区分 → 商城侧改 `SP`；② WMS 基础数据下 6270 物料品牌 / 6340 物料分类 已叫「物料」，中间的 6390 却叫「商品管理」→ 改「物料管理」；③ 组织节点 120「直营门店」下面曾挂过 6 家加盟店（店型权威已移到 `erp_customer.store_type`），名字宣称了错误的店型 → 改「门店」（当前 0 子节点）。备份到 `bak_cleanup_loose_ends_20261007`。幂等 | 菜单 6390、节点 120、schema `bak_cleanup_loose_ends_20261007` |
| 65_purchase_price.sql | **采购价目表**（头 + 明细）。此前 \`erp_product.purchase_price\` 是「一个物料一个采购价」，表达不了「不同供应商不同价 / 调价 / 量大价优」；而**采购单价直接决定存货成本**（订单价 → 入库 unit_cost → 批次成本 → 出库成本），填错的价会一路进到成本且无据可查。建 \`erp_purchase_price\` + \`erp_purchase_price_item\`、编码规则 \`CJJM\`、菜单 12200（基础资料 → 公共资料）+ 按钮 12201-12205。**顺带补齐物料主数据的业务编码**（\`erp_product.code\` + 规则 \`WL\`，之前 6 个主数据都有、唯独物料漏了）。设计见 [docs/purchase-price-design.md](../../docs/purchase-price-design.md)。幂等 | 菜单 12200+、表 \`erp_purchase_price*\` |
| 64_rename_product_to_material.sql | **术语统一：ERP 主数据「产品」→「物料」**。金蝶把这类主数据叫「物料」，而本系统**下游订货链与库存页面早已在用「物料」**（`ERP 物料编号` / `请选择物料` / `物料数`），只有主数据页还叫「产品」，术语分裂。本脚本把 10 条菜单改名（物料管理/物料信息/物料查询/物料创建/物料更新/物料删除/物料导出/物料分类/物料单位/物料库存），备份到 `bak_rename_product_to_material_20261007`。**只改显示名，不动 permission 标识**（`erp:product:*` 改了会让存量角色授权失效）；类名/表名/路由同样是 ASCII 未动。顺带把 ERP「物料」与商城「商品」在中文上区分开。幂等 | 菜单 2564/2565/2566-2570/2571/2577/2590 |
| 63_purchase_order_terms.sql | **采购订单记住「结算方式」与「交期」**：`erp_purchase_order` 加 `settlement_type` / `delivery_days` 两列。下单时从供应商带出默认值、**允许按单覆盖**；落库而非每次实时查档案，是为了保留**当时的约定**（供应商条件会变，历史订单不该跟着变）。配套：后端建单/改单时用供应商兜底（订单两字段 + 订单行税率，行未填税率时用供应商开票税点 —— 实测 `erp_product` 无税率列，供应商是唯一来源）；前端选供应商时自动带出三处、明细表新增行默认带出税点。幂等 | — |
| 62_supplier_profile.sql | **供应商档案扩展**（采购部门需求）：`erp_supplier` 新增 12 列 —— 账户户名、注册地址、结账方式、账期天数、开票情况、开票比例、开票类型、交期天数、是否签订合同、签订主体、营业执照、生产许可证；新增字典 `erp_supplier_settlement_type`（月结/半月结/次结-先款后货/次结-先货后款）、`erp_supplier_invoice_mode`（全额/按比例/需加税点/不开）、`erp_supplier_invoice_type`（普票/专票）。**复用现有列不重复造**：名称→`name`、税号→`tax_no`、账号→`bank_account`、开户行→`bank_name`、开票税点→`tax_percent`（0=免税）。设计见 [docs/supplier-master-data-design.md](../../docs/supplier-master-data-design.md)。幂等 | 字典 11580-11582 |
| 61_remove_infra_devtools.sql | **下线「表单构建」「API 接口」「数据源配置」**（承接 60，同为用不到的开发期工具）。删菜单 114 / 116 / 1255 与按钮 1256-1260（含任何挂在其下的未知子菜单）；删表 `infra_data_source_config`（0 行）+ 序列。菜单与授权备份到 `bak_infra_devtools_20261007`。连带删除已成孤儿的 `DatabaseTableService`（唯一消费者是被 60 删掉的 CodegenService）；`DataSourceConfigService` 经核查无框架层引用（运行时动态数据源走 `application.yaml`）故一并删。**保留** `components/form-create`（BPM 流程表单共用，18 个文件引用）。幂等 | 菜单 114/116/1255、schema `bak_infra_devtools_20261007` |
| 60_remove_monitor_and_codegen.sql | **下线「监控中心」与「代码生成」**（用户明确要求，功能用不到）。删菜单 13 条 —— 监控中心(2740)子树 7 条（2740/111 MySQL监控/112 Java监控/113 Redis监控/1077 链路追踪/1066/1067）+ 代码生成(115)及其 5 个按钮（1056-1060）；删对应角色授权；删表 `infra_codegen_table` / `infra_codegen_column`（实测均 0 行）与两个序列。菜单与授权备份到 `bak_infra_codegen_monitor_20261007`。**不动** 114 表单构建 / 116 API 接口（基础设施直属，不在范围）。两张表由基线创建，本脚本在重建后再次删除 —— 与 45 号脚本同模式。幂等 | 菜单 2740/115 子树、schema `bak_infra_codegen_monitor_20261007` |
| 59_drop_backup_schemas.sql | **删除历史备份 schema**（10 个 / 398 张表：`bak_cleanup_20260929`、`bak_erp_ctr(_2)_20260922`、`bak_member_center_20260929`、`bak_pay_archive_20260929`、`bak_promotion_20260929`、`bak_tenant123_20260928`、`bak_test_erp_20260929`、`bak_test_orders_20260929`、`bak_unused_modules_20260929`）。它们装的是**已经删过的**历史数据（下线模块 MES/PMS/CRM/HRM/IM/IoT、支付归档、营销评价、会员中心、测试订单/ERP），实测合计仅约 391 行、其余是空表壳。⚠️ **不可回退**。保留 `bak_testdata_20261007` 作为 58 的回退路径。幂等 | schema `bak_*` |
| 58_clean_all_test_data.sql | **全库测试数据物理清理**：先整表备份到 `bak_testdata_20261007`（71 张表 / 约 4706 行）**再删除** —— 因此本次删除**可回退**。清理 A 测试业务数据 49 张表（库存/批次/流水、采购销售单据、收付款、门店往来台账、购物车/浏览/收藏/统计、售后日志、记账凭证、单据流水号）+ B 演示主数据 12 张表（客户 15 行全部 `remark='demo-seed'`、物料 22、商品 26、分类、供应商、会员账号与授权）+ C 运行时数据 7 张表（登录令牌 3607、登录日志、操作日志、API 错误日志、上传文件记录）+ system_dept 的 13 个门店节点 + erp_warehouse 的 13 门店仓与 1 门店虚拟仓。**不动**菜单/字典/角色/真实用户/单位/单据类型/会计科目/结转方案/AI 配置/真实流程定义/act_* 引擎表。幂等 | schema `bak_testdata_20261007` |
| 57_code_rule_menu.sql | **编码规则菜单**：在「基础资料」(12180) 下补菜单 12190「编码规则」(component `system/code-rule/index`) + 按钮权限 12191-12194（`system:code-rule:query/create/update/delete`），并授给已拥有「基础资料」的 3 个角色（普通角色/财务/供应链）。补这个菜单是因为 56 建了规则表却没有维护入口 —— 管理员看不到前缀/流水，也没法为新主数据加规则。幂等 | 菜单 12190+ |
| 56_code_rule.sql | **统一编码第一步**：新建 `system_code_rule`（编码规则：前缀 + 流水长度 + 当前值，对齐金蝶的「编码规则」）；`erp_customer`/`erp_supplier`/`erp_warehouse`/`erp_product_unit`/`product_spu`/`system_dept` 加 `code` 并按 id 升序回填（存量 0 条为空）；`(tenant_id, code)` 部分唯一索引；规则当前值对齐各表已用流水最大值。生成服务与界面接入见提交 `2a7385d5`。幂等 | 表 system_code_rule |
| 55_master_data_menu.sql | **基础资料菜单归口**：新建一级目录「基础资料」(12180) + 「主数据」(12181) / 「公共资料」(12182)，把散在「系统管理 / ERP 销售·采购·库存·财务 / 商城系统」的 9 个主数据菜单迁入，并把新祖先链授给原本就有被迁菜单的角色（yudao 会剔除父菜单未授权的节点）。**只改菜单，不动表结构与 API 路径**。幂等 | 菜单 12180+ |
| 54_drop_legacy_store_columns.sql | ⚠️ **不可逆，执行前须确认**：先把旧值备份到 schema `bak_ordering_account_20261007`，再软删「代理客户」（有下级客户的客户档案），建 `uk_erp_customer_dept_id`（门店节点 ↔ 客户档案一对一），最后删除 `member_user.dept_id`/`customer_id`、`trade_order.agent_customer_id`、`erp_customer.parent_customer_id`。**必须等 53 执行完且后端已切换到授权表读取之后再跑** | schema `bak_ordering_account_20261007` |
| 53_member_user_store.sql | **订货账号「授权门店」**：新表 `member_user_store`（账号 → 多门店 + 默认门店；唯一索引保证「一账号一门店一条」「一账号一个默认门店」），从客户树回填——主体客户有下级则授权其全部下级（**代理自身排除**），否则授权自身；再补 29 号脚本播种账号的演示授权（29 先于本脚本执行，故授权写在这里）。幂等 | 序列 `member_user_store_seq` |
| 52_organization_architecture.sql | **组织架构**：`system_dept` 加 `dept_type`(ORG 组织 / STORE 门店) + `business_status`/`closed_time`/`closed_reason`（开店闭店）；按客户档案回填门店节点（实测命中 13 个：134-146）；字典 `system_dept_type`/`system_dept_business_status`；菜单「部门管理」(103) 改名「组织架构管理」+ 按钮权限 `system:dept:update-business-status`。**店型刻意不落本表**，以 `erp_customer.store_type` 为唯一权威。幂等 | 字典 11570+、菜单 12170 |

> `12_fix_erp_null_counters.sql` 作用的对象是 ERP 业务表(`erp_*`)。这些表**不在基线脚本中**
> (由 ERP 模块单独建表),所以全新环境若尚未导入 `erp_*` 表,该脚本会自动跳过缺失的表/列并打印
> NOTICE、不会报错;等 ERP 表就绪后重新执行一次即可。脚本为幂等,重复执行安全。

> `13_pay_app_seed.sql` 作用的对象是 pay 模块的业务表(`pay_app`),这类表**不在基线脚本中**
> (基线完全不含 `pay_*`),所以表不存在时脚本打印 NOTICE 后跳过、不报错。它只解决「下单能建单」;
> 要进一步发起在线支付,还需在该应用下配置支付渠道(`pay_channel`),或在后台「支付管理」里维护。

> `08_fms_subject_template.sql` 与上面的菜单/字典补丁不同,它是**业务种子数据**:FMS「账套初始化」从
> `fms_subject_template` 生成账套科目,该表为空时初始化必然失败(先静默不建科目,随后结账模板预置
> 因缺科目 560107 报错并回滚)。数据按《小企业会计准则(2013)》+ 默认编码规则 4-2-2-2 重构,覆盖
> 结账模板/方案预置引用的全部科目编码;拿到完整种子数据后可 `TRUNCATE fms_subject_template` 后改用官方版本。

> 另:`mes_wm_issue_status` 由 `11_dict_fresh_install_gaps.sql` 补齐后又随 MES 模块在 `45` 中删除,
> 该字典现已不存在(下方注释仅存档)。字典 `system_data_scope`、`system_menu_type` 基线脚本只有数据行、没有
> 类型行(字典管理界面看不到、`check-dict-coverage` 会判缺失),已由 `11_dict_fresh_install_gaps.sql`
> 补齐类型行(id 11200+/11210+/11220+,数据行 112000+)。线上库早前是手工补的,类型 id 用的
> 11000/11010/11020,与脚本里的 id 不同但语义一致(脚本按 `ON CONFLICT (id) DO NOTHING` 幂等执行)。

## 未补齐(有意)

基线脚本包含但本项目不需要的模块,未导入:

- **cms**(内容管理):菜单 43 页 + 187 按钮、字典 5 类、定时任务 5 个 —— 后端无 `juling-module-cms`,前端无 `views/cms`;
- **oa**(办公):菜单 6 页 + 20 按钮 —— 同样无模块/页面;
- **report**(报表):菜单 3 页 + 6 按钮 —— 报表模块已在 `pom.xml` 中移除。

另有 7 个模块**曾导入、现已物理下线**:MES(质检/生产)、HRM(人事)、IoT(物联网)、PMS(项目)、IM(即时通讯)、
CRM(客户)、MP(公众号)。它们由 `01/02/04/05` 等脚本补入菜单与字典,与金蝶替代路线无关且全部 0–4 行数据,
已在 `45_remove_unused_modules.sql` 中连表(备份到 `bak_unused_modules_20260929`)、菜单、字典、定时任务一起删除;
后端 7 个 Maven 模块与前端 `views/{mes,hrm,iot,pms,im,crm,mp}` 页面同步移除。**新环境无需再执行 01/02/05 里与这 7 个模块相关的部分**
(脚本保留原样以便追溯,执行后由 `45` 统一收敛)。

> 另:官方脚本里的 5 张演示表 `juling_demo01_contact` / `juling_demo02_category` /
> `juling_demo03_course|grade|student` 与其序列已从基线脚本中删除,对应的演示模块代码
> (后端 `infra` 的 demo01/02/03 + websocket 演示、5 个前端 app 的 `views|api/infra/demo`、
> uniapp 的 `pages-infra/demo`)也已一并移除,不再占用接口与构建产物。

如后续要启用这些模块,需自行准备 MySQL 全量脚本(本仓库为聚焦 PostgreSQL 已移除未使用的方言脚本),再用 `tools/` 下的脚本提取。

## tools/(提取脚本)

以 **MySQL 全量脚本**为参照,生成上述补丁的脚本(纯 Python 3,无第三方依赖):

| 脚本 | 用途 |
|---|---|
| `extract_fms_wms_menu.py` | 提取 fms/wms 菜单子树 + 字典,并转换 PG 语法(id 重映射) |
| `extract_more_menus.py` | 提取 hrm/im/pms 菜单子树 + crm 缺失项(父节点按 path 映射) |
| `extract_missing_dicts.py` | 补齐缺失字典类型与数据(需先导出库侧 `db_dict_types.txt`、`db_dict_values.txt`) |
| `gen_missing_jobs.py` | 补齐缺失定时任务(infra_job) |
| `compare_sql_gap.py` | 全量对账:表 / 菜单 / 字典差异 |
| `list_seed_tables.py` | 列出脚本中带种子数据的表,并生成库侧计数 SQL |
| `probe_missing_menus.py` | 侦察某模块菜单缺失情况 |

导出库侧快照(供 compare / extract_missing_dicts 使用):

```sql
-- db_tables.txt
SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name;
-- db_menu_segments.txt
SELECT COALESCE(NULLIF(split_part(component,'/',1),''),'(none)'), COUNT(*) FROM system_menu WHERE deleted=0 GROUP BY 1;
-- db_dict_types.txt
SELECT type, (SELECT COUNT(*) FROM system_dict_data d WHERE d.dict_type=t.type AND d.deleted=0) FROM system_dict_type t WHERE deleted=0;
-- db_dict_values.txt
SELECT dict_type || '|' || value FROM system_dict_data WHERE deleted=0;
```
