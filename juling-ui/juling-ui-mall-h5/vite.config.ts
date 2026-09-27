import { fileURLToPath, URL } from 'node:url';

import { VantResolver } from '@vant/auto-import-resolver';
import vue from '@vitejs/plugin-vue';
import { visualizer } from 'rollup-plugin-visualizer';
import UnoCSS from 'unocss/vite';
import AutoImport from 'unplugin-auto-import/vite';
import Components from 'unplugin-vue-components/vite';
import { defineConfig, loadEnv, type PluginOption } from 'vite';
import { compression } from 'vite-plugin-compression2';
import { VitePWA } from 'vite-plugin-pwa';

const projectRoot = fileURLToPath(new URL('./', import.meta.url));

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, projectRoot, 'VITE_');

  // 部署基础路径：生产构建部署在 /jl-mall/ 子路径下（对应 nginx 的 location /jl-mall/），
  // 开发环境保持根路径以简化本地调试；需要别的前缀时用 VITE_BASE 覆盖。
  const basePath = env.VITE_BASE || (mode === 'development' ? '/' : '/jl-mall/');

  const isBuild = mode !== 'development';
  const isReport = mode === 'report' || env.VITE_REPORT === 'true';
  const enableProxy = env.VITE_USE_PROXY === 'true';
  const apiPrefix = env.VITE_API_PREFIX || '/app-api';
  const proxyTarget = env.VITE_API_PROXY_TARGET || 'http://127.0.0.1:48080';
  const enablePwa = env.VITE_PWA === 'true';
  const dropConsole = env.VITE_DROP_CONSOLE === 'true';

  const plugins: PluginOption[] = [
    vue(),

    // 原子化 CSS
    UnoCSS(),

    /**
     * 自动按需引入 Vue / Vue Router / Pinia / VueUse API
     * 同时自动引入 src/composables 与 src/stores 下的自定义组合式函数，
     * 生成的类型声明写入 src/types/auto-imports.d.ts
     */
    AutoImport({
      imports: [
        'vue',
        'vue-router',
        'pinia',
        {
          '@vueuse/core': [
            'useDebounceFn',
            'useThrottleFn',
            'useEventListener',
            'useIntersectionObserver',
            'useLocalStorage',
            'useOnline',
            'useScroll',
            'useSessionStorage',
            'useWindowSize',
            'useClipboard',
          ],
        },
      ],
      dirs: ['src/composables', 'src/stores'],
      dts: 'src/types/auto-imports.d.ts',
      // 模板中也能使用（如 $route 之外的自动引入函数）
      vueTemplate: true,
      // 函数式组件（showToast / showDialog ...）也走 Vant 解析器，自动带上样式
      resolvers: [VantResolver()],
    }),

    // 自动按需引入组件（Vant 4 + src/components 下的本地组件）
    Components({
      dirs: ['src/components'],
      extensions: ['vue'],
      deep: true,
      dts: 'src/types/components.d.ts',
      resolvers: [VantResolver()],
    }),

    // PWA：Workbox 生成 Service Worker，实现离线访问
    VitePWA({
      disable: !enablePwa,
      registerType: 'autoUpdate',
      includeAssets: ['favicon.svg', 'apple-touch-icon.png', 'robots.txt'],
      manifest: {
        name: '亚特订货商城',
        short_name: '亚特商城',
        description: '亚特 · 移动端订货商城',
        lang: 'zh-CN',
        start_url: basePath,
        scope: basePath,
        display: 'standalone',
        orientation: 'portrait',
        theme_color: '#0081ff',
        background_color: '#f6f6f6',
        icons: [
          { src: 'pwa-192x192.png', sizes: '192x192', type: 'image/png' },
          { src: 'pwa-512x512.png', sizes: '512x512', type: 'image/png' },
          {
            src: 'pwa-maskable-512x512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'maskable',
          },
        ],
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,svg,webp,woff,woff2}'],
        // 体积分析报告只用于本地排查，不进入预缓存
        globIgnores: ['**/stats.html'],
        // 单文件预缓存体积上限（图片资源较多时可适当调大）
        maximumFileSizeToCacheInBytes: 4 * 1024 * 1024,
        cleanupOutdatedCaches: true,
        clientsClaim: true,
        skipWaiting: true,
        navigateFallback: `${basePath}index.html`,
        // 接口请求不要被导航回退拦截
        navigateFallbackDenylist: [/^\/app-api/, /^\/infra/, /^\/admin-api/],
        runtimeCaching: [
          {
            // 商品图片等静态资源：缓存优先
            urlPattern: /\.(?:png|jpe?g|webp|gif|svg|woff2?)$/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'static-assets',
              expiration: { maxEntries: 300, maxAgeSeconds: 60 * 60 * 24 * 30 },
              cacheableResponse: { statuses: [0, 200] },
            },
          },
          {
            // 商品详情等读接口：网络优先，断网回退缓存
            urlPattern: ({ url }) => url.pathname.startsWith(apiPrefix),
            handler: 'NetworkFirst',
            method: 'GET',
            options: {
              cacheName: 'api-get',
              networkTimeoutSeconds: 5,
              expiration: { maxEntries: 100, maxAgeSeconds: 60 * 60 * 24 },
              cacheableResponse: { statuses: [0, 200] },
            },
          },
        ],
      },
      devOptions: { enabled: false },
    }),
  ];

  // Brotli / Gzip 预压缩（配合 nginx gzip_static / brotli_static）
  if (isBuild) {
    plugins.push(
      compression({
        algorithms: ['brotliCompress', 'gzip'],
        threshold: 1024,
        deleteOriginalAssets: false,
      }),
    );
  }

  // 打包体积可视化：pnpm build:report
  if (isReport) {
    plugins.push(
      visualizer({
        filename: 'dist/stats.html',
        gzipSize: true,
        brotliSize: true,
        open: false,
        template: 'treemap',
      }) as PluginOption,
    );
  }

  return {
    base: basePath,

    plugins,

    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url)),
      },
    },

    /**
     * 预构建白名单。
     *
     * 只被懒加载路由引入的依赖（如 motion-v）如果留给 Vite 在运行中发现，会触发一次
     * 「重新预构建」：依赖哈希随之变化，已经打开的页面在下一次懒加载新路由时就会拿到
     * 504 Outdated Optimize Dep，浏览器侧表现为
     * 「Failed to fetch dynamically imported module」，只能刷新页面才能恢复。
     * 显式列进来，让它们在 dev server 启动时一次性预构建好。
     */
    optimizeDeps: {
      include: ['motion-v'],
    },

    css: {
      devSourcemap: false,
    },

    esbuild: {
      drop: dropConsole ? ['console', 'debugger'] : [],
    },

    server: {
      host: '0.0.0.0',
      port: Number(env.VITE_PORT) || 3001,
      open: false,
      // Windows 上部分编辑器/工具采用「临时目录 + 原子改名」保存文件，会短暂产生
      // 形如 `.<name>.vue.<pid>.<guid>.tmpdir/<name>.vue.tmp` 的路径。Vite 的 fs.watch
      // 会尝试监听这个转瞬即逝且被占用的临时文件，抛 EBUSY 后整个 dev server 进程退出。
      // 把这类中间产物排除在监听之外。
      watch: {
        ignored: ['**/*.tmpdir/**', '**/*.tmp'],
      },
      proxy: enableProxy
        ? {
            [apiPrefix]: {
              target: proxyTarget,
              changeOrigin: true,
              ws: true,
            },
            // 图片等文件资源由后端返回的 /admin-api 路径承载（yudao 文件服务）。
            // 生产环境由 nginx 承担同样的转发（location /admin-api/），开发环境补上这条
            // 才能让 resolveImage 归一化后的相对路径有处可去。
            '/admin-api': {
              target: proxyTarget,
              changeOrigin: true,
            },
          }
        : undefined,
    },

    preview: {
      host: '0.0.0.0',
      port: 4173,
    },

    build: {
      // 兼顾公众号 / APP WebView（安卓 5+、iOS 12+）的兼容性
      target: 'es2015',
      cssTarget: 'chrome61',
      outDir: 'dist',
      assetsDir: 'assets',
      sourcemap: false,
      reportCompressedSize: false,
      chunkSizeWarningLimit: 1500,
      rollupOptions: {
        output: {
          chunkFileNames: 'assets/js/[name]-[hash].js',
          entryFileNames: 'assets/js/[name]-[hash].js',
          assetFileNames: 'assets/[ext]/[name]-[hash].[ext]',
          manualChunks(id) {
            if (!id.includes('node_modules')) return;
            if (id.includes('vant')) return 'vant';
            if (id.includes('lodash')) return 'lodash';
            if (id.includes('@vueuse')) return 'vueuse';
            if (id.includes('axios')) return 'axios';
            if (/[\\/]node_modules[\\/](vue|@vue|vue-router|pinia)[\\/]/.test(id)) {
              return 'vue';
            }
            return 'vendor';
          },
        },
      },
    },
  };
});
