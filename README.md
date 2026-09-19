# 棱信矩灵 管理系统

面向 **棱信矩灵** 自有业务的一体化管理平台：进销存、财务、生产制造、人力资源、项目与客户管理。

- 后端：Spring Boot 3.5 + JDK 17 + MyBatis-Plus + PostgreSQL 15 + Redis + Flowable + Quartz
- 前端：Vue3 + Vben5 + Ant Design Vue（`juling-ui/juling-ui-admin-vben`），生产环境经 Nginx 发布
- 移动端：uni-app（`juling-ui/juling-ui-admin-uniapp`、`juling-ui/juling-ui-mall-uniapp`）
- 数据库：PostgreSQL 15，库名 `juling`

## 目录结构

```
JuLing/
├─ juling-server/               启动模块(打包为可执行 jar)
├─ juling-framework/            框架层:web/security/mybatis/redis/mq/job/monitor…
├─ juling-module-system/        系统管理(用户/角色/菜单/部门/岗位/字典/租户…)
├─ juling-module-infra/         基础设施(代码生成/文件/定时任务/日志/配置…)
├─ juling-module-member/        会员中心
├─ juling-module-bpm/           工作流(Flowable)
├─ juling-module-pay/           支付
├─ juling-module-mp/            微信公众号
├─ juling-module-mall/          商城(商品/促销/交易/统计)
├─ juling-module-crm/           客户关系
├─ juling-module-erp/           进销存
├─ juling-module-iot/           物联网
├─ juling-module-mes/ wms/      生产制造 / 仓储
├─ juling-module-hrm/ fms/ pms/ 人力资源 / 财务 / 项目管理
├─ juling-module-im/            即时通讯(WebSocket 实时消息)
├─ juling-module-ai/            AI 能力(大模型/知识库/绘图…)
├─ sql/                        数据库脚本(见下)
├─ script/                     运维与迁移脚本(备份/自检工具/本地补丁)
├─ run/start-backend.ps1       后端启动脚本
└─ juling-ui/                   各前端源码(vben / admin-uniapp / mall-uniapp)
```

数据库脚本：

| 位置 | 说明 |
|---|---|
| `sql/postgresql/juling-baseline.sql` | PostgreSQL 基线（system + infra 表结构与初始数据） |
| `sql/postgresql/quartz.sql` | Quartz 调度表 |
| `sql/local/` | **本项目补齐脚本**：缺失的业务模块菜单/字典/定时任务（幂等，重建环境时按该目录 README 的顺序执行） |

## 快速启动

```powershell
# 1) 依赖服务
#    postgres: 127.0.0.1:5432  库 juling  用户/密码 root/123456
#    redis   : 127.0.0.1:6379  密码 123456

# 2) 后端（编译 + 启动）
mvn -T 1C install -DskipTests -B -ntp      # 约 10~60 秒
.\run\start-backend.ps1                    # 端口 48080，API 前缀 /admin-api

# 3) 前端开发模式（Vite 热更新，pnpm 版本见 package.json 的 packageManager）
cd .\juling-ui\juling-ui-admin-vben
pnpm dev:antd                              # http://127.0.0.1:5666

# 4) 前端生产发布（经 Nginx 子路径 /jl）
pnpm -F @vben/web-antd run build           # 产物 apps/web-antd/dist
# Nginx: location /jl/ → alias 到上面的 dist；/admin-api/ → 48080；/infra/ws → WebSocket
```

默认账号 `admin`（租户：棱信矩灵）。初始密码已由 `admin123` 改为自定义强密码，出于安全考虑
**不写入仓库**，仅存于本机文件 `script/local/admin-password.txt`（该目录已被 Git 排除）；
如需重置，使用模板 `sql/local/admin_password_reset.sql`（把 BCrypt 值写回 `system_users`）。

## 二开说明

- **PostgreSQL 适配**：统计类 Mapper 的 SQL 已由 MySQL 方言改写为 PG 原生
  （`COALESCE` / `to_char` / `EXTRACT` / `STRING_TO_ARRAY`，以及 `deleted = 0` 等）。
  如需换回 MySQL，需自行改写统计类 Mapper 与代码生成模板。
- **品牌**：界面标题、水印、菜单与提示文案统一为「棱信矩灵 / 矩灵」。
- **命名约定**：Maven 坐标 `com.lxjl.boot:juling-*`，Java 包 `com.lxjl.juling.*`，配置键 `juling.*`，
  数据库库名 `juling`；新增业务模块按同一约定命名。
- **许可**：MIT License，详见 [LICENSE](./LICENSE)。

## 模块启停

所有业务模块都通过 **Maven 依赖接线**，而不是配置文件开关：模块是否生效，取决于
`juling-server/pom.xml` 里是否（未注释地）声明了它。

```powershell
# 查看当前启用了哪些模块
Select-String -Path juling-server\pom.xml -Pattern '<artifactId>juling-module-'
```

**未启用的模块不会注册任何 Controller**，此时请求该模块的路径会被
`DefaultController` 兜底，返回 `code=501` 的可读提示（而不是 404）。

启用某个模块的步骤：

1. 根 `pom.xml` 的 `<modules>` 里放开该模块（被注释时）；
2. `juling-server/pom.xml` 里放开对应 `<dependency>`；
3. **先停后端**再构建（Windows 下运行中的进程会锁住 `juling-server.jar`，`mvn clean` 会失败）：
   `Stop-ScheduledTask -TaskName 'JuLing-Backend'` → `mvn -T 1C clean install -DskipTests` → `Start-ScheduledTask -TaskName 'JuLing-Backend'`；
4. 数据库：模块自带表（见其 `src/test/resources/sql/create_tables.sql`）+ 菜单/字典（`sql/local/`，见该目录 README）；
5. 前端：菜单在 `system_menu` 配置，页面在 `juling-ui/juling-ui-admin-vben/apps/web-antd/src/views/<模块>/`。

各模块的额外前提：

| 模块 | 额外依赖 / 说明 |
|---|---|
| `juling-module-iot` | 设备时序数据需要 TDengine；未部署时 `iot/statistics/*` 等接口会报错 |
| `juling-module-mp` | 需要微信公众号的 appId/secret 等配置，未配置时公众号相关接口不可用 |
| `juling-module-ai` | 需要各家大模型的 API Key（`juling.ai.*`，默认关闭） |

> **数据报表**：本仓库**不包含**报表设计器模块。固定口径的业务报表（FMS 资产负债表/利润表/现金流量表、
> HRM 考勤报表、MES/WMS 等）由各业务模块自带页面提供；如需业务人员自助拖拽做看板，
> 建议独立部署 BI 工具（Metabase / Superset / Grafana）直连 PostgreSQL，用只读账号 + 视图/行级安全隔离数据。

## 仓库约定

- **大文件拦截**（可选，每个克隆执行一次）：`git config core.hooksPath script/git-hooks`。
  提交超过 5MB 的文件会被拒绝（阈值可用环境变量 `LARGE_FILE_LIMIT_MB` 调整，`git commit --no-verify` 可临时绕过）；
  `.gitignore` 同时内置了常见大文件后缀（`*.exe` / `*.zip` / `*.mp4` / `*.psd` / `*.war` 等）。
- **数据库**：本地库名 `juling`；模块补齐脚本、演示数据清理脚本与维护脚本都在 `sql/local/`，执行顺序见该目录 README。
- **管理员密码**：已改为自定义强密码且不入库，仅存于本机 `script/local/admin-password.txt`；
  重置用模板 `sql/local/admin_password_reset.sql`（仓库内只有占位符，没有真实口令/哈希）。
- **数据库备份**：`script/backup/backup-postgres.ps1`（`pg_dump -Fc` + 归档校验 + 保留天数），
  已注册 Windows 计划任务 `JuLing-Postgres-Backup` 每天 02:30 执行；恢复步骤见 `script/backup/README.md`。
- **后端只监听本机**：`application-local.yaml` 中 `server.address: 127.0.0.1`，外部统一经 Nginx 访问；
  `/druid/*`、`/doc.html` 等运维入口不对外代理，Druid 控制台口令存于本机 `script/local/druid-console.txt`（不入库）；
  Nginx 侧片段归档在 `script/nginx/README.md`（线上配置在 Nginx 安装目录，仓库外）。
- **自检工具**：`script/tools/` 下一组可重复执行的脚本（PG 类型不匹配、MySQL 专有 SQL、实体类型、
  字典覆盖、文档链接、全接口冒烟），用法与已修问题见 `script/tools/README.md`。

## 许可

本项目采用 **MIT License**，完整的版权与许可声明见 [LICENSE](./LICENSE)。
随代码分发的第三方组件（Vben、uni-app 生态组件等）保留其各自的许可与署名。
