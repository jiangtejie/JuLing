<script setup lang="ts">
  import { showImagePreview, showSuccessToast, showToast } from 'vant';
  import { addCart } from '@/api/cart';
  import { getProductDetail } from '@/api/product';
  import type { Product, Sku } from '@/types';
  import { useCartStore, type AddCartPayload } from '@/stores/cart';
  import { useUserStore } from '@/stores/user';
  import { formatCount } from '@/utils/format';
  import { resolveImage } from '@/utils/image';
  import { resolvePrice } from '@/utils/price';
  import { BizError } from '@/utils/request';

  defineOptions({ name: 'ProductDetail' });

  const route = useRoute();
  const router = useRouter();
  const cartStore = useCartStore();
  const userStore = useUserStore();

  const productId = computed(() => Number(route.params.id));

  const product = ref<Product | null>(null);
  const loading = ref(true);
  /** 加载失败（网络 / 服务异常）——与「商品不存在」区分，可重试 */
  const loadError = ref(false);
  const activeSkuId = ref(0);
  const quantity = ref(1);

  const skus = computed<Sku[]>(() => product.value?.skus ?? []);

  /** 轮播图：优先后端多图（sliderPicUrls），缺失时回退主图；统一做内网地址归一化 */
  const gallery = computed<string[]>(() => {
    const sliders = (product.value?.sliderPicUrls ?? []).filter(Boolean).map(resolveImage);
    return sliders.length ? sliders : [resolveImage(product.value?.picUrl)];
  });

  /** 点击轮播图放大预览（样式已在 main.ts 引入） */
  function previewImage(index: number): void {
    showImagePreview({ images: gallery.value, startPosition: index, closeable: true });
  }

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
      loadError.value = false;
    } catch (error) {
      // 拦截器已提示。业务错误（如商品不存在/已下架）不是加载失败；
      // 网络或服务异常才标记为可重试，避免把「网络不通」说成「商品不存在」。
      loadError.value = !(error instanceof BizError);
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
      void addCart({ skuId: payload.sku.id, count: payload.quantity }).catch((error) => {
        console.warn('[cart] 同步加入订货单失败:', error);
      });
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

    <!-- 加载态：骨架屏（贴合内容结构，避免居中转圈带来的跳动） -->
    <div v-if="loading" class="detail__skeleton">
      <van-skeleton title :row="3" />
      <van-skeleton title :row="5" class="mt-3" />
    </div>

    <!-- 加载失败：网络 / 服务异常，给一个重试入口（与「商品不存在」区分开） -->
    <div v-else-if="loadError" class="detail__error">
      <van-empty image="error" description="加载失败，请检查网络后重试">
        <van-button round type="primary" size="small" class="mt-3" @click="load">
          重新加载
        </van-button>
      </van-empty>
    </div>

    <template v-else-if="product">
      <div class="app-scroll">
        <!-- 轮播：多图可滑动，点击放大预览；单图时不显示指示器 -->
        <van-swipe
          class="detail__banner"
          :autoplay="0"
          :show-indicators="gallery.length > 1"
          indicator-color="#fff"
        >
          <van-swipe-item v-for="(img, index) in gallery" :key="index">
            <van-image
              class="detail__banner-img"
              :src="img"
              fit="cover"
              @click="previewImage(index)"
            />
          </van-swipe-item>
        </van-swipe>

        <div class="detail__head app-card">
          <div class="flex-between">
            <PriceText :value="priceInfo.price" size="large" />
            <span class="detail__sales">已订 {{ formatCount(product.salesCount ?? 0) }}</span>
          </div>
          <div class="detail__name">{{ product.name }}</div>
          <div class="detail__sub">{{ product.subTitle }}</div>
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

      <!-- 底部固定操作栏（van-action-bar 自带 safe-area 与 placeholder 占位） -->
      <van-action-bar class="detail__bar" placeholder safe-area-inset-bottom>
        <van-action-bar-icon
          icon="shopping-cart-o"
          text="订货单"
          :badge="cartStore.totalQuantity"
          :badge-props="{ showZero: false }"
          to="/cart"
        />
        <van-action-bar-button
          type="warning"
          text="加入订货单"
          :disabled="soldOut"
          @click="onAddCart"
        />
        <van-action-bar-button
          type="danger"
          :text="soldOut ? '已售罄' : '立即订货'"
          :disabled="soldOut"
          @click="onBuyNow"
        />
      </van-action-bar>
    </template>

    <van-empty v-else description="商品不存在或已下架" />
  </div>
</template>

<style scoped lang="scss">
  .detail {
    &__skeleton {
      padding: 24px 16px;
    }

    &__error {
      display: flex;
      flex: 1;
      align-items: center;
      justify-content: center;
    }

    &__banner {
      height: 300px;
      background: #fff;
    }

    &__banner-img {
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

    &__bar {
      --van-action-bar-height: 52px;
    }
  }
</style>
