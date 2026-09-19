# 棱信矩灵 管理后台(前端)

基于 Vue3 + Vben5 + Ant Design Vue 的中后台前端,服务于 **棱信矩灵 管理系统**。

- 开发模式:`pnpm dev:antd` → http://127.0.0.1:5666(热更新,接口代理到后端 48080)
- 生产构建:`pnpm -F @vben/web-antd run build` → `apps/web-antd/dist`,由 Nginx 以子路径 `/jl` 发布
- 后端接口:`/admin-api`(REST)、`/infra/ws`(IM 实时消息 WebSocket)
- 环境要求:Node.js ≥ 22.18、pnpm ≥ 11

## 常用命令

```bash
pnpm install            # 安装依赖(强制使用 pnpm)
pnpm dev:antd           # 启动开发服务器
pnpm -F @vben/web-antd run build   # 生产构建
```

## 环境变量(节选)

| 变量 | 说明 |
|---|---|
| `VITE_APP_TITLE` | 系统标题:棱信矩灵管理系统 |
| `VITE_BASE` | 资源前缀(生产为 `/jl/`) |
| `VITE_GLOB_API_URL` | 接口地址(生产为同源 `/admin-api`) |
| `VITE_BASE_URL` | 供 WebSocket 推导地址;留空时使用当前页面 host |

## 目录

```
apps/web-antd/          管理后台主体(views / api / router / store …)
packages/               共享能力:UI 组件、表单、请求、偏好设置等
internal/               构建与工程化配置(vite、tsconfig、lint)
```

## 许可

前端基于 Vben5 + Ant Design Vue 构建,MIT License,详见仓库根 LICENSE。
