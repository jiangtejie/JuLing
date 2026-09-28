import { onActivated, onDeactivated, onMounted } from 'vue';

/**
 * 页签缓存下的「首屏加载 + 切回刷新」。
 *
 * 背景：布局用 <KeepAlive :include="getCachedTabs"> 缓存页签，而 cachedTabs（页签缓存名单）
 * 是路由跳转之后由 tabbar store 异步写入的：首次进入某路由时组件先完成挂载，此时 include 里
 * 还没有当前路由名，KeepAlive 不会把该实例标记为「需要缓存」，Vue 挂载时也就不会触发 onActivated。
 * 因此只依赖 onActivated 做首屏加载的页面，首次进入不会发请求（首屏请求数 0），
 * 等切到别的页签再切回来时 include 已就绪，组件被缓存并激活，onActivated 才触发，数据才出现。
 *
 * 统一兜底：
 * 1. onMounted 负责首屏加载一次（首次挂载 onActivated 不会触发）；
 * 2. onDeactivated 打标记，onActivated 只在该标记存在（即「被页签缓存冻结过又切回」）时重新加载，
 *    这样首屏只请求一次，切回页签仍然刷新。
 *
 * @param loadFn 页面原有的加载逻辑（原 onActivated 的函数体）
 */
export function usePageActivateLoad(loadFn: () => Promise<void> | void) {
  onMounted(() => {
    loadFn();
  });

  /** 是否曾经被页签缓存「冻结」过，用于区分首次挂载与切回页签 */
  let deactivated = false;

  onDeactivated(() => {
    deactivated = true;
  });

  onActivated(() => {
    if (!deactivated) {
      return;
    }
    deactivated = false;
    loadFn();
  });
}
