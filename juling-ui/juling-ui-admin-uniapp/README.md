# 棱信矩灵 移动端管理后台(uni-app)

基于 uni-app 实现的移动端管理后台,复用本仓库后端接口(`/admin-api`),与桌面端
`juling-ui-admin-vben` 功能对应,面向手机 App / 小程序 / H5 场景。

## 开发与运行

推荐使用 **HBuilderX** 打开运行,或使用 CLI:

```bash
npm install              # 或 pnpm install
npm run dev:h5           # H5 预览
npm run dev:mp-weixin    # 微信小程序
```

## 接口配置

配置文件:`env/.env`(按 mode 叠加 `env/.env.development`、`env/.env.production`、`env/.env.test`)

| 变量 | 说明 |
|---|---|
| `VITE_SERVER_BASEURL` | 后端地址,默认 `http://localhost:48080/admin-api` |
| `VITE_UPLOAD_BASEURL` | 文件上传地址 |
| `VITE_STATIC_BASEURL` | 静态资源地址(留空表示使用服务端返回的地址) |
| `VITE_APP_TITLE` | 系统标题 |
| `VITE_APP_TENANT_ENABLE` | 多租户开关 |

> **真机 / 局域网调试**:手机访问不到 `localhost`,请把 `VITE_SERVER_BASEURL` 改为开发机的局域网 IP,
> 例如 `http://192.168.x.x:48080/admin-api`,并确保后端在该网段可访问。

## 许可

MIT License;版权与许可声明见仓库根 LICENSE。
