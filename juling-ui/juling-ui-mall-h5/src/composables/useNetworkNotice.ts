import { closeNotify, showNotify } from 'vant';
import { useAppStore } from '@/stores/app';

/**
 * 网络状态变化的全局提示（顶部 Notify 横幅）。
 *
 * 断网时常驻提示（直到网络恢复），恢复后短暂提示一次；
 * 提示文案集中在拦截器之外，避免与请求错误的 Toast 互相干扰。
 */
export function useNetworkNotice(): void {
  const appStore = useAppStore();

  watch(
    () => appStore.online,
    (online, prev) => {
      // 首次触发（组件初始化）：只处理「一进来就处于离线」，否则会莫名弹出「网络已恢复」
      if (prev === undefined) {
        if (!online) {
          showNotify({ type: 'warning', message: '当前无网络，请检查网络连接', duration: 0 });
        }
        return;
      }

      if (online) {
        closeNotify();
        showNotify({ type: 'success', message: '网络已恢复', duration: 2000 });
      } else {
        showNotify({ type: 'warning', message: '网络已断开，暂时无法加载新数据', duration: 0 });
      }
    },
    { immediate: true },
  );
}
