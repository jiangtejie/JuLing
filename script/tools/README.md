# script/tools —— 仓库自检小工具

PostgreSQL 化改造后，MySQL 风格的 SQL / 类型写法不会在编译期暴露，只在运行期报错。
这里放一组可重复执行的自检工具，提交前或换环境后跑一遍即可。

| 工具 | 检查内容 | 依赖 |
|---|---|---|
| `check-pg-type-mismatch.py` | PG 列类型与 SQL 字面量不匹配：`boolean 列 = 0/1`、`smallint 列 = TRUE/FALSE`（运行期报 `operator does not exist`） | 本地库可连（`docker exec postgres`） |
| `check-mysql-sql.py` | 全仓 SQL 片段里的 MySQL 专有函数与语法（`MONTH()` / `IFNULL()` / `GROUP_CONCAT` / 反引号 / `LIMIT m,n`…），含代码生成模板 | 无 |
| `check-pg-entity-types.py` | 实体字段类型 ↔ PG 列类型交叉校验（`boolean ↔ Boolean`、`smallint ↔ Integer`），找出 `column is of type A but expression is of type B` | 本地库可连 |
| `check-dict-coverage.py` | 代码里 `@DictFormat` / `@ExcelColumnSelect` 引用的字典是否都在库中存在、且都有数据行（缺失会导致下拉为空、导入模板下载失败） | 本地库可连 |
| `check-doc-links.py` | 已跟踪 markdown 中引用的**仓库内路径**是否真实存在（防止文档指向已被删除/从未入库的文件） | 无 |
| `smoke-all-endpoints.py` | 遍历所有无路径参数的 GET 接口做冒烟，输出非预期返回码与异常消息，用于发现运行期兼容问题 | 后端已启动 |

```bash
python script/tools/check-doc-links.py
python script/tools/check-mysql-sql.py
python script/tools/check-pg-type-mismatch.py
python script/tools/check-pg-entity-types.py
python script/tools/check-dict-coverage.py
python script/tools/smoke-all-endpoints.py                       # 默认 http://127.0.0.1:48080
python script/tools/smoke-all-endpoints.py http://127.0.0.1:48080
```

说明：

- 冒烟脚本输出「异常接口 / 总数」，其中 `code=400/401/403/404/405/501` 视为正常（参数或权限问题），
  其它返回码才是可疑项；再结合 `infra_api_error_log` 看根因分类。
- 依赖数据库的三个脚本通过 `docker exec postgres psql` 读 `information_schema`，库名固定 `juling`。

## 已修复的典型问题（供参考）

| 症状 | 根因 | 修法 |
|---|---|---|
| `function month(timestamp) does not exist` | HRM 生日待办用了 MySQL 的 `MONTH()` | 改 `EXTRACT(MONTH FROM ...)` |
| `operator does not exist: boolean = integer` | 布尔列（如 `iqc_check_flag`）与 `= 1` 比较 | 改 `= TRUE`（MySQL 同样成立） |
| `operator does not exist: smallint = boolean` | smallint 列（如 `deleted`）与 `= FALSE` 比较 | 改 `= 0` |
| `UNION types text and bigint cannot be matched` | UNION 分支里的裸 `NULL` 被 PG 推断为 `text` | 改 `CAST(NULL AS bigint)` |
| 重建库后 `function ifnull(numeric, integer) does not exist` | 代码用 `IFNULL()`，原先靠手工建的兼容函数才跑通 | 改 `COALESCE()` |
| 导入模板下载报 `FormulaParseException ... '$F$1:$F$0'` | 字典项为空时仍生成下拉，区间首尾倒置 | 框架跳过空字典下拉 + 补齐缺失字典数据（见 `sql/local/09_dict_baseline_gaps.sql`） |
| 导入模板下载报 `Convert data:xxx error / UnsupportedOperationException` | `AreaConvert` 只实现读、未实现 `convertToExcelData`（地区列一写就崩） | 框架补上写实现（`AreaUtils.format(id, "/")`，与读路径的解析分隔符对称） |
| 操作日志导出 500（`TranslateUtils.transService` 为 null） | `@ConditionalOnBean(TransService)` 在自动配置评估期看不到 easy-trans 的 bean | 改用 `@ConditionalOnClass` + `ObjectProvider` 运行时取 bean，并给 `TranslateUtils` 加空值保护 |
| 提示文案里出现历史项目字样 | `DefaultController`、Quartz、`MpAccountServiceImpl` 三处漏改（返回给前端/日志） | 统一改为「参考项目 README 开启」 |

> 背景（文档类问题）：`run/` 一度只被本地 `.git/info/exclude` 排除，导致 README 引用的启动脚本在克隆后不存在；
> `check-doc-links.py` 用于在提交前发现这类「文档指向不存在文件」的问题。

## 跑单元测试需要的环境

单测**完全自包含，不需要任何外部服务**：

- 数据库：H2 内存库（`BaseDbUnitTest` 按 `spring.sql.init` 自动建表）
- Redis：`BaseRedisUnitTest` 通过 jedismock 在 **16379** 端口内嵌一个 Redis
  （各模块 `application-unit-test.yaml` 里的 `spring.data.redis.port` 即此端口）

两个注意点：

1. **16379 不能被别的进程占用，且测试阶段要串行跑**。内嵌 Redis 的端口是固定的
   （各模块 `application-unit-test.yaml` 的 `spring.data.redis.port = 16379`），
   `RedisTestConfiguration` 里启动失败是 `catch (Exception ignore)` 静默忽略的，于是：

   - 端口被外部进程占用 → 测试连到那个外部实例，Redis 状态跨用例/跨轮次残留
     （典型症状：MES 自动编码序号断言 `expected 0001 but was 0002`）
   - 用 `mvn -T` 并行跑多个模块 → 先起的 JVM 占住端口，后起的启动失败，
     表现为 `RedisConnectionFailure: Cannot get Jedis connection`

   因此：`mvn -T 1C clean install -DskipTests` 之后，用 **`mvn test`（不加 -T）** 跑测试，
   并先确认 `netstat -ano | findstr 16379` 没有占用。

2. 若某模块测试报 `NOAUTH Authentication required`，说明它的 `application-unit-test.yaml`
   里 `data:` / `redis:` 缩进写错（挂到了 `spring.sql.init` 下），配置不生效而回落到 6379 的生产 Redis。
   校验方式：`data:` 到 `redis:` 的父链必须是 `spring.data`（本仓库已修正 7 个模块）。

## 连接非 Docker 数据库

依赖数据库的三个脚本默认走 `docker exec postgres psql -U root -d juling`；
如需连别处的库，设置环境变量即可（两者任选其一）：

```bash
export JULING_PSQL_CONN='postgresql://root:123456@127.0.0.1:5432/juling'   # 连接串
export JULING_PSQL_CMD='psql -h 10.0.0.8 -U root -d juling'                # 完整命令前缀
```

`smoke-all-endpoints.py` 需要已启动的后端，按需在部署环境里跑。
