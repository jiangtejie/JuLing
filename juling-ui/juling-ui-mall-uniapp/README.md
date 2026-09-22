# 棱信矩灵 商城(uni-app C 端)

面向消费者的商城前端(uni-app),支持 H5 / 微信小程序 / App,调用后端 `member` 与 `mall` 相关接口
(接口前缀 `/app-api`),与桌面管理端共用同一套后端服务。

## 开发与运行

环境要求:Node.js >= 20、pnpm >= 9(本仓库统一使用 pnpm)。也可直接用 **HBuilderX** 打开运行。

```bash
pnpm install            # 安装依赖
pnpm dev:h5             # H5 预览(默认 http://127.0.0.1:3001)
pnpm dev:mp-weixin      # 微信小程序(产物在 dist/dev/mp-weixin)
pnpm dev:app            # App
pnpm build:h5           # H5 生产构建
pnpm build:mp-weixin    # 微信小程序生产构建
```

> 端口取自 `.env` 的 `SHOPRO_DEV_PORT`。本机 3000 端口被 WSL(`wslrelay`)占用,故默认设为 3001;
> 若该端口也被占用,Vite 会自动顺延,请以启动日志打印的地址为准。

### 关于 CLI 启动脚本 `scripts/uni-cli.js`

本项目沿用 **HBuilderX 的扁平目录结构**(`manifest.json`、`pages.json` 都在项目根目录),
而 uni CLI 在未指定 `UNI_INPUT_DIR` 时默认读取 `<项目根>/src`,会直接报
`ENOENT: .../src/manifest.json`。所以所有 `dev:*` / `build:*` 脚本都经由
`scripts/uni-cli.js` 启动:它先把 `UNI_INPUT_DIR`、`VITE_ROOT_DIR` 指向项目根,再加载 uni CLI,
并与 CLI 同进程运行(中断时不会残留占用端口的子进程)。用 HBuilderX 打开本项目不受影响。

### 依赖安装的两个约定(`pnpm-workspace.yaml`)

- `shamefullyHoist: true`:uni-app CLI 需要扁平的 `node_modules`,否则部分编译器子包解析不到;
- `allowBuilds`:显式关闭 `esbuild` 的 `install.js`。其平台二进制由 optionalDependencies
  (`@esbuild/win32-x64`)提供,`install.js` 只是联网兜底,在镜像网络下会长时间卡住;
  `core-js` / `vue-demi` 的安装脚本对本项目亦无必要。

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
| `SHOPRO_DEV_PORT` | 本地开发端口,默认 `3001`(3000 常被 WSL 占用) |
| `SHOPRO_H5_URL` | H5 访问域名,用于分享链接与复制链接 |

> **真机 / 局域网调试**:把 `SHOPRO_DEV_BASE_URL` 改为开发机局域网 IP(如 `http://192.168.x.x:48080`)。

## 后端数据依赖

商城首页与个人中心是**装修驱动**的:应用启动时请求 `/app-api/promotion/diy-template/used`。
后端若未启用任何装修模板,前端会跳转到 `/pages/public/error?errCode=TemplateError`
(提示「未找到模板,请前往后台启用对应模板」)。请先在管理后台「商城装修」中创建并启用模板;
前端支持的组件类型见 `sheep/components/s-block-item/s-block-item.vue` 的映射表。

## 占位图资源

仓库里原本缺失整棵 `static/img/**` 目录,而代码中有约 25 处引用它(订单状态、支付渠道、
分享、钱包、快捷菜单、默认头像、海报底图等),运行时会显示成裂图。现由
`scripts/gen-placeholder-assets.mjs` 用自绘几何图形统一生成(共 55 个文件)。

**这些是占位素材,不是品牌素材,上线前请按需替换:**

| 类别 | 位置 | 说明 |
|---|---|---|
| 支付/登录渠道 | `shop/pay/*`、`shop/platform/*` | 中性色块 + 单字/符号表示,**未使用任何厂商商标**,请替换为官方素材 |
| 轮播图 | `banner/*` | 纯装饰渐变,图中已标注「占位图」,请替换为运营素材 |
| 海报底图 | `shop/config/*-poster-bg.png` | 装饰渐变,按画布比例 750×1334 生成 |
| 功能图标 | `shop/order`、`shop/tools`、`tabbar`、`menu` 等 | 通用几何图标,可长期使用或按品牌风格替换 |

重新生成(脚本依赖 resvg,未加入 `package.json` 以免污染前端依赖):

```bash
npm i -D @resvg/resvg-js
node scripts/gen-placeholder-assets.mjs
```

> 尺寸约定:`static/img/tabbar` 与 `menu` 供装修模板引用(96/120px);
> `banner` 为 750×348(轮播组件默认高 174px 的 2 倍图);海报底图为 750×1334。

## 目录

```
pages/          页面
sheep/          业务组件、API 封装与工具
static/         静态资源
uni_modules/    uni-app 插件
```

## 许可

MIT License;版权与许可声明见仓库根 LICENSE。
