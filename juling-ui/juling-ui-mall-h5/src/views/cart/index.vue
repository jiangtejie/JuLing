<script setup lang="ts">
  import { AnimatePresence, motion } from 'motion-v';
  import { showToast } from 'vant';
  import { deleteCart, updateCartQuantity } from '@/api/cart';
  import type { CartItem, InvalidCartItem } from '@/types';
  import { useCartStore } from '@/stores/cart';
  import { useUserStore } from '@/stores/user';
  import { confirmDialog } from '@/utils/confirm';
  import { resolveImage } from '@/utils/image';

  defineOptions({ name: 'Cart' });

  const router = useRouter();
  const cartStore = useCartStore();
  const userStore = useUserStore();
  const { items, invalidItems, totalPrice, totalQuantity, allChecked } = storeToRefs(cartStore);

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

  /* ------------------------------- 失效商品 ------------------------------- */

  /**
   * 失效商品（后端 invalidList）。
   *
   * 单独成组、灰显并给出失效原因：门店才能明白「为什么少了一件」而不是莫名少了。
   * 这批行项不参与勾选与结算（adapter 已强制 checked: false），只提供「移除」。
   */
  function onRemoveInvalidOne(item: InvalidCartItem): void {
    // SPU 已被删除时 name 可能为空，退回规格文案兜底，避免出现「确认移除「」？」
    const label = item.name || item.specText || '该商品';
    void removeItems([item], `确认从订货单移除「${label}」？`);
  }

  /** 一键清空失效商品（确认后本地 + 服务端一起删） */
  function onRemoveInvalid(): void {
    const count = invalidItems.value.length;
    if (!count) return;
    void removeItems([...invalidItems.value], `确认移除全部 ${count} 件失效商品？`);
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

    <!-- 有效项与失效项都没有才算空；只剩失效商品时也要展示分组（否则「为什么空了」无从解释） -->
    <div v-if="!items.length && !invalidItems.length" class="cart__empty">
      <van-empty description="订货单还是空的">
        <van-button round type="primary" size="small" to="/home">去选购</van-button>
      </van-empty>
    </div>

    <template v-else>
      <div
        class="app-scroll cart__list"
        :class="{ 'cart__list--with-invalid': invalidItems.length }"
      >
        <!--
          左滑删除（美团 / 京东购物车的通用手势）。
          删除时由 AnimatePresence 播放退出动画：高度与下边距一起收起到 0，
          否则行项会「瞬间消失」，被删掉的是哪一行看不清楚。
        -->
        <AnimatePresence>
          <motion.div
            v-for="item in items"
            :key="item.key"
            class="cart__swipe-wrap"
            :exit="{ opacity: 0, height: 0, marginBottom: 0 }"
            :transition="{ duration: 0.22, ease: 'easeOut' }"
          >
            <van-swipe-cell class="cart__swipe">
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
          </motion.div>
        </AnimatePresence>

        <!--
          失效商品分组（京东 / 美团购物车同款）：灰显 + 失效原因 + 移除。
          这些商品不能下单，所以不参与勾选与结算，只在底部提示「已排除 N 件」。
        -->
        <div v-if="invalidItems.length" class="cart__invalid">
          <div class="flex-between cart__invalid-head">
            <span class="cart__invalid-title">失效商品 {{ invalidItems.length }} 件</span>
            <span class="cart__invalid-clear" @click="onRemoveInvalid">清空失效商品</span>
          </div>

          <div v-for="item in invalidItems" :key="item.key" class="cart__invalid-item app-card">
            <van-image
              class="cart__img cart__invalid-img"
              :src="resolveImage(item.picUrl)"
              fit="cover"
              radius="6"
              lazy-load
            />
            <div class="cart__info">
              <div class="cart__invalid-name-row">
                <span class="cart__invalid-tag">失效</span>
                <span class="text-ellipsis-2 cart__name cart__invalid-name">{{ item.name }}</span>
              </div>
              <div class="cart__spec text-ellipsis">{{ item.specText }}</div>
              <div class="cart__invalid-reason">{{ item.invalidReason }}</div>
            </div>
            <van-button
              class="cart__invalid-remove"
              size="mini"
              round
              plain
              type="danger"
              text="移除"
              @click.stop="onRemoveInvalidOne(item)"
            />
          </div>
        </div>
      </div>

      <!--
        结算栏：Vant SubmitBar，price 单位为分。
        管理态下不显示金额，按钮换成「删除(N)」并只在有勾选时可用。
      -->
      <van-submit-bar
        v-if="items.length"
        class="cart__submit"
        :price="managing ? undefined : totalPrice"
        :button-text="managing ? `删除(${checkedCount})` : `提交订货单(${totalQuantity})`"
        :button-type="managing ? 'danger' : 'primary'"
        :disabled="managing && !checkedCount"
        label="合计："
        @submit="onSubmit"
      >
        <!-- 结算按钮上方说明差额来源：少的那几件是失效商品，不是被系统吞了 -->
        <template #top>
          <div v-if="invalidItems.length" class="cart__invalid-tip">
            有 {{ invalidItems.length }} 件失效商品已排除，不参与本次结算
          </div>
        </template>
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

    /* 退出动画需要一个可收起的包裹层：行间距放在这里，收起时一并归零 */
    &__swipe-wrap {
      margin-bottom: 10px;
      overflow: hidden;
    }

    /* 卡片与左滑出来的按钮才能同高 */
    &__swipe {
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

    /* 底部多了「失效商品已排除」提示行时，列表再往上让出这行高度 */
    &__list--with-invalid {
      padding-bottom: 88px;
    }

    /* ------------------------------ 失效商品分组 ------------------------------ */

    &__invalid {
      padding-top: 4px;
    }

    &__invalid-head {
      align-items: baseline;
      padding: 8px 2px;
    }

    &__invalid-title {
      font-size: 13px;
      font-weight: 600;
    }

    &__invalid-clear {
      font-size: 12px;
      color: var(--app-primary-color);
    }

    &__invalid-item {
      display: flex;
      align-items: center;
      gap: 10px;
      margin-bottom: 10px;
      padding: 12px;
    }

    /* 失效商品整体降饱和，一眼与可下单行项区分开 */
    &__invalid-img {
      opacity: 0.45;
      filter: grayscale(1);
    }

    &__invalid-name-row {
      display: flex;
      align-items: flex-start;
      gap: 4px;
    }

    &__invalid-name {
      flex: 1;
      min-width: 0;
      color: var(--app-text-color-secondary);
    }

    &__invalid-tag {
      flex: none;
      padding: 0 4px;
      font-size: 10px;
      line-height: 15px;
      color: var(--app-text-color-secondary);
      border: 1px solid var(--app-border-color);
      border-radius: 4px;
    }

    &__invalid-reason {
      margin-top: 2px;
      font-size: 12px;
      color: var(--app-danger-color);
    }

    &__invalid-remove {
      flex: none;
    }

    /* 结算栏上方：说明「少了的商品去哪了」 */
    &__invalid-tip {
      padding: 6px 16px;
      font-size: 12px;
      color: var(--app-warning-color);
      text-align: center;
      background: #fffbe8;
    }

    &__submit {
      /* van-submit-bar 自带 safe-area 处理 */
      --van-submit-bar-height: 52px;
    }
  }
</style>
