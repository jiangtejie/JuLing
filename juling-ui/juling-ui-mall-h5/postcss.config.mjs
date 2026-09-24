export default {
  plugins: {
    // 移动端适配核心：把设计稿上的 px 自动换算成 vw。
    // 设计稿基准宽度 375（Vant 4 组件库同样以 375 为基准，无需 exclude）。
    // 若设计稿是 750 宽，把 viewportWidth 改为 750 即可。
    'postcss-px-to-viewport-8-plugin': {
      unitToConvert: 'px',
      viewportWidth: 375,
      unitPrecision: 5,
      propList: ['*'],
      viewportUnit: 'vw',
      fontViewportUnit: 'vw',
      // 命中这些类名的选择器不做换算（用于少数需要固定 px 的场景）
      selectorBlackList: ['.ignore-vw', '.no-vw', '.keep-px'],
      // 1px 边框保持 1px，避免高分屏下细线消失
      minPixelValue: 1,
      mediaQuery: true,
      replace: true,
      exclude: [],
      landscape: false,
    },
    autoprefixer: {},
  },
};
