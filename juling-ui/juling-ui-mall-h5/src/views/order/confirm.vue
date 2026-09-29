<script setup lang="ts">
  import { showSuccessToast, showToast } from 'vant';
  import { createOrder } from '@/api/order';
  import { useCartStore } from '@/stores/cart';
  import { useStoreStore } from '@/stores/store';
  import { formatPrice } from '@/utils/format';
  import { resolveImage } from '@/utils/image';
  import { isMobile } from '@/utils/is';
  import { withSilentRequest } from '@/utils/request';

  defineOptions({ name: 'OrderConfirm' });

  /** 可下单门店接口地址：与 api 层 getStoreList() 一致（该调用链无法透传 silent 配置） */
  const STORE_LIST_URL = '/trade/order/store-list';

  const router = useRouter();
  const cartStore = useCartStore();
  const { checkedItems, totalPrice, totalQuantity } = storeToRefs(cartStore);

  // 门店订货链 S1：下单门店（代理账号可能存在多家门店，需显式确认避免下错店）
  const storeStore = useStoreStore();
  const { stores, currentStore } = storeToRefs(storeStore);
  const showStorePicker = ref(false);
  const pickedStoreId = ref<number | null>(null);

  /**
   * 切换下单门店。
   *
   * switchStore 内部有二次确认（切换会清空当前订货单），因此必须 await：
   * 用户在确认框点「取消」时不能把单选态改掉，否则弹窗里的选中项会与 currentStore 不一致。
   */
  async function onPickStore(customerId: number): Promise<void> {
    const switched = await storeStore.switchStore(customerId);
    if (!switched) return;
    pickedStoreId.value = customerId;
    showStorePicker.value = false;
  }

  const remark = ref('');
  // 不预填任何示例地址：避免用户未填写就把假收货信息提交到后端
  const address = reactive({ name: '', mobile: '', address: '' });

  async function onSubmit(): Promise<void> {
    if (!checkedItems.value.length) {
      showToast('请先选择要下单的商品');
      return;
    }
    if (!address.name.trim()) {
      showToast('请输入收货人姓名');
      return;
    }
    if (!isMobile(address.mobile.trim())) {
      showToast('请输入正确的联系电话');
      return;
    }
    if (!address.address.trim()) {
      showToast('请输入详细收货地址');
      return;
    }
    if (!currentStore.value) {
      showToast('当前账号未绑定门店，请联系管理员配置后再下单');
      return;
    }

    let orderId: number;
    try {
      orderId = await createOrder({
        items: checkedItems.value.map((item) => ({
          skuId: item.skuId,
          quantity: item.quantity,
        })),
        receiverName: address.name.trim(),
        receiverMobile: address.mobile.trim(),
        receiverAddress: address.address.trim(),
        remark: remark.value,
        // 门店订货链：显式携带所选门店，后端校验归属并快照组织/客户
        storeCustomerId: currentStore.value.customerId,
      });
    } catch {
      return;
    }

    cartStore.clearChecked();
    showSuccessToast('订货单提交成功');
    // 线下收款：下单后引导上传付款截图，核验通过才进入发货
    await router.replace(`/order/${orderId}/payment`);
  }

  const { loading, run } = useSubmit(onSubmit);

  onMounted(async () => {
    // 排序：先展示已勾选商品
    if (!checkedItems.value.length && cartStore.items.length) {
      showToast('请先在订货单中勾选商品');
    }
    // 门店订货链：拉取可下单门店（未绑定门店时后端会拦截下单，这里静默失败并给出提示）
    try {
      // 失败提示由本页负责（「请联系管理员绑定门店」比后端原始文案更有业务含义），
      // 因此声明该请求静默：否则拦截器先弹一条、这里再弹一条，同一次失败出现两条 toast
      await withSilentRequest(STORE_LIST_URL, () => storeStore.fetchStores());
      pickedStoreId.value = currentStore.value?.customerId ?? null;
    } catch {
      showToast('未能获取下单门店，请联系管理员绑定门店');
    }
  });
</script>

<template>
  <div class="app-page order-confirm">
    <AppNavBar title="确认订单" />

    <div class="app-scroll">
      <!-- 下单门店：代理账号可能有多家门店，显式展示当前门店避免下错 -->
      <van-cell-group inset class="order-confirm__group">
        <van-cell
          title="下单门店"
          :value="currentStore?.customerName || '未绑定门店'"
          :is-link="stores.length > 1"
          @click="stores.length > 1 && (showStorePicker = true)"
        />
      </van-cell-group>

      <!-- 收货信息 -->
      <van-cell-group inset class="order-confirm__group">
        <van-field
          v-model="address.name"
          label="收货人"
          placeholder="请输入收货人姓名"
          input-align="right"
          required
        />
        <van-field
          v-model="address.mobile"
          label="联系电话"
          type="tel"
          maxlength="11"
          placeholder="请输入联系电话"
          input-align="right"
          required
        />
        <van-field
          v-model="address.address"
          label="收货地址"
          type="textarea"
          rows="2"
          autosize
          placeholder="请输入详细收货地址"
          required
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
            lazy-load
          />
          <div class="order-confirm__info">
            <div class="text-ellipsis-2 order-confirm__name">{{ item.name }}</div>
            <div class="order-confirm__spec text-ellipsis">{{ item.specText }}</div>
            <div class="flex-between mt-1">
              <PriceText :value="item.price" />
              <span class="order-confirm__qty">× {{ item.quantity }}</span>
            </div>
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

    <van-popup v-model:show="showStorePicker" position="bottom" round>
      <div class="store-picker">
        <div class="store-picker__title">选择下单门店</div>
        <van-radio-group v-model="pickedStoreId">
          <van-cell
            v-for="item in stores"
            :key="item.customerId"
            :title="item.customerName"
            clickable
            @click="onPickStore(item.customerId)"
          >
            <template #right-icon>
              <van-radio :name="item.customerId" @click.stop="onPickStore(item.customerId)" />
            </template>
          </van-cell>
        </van-radio-group>
      </div>
    </van-popup>

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

  .store-picker {
    max-height: 60vh;
    padding: 12px 0 20px;
    overflow-y: auto;

    &__title {
      padding: 4px 16px 10px;
      font-size: 15px;
      font-weight: 600;
      text-align: center;
    }
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
