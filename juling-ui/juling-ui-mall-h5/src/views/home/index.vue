<script setup lang="ts">
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

  /** 轮播（演示用渐变色，接入后端后替换为图片 URL） */
  const banners = [
    {
      id: 1,
      title: '新客首单立减',
      desc: '满 500 元包邮',
      bg: 'var(--app-primary-gradient)',
    },
    {
      id: 2,
      title: '专属订货价',
      desc: '登录后可查看专属订货价',
      bg: 'linear-gradient(135deg, #ff7a45, #ffa940)',
    },
    {
      id: 3,
      title: '整箱直供',
      desc: '厂价直发，省去中间环节',
      bg: 'linear-gradient(135deg, #07c160, #4dd88a)',
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

        <!-- 轮播 -->
        <van-swipe class="home__banner" :autoplay="4000" indicator-color="#fff">
          <van-swipe-item v-for="item in banners" :key="item.id">
            <div class="home__banner-item" :style="{ background: item.bg }">
              <div class="home__banner-title">{{ item.title }}</div>
              <div class="home__banner-desc">{{ item.desc }}</div>
            </div>
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

    &__banner-item {
      display: flex;
      flex-direction: column;
      justify-content: center;
      height: 120px;
      padding: 0 20px;
      color: #fff;
    }

    &__banner-title {
      font-size: 20px;
      font-weight: 600;
    }

    &__banner-desc {
      margin-top: 6px;
      font-size: 13px;
      opacity: 0.9;
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
