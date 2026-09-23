<script setup lang="ts">
  import { showSuccessToast, showToast } from 'vant';
  import { createOrder } from '@/api/order';
  import { DEFAULT_ADDRESS } from '@/constants';
  import { useCartStore } from '@/stores/cart';
  import { formatPrice } from '@/utils/format';
  import { resolveImage } from '@/utils/image';

  defineOptions({ name: 'OrderConfirm' });

  const router = useRouter();
  const cartStore = useCartStore();
  const { checkedItems, totalPrice, totalQuantity } = storeToRefs(cartStore);

  const remark = ref('');
  const address = reactive({ ...DEFAULT_ADDRESS });

  async function onSubmit(): Promise<void> {
    if (!checkedItems.value.length) {
      showToast('请先选择要下单的商品');
      return;
    }

    try {
      await createOrder({
        items: checkedItems.value.map((item) => ({
          skuId: item.skuId,
          quantity: item.quantity,
        })),
        receiverName: address.name,
        receiverMobile: address.mobile,
        receiverAddress: address.address,
        remark: remark.value,
      });
    } catch {
      return;
    }

    cartStore.clearChecked();
    showSuccessToast('订货单提交成功');
    await router.replace('/order/list');
  }

  const { loading, run } = useSubmit(onSubmit);

  onMounted(() => {
    // 排序：先展示已勾选商品
    if (!checkedItems.value.length && cartStore.items.length) {
      showToast('请先在订货单中勾选商品');
    }
  });
</script>

<template>
  <div class="app-page order-confirm">
    <AppNavBar title="确认订单" />

    <div class="app-scroll">
      <!-- 收货信息 -->
      <van-cell-group inset class="order-confirm__group">
        <van-field
          v-model="address.name"
          label="收货人"
          placeholder="请输入收货人姓名"
          input-align="right"
        />
        <van-field
          v-model="address.mobile"
          label="联系电话"
          type="tel"
          placeholder="请输入联系电话"
          input-align="right"
        />
        <van-field
          v-model="address.address"
          label="收货地址"
          type="textarea"
          rows="2"
          autosize
          placeholder="请输入详细收货地址"
        />
      </van-cell-group>

      <!-- 商品清单 -->
      <div class="order-confirm__card app-card">
        <div class="order-confirm__title">商品清单</div>
        <div v-for="item in checkedItems" :key="item.key" class="order-confirm__item">
          <van-image
            class="order-confirm__img"
            :src="resolveImage(item.picUrl)"
            fit="cover"
            radius="6"
          />
          <div class="order-confirm__info">
            <div class="text-ellipsis-2 order-confirm__name">{{ item.name }}</div>
            <div class="order-confirm__spec text-ellipsis">{{ item.specText }}</div>
            <div class="flex-between mt-1">
              <PriceText :value="item.price" />
              <span class="order-confirm__qty">× {{ item.quantity }}</span>
            </div>
            <van-tag v-if="item.tierPrice" type="danger" plain class="mt-1">已享阶梯价</van-tag>
          </div>
        </div>

        <van-empty v-if="!checkedItems.length" description="没有待下单的商品" />
      </div>

      <!-- 备注 -->
      <van-cell-group inset class="order-confirm__group">
        <van-field
          v-model="remark"
          label="订单备注"
          type="textarea"
          rows="2"
          autosize
          maxlength="100"
          show-word-limit
          placeholder="如有特殊配送要求请在此说明"
        />
      </van-cell-group>

      <!-- 金额明细 -->
      <van-cell-group inset class="order-confirm__group">
        <van-cell title="商品件数" :value="`${totalQuantity} 件`" />
        <van-cell title="运费" value="按实际结算" />
        <van-cell title="合计金额" :value="`¥${formatPrice(totalPrice)}`" />
      </van-cell-group>
    </div>

    <van-submit-bar
      :price="totalPrice"
      :loading="loading"
      button-text="提交订货单"
      label="实付："
      @submit="run"
    />
  </div>
</template>

<style scoped lang="scss">
  /* 内容底部避让固定提交栏（van-submit-bar 默认无 placeholder），避免最后一项被遮挡 */
  :deep(.app-scroll) {
    padding-bottom: 52px;
  }

  .order-confirm {
    &__group {
      margin-top: 12px;
    }

    &__card {
      margin: 12px;
      padding: 12px;
    }

    &__title {
      margin-bottom: 8px;
      font-size: 14px;
      font-weight: 600;
    }

    &__item {
      display: flex;
      gap: 10px;
      padding: 8px 0;

      & + & {
        border-top: 1px solid var(--app-border-color);
      }
    }

    &__img {
      flex: none;
      width: 70px;
      height: 70px;
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

    &__qty {
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }
  }
</style>
