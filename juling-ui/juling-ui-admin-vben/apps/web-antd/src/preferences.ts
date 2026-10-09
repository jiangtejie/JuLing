import {
  defineOverridesPreferences,
  definePreferencesExtension,
} from '@vben/preferences';

/**
 * 应用默认首页：登录后的落地页，同时也是根路径 `/` 的重定向目标。
 *
 * !!! 不要只改这里的值 !!!
 * `defaultHomePath` 属于会被持久化到 localStorage 的偏好设置（key 形如
 * `<namespace>-preferences`，即 `juling-vben-antd-<version>-dev-preferences`），
 * 而 `@core/preferences` 的 initPreferences 在做合并时是「缓存优先于代码默认值」
 * （见 packages/@core/preferences/src/preferences.ts 里的
 * `mergeWithArrayOverride({}, cachedPreferences, this.initialPreferences)`），
 * 所以老版本浏览器里残留的旧值（例如 /erp/home）会盖掉这里配置的 /home，
 * 表现为登录后、以及打开根路径都被送进 ERP 首页。
 * 因此 main.ts 启动时还会用这个常量对 app.defaultHomePath 做一次强制修正。
 */
export const DEFAULT_HOME_PATH = '/home';

interface WebAntdPreferencesExtension {
  defaultTableSize: number;
  enableFormFullscreen: boolean;
  reportTitle: string;
  tenantMode: 'multi' | 'single';
}

/**
 * @description 项目配置文件
 * 只需要覆盖项目中的一部分配置，不需要的配置不用覆盖，会自动使用默认配置
 * !!! 更改配置后请清空缓存，否则可能不生效
 */
export const overridesPreferences = defineOverridesPreferences({
  // overrides
  app: {
    /** 后端路由模式 */
    accessMode: 'backend',
    name: import.meta.env.VITE_APP_TITLE,
    enableRefreshToken: true,
    /** 默认首页：登录后跳转「首页」欢迎页（本地路由，所有账号都有；原先指向 /erp/home，需要 ERP 权限） */
    defaultHomePath: DEFAULT_HOME_PATH,
  },
  logo: {
    // 使用 BASE_URL 拼接,兼容根路径(dev)与 nginx 子路径(如 /jl)部署
    source: `${import.meta.env.BASE_URL}logo.svg`,
    sourceDark: `${import.meta.env.BASE_URL}logo.svg`,
  },
  footer: {
    /** 默认关闭 footer 页脚，因为有一定遮挡 */
    enable: false,
    fixed: false,
  },
  copyright: {
    companyName: import.meta.env.VITE_APP_TITLE,
    companySiteLink: 'https://github.com/jiangtejie/JuLing',
    icp: '',
    icpLink: '',
  },
});

export const preferencesExtension =
  definePreferencesExtension<WebAntdPreferencesExtension>({
    tabLabel: 'preferences.antd.tabLabel',
    title: 'preferences.antd.title',
    fields: [
      {
        component: 'switch',
        defaultValue: true,
        key: 'enableFormFullscreen',
        label: 'preferences.antd.fields.enableFormFullscreen.label',
        tip: 'preferences.antd.fields.enableFormFullscreen.tip',
      },
      {
        component: 'select',
        defaultValue: 'single',
        key: 'tenantMode',
        label: 'preferences.antd.fields.tenantMode.label',
        options: [
          {
            label: 'preferences.antd.fields.tenantMode.options.single.label',
            value: 'single',
          },
          {
            label: 'preferences.antd.fields.tenantMode.options.multi.label',
            value: 'multi',
          },
        ],
      },
      {
        component: 'number',
        componentProps: {
          max: 200,
          min: 10,
          step: 10,
        },
        defaultValue: 20,
        key: 'defaultTableSize',
        label: 'preferences.antd.fields.defaultTableSize.label',
      },
      {
        component: 'input',
        defaultValue: '',
        key: 'reportTitle',
        label: 'preferences.antd.fields.reportTitle.label',
        placeholder: 'preferences.antd.fields.reportTitle.placeholder',
      },
    ],
  });
