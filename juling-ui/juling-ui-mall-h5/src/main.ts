import { createApp } from 'vue';
import { showToast } from 'vant';

// 原子化 CSS：reset 在前，工具类在后
import '@unocss/reset/tailwind-compat.css';
import 'virtual:uno.css';

// Vant 函数式组件（Toast / Dialog / Notify / ImagePreview）是按需引入的漏网之鱼，
// 组件式用法由 unplugin-vue-components 自动带样式，函数式调用需要显式引入样式。
import 'vant/es/toast/style';
import 'vant/es/dialog/style';
import 'vant/es/notify/style';
import 'vant/es/image-preview/style';

import './styles/index.scss';

import App from './App.vue';
import { setupPwa } from './pwa';
import { setupRouter } from './router';
import { setupStore } from './stores';

function bootstrap(): void {
  const app = createApp(App);

  // 全局错误兜底：组件内未捕获的异常不至于「白屏且无任何提示」
  app.config.errorHandler = (err, _instance, info) => {
    console.error('[app] 未捕获异常:', err, info);
    showToast({ message: '页面出现异常，请稍后重试', duration: 2000 });
  };

  setupStore(app);
  setupRouter(app);
  setupPwa();

  app.mount('#app');

  // 移除 index.html 中的首屏 loading 占位
  document.getElementById('app-loading')?.remove();
}

bootstrap();
