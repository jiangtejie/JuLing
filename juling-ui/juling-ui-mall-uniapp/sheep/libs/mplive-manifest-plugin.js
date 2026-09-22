const fs = require('fs');
const path = require('path');

/**
 * 微信小程序「直播插件」(live-player-plugin) 开关
 *
 * - 仅在 mp-weixin 平台生效，其它平台直接跳过；
 * - 只有插件配置**确实需要变更**时才回写 manifest.json。此前是每次构建都用
 *   JSON.stringify 全量重写，导致数组被强制换行、文件末尾换行丢失，
 *   每次编译都会在 git 里留下一份无意义的格式 diff。
 * - manifest 路径改为在插件执行时（而非模块加载时）解析，避免 UNI_INPUT_DIR
 *   尚未设置时读到 undefined/manifest.json。
 */
const LIVE_PLAYER_PLUGIN = {
  version: '1.3.5',
  provider: 'wx2b03c6e691cd7370',
};

function mpliveMainfestPlugin(isOpen) {
  if (process.env.UNI_PLATFORM !== 'mp-weixin') return;

  const manifestPath = path.resolve(
    process.env.UNI_INPUT_DIR || process.cwd(),
    'manifest.json',
  );
  if (!fs.existsSync(manifestPath)) return;

  const original = fs.readFileSync(manifestPath, { encoding: 'utf-8' });
  const manifestData = JSON.parse(original);
  const plugins = manifestData['mp-weixin'] && manifestData['mp-weixin'].plugins;
  if (!plugins) return;

  let changed = false;
  if (isOpen === '0' && 'live-player-plugin' in plugins) {
    delete plugins['live-player-plugin'];
    changed = true;
  }
  if (
    isOpen === '1' &&
    JSON.stringify(plugins['live-player-plugin']) !== JSON.stringify(LIVE_PLAYER_PLUGIN)
  ) {
    plugins['live-player-plugin'] = LIVE_PLAYER_PLUGIN;
    changed = true;
  }

  if (changed) {
    fs.writeFileSync(manifestPath, JSON.stringify(manifestData, null, 2) + '\n', {
      encoding: 'utf-8',
    });
  }
}

export default mpliveMainfestPlugin
