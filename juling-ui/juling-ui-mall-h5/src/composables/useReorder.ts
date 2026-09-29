import { showToast } from 'vant';
import { addCart } from '@/api/cart';
import { getProductDetail } from '@/api/product';
import { useCartStore } from '@/stores/cart';
import type { Order, Product } from '@/types';

/**
 * 「再来一单」：把历史订单里的商品重新加入订货单。
 *
 * 设计要点（对齐美团的做法）：
 * 1. **不沿用订单里的历史价格与库存快照**，而是按当前商品数据重新加入——
 *    否则会把早已调价或下架的商品按旧价塞进订货单，下单时才发现问题；
 * 2. 商品已下架、规格已删除、已售罄的行项会被跳过，并告知客户跳过了几件；
 * 3. 同一 SPU 只请求一次商品详情，避免按行项重复请求；
 * 4. 数量沿用历史下单数量，但不会低于当前起订量；
 * 5. 登录态下顺带同步到服务端订货单（失败不影响本地体验）。
 */
export function useReorder() {
  const cartStore = useCartStore();
  const reordering = ref(false);

  /** 允许再来一单的订单状态：已完成 / 已取消 */
  function canReorder(order: Order | null | undefined): boolean {
    return order?.status === 'COMPLETED' || order?.status === 'CANCELED';
  }

  async function reorder(order: Order): Promise<void> {
    if (reordering.value) return;

    const items = order.items ?? [];
    if (!items.length) {
      showToast('该订单没有商品');
      return;
    }

    reordering.value = true;
    try {
      // 1. 同一 SPU 只查一次详情（商品可能已下架，失败即视为不可再订）
      const spuIds = [...new Set(items.map((item) => item.spuId))];
      const detailMap = new Map<number, Product>();
      await Promise.all(
        spuIds.map(async (spuId) => {
          try {
            detailMap.set(spuId, await getProductDetail(spuId));
          } catch {
            // 商品不存在 / 已下架：跳过，由下面的计数统一提示
          }
        }),
      );

      // 2. 逐行加入订货单，失效行项跳过
      let added = 0;
      let skipped = 0;
      for (const item of items) {
        const sku = detailMap.get(item.spuId)?.skus?.find((it) => it.id === item.skuId);
        if (!sku || (sku.stock ?? 0) <= 0) {
          skipped += 1;
          continue;
        }
        const quantity = Math.max(item.quantity, sku.minOrderQuantity ?? 1);
        cartStore.addItem({ spuId: item.spuId, sku, quantity });
        void addCart({ skuId: item.skuId, count: quantity }).catch(() => {
          // 服务端同步失败不阻塞：订货单以本地为准
        });
        added += 1;
      }

      if (added === 0) {
        showToast('商品已下架或售罄，暂时无法再来一单');
        return;
      }
      showToast(skipped > 0 ? `已加入 ${added} 件，${skipped} 件商品已失效` : '已加入订货单');
    } finally {
      reordering.value = false;
    }
  }

  return { canReorder, reorder, reordering };
}
