import { initPreferences, preferences, updatePreferences } from '@vben/preferences';
import { unmountGlobalLoading } from '@vben/utils';

import {
  DEFAULT_HOME_PATH,
  overridesPreferences,
  preferencesExtension,
} from './preferences';

/**
 * 应用初始化完成之后再进行页面加载渲染
 */
async function initApplication() {
  // name用于指定项目唯一标识
  // 用于区分不同项目的偏好设置以及存储数据的key前缀以及其他一些需要隔离的数据
  const env = import.meta.env.PROD ? 'prod' : 'dev';
  const appVersion = import.meta.env.VITE_APP_VERSION;
  const namespace = `${import.meta.env.VITE_APP_NAMESPACE}-${appVersion}-${env}`;

  // app偏好设置初始化
  await initPreferences({
    extension: preferencesExtension,
    namespace,
    overrides: overridesPreferences,
  });

  // 修正历史缓存里的默认首页：
  // initPreferences 合并偏好设置时是「缓存优先于代码默认值」，老版本浏览器里残留的
  // app.defaultHomePath（例如 /erp/home）会盖掉代码里配置的 /home，表现为登录后、
  // 以及打开根路径都被送进 ERP 首页，而不是「首页」欢迎页。
  // defaultHomePath 是应用级常量、偏好设置面板也没有修改入口，所以这里直接以代码默认值为准
  // 覆盖并写回缓存（只动这一个字段，不影响其它用户偏好设置）。
  if (preferences.app.defaultHomePath !== DEFAULT_HOME_PATH) {
    updatePreferences({ app: { defaultHomePath: DEFAULT_HOME_PATH } });
  }

  // 启动应用并挂载
  // vue应用主要逻辑及视图
  const { bootstrap } = await import('./bootstrap');
  await bootstrap(namespace);

  // 移除并销毁loading
  unmountGlobalLoading();
}

initApplication();
