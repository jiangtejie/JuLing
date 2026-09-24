import placeholder from '@/assets/images/product-placeholder.svg';
import { normalizeAssetUrl } from '@/utils/asset';

/**
 * 图片地址：先做「内网 / 本机绝对地址 → 同源相对路径」的归一化
 * （见 `utils/asset.ts` 的说明），再兜底为本地占位图，避免接口未返回图片时破图。
 */
export function resolveImage(url?: string | null): string {
  return normalizeAssetUrl(url) || placeholder;
}

export { placeholder as placeholderImage };
