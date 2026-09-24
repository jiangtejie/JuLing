import placeholder from '@/assets/images/product-placeholder.svg';

/** 图片缺省值：避免接口未返回图片时出现破图 */
export function resolveImage(url?: string | null): string {
  if (!url) return placeholder;
  const trimmed = url.trim();
  return trimmed ? trimmed : placeholder;
}

export { placeholder as placeholderImage };
