<script setup lang="ts">
  import { showSuccessToast, showToast } from 'vant';
  import { addCart } from '@/api/cart';
  import { getProductDetail } from '@/api/product';
  import type { Product, Sku } from '@/types';
  import { useCartStore, type AddCartPayload } from '@/stores/cart';
  import { useUserStore } from '@/stores/user';
  import { formatCount, formatPrice } from '@/utils/format';
  import { resolveImage } from '@/utils/image';
  import { resolvePrice } from '@/utils/price';

  defineOptions({ name: 'ProductDetail' });

  const route = useRoute();
  const router = useRouter();
  const cartStore = useCartStore();
  const userStore = useUserStore();

  const productId = computed(() => Number(route.params.id));

  const product = ref<Product | null>(null);
  const loading = ref(true);
  const activeSkuId = ref(0);
  const quantity = ref(1);

  const skus = computed<Sku[]>(() => product.value?.skus ?? []);

  const activeSku = computed<Sku | undefined>(
    () => skus.value.find((item) => item.id === activeSkuId.value) ?? skus.value[0],
  );

  /** 当前数量对应的成交价（阶梯价核心） */
  const priceInfo = computed(() => {
    const sku = activeSku.value;
    if (!sku) return { price: 0, isTierPrice: false, tier: undefined };
    return resolvePrice({ price: sku.price, tierPrices: sku.tierPrices }, quantity.value);
  });

  const stock = computed(() => activeSku.value?.stock ?? 0);
  const soldOut = computed(() => stock.value <= 0);

  async function load(): Promise<void> {
    loading.value = true;
    try {
      const detail = await getProductDetail(productId.value);
      product.value = detail;
      const firstSku = detail.skus?.[0];
      activeSkuId.value = firstSku?.id ?? 0;
      quantity.value = firstSku?.minOrderQuantity ?? 1;
    } catch {
      // 拦截器已提示
    } finally {
      loading.value = false;
    }
  }

  function onSelectSku(sku: Sku): void {
    if (sku.stock <= 0) {
      showToast('该规格暂时缺货');
      return;
    }
    activeSkuId.value = sku.id;
    quantity.value = Math.max(quantity.value, sku.minOrderQuantity ?? 1);
  }

  function buildPayload() {
    const sku = activeSku.value;
    const current = product.value;
    if (!sku || !current) return null;
    return {
      spuId: current.id,
      sku,
      quantity: quantity.value,
    };
  }

  /** 本地加入订货单；登录态同时同步到服务端（失败不阻塞本地体验） */
  function addToCart(payload: AddCartPayload): void {
    cartStore.addItem(payload);
    if (userStore.isLogin) {
      void addCart({ skuId: payload.sku.id, count: payload.quantity }).catch(() => undefined);
    }
  }

  function onAddCart(): void {
    const payload = buildPayload();
    if (!payload) {
      showToast('请选择商品规格');
      return;
    }
    addToCart(payload);
    showSuccessToast('已加入订货单');
  }

  function onBuyNow(): void {
    const payload = buildPayload();
    if (!payload) {
      showToast('请选择商品规格');
      return;
    }
    addToCart(payload);
    void router.push('/order/confirm');
  }

  onMounted(() => {
    void load();
  });
</script>

<template>
  <div class="app-page detail">
    <AppNavBar :title="product?.name ?? '商品详情'" />

    <van-loading v-if="loading" class="detail__loading" size="24" vertical>加载中…</van-loading>

    <template v-else-if="product">
      <div class="app-scroll">
        <van-image class="detail__banner" :src="resolveImage(product.picUrl)" fit="cover" />

        <div class="detail__head app-card">
          <div class="flex-between">
            <PriceText :value="priceInfo.price" size="large" />
            <span class="detail__sales">已订 {{ formatCount(product.salesCount ?? 0) }}</span>
          </div>
          <div class="detail__name">{{ product.name }}</div>
          <div class="detail__sub">{{ product.subTitle }}</div>
        </div>

        <!-- 阶梯价：订货业务核心信息 -->
        <div v-if="activeSku?.tierPrices?.length" class="detail__block app-card">
          <div class="detail__block-title">
            <i class="i-carbon-chart-line mr-1" />阶梯价（当前数量 {{ quantity }} 件）
          </div>
          <div class="detail__tiers">
            <div
              v-for="tier in activeSku.tierPrices"
              :key="tier.minQuantity"
              class="detail__tier"
              :class="{ 'detail__tier--active': priceInfo.tier?.minQuantity === tier.minQuantity }"
            >
              <div class="detail__tier-range">
                {{ tier.minQuantity }}
                <template v-if="tier.maxQuantity">-{{ tier.maxQuantity }}</template>
                <template v-else>+</template>
              </div>
              <div class="detail__tier-price">¥{{ formatPrice(tier.price) }}</div>
            </div>
          </div>
        </div>

        <!-- 规格选择 -->
        <div class="detail__block app-card">
          <div class="detail__block-title">选择规格</div>
          <div class="detail__skus">
            <van-tag
              v-for="sku in skus"
              :key="sku.id"
              class="detail__sku"
              :type="sku.id === activeSku?.id ? 'primary' : 'default'"
              :plain="sku.id !== activeSku?.id"
              size="large"
              :class="{ 'detail__sku--disabled': sku.stock <= 0 }"
              @click="onSelectSku(sku)"
            >
              {{ sku.name }}
            </van-tag>
          </div>

          <van-cell title="订货数量" :border="false">
            <template #value>
              <van-stepper
                v-model="quantity"
                :min="activeSku?.minOrderQuantity ?? 1"
                :max="Math.max(stock, 1)"
                integer
                button-size="24"
                input-width="44"
              />
            </template>
          </van-cell>
          <van-cell title="可用库存" :value="`${stock} ${product.unit ?? '件'}`" :border="false" />
        </div>

        <!-- 图文详情 -->
        <div class="detail__block app-card">
          <div class="detail__block-title">商品详情</div>
          <!-- eslint-disable-next-line vue/no-v-html -->
          <div class="detail__html" v-html="product.detailHtml" />
        </div>
      </div>

      <van-submit-bar
        class="detail__submit"
        :button-text="soldOut ? '已售罄' : '立即订货'"
        :disabled="soldOut"
        @submit="onBuyNow"
      >
        <div class="detail__add" @click="onAddCart">
          <i class="i-carbon-shopping-cart" />
          <span>加入订货单</span>
        </div>
      </van-submit-bar>
    </template>

    <van-empty v-else description="商品不存在或已下架" />
  </div>
</template>

<style scoped lang="scss">
  .detail {
    &__loading {
      display: flex;
      flex: 1;
      align-items: center;
      justify-content: center;
    }

    &__banner {
      display: block;
      width: 100%;
      height: 300px;
    }

    &__head {
      margin: -12px 12px 0;
      padding: 12px;
    }

    &__sales {
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__name {
      margin-top: 8px;
      font-size: 16px;
      font-weight: 600;
      line-height: 1.4;
    }

    &__sub {
      margin-top: 4px;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__block {
      margin: 12px;
      padding: 12px;
    }

    &__block-title {
      display: flex;
      align-items: center;
      margin-bottom: 10px;
      font-size: 14px;
      font-weight: 600;
    }

    &__tiers {
      display: flex;
      gap: 8px;
      overflow-x: auto;
    }

    &__tier {
      flex: none;
      min-width: 78px;
      padding: 8px 10px;
      text-align: center;
      background: var(--app-bg-color);
      border: 1px solid transparent;
      border-radius: var(--app-radius-md);
    }

    &__tier--active {
      background: rgb(0 129 255 / 8%);
      border-color: var(--app-primary-color);
    }

    &__tier-range {
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__tier-price {
      margin-top: 2px;
      font-size: 14px;
      font-weight: 600;
      color: var(--app-danger-color);
    }

    &__skus {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }

    &__sku {
      cursor: pointer;
    }

    &__sku--disabled {
      opacity: 0.45;
    }

    &__html {
      font-size: 13px;
      line-height: 1.7;
      color: var(--app-text-color-secondary);
    }

    &__submit {
      --van-submit-bar-height: 52px;
    }

    &__add {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 2px;
      padding: 0 8px;
      font-size: 12px;
      color: var(--app-text-color);
    }
  }
</style>
