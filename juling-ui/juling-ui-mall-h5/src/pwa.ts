import { registerSW } from 'virtual:pwa-register';
import { showToast } from 'vant';

/**
 * 注册 Service Worker（生产环境 + VITE_PWA=true 时生效）。
 * 采用 autoUpdate 策略：检测到新版本后自动更新，并提示用户刷新。
 */
export function setupPwa(): void {
  if (import.meta.env.DEV || import.meta.env.VITE_PWA !== 'true') return;

  try {
    registerSW({
      immediate: true,
      onOfflineReady() {
        showToast('资源已缓存，可离线访问');
      },
      onRegisterError(error) {
        console.error('[pwa] Service Worker 注册失败:', error);
      },
    });
  } catch (error) {
    console.error('[pwa] 初始化失败:', error);
  }
}
