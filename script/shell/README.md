# script/shell —— Linux 服务器部署脚本(模板)

`deploy.sh` 用于**Linux 服务器**上的单机部署：备份旧 jar → 停服 → 换 jar → 启动 → 健康检查。
通用模板，使用前请按本项目调整：

| 变量 | 模板默认值 | 本项目建议 |
|---|---|---|
| `BASE_PATH` | `/work/projects/juling-server` | 换成实际部署目录 |
| `SERVER_NAME` | `juling-server` | 保持(与构建产物 `juling-server.jar` 一致) |
| `PROFILES_ACTIVE` | `development` | 本项目本地为 `local`；服务器建议另建 `prod` profile |
| `HEALTH_CHECK_URL` | `http://127.0.0.1:48080/actuator/health/` | 端口一致即可；依赖 Actuator，其依赖链为 `juling-server → juling-module-infra → juling-spring-boot-starter-monitor → spring-boot-starter-actuator`，默认只暴露 `health` |
| `JAVA_OPS` | `-Xms512m -Xmx512m` | 按服务器内存调整 |

注意事项：

- 脚本用 `ps -ef | grep <BASE_PATH>/<SERVER_NAME>` 找进程，因此**部署目录与 jar 名不要包含空格**；
- 健康检查若长期不通过，脚本会 `exit 1` 并打印 `nohup.out` 末尾日志；
  若服务器上未启用 Actuator，请把 `HEALTH_CHECK_URL` 留空（脚本会退化为 sleep 120 秒后打印日志）；
- 本项目**本机 Windows 环境不使用**该脚本：本机用 `run/start-backend.ps1` 或计划任务 `JuLing-Backend`
  （见 `run/README.md`），生产前端由 nginx 发布 `/jl`（见 `script/nginx/README.md`）。
