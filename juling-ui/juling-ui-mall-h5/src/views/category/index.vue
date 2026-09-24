<script setup lang="ts">
  import { showToast } from 'vant';
  import { getCategoryList, getProductPage } from '@/api/product';
  import type { Product } from '@/types';
  import { useCartStore } from '@/stores/cart';
  import { formatPrice } from '@/utils/format';
  import { resolveImage } from '@/utils/image';

  defineOptions({ name: 'Category' });

  const router = useRouter();
  const cartStore = useCartStore();

  const categories = ref<Array<{ id: number; name: string }>>([]);
  /** van-sidebar 的 v-model 是「索引」而非业务 id */
  const activeIndex = ref(0);

  const { list, loading, finished, error, refreshing, total, onLoad, onRefresh, search } =
    usePaging<Product, { categoryId?: number }>((params) => getProductPage(params), {
      immediate: false,
    });

  const activeName = computed(() => categories.value[activeIndex.value]?.name ?? '');

  async function init(): Promise<void> {
    try {
      categories.value = await getCategoryList();
      const first = categories.value[0];
      if (first) await search({ categoryId: first.id });
    } catch (err) {
      // 错误提示由请求层统一处理，这里仅留痕，避免未捕获的 Promise rejection
      console.warn('[category] 初始化失败:', err);
    }
  }

  async function onSelect(index: number): Promise<void> {
    const category = categories.value[index];
    if (!category) return;
    await search({ categoryId: category.id });
  }

  function toDetail(id: number): void {
    void router.push(`/product/${id}`);
  }

  /** 悬浮购物车栏：查看订货单明细 */
  function toCart(): void {
    void router.push('/cart');
  }

  /** 悬浮购物车栏：去结算 */
  function toConfirm(): void {
    if (!cartStore.checkedItems.length) {
      showToast('请先勾选要下单的商品');
      return;
    }
    void router.push('/order/confirm');
  }

  onMounted(() => {
    void init();
  });
</script>

<template>
  <div class="app-page app-page--fixed">
    <AppNavBar title="商品分类" :left-arrow="false" />

    <div class="category">
      <!-- 左侧一级分类 -->
      <van-sidebar v-model="activeIndex" class="category__sidebar" @change="onSelect">
        <van-sidebar-item v-for="item in categories" :key="item.id" :title="item.name" />
      </van-sidebar>

      <!-- 右侧商品：内部滚动容器，下拉刷新需挂在容器内才生效 -->
      <div
        :class="[
          'category__content',
          { 'category__content--with-cartbar': cartStore.totalKinds > 0 },
        ]"
      >
        <van-pull-refresh v-model="refreshing" @refresh="onRefresh">
          <div class="flex-between category__title">
            <span>{{ activeName }}</span>
            <span v-if="total" class="category__count">共 {{ total }} 件</span>
          </div>
          <van-list
            v-model:loading="loading"
            :finished="finished"
            :error="error"
            :loading-text="list.length ? '加载中...' : ''"
            finished-text="没有更多了"
            error-text="加载失败，点击重试"
            @load="onLoad"
          >
            <!-- 首屏骨架：列表为空且加载中时用骨架屏代替空白（切换分类同样适用） -->
            <ListSkeleton v-if="!list.length && loading && !refreshing" :rows="4" />
            <div
              v-for="product in list"
              :key="product.id"
              class="category__item"
              @click="toDetail(product.id)"
            >
              <van-image
                :src="resolveImage(product.picUrl)"
                fit="cover"
                radius="6"
                lazy-load
                class="category__img"
              />
              <div class="category__info">
                <div class="text-ellipsis-2 category__name">{{ product.name }}</div>
                <div class="category__stock">库存 {{ product.stock }} 件</div>
                <PriceText :value="product.price" />
              </div>
            </div>
          </van-list>

          <!-- 空态：该分类下暂无商品（区别于「加载失败」，无需重试入口） -->
          <van-empty v-if="!loading && !list.length" image="search" description="该分类暂无商品" />
        </van-pull-refresh>
      </div>
    </div>

    <!-- 底部悬浮购物车栏（美团外卖点菜式）：有已选商品时出现 -->
    <div v-if="cartStore.totalKinds > 0" class="category__cartbar">
      <div class="category__cartbar-info" @click="toCart">
        <div class="category__cartbar-icon">
          <van-icon name="shopping-cart-o" size="20" />
          <span class="category__cartbar-badge">{{ cartStore.totalQuantity }}</span>
        </div>
        <div class="category__cartbar-amount">
          <span class="category__cartbar-price">¥{{ formatPrice(cartStore.totalPrice) }}</span>
          <span class="category__cartbar-tip">共 {{ cartStore.totalKinds }} 种</span>
        </div>
      </div>
      <van-button
        class="category__cartbar-btn"
        type="primary"
        round
        size="small"
        @click="toConfirm"
      >
        去结算
      </van-button>
    </div>
  </div>
</template>

<style scoped lang="scss">
  .category {
    display: flex;
    flex: 1;
    min-height: 0;
    overflow: hidden;

    &__sidebar {
      flex: none;
      width: 88px;
      height: 100%;
      overflow-y: auto;
      background: #fff;
    }

    &__content {
      flex: 1;
      height: 100%;
      overflow-y: auto;
      /* 底部预留固定 tabbar 的高度，否则滚到底时最后一项（如「没有更多了」）会被 tabbar 遮挡 */
      padding: 0 12px calc(12px + var(--app-tabbar-height) + env(safe-area-inset-bottom));
      background: var(--app-bg-color);
    }

    /* 有悬浮购物车栏时，内容区再多留出它的高度（48 + 8 间距） */
    &__content--with-cartbar {
      padding-bottom: calc(12px + var(--app-tabbar-height) + env(safe-area-inset-bottom) + 56px);
    }

    /* ===== 悬浮购物车栏（美团外卖点菜式） ===== */
    &__cartbar {
      position: fixed;
      right: 12px;
      left: 12px;
      bottom: calc(var(--app-tabbar-height) + env(safe-area-inset-bottom) + 8px);
      z-index: 10;
      display: flex;
      align-items: center;
      justify-content: space-between;
      height: 48px;
      padding: 0 6px 0 12px;
      background: #fff;
      border-radius: 24px;
      box-shadow: 0 4px 16px rgb(0 0 0 / 12%);
    }

    &__cartbar-info {
      display: flex;
      flex: 1;
      align-items: center;
      gap: 10px;
      min-width: 0;
    }

    &__cartbar-icon {
      position: relative;
      display: flex;
      flex: none;
      align-items: center;
      justify-content: center;
      width: 34px;
      height: 34px;
      color: #fff;
      background: var(--app-primary-color);
      border-radius: 50%;
    }

    &__cartbar-badge {
      position: absolute;
      top: -4px;
      right: -4px;
      min-width: 16px;
      height: 16px;
      padding: 0 4px;
      font-size: 10px;
      line-height: 16px;
      color: #fff;
      text-align: center;
      background: var(--app-danger-color);
      border-radius: 8px;
    }

    &__cartbar-amount {
      display: flex;
      flex-direction: column;
      min-width: 0;
    }

    &__cartbar-price {
      font-size: 16px;
      font-weight: 600;
      line-height: 1.1;
      color: var(--app-danger-color);
    }

    &__cartbar-tip {
      font-size: 11px;
      color: var(--app-text-color-secondary);
    }

    &__title {
      padding: 12px 0 8px;
      font-size: 14px;
      font-weight: 600;
    }

    &__count {
      font-size: 12px;
      font-weight: 400;
      color: var(--app-text-color-secondary);
    }

    &__item {
      display: flex;
      gap: 10px;
      padding: 10px;
      margin-bottom: 10px;
      background: #fff;
      border-radius: var(--app-radius-md);
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

    &__stock {
      margin: 4px 0;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }
  }
</style>
