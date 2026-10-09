import type { CSSOptions, UserConfig } from 'vite';

import type { DefineApplicationOptions } from '../typing';

import path, { relative } from 'node:path';

import { findMonorepoRoot } from '@vben/node-utils';

import { NodePackageImporter } from 'sass-embedded';
import { defineConfig, loadEnv, mergeConfig } from 'vite';

import { defaultImportmapOptions, getDefaultPwaOptions } from '../options';
import { loadApplicationPlugins } from '../plugins';
import { loadAndConvertEnv } from '../utils/env';
import { getCommonConfig } from './common';

function defineApplicationConfig(userConfigPromise?: DefineApplicationOptions) {
  return defineConfig(async (config) => {
    const options = await userConfigPromise?.(config);
    const { appTitle, base, port, ...envConfig } = await loadAndConvertEnv();
    const { command, mode } = config;
    const { application = {}, vite = {} } = options || {};
    const root = process.cwd();
    const isBuild = command === 'build';
    const env = loadEnv(mode, root);

    const plugins = await loadApplicationPlugins({
      archiver: true,
      archiverPluginOptions: {},
      compress: false,
      compressTypes: ['brotli', 'gzip'],
      devtools: true,
      env,
      extraAppConfig: true,
      html: true,
      i18n: true,
      importmapOptions: defaultImportmapOptions,
      injectAppLoading: true,
      injectMetadata: true,
      isBuild,
      license: true,
      mode,
      nitroMock: !isBuild,
      nitroMockOptions: {},
      print: !isBuild,
      printInfoMap: {
        Docs: 'https://github.com/jiangtejie/JuLing#readme',
      },
      pwa: true,
      pwaOptions: getDefaultPwaOptions(appTitle),
      vxeTableLazyImport: true,
      ...envConfig,
      ...application,
    });

    const { injectGlobalScss = true } = application;

    const applicationConfig: UserConfig = {
      base,
      build: {
        rolldownOptions: {
          output: {
            assetFileNames: '[ext]/[name]-[hash].[ext]',
            chunkFileNames: 'js/[name]-[hash].js',
            entryFileNames: 'jse/index-[name]-[hash].js',
            minify: isBuild
              ? {
                  compress: {
                    dropDebugger: true,
                  },
                }
              : false,
          },
        },
        target: 'es2015',
      },
      css: createCssOptions(injectGlobalScss),
      plugins,
      server: {
        host: true,
        port,
        // 关于 server.watch.ignored（忽略「临时目录 + 原子改名」产生的 .tmpdir/.tmp，
        // 否则 Windows 上 fs.watch 抛 EBUSY 会直接搞挂 dev server）：
        // 该键写在这里**不生效**——实测解析后的 server.watch 为 undefined（warmup 却保留），
        // 会被后续 mergeConfig 丢掉。请写在各自 app 的 vite.config.ts 里，
        // 参考 apps/web-antd/vite.config.ts 的 server.watch.ignored（用函数，不能用 glob）。
        warmup: {
          // 预热文件
          clientFiles: [
            './index.html',
            './src/bootstrap.ts',
            './src/{views,layouts,router,store,api,adapter}/*',
          ],
        },
      },
    };

    const mergedCommonConfig = mergeConfig(
      await getCommonConfig(),
      applicationConfig,
    );
    return mergeConfig(mergedCommonConfig, vite);
  });
}

function createCssOptions(injectGlobalScss = true): CSSOptions {
  const root = findMonorepoRoot();
  return {
    preprocessorOptions: injectGlobalScss
      ? {
          scss: {
            additionalData: (content: string, filepath: string) => {
              const relativePath = relative(root, filepath);
              // apps下的包注入全局样式
              if (relativePath.startsWith(`apps${path.sep}`)) {
                return `@use "@vben/styles/global" as *;\n${content}`;
              }
              return content;
            },
            // api: 'modern',
            importers: [new NodePackageImporter()],
          },
        }
      : {},
  };
}

export { defineApplicationConfig };
