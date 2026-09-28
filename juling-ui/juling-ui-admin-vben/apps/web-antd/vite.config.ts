import { defineConfig } from '@vben/vite-config';

export default defineConfig(async () => {
  return {
    application: {},
    vite: {
      server: {
        allowedHosts: true,
        // 忽略「临时目录 + 原子改名」保存产生的中间产物，否则 Vite 的 fs.watch 会在
        // Windows 上抛 EBUSY 直接搞挂 dev server。
        // 注意两点：① 必须用函数——Vite 8 给 chokidar 传了 disableGlobbing: true，glob 写法失效；
        // ② 必须写在 app 自己的配置里——放在 internal/vite-config 的共享配置里会被合并时丢掉
        //（实测解析后的 server.watch 为 undefined，warmup 却还在）。
        watch: {
          ignored: [
            (path: string) =>
              typeof path === 'string' &&
              (path.includes('.tmpdir') || path.endsWith('.tmp')),
          ],
        },
        proxy: {
          '/admin-api': {
            changeOrigin: true,
            rewrite: (path) => path.replace(/^\/admin-api/, ''),
            // mock代理目标地址
            target: 'http://localhost:48080/admin-api',
            ws: true,
          },
        },
      },
    },
  };
});
