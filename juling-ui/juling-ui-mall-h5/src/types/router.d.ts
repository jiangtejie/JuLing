import 'vue-router';

declare module 'vue-router' {
  interface RouteMeta {
    /** 页面标题（用于 document.title） */
    title?: string;
    /** 是否需要登录 */
    auth?: boolean;
    /** 是否缓存页面（组件 name 需与路由 name 一致） */
    keepAlive?: boolean;
    /** 是否显示底部 tabbar */
    tabbar?: boolean;
    /** 是否隐藏顶部导航栏（自定义导航时使用） */
    hideNavBar?: boolean;
  }
}
