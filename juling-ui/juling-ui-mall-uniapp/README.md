# 棱信矩灵 商城(uni-app C 端)

面向消费者的商城前端(uni-app),支持 H5 / 微信小程序 / App,调用后端 `member` 与 `mall` 相关接口
(接口前缀 `/app-api`),与桌面管理端共用同一套后端服务。

## 开发与运行

推荐使用 **HBuilderX** 打开运行,或使用 CLI:

```bash
npm install           # 或 pnpm install
npm run dev:h5        # H5 预览(默认端口 3000)
npm run dev:mp-weixin # 微信小程序
```

## 接口配置(`.env`)

| 变量 | 说明 |
|---|---|
| `SHOPRO_BASE_URL` | 生产环境后端地址(部署时改为自有域名) |
| `SHOPRO_TRIAL_BASE_URL` | 体验环境后端地址 |
| `SHOPRO_DEV_BASE_URL` | 开发环境后端地址(默认 `http://127.0.0.1:48080`) |
| `SHOPRO_API_PATH` | 接口前缀,默认 `/app-api` |
| `SHOPRO_WEBSOCKET_PATH` | WebSocket 前缀,默认 `/infra/ws` |
| `SHOPRO_STATIC_URL` | 静态资源前缀(留空表示使用服务端返回地址) |
| `SHOPRO_TENANT_ID` | 租户编号,默认 1 |

> **真机 / 局域网调试**:把 `SHOPRO_DEV_BASE_URL` 改为开发机局域网 IP(如 `http://192.168.x.x:48080`)。

## 目录

```
pages/          页面
sheep/          业务组件、API 封装与工具
static/         静态资源
uni_modules/    uni-app 插件
```

## 许可

MIT License;版权与许可声明见仓库根 LICENSE。
