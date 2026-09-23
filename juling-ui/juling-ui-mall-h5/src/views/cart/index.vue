<script setup lang="ts">
  import { showConfirmDialog, showToast } from 'vant';
  import { deleteCart, updateCartQuantity } from '@/api/cart';
  import type { CartItem } from '@/types';
  import { useCartStore } from '@/stores/cart';
  import { useUserStore } from '@/stores/user';
  import { formatPrice } from '@/utils/format';
  import { resolveImage } from '@/utils/image';

  defineOptions({ name: 'Cart' });

  const router = useRouter();
  const cartStore = useCartStore();
  const userStore = useUserStore();
  const { items, totalPrice, totalQuantity, allChecked } = storeToRefs(cartStore);

  onMounted(() => {
    // 登录态：以服务端订货单为准；拉取失败则沿用本地数据
    if (userStore.isLogin) {
      void cartStore.loadFromServer().catch(() => undefined);
    }
  });

  function onQuantityChange(item: CartItem, value: number | string): void {
    const count = Number(value);
    cartStore.updateQuantity(item.skuId, count);
    // 登录态：同步到服务端（失败不阻塞本地操作）
    if (userStore.isLogin && item.cartId) {
      void updateCartQuantity({ id: item.cartId, count }).catch(() => undefined);
    }
  }

  async function onRemove(): Promise<void> {
    const checked = items.value.filter((item) => item.checked);
    if (!checked.length) {
      showToast('请先选择要删除的商品');
      return;
    }
    await showConfirmDialog({
      title: '提示',
      message: `确认删除已选的 ${checked.length} 种商品？`,
    });
    cartStore.removeItems(checked.map((item) => item.skuId));
    // 登录态：同步删除到服务端
    if (userStore.isLogin) {
      const ids = checked
        .map((item) => item.cartId)
        .filter((id): id is number => typeof id === 'number');
      if (ids.length) void deleteCart(ids).catch(() => undefined);
    }
    showToast('已删除');
  }

  function toDetail(id: number): void {
    void router.push(`/product/${id}`);
  }

  function toConfirm(): void {
    if (!cartStore.checkedItems.length) {
      showToast('请先选择要下单的商品');
      return;
    }
    void router.push('/order/confirm');
  }
</script>

<template>
  <div class="app-page">
    <AppNavBar title="订货单" :left-arrow="false">
      <template #right>
        <span class="cart__clear" @click="onRemove">删除</span>
      </template>
    </AppNavBar>

    <div v-if="!items.length" class="cart__empty">
      <van-empty description="订货单还是空的">
        <van-button round type="primary" size="small" to="/home">去选购</van-button>
      </van-empty>
    </div>

    <template v-else>
      <div class="app-scroll cart__list">
        <div v-for="item in items" :key="item.key" class="cart__item app-card">
          <van-checkbox v-model="item.checked" class="cart__check" />

          <van-image
            class="cart__img"
            :src="resolveImage(item.picUrl)"
            fit="cover"
            radius="6"
            @click="toDetail(item.spuId)"
          />

          <div class="cart__info">
            <div class="text-ellipsis-2 cart__name" @click="toDetail(item.spuId)">
              {{ item.name }}
            </div>
            <div class="cart__spec text-ellipsis">{{ item.specText }}</div>

            <div class="flex-between mt-1">
              <PriceText :value="item.price" />
              <van-stepper
                :model-value="item.quantity"
                :min="item.minOrderQuantity"
                :max="item.stock"
                integer
                button-size="22"
                input-width="40"
                @change="(value: number | string) => onQuantityChange(item, value)"
              />
            </div>

            <div class="cart__tier">
              <van-tag v-if="item.tierPrice" type="danger">已享阶梯价</van-tag>
              <span v-if="item.tierPrice" class="cart__origin">
                原价 ¥{{ formatPrice(item.originPrice) }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- 结算栏：Vant SubmitBar，price 单位为分 -->
      <van-submit-bar
        class="cart__submit"
        :price="totalPrice"
        :button-text="`提交订货单(${totalQuantity})`"
        label="合计："
        @submit="toConfirm"
      >
        <van-checkbox v-model="allChecked">全选</van-checkbox>
      </van-submit-bar>
    </template>
  </div>
</template>

<style scoped lang="scss">
  .cart {
    &__clear {
      font-size: 14px;
      color: var(--app-danger-color);
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

    &__item {
      display: flex;
      gap: 10px;
      padding: 12px;
      margin-bottom: 10px;
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

    &__tier {
      display: flex;
      align-items: center;
      gap: 6px;
      min-height: 20px;
      margin-top: 4px;
    }

    &__origin {
      font-size: 12px;
      color: var(--app-text-color-secondary);
      text-decoration: line-through;
    }

    &__submit {
      /* van-submit-bar 自带 safe-area 处理 */
      --van-submit-bar-height: 52px;
    }
  }
</style>
