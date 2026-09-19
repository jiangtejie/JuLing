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
```

> 全新环境按 `01 → 11` 顺序执行一遍即可;字典覆盖可用
> `python script/tools/check-dict-coverage.py` 复核(应输出「缺失 0 个 / 无数据行 0 个」)。

> 本地库名统一为 `juling`(见根 README 与 `application-local.yaml`)。
> 管理员密码已改为自定义强密码,不入库;重置用下方「维护脚本」里的 `admin_password_reset.sql` 模板。

所有脚本均为**幂等**(`ON CONFLICT (id) DO NOTHING`),重复执行安全。

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
