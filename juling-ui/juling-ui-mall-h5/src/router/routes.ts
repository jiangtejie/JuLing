import type { RouteRecordRaw } from 'vue-router';

/**
 * 路由表。
 *
 * 说明：
 * - 采用 Hash 模式（见 router/index.ts），在公众号 / APP WebView 中无需服务端 rewrite，
 *   兼容性最好；
 * - meta.tabbar 控制底部导航是否展示；
 * - meta.keepAlive 需要组件通过 defineOptions({ name }) 声明与路由 name 一致的名字；
 * - meta.auth 为 true 的路由未登录时会被守卫重定向到登录页。
 */
export const routes: RouteRecordRaw[] = [
  {
    path: '/',
    redirect: '/home',
  },
  {
    path: '/home',
    name: 'Home',
    component: () => import('@/views/home/index.vue'),
    meta: { title: '首页', tabbar: true, keepAlive: true },
  },
  {
    path: '/category',
    name: 'Category',
    component: () => import('@/views/category/index.vue'),
    meta: { title: '分类', tabbar: true, keepAlive: true },
  },
  {
    path: '/cart',
    name: 'Cart',
    component: () => import('@/views/cart/index.vue'),
    meta: { title: '订货单', tabbar: true, keepAlive: true },
  },
  {
    path: '/user',
    name: 'User',
    component: () => import('@/views/user/index.vue'),
    meta: { title: '我的', tabbar: true, keepAlive: true },
  },

  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/index.vue'),
    meta: { title: '登录' },
  },

  {
    path: '/product/list',
    name: 'ProductList',
    component: () => import('@/views/product/list.vue'),
    meta: { title: '商品列表' },
  },
  {
    path: '/product/:id',
    name: 'ProductDetail',
    component: () => import('@/views/product/detail.vue'),
    meta: { title: '商品详情' },
  },

  {
    path: '/order/confirm',
    name: 'OrderConfirm',
    component: () => import('@/views/order/confirm.vue'),
    meta: { title: '确认订单', auth: true },
  },
  {
    path: '/order/list',
    name: 'OrderList',
    component: () => import('@/views/order/list.vue'),
    meta: { title: '我的订单', auth: true },
  },
  {
    path: '/order/:id',
    name: 'OrderDetail',
    component: () => import('@/views/order/detail.vue'),
    meta: { title: '订单详情', auth: true },
  },

  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('@/views/error/404.vue'),
    meta: { title: '页面不存在' },
  },
];
