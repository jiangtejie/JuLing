# sql/local —— 本地补齐脚本(PostgreSQL)

基线 `sql/postgresql/juling-baseline.sql` 缺少部分业务模块的**菜单 / 字典 / 定时任务**数据,
本目录记录本项目补齐这些数据所用的脚本,便于新环境重建时复用。

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
```

> 全新环境按 `01 → 15` 顺序执行一遍即可;字典覆盖可用
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
| 19_trade_after_sale_offline_refund.sql | 售后线下退款：`trade_after_sale` 增加 `refund_channel_code`/`refund_proof_urls`/`refund_remark`，配合后台「确认线下退款」登记（原 `pay_refund_id` 保留但不再写入）。幂等 | — |
| 18_remove_pay_module.sql | 支付模块下线（本分支只走线下转账）：清理「支付管理」菜单树与 `pay:*` 权限、删除支付类字典（**保留 `pay_channel_code`**，线下收款渠道仍在用）与 5 个支付定时任务；14 张 `pay_*` 表**重命名**为 `zz_deprecated_pay_*` 归档（可回滚，确认无误后按脚本注释执行 DROP）。幂等 | — |
| 16_trade_payment_proof.sql | 线下收款改造：新表 `trade_order_payment_proof`（一次上传一行，支持多图/多次上传/驳回重传/金额核定）、`trade_order` 增加 `paid_amount`\+`payment_proof_status`、字典 `trade_payment_proof_status`、`pay_channel_code` 增加 4 个线下渠道、按钮权限 `trade:order:payment-proof:audit` | — |
| 15_add_missing_primary_keys.sql | 给「缺主键 + 有 id 列 + id 无 NULL 且唯一」的表补 `PRIMARY KEY (id)`。yate 库 552 张表里曾有 453 张没有主键(转换时丢失,id 数据本身干净),导致 PostgreSQL 无法做主键函数依赖推断,关联查询 + `GROUP BY` 主键时报 `column "t.xxx" must appear in the GROUP BY clause`(MySQL 宽松模式不报)。脚本幂等,id 有 NULL/重复的表会跳过并打印 NOTICE | — |

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

> 另:字典 `system_data_scope`、`system_menu_type`、`mes_wm_issue_status` 基线脚本只有数据行、没有
> 类型行(字典管理界面看不到、`check-dict-coverage` 会判缺失),已由 `11_dict_fresh_install_gaps.sql`
> 补齐类型行(id 11200+/11210+/11220+,数据行 112000+)。线上库早前是手工补的,类型 id 用的
> 11000/11010/11020,与脚本里的 id 不同但语义一致(脚本按 `ON CONFLICT (id) DO NOTHING` 幂等执行)。

## 未补齐(有意)

基线脚本包含但本项目不需要的模块,未导入:

- **cms**(内容管理):菜单 43 页 + 187 按钮、字典 5 类、定时任务 5 个 —— 后端无 `juling-module-cms`,前端无 `views/cms`;
- **oa**(办公):菜单 6 页 + 20 按钮 —— 同样无模块/页面;
- **report**(报表):菜单 3 页 + 6 按钮 —— 报表模块已在 `pom.xml` 中移除。

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
