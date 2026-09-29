import type { RouteRecordRaw } from 'vue-router';

/**
 * 首页欢迎页（默认落地页）。
 *
 * 放在 `routes/modules` 下作为本地路由：后端菜单模式下，本地路由会被无条件合并进
 * 路由表与左侧菜单（见 packages/utils/src/helpers/generate-routes-backend.ts），
 * 不做权限过滤，因此**所有账号**都能看到这个入口，也都用它作为登录后的默认首页。
 *
 * 页面本身只用账号信息与「当前账号可见的菜单」渲染，不请求需要权限的接口，
 * 所以任何角色打开都不会 403 或报错。
 */
const routes: RouteRecordRaw[] = [
  {
    path: '/home',
    name: 'Home',
    component: () => import('#/views/home/index.vue'),
    meta: {
      title: '首页',
      icon: 'lucide:home',
      // 排在所有后端菜单之前
      order: -1,
      keepAlive: true,
      // 固定在标签栏，方便随时回到首页
      affixTab: true,
    },
  },
];

export default routes;
