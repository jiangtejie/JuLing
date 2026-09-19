# run/ —— 本地启动脚本

本目录只跟踪**启动脚本与说明**；运行期产物（`*.log`、`uploads/`）由 `.gitignore` 忽略。

| 文件 | 作用 |
|---|---|
| `start-backend.ps1` | 启动后端（`juling-server`，端口 48080）。优先用 `juling-server/target/juling-server.jar`，target 被清理时回退到本地 Maven 仓库的快照 jar |
| `start-frontend-dev.ps1` | 启动前端开发服务器（Vite，端口 5666）。**仅开发调试用**；生产访问的是 nginx 发布的 `/jl`（`apps/web-antd/dist`），不依赖它 |

## 计划任务（本机已注册）

| 任务 | 触发 | 说明 |
|---|---|---|
| `JuLing-Backend` | 登录时自动启动 | 后端 48080；失败自动重启 3 次 |
| `JuLing-Frontend-Dev` | 按需 | 前端 dev 5666 |
| `JuLing-Postgres-Backup` | 每天 02:30 | 数据库备份，见 `script/backup/README.md` |

```powershell
Start-ScheduledTask   -TaskName 'JuLing-Backend'      # 启动后端
Stop-ScheduledTask    -TaskName 'JuLing-Backend'      # 停止后端
Start-ScheduledTask   -TaskName 'JuLing-Frontend-Dev' # 启动前端 dev
Stop-ScheduledTask    -TaskName 'JuLing-Frontend-Dev' # 停止前端 dev

Disable-ScheduledTask -TaskName 'JuLing-Backend'      # 暂时禁用登录自启（仍可手动 Start）
Get-ScheduledTaskInfo -TaskName 'JuLing-Backend'      # 查看上次运行结果
```

## 注意

- **构建前请先停后端**：运行中的 `juling-server.jar` 会被占用，导致 `mvn install` 在
  `spring-boot:repackage` 阶段报 `Unable to rename ... juling-server.jar.original`。
  ```powershell
  Stop-ScheduledTask -TaskName 'JuLing-Backend'
  mvn -T 1C install -DskipTests -B -ntp
  Start-ScheduledTask -TaskName 'JuLing-Backend'
  ```
- 后端只监听 `127.0.0.1:48080`（见 `application-local.yaml` 的 `server.address`），
  外部统一经 nginx 访问 `/jl` 与 `/admin-api`。
- `.ps1` 脚本含中文，必须以 **UTF-8 BOM** 保存，否则 Windows PowerShell 5.1 会按 GBK 解析而报错。
