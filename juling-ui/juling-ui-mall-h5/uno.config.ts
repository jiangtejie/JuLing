import { createRequire } from 'node:module';
import {
  defineConfig,
  presetAttributify,
  presetIcons,
  presetWind3,
  transformerDirectives,
  transformerVariantGroup,
} from 'unocss';

const require = createRequire(import.meta.url);

/**
 * 显式注入 @iconify-json/carbon 图标数据。
 *
 * 为什么不依赖自动加载：pnpm 的严格依赖布局下，@unocss/preset-icons 内部
 * 通过文件系统动态查找 @iconify-json/* 会失败（构建时大量
 * "[unocss] failed to load icon" 警告，图标渲染为空）。
 * 显式传入 collections 则完全绕过该查找，行为稳定可预期。
 *
 * 需要新增图标集时：pnpm add -D @iconify-json/xxx，再在这里补一行。
 */
const carbonIcons = require('@iconify-json/carbon/icons.json');

export default defineConfig({
  presets: [
    // Tailwind / Windi 兼容语法（v3 语义）
    presetWind3({ dark: 'class' }),
    // 属性化模式：<div flex items-center />
    presetAttributify(),
    // 图标：class="i-carbon-shopping-cart"，按需生成，零额外请求
    presetIcons({
      scale: 1.2,
      warn: true,
      collections: {
        carbon: () => carbonIcons,
      },
      extraProperties: {
        display: 'inline-block',
        'vertical-align': 'middle',
      },
    }),
  ],

  transformers: [transformerDirectives(), transformerVariantGroup()],

  theme: {
    colors: {
      // 与 styles/variables.scss 中的 CSS 变量保持一致，换肤只需改一处
      primary: 'var(--app-primary-color)',
      success: 'var(--app-success-color)',
      warning: 'var(--app-warning-color)',
      danger: 'var(--app-danger-color)',
      'app-bg': 'var(--app-bg-color)',
      'app-text': 'var(--app-text-color)',
      'app-text-secondary': 'var(--app-text-color-secondary)',
      'app-border': 'var(--app-border-color)',
    },
  },

  shortcuts: {
    // 布局
    'flex-center': 'flex items-center justify-center',
    'flex-between': 'flex items-center justify-between',
    'flex-col-center': 'flex flex-col items-center justify-center',
    'app-page': 'min-h-screen box-border bg-app-bg',
    // 文本
    'text-ellipsis': 'overflow-hidden whitespace-nowrap text-ellipsis',
    'text-ellipsis-2':
      'overflow-hidden [display:-webkit-box] [-webkit-line-clamp:2] [-webkit-box-orient:vertical]',
    // 安全区（刘海屏 / 底部横条）
    'pb-safe': 'pb-[env(safe-area-inset-bottom)]',
    'pt-safe': 'pt-[env(safe-area-inset-top)]',
    'mb-safe': 'mb-[env(safe-area-inset-bottom)]',
    // 通用卡片
    'app-card': 'bg-white rounded-12px overflow-hidden',
  },

  // 动态拼接、模板中拼接出来的类名需要显式保留
  safelist: ['i-carbon-home', 'i-carbon-user', 'i-carbon-search', 'i-carbon-shopping-cart'],

  content: {
    pipeline: {
      include: [/\.(vue|[jt]sx?|html)($|\?)/],
      // 必须排除产物目录与依赖：否则上一轮 dist 里的压缩代码会被当成
      // 源码扫描，产生大量非法图标名与无用工具类。
      exclude: [/[\\/]node_modules[\\/]/, /[\\/]dist[\\/]/, /[\\/]\.git[\\/]/],
    },
  },
});
