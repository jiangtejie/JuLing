import type { RouteRecordRaw } from 'vue-router';

// OA 请假相关路由配置
const routes: RouteRecordRaw[] = [
  {
    path: '/bpm/oa',
    name: 'OALeave',
    // 注意：redirect 必须放在路由记录顶层。放在 meta 里 vue-router 不会读取，
    // 只会让 /bpm/oa 命中这个没有 component 的父路由，渲染出空白页。
    // 目标必须是真实存在的子路由地址（子路由定义在下方：path: 'leave'）。
    redirect: '/bpm/oa/leave',
    meta: {
      title: 'OA请假',
      hideInMenu: true,
    },
    children: [
      {
        path: 'leave',
        name: 'OALeaveIndex',
        component: () => import('#/views/bpm/oa/leave/index.vue'),
        meta: {
          title: '请假列表',
          activePath: '/bpm/oa/leave',
        },
      },
      {
        path: 'leave/create',
        name: 'OALeaveCreate',
        component: () => import('#/views/bpm/oa/leave/create.vue'),
        meta: {
          title: '创建请假',
          activePath: '/bpm/oa/leave',
        },
      },
      {
        path: 'leave/detail',
        name: 'OALeaveDetail',
        component: () => import('#/views/bpm/oa/leave/detail.vue'),
        meta: {
          title: '请假详情',
          activePath: '/bpm/oa/leave',
        },
      },
    ],
  },
];

export default routes;
