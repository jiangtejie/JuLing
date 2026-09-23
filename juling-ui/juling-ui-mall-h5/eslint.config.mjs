import js from '@eslint/js';
import prettier from 'eslint-config-prettier';
import pluginVue from 'eslint-plugin-vue';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  {
    ignores: [
      '**/dist/**',
      '**/node_modules/**',
      '**/public/**',
      '**/.husky/**',
      '**/stats.html',
      // unplugin 自动生成，无需 lint
      'src/types/auto-imports.d.ts',
      'src/types/components.d.ts',
      // 本地工具目录（编辑器 / agent 产生的备份、快照），不参与项目 lint
      '**/.rivet/**',
    ],
  },

  js.configs.recommended,
  ...tseslint.configs.recommended,
  ...pluginVue.configs['flat/recommended'],

  {
    // .vue 文件内的 <script lang="ts"> 交给 TS 解析器
    files: ['**/*.vue'],
    languageOptions: {
      parserOptions: { parser: tseslint.parser, extraFileExtensions: ['.vue'] },
    },
  },

  {
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
    },
    rules: {
      // 自动引入（unplugin-auto-import）会让 no-undef 产生大量误报；
      // 未定义标识符由 TypeScript 保证，这里关闭基础规则。
      'no-undef': 'off',
      'no-unused-vars': 'off',
      '@typescript-eslint/no-unused-vars': [
        'error',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_', caughtErrorsIgnorePattern: '^_' },
      ],
      // 业务数据（SKU / 订单）结构复杂，允许在边界处使用 any
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/consistent-type-imports': [
        'error',
        { prefer: 'type-imports', fixStyle: 'inline-type-imports' },
      ],

      'no-console': ['warn', { allow: ['warn', 'error', 'info'] }],
      'no-debugger': 'error',

      // 页面组件用目录名命名（views/home/index.vue 等），不强制多词
      'vue/multi-word-component-names': 'off',
      'vue/require-default-prop': 'off',
      'vue/block-order': ['error', { order: ['script', 'template', 'style'] }],
      'vue/component-name-in-template-casing': ['error', 'PascalCase'],
      'vue/define-macros-order': [
        'error',
        { order: ['defineOptions', 'defineProps', 'defineEmits', 'defineSlots'] },
      ],
    },
  },

  // 配置文件 / 脚本运行在 Node 环境
  {
    files: ['*.config.{js,mjs,ts}', 'scripts/**/*.{js,mjs}'],
    rules: { 'no-console': 'off' },
  },

  prettier,
);
