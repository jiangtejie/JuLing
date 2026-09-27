<script setup lang="ts">
  import banner1 from '@/assets/images/banner-1.jpg';
  import { getProductPage } from '@/api/product';
  import type { Product } from '@/types';
  import { formatCount } from '@/utils/format';
  import { resolveImage } from '@/utils/image';

  defineOptions({ name: 'Home' });

  const router = useRouter();

  const keyword = ref('');

  const { list, loading, finished, refreshing, total, error, onLoad, onRefresh } = usePaging<
    Product,
    { keyword?: string }
  >((params) => getProductPage(params));

  /**
   * 首页轮播。
   *
   * 目前用本地运营图（src/assets/images/banner-1.jpg，750×350 / 约 42 KB，
   * 由 1837×856 的原图等比缩放 + JPEG q85 导出）；后端 banner 接口就绪后，
   * 把这里换成接口数据即可，模板与样式不用动。新增图片时往数组里追加一项。
   */
  const banners = [
    {
      id: 1,
      image: banner1,
      alt: '亚特云餐饮 · 共赢数字餐饮新时代',
    },
  ];

  /** 快捷入口：使用 UnoCSS presetIcons（按需打包图标，零额外请求） */
  const quickEntries = [
    { label: '全部商品', icon: 'i-carbon-catalog', to: '/product/list' },
    { label: '我的订单', icon: 'i-carbon-receipt', to: '/order/list' },
    { label: '订货单', icon: 'i-carbon-shopping-cart', to: '/cart' },
  ];

  function onSearch(): void {
    void router.push({
      path: '/product/list',
      query: keyword.value ? { keyword: keyword.value } : {},
    });
  }

  function toDetail(id: number): void {
    void router.push(`/product/${id}`);
  }
</script>

<template>
  <div class="app-page">
    <!-- 搜索栏 -->
    <div class="home__search">
      <van-search
        v-model="keyword"
        shape="round"
        background="transparent"
        placeholder="搜索商品名称 / 编码"
        @search="onSearch"
      />
    </div>

    <van-pull-refresh v-model="refreshing" @refresh="onRefresh">
      <div class="app-scroll">
        <!-- 公告栏：静态展示（文案短，滚动反而首屏空白、不易读），可关闭 -->
        <van-notice-bar
          mode="closeable"
          left-icon="volume-o"
          background="#fff7e6"
          color="#ed6a0c"
          text="满 500 元包邮 · 厂价直供"
        />

        <!-- 轮播：只有一张时不显示指示点 -->
        <van-swipe
          class="home__banner"
          :autoplay="4000"
          :show-indicators="banners.length > 1"
          indicator-color="#fff"
        >
          <van-swipe-item v-for="item in banners" :key="item.id">
            <van-image
              class="home__banner-img"
              :src="item.image"
              :alt="item.alt"
              fit="cover"
            />
          </van-swipe-item>
        </van-swipe>

        <!-- 快捷入口 -->
        <div class="home__entries app-card">
          <div
            v-for="entry in quickEntries"
            :key="entry.label"
            class="home__entry"
            @click="router.push(entry.to)"
          >
            <i :class="entry.icon" class="home__entry-icon" />
            <span class="home__entry-label">{{ entry.label }}</span>
          </div>
        </div>

        <!-- 商品列表 -->
        <div class="flex-between home__section-title">
          <span>热销订货商品</span>
          <span v-if="total" class="home__section-count">共 {{ total }} 件</span>
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
          <!-- 首屏骨架：列表为空且首屏加载中时用骨架屏代替空白；下拉刷新（refreshing）时不显示，避免高度跳动 -->
          <ListSkeleton v-if="!list.length && loading && !refreshing" :rows="4" />
          <div v-if="list.length" class="home__goods">
            <div
              v-for="product in list"
              :key="product.id"
              class="home__goods-item app-card"
              @click="toDetail(product.id)"
            >
              <van-image
                class="home__goods-img"
                :src="resolveImage(product.picUrl)"
                fit="cover"
                radius="8"
                lazy-load
              />
              <div class="home__goods-info">
                <div class="text-ellipsis-2 home__goods-name">{{ product.name }}</div>
                <div class="home__goods-sub text-ellipsis">{{ product.subTitle }}</div>
                <div class="flex-between mt-1">
                  <PriceText :value="product.price" size="large" />
                  <span class="home__goods-sales"
                    >已订 {{ formatCount(product.salesCount ?? 0) }}</span
                  >
                </div>
              </div>
            </div>
          </div>
        </van-list>

        <van-empty v-if="!loading && !list.length" description="暂无商品" />
      </div>
    </van-pull-refresh>
  </div>
</template>

<style scoped lang="scss">
  .home {
    &__search {
      background: var(--app-primary-color);
      padding-top: env(safe-area-inset-top);
    }

    &__banner {
      margin: 12px;
      border-radius: var(--app-radius-lg);
      overflow: hidden;
    }

    /* 与素材等比：设计稿宽 375 - 左右各 12 = 351，351 × 856/1837 ≈ 164。
       px 会被自动换算成 vw，所以任意屏宽下图片都刚好铺满、不裁切；
       换图时按同一个公式重算高度即可。 */
    &__banner-img {
      display: block;
      width: 100%;
      height: 164px;
    }

    &__entries {
      display: flex;
      margin: 0 12px;
      padding: 16px 0;
    }

    &__entry {
      display: flex;
      flex: 1;
      flex-direction: column;
      align-items: center;
      gap: 6px;
    }

    &__entry-icon {
      color: var(--app-primary-color);
      font-size: 24px;
    }

    &__entry-label {
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__section-title {
      margin: 16px 12px 8px;
      font-size: 16px;
      font-weight: 600;
    }

    &__section-count {
      font-size: 12px;
      font-weight: 400;
      color: var(--app-text-color-secondary);
    }

    &__goods {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      padding: 0 12px;
    }

    &__goods-item {
      display: flex;
      width: 100%;
      gap: 10px;
      padding: 10px;
    }

    &__goods-img {
      flex: none;
      width: 90px;
      height: 90px;
    }

    &__goods-info {
      flex: 1;
      min-width: 0;
    }

    &__goods-name {
      font-size: 14px;
      font-weight: 500;
      line-height: 1.4;
    }

    &__goods-sub {
      margin-top: 2px;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__goods-sales {
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }
  }
</style>
