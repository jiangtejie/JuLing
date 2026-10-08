# JuLing-yate 迁移部署方案（Docker Compose）

> 目标：把这套系统整体迁到你自己的服务器上，用 Docker Compose 跑起来。
> 本文是**可执行的步骤**，不是概念说明。每一步都能直接敲。

## 0. 先把这份方案的范围说清楚

本方案负责**运行环境**：数据库、缓存、后端、前端、反向代理、初始化、备份、发布、回滚。

**不在本方案内**（要单独决定）：
- **多主体/多账套**：当前架构是单组织，单据上没有主体字段。上线前要不要加，见最后一节。
- **总账/凭证**：系统目前只有收付款与往来账，没有总账。
- **金蝶的历史数据迁移**：这是数据工程，不是部署问题。

## 1. 服务器与前置条件

| 项 | 要求 | 说明 |
| --- | --- | --- |
| 系统 | Linux x86_64 | amd64 镜像；ARM 需换基础镜像 |
| CPU / 内存 | 建议 4 核 / 8G 起 | 后端默认给 2G 堆，Postgres 与 Redis 另有开销 |
| 磁盘 | 建议 100G 起 | 数据库 + 上传文件 + 堆转储 |
| Docker | 24+ ，含 compose v2 | 用 docker compose（不是 docker-compose） |
| 构建机 | 需 JDK 17 + Maven + Node 20+ | **只用来构建**，不必是同一台服务器 |

**为什么构建不在服务器上做**：后端镜像只打包 jar、不编译（见 deploy/backend/Dockerfile 的注释），
服务器上就不需要装 Maven 和整个源码树 —— 镜像小、构建快、也避免源码留在生产机。

## 2. 端口与目录规划

| 服务 | 容器内 | 宿主机 | 对外 |
| --- | --- | --- | --- |
| nginx | 80 | 80 | **唯一对外入口** |
| backend | 48080 | 127.0.0.1:48080 | 否，只给 nginx 与本机排查 |
| postgres | 5432 | 127.0.0.1:5432 | 否 |
| redis | 6379 | 不映射 | 否 |

**只把 80 暴露到公网**，其余绑在 127.0.0.1。数据库直连暴露到公网是最常见的事故来源。

路径规划：

    后台管理     http://<服务器>/jl/
    门店订货 H5  http://<服务器>/jl-mall/
    后端接口     /admin-api/   （后台）    /app-api/   （H5）
    上传文件     /uploads/

## 3. 首次部署

### 3.1 准备配置

    cd <仓库>/deploy
    cp .env.example .env
    vi .env          # 改所有密码；JAVA_OPTS 按内存调整

**不要提交 .env。** 建议在 .gitignore 里加上 deploy/.env。

### 3.2 编译后端

    cd <仓库>
    mvn -T 1C clean package -DskipTests

产物必须是 juling-server/target/juling-server.jar（pom 里 finalName 已配成 juling-server）。

### 3.3 构建前端（两个）

    cd juling-ui/juling-ui-admin-vben
    pnpm install && pnpm run build:antd      # 产物 apps/web-antd/dist

    cd ../juling-ui-mall-h5
    pnpm install && pnpm run build:prod      # 产物 dist

H5 的 .env.production 里 VITE_API_BASE_URL 留空 = 同源部署，靠 nginx 反代 /app-api。
**若你把 H5 部署到另一个域名，这里必须填完整地址**，否则请求会打到错误的源。

### 3.4 建库建表

    cd <仓库>/deploy
    docker compose --profile init run --rm db-init

它会按顺序执行：

    sql/postgresql/baseline-schema.sql   ① 结构基线（236 表 / 515 序列）
    sql/postgresql/baseline-seed.sql     ② 框架种子（菜单/字典/角色/用户/编码规则）

    sql/local/ 是两年的演进历史，**新环境不需要执行**（见 sql/postgresql/README-baseline.md）

**为什么不用 postgres 镜像的 entrypoint 做初始化**：它不递归子目录（我们的脚本分在两个目录），
而且只在数据卷为空时执行一次 —— 之后改了脚本不会重跑，出问题很难排查。
一次性容器可以随时重跑，且所有脚本都是幂等的。

### 3.5 启动

    docker compose up -d
    docker compose ps               # 四个服务都应 healthy / running
    docker compose logs -f backend  # 首次启动看一遍，确认没有报错

### 3.6 验收清单（**这一步别跳**）

| # | 检查 | 命令 / 操作 |
| --- | --- | --- |
| 1 | 后端健康 | curl -s http://127.0.0.1:48080/actuator/health/ |
| 2 | 后台能打开 | 浏览器访问 /jl/ ，能登录 |
| 3 | H5 能打开 | 浏览器访问 /jl-mall/ |
| 4 | 接口通 | 登录后随便点一个列表页，有数据返回（不是 401/500） |
| 5 | 数据库连的是新库 | docker compose exec postgres psql -U root -d yate -c 'select count(*) from system_users' |
| 6 | 上传可用 | 传一张图片，能在 /uploads/ 下看到文件 |
| 7 | 定时任务没乱跑 | 首次上线前确认 spring.quartz.auto-startup 的设置符合预期 |

## 4. 日常发布（只发后端 / 只发前端）

**只发后端**（最常见）：

    git pull && mvn -T 1C clean package -DskipTests
    docker compose build backend && docker compose up -d backend

**只发前端**：前端是挂载目录，不重建镜像：

    cd juling-ui/juling-ui-admin-vben && pnpm run build:antd
    docker compose restart nginx

前端**必须重启 nginx**：挂载的目录内容变了，但 nginx 可能还在用旧的缓存。

## 5. 数据迁移（把当前开发库的数据搬过去）

当前开发库存的是**真实业务数据**时，不要跑 3.4 的全量初始化，改成：

1) 目标机先跑 3.4 建好**空的**结构（脚本幂等，安全）
2) 从旧库导出**只含数据**：

    pg_dump -h <旧> -U root -d yate --data-only --column-inserts \
      -f data.sql

3) 导入新库：

    docker compose exec -T postgres psql -U root -d yate < data.sql

**用 --column-inserts**：列顺序变化时不会错位，比 COPY 格式稳。

**导出前先删掉测试数据**。当前开发库里有一批我调试时造的记录（物料/门店/价目表 id 都是 900001，
名称以 TEST- 开头），迁移前应当清掉。

## 6. 备份与恢复

**备份**（建议 cron 每天一次，保留 30 天）：

    docker compose exec -T postgres pg_dump -U root -d yate -F c -f /tmp/yate.dump
    docker compose cp postgres:/tmp/yate.dump ./backup/yate-$(date +%F).dump

**恢复**：

    docker compose cp ./backup/yate-2026-01-01.dump postgres:/tmp/r.dump
    docker compose exec postgres pg_restore -U root -d yate --clean --if-exists /tmp/r.dump

**别忘了上传文件**：uploads 卷不在数据库备份里。它对应宿主机的 docker volume，
备份时要一并处理（docker run --rm -v juling-yate_uploads:/data -v $PWD:/backup alpine tar czf /backup/uploads.tgz -C /data .）。

## 7. 已知的坑（都是这套系统实际踩过的）

**① 中文与编码**：Postgres 用 --locale=C --encoding=UTF8 初始化。
不同宿主的 locale 不一致会导致排序与索引行为不同，用 C 最稳。

**② 时区**：所有容器都设 TZ=Asia/Shanghai。不设的话，单据时间会差 8 小时，
而这类问题**往往到对账时才发现**。

**③ 多租户是开着的**：application.yaml 里 tenant.enable=true，MyBatis-Plus 会自动按 tenant_id 过滤。
手工 INSERT 数据时**必须带上正确的 tenant_id** —— 写成 0 的数据在界面上永远看不到
（我调试时就踩过这个，灌进去的测试数据在页面上一条都不显示）。

**④ 定时任务用数据库存 Job**：spring.quartz.job-store-type=jdbc。Quartz 的表已并入新基线
（原 quartz.sql 已移除），不再需要单独执行。

**⑤ 上传目录**：必须挂卷。否则容器一重建，所有已上传的附件就没了。

**⑥ 前端资源与 index.html 的缓存策略不同**：带哈希的资源可以长缓存，
但 index.html 必须 no-cache，否则发版后用户还是加载旧版本（nginx 配置里已经区分了）。

**⑦ 数据库不要暴露公网**：compose 里已绑 127.0.0.1，改配置时别顺手放开。

## 8. 回滚

**后端**：

    docker compose build backend --build-arg 无      # 用上一个 git tag 重新构建即可
    # 或保留上一版镜像：docker tag juling-yate-backend:old ...；回滚时 docker compose up -d backend

**建议**：每次发布前先 docker tag 一下当前镜像，回滚就是切换 tag，几秒钟的事。

**前端**：产物是挂载的目录，回滚 = 重新构建上一个版本，或用备份的 dist 目录覆盖。

**数据库**：结构变更脚本都是幂等的，但**没有下行脚本**。
所以：**改结构的脚本上线前，必须先做一次备份**。

## 9. 上线前必须先定的两件事

**① 主体归属（多账套）**

你说以后会抛弃金蝶、全部在本系统内做。那么**主体维度必须在有数据之前定**。

理由不是财务需求，而是**进销存自己的需求**：库存要按主体分、采购入库要进某个主体的库、
成本要落到某个主体头上。现在 ErpSupplierDO.contractEntity（合同签订主体）已经是个
自由文本字段了 —— 说明业务上已经在用主体概念，只是没有结构化的承载。

**建议**：新建 erp_legal_entity 表（不要复用 system_dept，两者的层级和变化节奏不同），
并在单据与库存表上加 org_id（可空、先不用）。现在做只是加字段，有数据之后再补归属就难了。

**② 是否新建 application-prod.yaml**

现在只有 application-local.yaml。生产环境要么新建 prod 配置，
要么完全靠环境变量覆盖（compose 里已经写了 SPRING_* 的覆盖项）。
**我倾向后者**：配置只存在于 .env 与 compose 里，不在仓库里留生产密码。

## 10. 我没有验证过的部分

如实说明，避免你把没验过的东西当成验过的：

1. **这套 compose 没有实际跑过** —— 是在你现有开发环境的基础上推出来的。
   它引用的路径、端口、依赖（Postgres 15 / Redis 7 / JDK 21 运行 17 字节码）都是从代码与配置里读出来的，
   但**没有在真机 Docker 上端到端验证**。
2. **前端 dist 路径**：apps/web-antd/dist 与 juling-ui-mall-h5/dist 是构建脚本推断的，
   第一次构建后请确认实际产物目录。
3. **H5 的 PWA 配置**（VITE_PWA=true）：离线缓存策略在生产是否需要，我没评估。

**建议第一次部署时逐条跑 3.6 的验收清单** —— 那七条能覆盖掉大部分「配错了但看起来起来了」的情况。
