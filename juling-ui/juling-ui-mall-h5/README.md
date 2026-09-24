# juling-ui-mall-h5 · 矩灵订货商城 H5

炬信矩灵移动端**订货商城** H5 基座。面向微信公众号 / APP 内嵌 WebView / 手机浏览器，覆盖「商品浏览 → SKU 选择 → 阶梯价订货 → 提交订货单 → 订单跟踪」的完整链路骨架。

## 技术栈

| 分类 | 选型 | 说明 |
| --- | --- | --- |
| 核心框架 | Vue 3.5（`<script setup>`） | Composition API，逻辑复用友好 |
| 构建工具 | Vite 7 | 极速 HMR，生产构建基于 Rollup |
| 语言 | TypeScript 5.9 | SKU / 订单 / 阶梯价全链路类型化 |
| 路由 | Vue Router 4（**Hash 模式**） | 公众号 / WebView 免服务端 rewrite，兼容性最好 |
| 状态管理 | Pinia 3 + pinia-plugin-persistedstate | 订货单、登录态自动持久化 |
| UI 组件 | Vant 4 | 移动端组件事实标准（SubmitBar / Stepper / Tabs 等） |
| 原子化 CSS | UnoCSS 66（presetWind3 + presetIcons） | 按需生成，零额外体积 |
| 移动端适配 | postcss-px-to-viewport-8-plugin | 设计稿 px 自动转 vw |
| 请求 | Axios + 请求/响应拦截器 | 统一注入 Token / tenant-id，统一错误提示，401 静默刷新重放 |
| 接口适配 | `src/api/adapters` | 后端 DTO → 前端领域模型（字段改名、状态码、时间戳、属性数组转换） |
| 工具库 | VueUse、lodash-es | 组合式函数 + 安全深拷贝 |
| PWA | vite-plugin-pwa（Workbox） | 静态资源预缓存 + 离线访问 |
| 按需引入 | unplugin-vue-components / unplugin-auto-import | Vant 组件与 Vue/Pinia/VueUse API 自动引入 |
| 产物分析 | rollup-plugin-visualizer | 定位体积过大的依赖 |
| 产物压缩 | vite-plugin-compression2 | 生成 .br / .gz 预压缩文件 |
| 工程化 | pnpm + ESLint 10 + Prettier + Husky + lint-staged + commitlint | 依赖一致性与提交规范 |

## 环境要求

- Node.js **>= 20.19**（本工程在 Node 24 上验证通过）
- pnpm **>= 9**（package.json 已声明 `packageManager: pnpm@11.7.0`）

## 快速开始

```bash
pnpm install          # 安装依赖（preinstall 会强制校验包管理器）
pnpm dev              # 启动开发服务器 http://localhost:3001
pnpm build            # 类型检查 + 生产构建
pnpm build:report     # 生产构建并生成 dist/stats.html 体积分析报告
pnpm preview          # 本地预览构建产物 http://localhost:4173
```

其他脚本：

| 命令                          | 作用                                |
| ----------------------------- | ----------------------------------- |
| `pnpm type-check`             | vue-tsc 全量类型检查                |
| `pnpm type-check:node`        | 校验 vite.config.ts / uno.config.ts |
| `pnpm lint` / `pnpm lint:fix` | ESLint 检查 / 自动修复              |
| `pnpm format`                 | Prettier 格式化                     |
| `pnpm gen:icons`              | 重新生成 PWA 图标（零依赖脚本）     |

> 开发端口固定 **3001**：本机 3000 端口常被 WSL 的 wslrelay 占用，与 juling-ui 其它子工程保持一致。

## 目录结构

```text
juling-ui-mall-h5
├── public/                     # 静态资源（favicon / PWA 图标 / robots.txt）
├── scripts/
│   ├── gen-icons.mjs           # 零依赖 PNG 图标生成器
│   └── setup-husky.mjs         # Husky 安装守卫（见「Git 钩子」一节）
├── src
│   ├── api/                    # 接口层：auth / product / cart / order
│   │   └── adapters/           # 后端 DTO → 前端领域模型（product / order / cart / user）
│   ├── assets/                 # 图片等资源
│   ├── components/             # 全局公共组件（自动注册，无需 import）
│   │   ├── AppNavBar.vue       # 导航栏（自动处理返回与兜底）
│   │   ├── AppPage.vue         # 页面容器（导航栏 + 滚动区 + 底部槽位）
│   │   ├── AppTabbar.vue       # 底部导航（首页 / 分类 / 我的）
│   │   ├── ListSkeleton.vue    # 列表首屏骨架屏（商品行 / 订单卡两种形态）
│   │   └── PriceText.vue       # 金额展示（分转元，统一小数位）
│   ├── composables/            # 组合式函数（自动引入）
│   │   ├── usePaging.ts        # 分页列表（配合 van-list / van-pull-refresh）
│   │   ├── useSubmit.ts        # 防重复提交
│   │   └── useNetworkNotice.ts # 断网 / 恢复的全局提示
│   ├── config/                 # 应用配置（读环境变量）
│   ├── constants/              # 常量（存储 key、订单状态等）
│   ├── router/                 # 路由表 + 守卫（Hash 模式）
│   ├── stores/                 # Pinia：app / user / cart
│   ├── styles/                 # 全局样式与设计变量
│   ├── types/                  # 类型定义（SKU / 订单 / 购物车 / 环境变量）
│   ├── utils/                  # 工具：request / storage / auth / format / price / confirm
│   └── views/                  # 页面
├── postcss.config.mjs          # px 转 vw 适配
├── uno.config.ts               # UnoCSS 预设、主题、快捷类
└── vite.config.ts              # 插件、代理、分包、PWA、压缩
```

## 环境变量

| 变量                                | 说明                                                      |
| ----------------------------------- | --------------------------------------------------------- |
| `VITE_APP_TITLE`                    | 应用标题（注入 index.html）                               |
| `VITE_APP_TENANT_ID`                | 多租户 ID，作为 tenant-id 请求头                          |
| `VITE_STORAGE_PREFIX`               | 本地存储 key 前缀，避免同域多应用冲突                     |
| `VITE_API_PREFIX`                   | 接口前缀，默认 /app-api（yudao 体系 app 端约定）          |
| `VITE_API_BASE_URL`                 | 接口根地址；**同源部署留空**                              |
| `VITE_API_PROXY_TARGET`             | 开发代理目标，默认 http://127.0.0.1:48080                 |
| `VITE_USE_PROXY`                    | 是否启用开发代理（开发环境 true）                         |
| `VITE_PORT`                         | 开发服务器端口，默认 3001                                 |
| `VITE_DROP_CONSOLE`                 | 生产构建是否剔除 console / debugger                       |
| `VITE_PWA`                          | 是否启用 Service Worker                                   |
| `VITE_REPORT`                       | 是否开启打包体积分析（对应 `pnpm build:report`）          |
| `VITE_BASE`                         | 部署基础路径；缺省时开发用 `/`、构建用 `/jl-mall/`        |
| `VITE_WS_PATH` / `VITE_UPLOAD_TYPE` | WebSocket 前缀 / 上传方式，预留给后续能力，当前业务未使用 |

开发环境请求链路：axios(baseURL = /app-api) → Vite 代理 → http://127.0.0.1:48080/app-api 生产环境：`VITE_API_BASE_URL` 留空即走同源 /app-api（由 nginx 反代到 juling-server）

## 核心约定

### 1. 移动端适配（px 转 vw）

`postcss.config.mjs` 中 `viewportWidth: 375`。

- **设计稿按 375 宽出图**，代码里直接写设计稿上的 px 数值，构建时自动转 vw；
- Vant 4 同样以 375 为基准，因此**不排除 node_modules**，组件尺寸与业务样式同比缩放；
- 若设计稿是 750，把 `viewportWidth` 改成 750 即可；
- `minPixelValue: 1` 保证 1px 细线不被换算掉；
- 少数需要固定 px 的元素加 `.ignore-vw` / `.no-vw` / `.keep-px` 类名。

### 2. 主题与换肤

所有颜色集中在 `src/styles/variables.scss` 的 CSS 变量中，并同步覆盖 Vant 的 `--van-*` 变量。改主题只需改这一处：品牌色、品牌渐变（`--app-primary-gradient`）与订单状态色都已变量化，组件里不再出现写死的十六进制色值（首页 banner 的另外两个渐变色属于运营配色，不随主题）。

> 变量声明使用 `:root:root`：按需引入时 Vant 样式是异步 chunk，加载顺序不可控，提高一级选择器优先级可确保主题覆盖一定生效。
>
> 运行时动态换肤（如按租户下发主题色）可在任意时机调用 `document.documentElement.style.setProperty('--app-primary-color', color)`。

### 3. 接口约定

`src/utils/request.ts` 约定后端返回 `{ code, data, msg }`：

- `code === 0`（或 200）视为成功，拦截器直接**解包返回 data**，业务代码拿到的就是数据本体；
- `code === 401` 或 HTTP 401：清理 Token 并跳转登录页（带 redirect 回跳参数）；
- 其他错误：统一 Toast 提示（并发失败做了 1 秒节流，避免弹幕式报错）；
- 请求自动注入 `Authorization: Bearer <token>` 与 `tenant-id`；
- 单次请求可用 `{ silent: true }` 关闭全局错误提示。

```ts
import { http } from '@/utils/request';

const detail = await http.get<Product>('/product/spu/get-detail', { id: 1 });
// detail 已经是 data 本体，类型为 Product
```

**与后端字段的差异在 `src/api/adapters` 收口**：字段改名（`introduction`→`subTitle`、`no`→`orderNo`、`count`→`quantity`）、订单状态 `Integer` ↔ 字符串 key、时间戳归一、`properties` 对象数组转 `Record`。视图与 store 只消费前端领域模型，后端字段变动只需改 adapter 一处。`src/types/backend.ts` 逐字对齐后端 App 端 VO，**业务代码不要直接消费**。

### 4. 状态管理

- `useUserStore`：Token 只存在 `utils/auth.ts`（单一数据源，避免与 store 持久化打架），store 仅持久化会员信息；
- `useCartStore`：订货单行项持久化到 localStorage，刷新或从公众号返回都不会丢失；
- `useAppStore`：keep-alive 缓存名单、网络状态。

**阶梯价逻辑**保留在 `src/utils/price.ts` 的 `resolvePrice`（按订货数量匹配区间，未命中回退 SKU 基础价），购物车每次修改数量都会重新计算单价。但**后端目前没有阶梯价数据源**：`adapters/product.ts` 把 `tierPrices` 置空，实际恒回退基础价，界面上也不再展示阶梯价区块；后端在 SKU 上补齐区间价字段后，只需把 adapter 的映射接上即可恢复。

### 5. 路由

- **Hash 模式**：`https://host/#/order/list`，公众号 / WebView / 静态托管均无需服务端配置；
- `meta` 约定：

| 字段        | 作用                                       |
| ----------- | ------------------------------------------ |
| `title`     | 页面标题（自动写入 document.title）        |
| `auth`      | 需要登录，未登录跳 `/login?redirect=...`   |
| `tabbar`    | 显示底部导航                               |
| `keepAlive` | 缓存页面，**组件 name 需与路由 name 一致** |

- keep-alive 由 `App.vue` 统一处理，缓存名单来自路由守卫写入的 `useAppStore().cachedViews`；
- 页面组件用 `defineOptions({ name: "Home" })` 声明与路由 name 相同的名字。

### 6. 自动按需引入

`unplugin-auto-import` 已自动引入 vue、vue-router、pinia、部分 VueUse API，以及 `src/composables`、 `src/stores` 下的所有导出（如 `usePaging`、`useCartStore`）。`unplugin-vue-components` 自动注册 Vant 组件与 `src/components` 下的全局组件。

因此页面里**不需要**写这些 import：ref / computed / onMounted、useRouter、PriceText、useCartStore。

仍然需要**显式 import** 的：

- Vant 的**函数式组件**（showToast / showConfirmDialog 等），样式已在 `main.ts` 统一引入；
- 类型（`import type { Product } from "@/types"`）；
- `src/api`、`src/utils` 下的具体模块（保持依赖关系可追溯）。

生成的 `src/types/auto-imports.d.ts` 与 `src/types/components.d.ts` **已入库**，保证全新克隆的仓库无需先跑 dev 就能通过 `pnpm type-check`。

### 7. 图片懒加载

`van-image` 加上 `lazy-load` 即启用（插件在 `main.ts` 全局注册）。插件**刻意使用 IntersectionObserver 模式** （`observer: true`）而不是 Vant 默认的滚动事件模式：后者只监听 window 滚动，分类页这类「内容区内部滚动」的页面收不到滚动信号，图片会一直不加载。不支持 IntersectionObserver 的老 WebView 由 Vant 自动回退到事件模式。

### 8. PWA

`vite-plugin-pwa` 采用 `generateSW` + `autoUpdate`：

- 预缓存 JS / CSS / HTML / 图片 / 字体；
- 图片走 CacheFirst，商品读接口走 NetworkFirst（断网回退缓存）；
- `/app-api` 等接口路径已加入 `navigateFallbackDenylist`，不会被导航回退拦截；
- 开发环境默认不注册 Service Worker（`VITE_PWA=false`），避免缓存干扰调试。

### 9. 打包与部署

- **子路径部署**：构建时 `base` 为 `/jl-mall/`（可用 `VITE_BASE` 覆盖），对应 nginx 的 `location /jl-mall/`；PWA manifest 的 `start_url` / `scope` 与 Workbox 的 `navigateFallback` 一并跟随该路径；
- 产物分包：vue / vant / axios / vueuse / lodash / vendor；
- 构建同时输出 `.br` 与 `.gz`，nginx 打开 `brotli_static on;` / `gzip_static on;` 即可直接命中；
- 构建目标 `es2015` + `cssTarget: chrome61`，兼顾较老的安卓 WebView；
- 部署为纯静态文件即可（Hash 路由无需 try_files 回退配置）。

### 10. Git 钩子（重要）

本工程位于 **JuLing 单体仓库**之内，而该仓库根目录已经设置了 `core.hooksPath = script/git-hooks`。直接执行 husky 会**覆盖整个仓库**的钩子配置、影响其它子工程，因此 `scripts/setup-husky.mjs` 做了守卫：

- 本目录就是 Git 根目录（独立仓库或已 git init）→ 正常安装 husky 钩子；
- 处于上层仓库子目录中 → 只打印提示、跳过安装，**不会让 pnpm install 失败**。

需要在本工程启用提交前校验时，二选一：

```bash
# A. 作为独立仓库
git init && pnpm prepare

# B. 让整个仓库统一使用本工程的钩子（会影响其它子工程，请与团队确认）
git config core.hooksPath juling-ui/juling-ui-mall-h5/.husky/_
```

提交规范（commitlint，Conventional Commits）：

```text
feat(order): 支持阶梯价按数量自动重算
fix(cart): 修复订货单数量超过库存后未截断
```

允许的 type：feat / fix / docs / style / refactor / perf / test / build / ci / chore / revert。

## 关键设计决策与踩坑记录

1. **ESLint 用 10 而非 9**：安装时 9.x 已被 npm 标记 deprecated（EOL）；typescript-eslint@8 与 eslint-plugin-vue@10 均已支持 ESLint 10。
2. **workbox-build / workbox-window 必须显式安装**：它们是 vite-plugin-pwa 的 peer，pnpm 严格布局下 `virtual:pwa-register` 无法从根解析，构建会直接失败。
3. **UnoCSS 图标必须显式传 collections**：pnpm 布局下 preset 内部按文件系统查找 `@iconify-json/*` 会失败（大量 failed to load icon 警告且图标空白），改为用 createRequire 显式注入 `@iconify-json/carbon/icons.json`。
4. **UnoCSS 扫描必须排除 dist**：否则上一轮构建的压缩产物会被当作源码扫描，产生大量非法图标名与无用工具类；已在 `content.pipeline.exclude` 中排除。
5. **pnpm 11 需要 allowBuilds**：否则 esbuild 的构建脚本被拦截，`pnpm install` 以非 0 退出（配置在 `pnpm-workspace.yaml`）。
6. **`pnpm exec` 会触发依赖校验**：脚本或 CI 中调用本地 CLI 建议直接走 `node node_modules/<pkg>/bin/xxx.js`，避免多余的重装流程。
7. **tsconfig 自包含**：未依赖 `@vue/tsconfig`，所有编译选项显式声明，减少一层路径不确定性。
8. **金额统一以「分」为最小单位**在后端与前端之间流转，展示时才用 `formatPrice()` 转元，避免浮点误差（`van-submit-bar` 的 price 同样要求分）。
9. **Lazyload 用 IntersectionObserver 模式**：Vant 的 Lazyload 默认基于 scroll 事件、只监听 window，分类页（内容区内部滚动）加 `lazy-load` 后图片不会加载；改为 `observer: true` 后由 IO 统一驱动，列表新增元素与 keep-alive 返回都会重新参与观察。
10. **`van-skeleton` 自定义模板的动画来自根元素**：`.van-skeleton--animate` 的闪烁作用在组件根上，自定义 `#template` 插槽无需再给子元素加动画类名；骨架卡片与真实卡片保持同一内边距，避免加载完成时跳动。
11. **`van-action-bar` 的 `placeholder` 高度由 `useHeight` 实测**，而 CSS 变量沿 DOM 继承 ——把 `--van-action-bar-height` 定义在组件根上，fixed 操作栏与占位块会同时生效，不需要手写避让 padding。
12. **列表首屏骨架的显示条件是 `!list.length && loading && !refreshing`**：下拉刷新时列表会被清空，若只判断前两项会闪一下骨架；同时把 `van-list` 的 `loading-text` 条件化为「列表非空时才显示」，避免首屏骨架与「加载中...」文案叠在一起。
13. **Vant 的 `showConfirmDialog` 在「取消」时 reject**（`dialog/function-call.mjs` 里的 `(action === "confirm" ? resolve : reject)(action)`），而 Vue 会把事件处理器返回的 Promise rejection 交给 `app.config.errorHandler` —— 用户只是想放弃操作，却会看到兜底的「页面出现异常」Toast。**统一改用 `utils/confirm.ts` 的 `confirmDialog()`**（取消返回 `false`），需要 loading 反馈的操作用 `van-action-bar-button` / `van-button` 的 `loading` 属性而不是全局 loading。
14. **后端返回的文件地址是内网绝对 URL**（`http://127.0.0.1:48080/admin-api/infra/file/...`），公网访问时浏览器会去请求访问者自己的 127.0.0.1，https 页面下还会触发混合内容拦截 —— 表现就是「页面能开、图片全裂」。`utils/asset.ts` 的 `normalizeAssetUrl()` 会把本机 / 内网来源（127.x / localhost / 10.x / 192.168.x / 172.16-31.x / ::1）改写成同源相对路径（保留 `/admin-api` 前缀），由 nginx 或 vite 代理转发；**部署侧必须存在 `/admin-api/` → 后端的转发**。

## 后续建议

- 商品详情目前使用**自定义 SKU 选择器**（订货场景需要展示起订量与库存，Vant 的 `van-sku` 数据结构不覆盖）；若后端提供标准 SKU 树，可切换为 `van-sku`；
- **阶梯价**：需要后端在 SKU 上补区间价字段（`juling-module-product`），前端只需在 `adapters/product.ts` 接上映射，`resolvePrice` 逻辑已保留；
- **收货地址**：当前为手工填写 + 必填校验（未预填任何示例数据），建议接入地址簿接口并把确认订单页改为「选择地址」；
- **订货客户标识**：后端无 `verified` / `customerId`，「我的」页已降级为展示会员等级，待后端补齐；
- 可按需引入 `vite-plugin-legacy` 支持更老的低端安卓机；
- 若后续需要 SEO 或微信分享签名，可把 Hash 模式切为 History 模式并配置 nginx try_files。
