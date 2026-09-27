<script setup lang="ts">
  import { showToast } from 'vant';
  import { deleteCart, updateCartQuantity } from '@/api/cart';
  import type { CartItem } from '@/types';
  import { useCartStore } from '@/stores/cart';
  import { useUserStore } from '@/stores/user';
  import { confirmDialog } from '@/utils/confirm';
  import { resolveImage } from '@/utils/image';

  defineOptions({ name: 'Cart' });

  const router = useRouter();
  const cartStore = useCartStore();
  const userStore = useUserStore();
  const { items, totalPrice, totalQuantity, allChecked } = storeToRefs(cartStore);

  /**
   * 管理模式（京东 / 美团购物车的「管理」态）：
   * 导航栏右上角切换，开启后行点击改为勾选、底部按钮由「提交订货单」变为「删除」。
   */
  const managing = ref(false);
  const checkedCount = computed(() => cartStore.checkedItems.length);

  onMounted(() => {
    // 登录态：以服务端订货单为准；拉取失败则沿用本地数据
    if (userStore.isLogin) {
      void cartStore.loadFromServer().catch((error) => {
        console.warn('[cart] 拉取服务端订货单失败:', error);
      });
    }
  });

  // 删空后自动退出管理模式，避免底部停在「删除」而页面已经空了
  watch(
    () => items.value.length,
    (len) => {
      if (!len) managing.value = false;
    },
  );

  function toggleManage(): void {
    managing.value = !managing.value;
  }

  /** 行点击：普通态进商品详情，管理态切换勾选（与京东购物车一致） */
  function onRowClick(item: CartItem): void {
    if (managing.value) {
      item.checked = !item.checked;
      return;
    }
    void router.push(`/product/${item.spuId}`);
  }

  function onQuantityChange(item: CartItem, value: number | string): void {
    const count = Number(value);
    cartStore.updateQuantity(item.skuId, count);
    // 登录态：同步到服务端（失败不阻塞本地操作）
    if (userStore.isLogin && item.cartId) {
      void updateCartQuantity({ id: item.cartId, count }).catch((error) => {
        console.warn('[cart] 同步数量失败:', error);
      });
    }
  }

  /**
   * 删除行项：本地立即生效，登录态异步同步服务端。
   * 左滑删除与管理态批量删除共用这一段，避免两处逻辑各写一遍。
   */
  async function removeItems(targets: CartItem[], tip: string): Promise<void> {
    if (!targets.length) return;
    if (!(await confirmDialog(tip))) return;

    cartStore.removeItems(targets.map((item) => item.skuId));

    if (userStore.isLogin) {
      const ids = targets
        .map((item) => item.cartId)
        .filter((id): id is number => typeof id === 'number');
      if (ids.length) {
        void deleteCart(ids).catch((error) => {
          console.warn('[cart] 同步删除失败:', error);
        });
      }
    }
    showToast('已删除');
  }

  /** 左滑删除单行 */
  function onRemoveOne(item: CartItem): void {
    void removeItems([item], `确认删除「${item.name}」？`);
  }

  /** 管理态：删除已勾选行项 */
  function onRemoveChecked(): void {
    const checked = cartStore.checkedItems;
    if (!checked.length) {
      showToast('请先选择要删除的商品');
      return;
    }
    void removeItems(checked, `确认删除已选的 ${checked.length} 种商品？`);
  }

  function toConfirm(): void {
    if (!cartStore.checkedItems.length) {
      showToast('请先选择要下单的商品');
      return;
    }
    void router.push('/order/confirm');
  }

  /** 底部按钮：普通态提交订货单，管理态删除 */
  function onSubmit(): void {
    if (managing.value) onRemoveChecked();
    else toConfirm();
  }
</script>

<template>
  <div class="app-page">
    <AppNavBar title="订货单" :left-arrow="false">
      <template #right>
        <!-- 有商品才给「管理」入口；原先把「删除」直接放在这里，既危险又容易被误触 -->
        <span v-if="items.length" class="cart__manage" @click="toggleManage">
          {{ managing ? '完成' : '管理' }}
        </span>
      </template>
    </AppNavBar>

    <div v-if="!items.length" class="cart__empty">
      <van-empty description="订货单还是空的">
        <van-button round type="primary" size="small" to="/home">去选购</van-button>
      </van-empty>
    </div>

    <template v-else>
      <div class="app-scroll cart__list">
        <!-- 左滑删除（美团 / 京东购物车的通用手势） -->
        <van-swipe-cell v-for="item in items" :key="item.key" class="cart__swipe">
          <div class="cart__item app-card" @click="onRowClick(item)">
            <van-checkbox v-model="item.checked" class="cart__check" @click.stop />

            <van-image
              class="cart__img"
              :src="resolveImage(item.picUrl)"
              fit="cover"
              radius="6"
              lazy-load
            />

            <div class="cart__info">
              <div class="text-ellipsis-2 cart__name">{{ item.name }}</div>
              <div class="cart__spec text-ellipsis">{{ item.specText }}</div>

              <div class="flex-between mt-1">
                <PriceText :value="item.price" />
                <!-- 数量控件自成一区，点它不要触发行点击 -->
                <span @click.stop>
                  <van-stepper
                    :model-value="item.quantity"
                    :min="item.minOrderQuantity"
                    :max="item.stock"
                    integer
                    button-size="22"
                    input-width="40"
                    @change="(value: number | string) => onQuantityChange(item, value)"
                  />
                </span>
              </div>
            </div>
          </div>

          <template #right>
            <van-button
              square
              type="danger"
              class="cart__swipe-del"
              text="删除"
              @click="onRemoveOne(item)"
            />
          </template>
        </van-swipe-cell>
      </div>

      <!--
        结算栏：Vant SubmitBar，price 单位为分。
        管理态下不显示金额，按钮换成「删除(N)」并只在有勾选时可用。
      -->
      <van-submit-bar
        class="cart__submit"
        :price="managing ? undefined : totalPrice"
        :button-text="managing ? `删除(${checkedCount})` : `提交订货单(${totalQuantity})`"
        :button-type="managing ? 'danger' : 'primary'"
        :disabled="managing && !checkedCount"
        label="合计："
        @submit="onSubmit"
      >
        <van-checkbox v-model="allChecked">全选</van-checkbox>
      </van-submit-bar>
    </template>
  </div>
</template>

<style scoped lang="scss">
  .cart {
    &__manage {
      font-size: 14px;
      color: var(--app-primary-color);
    }

    &__empty {
      display: flex;
      flex: 1;
      align-items: center;
      justify-content: center;
    }

    &__list {
      padding: 12px 12px 60px;
    }

    /* 行间距交给滑动单元，卡片与左滑出来的按钮才能同高 */
    &__swipe {
      margin-bottom: 10px;

      /* 按钮宽度是 vw 换算来的小数，Vant 默认「右移 100%」正好贴在单元格边缘，
         在 dpr=2 下会漏出约 1px 的红边；额外外推 1px 把它完全藏进裁剪区 */
      :deep(.van-swipe-cell__right) {
        display: flex;
        transform: translate3d(calc(100% + 1px), 0, 0);
      }
    }

    &__swipe-del {
      height: 100%;
      border-radius: 0 var(--app-radius-md) var(--app-radius-md) 0;
    }

    &__item {
      display: flex;
      gap: 10px;
      padding: 12px;
    }

    &__check {
      flex: none;
      align-self: center;
    }

    &__img {
      flex: none;
      width: 76px;
      height: 76px;
    }

    &__info {
      flex: 1;
      min-width: 0;
    }

    &__name {
      font-size: 14px;
      line-height: 1.4;
    }

    &__spec {
      margin-top: 2px;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__submit {
      /* van-submit-bar 自带 safe-area 处理 */
      --van-submit-bar-height: 52px;
    }
  }
</style>
