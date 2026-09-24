<script setup lang="ts">
  import { getProductPage } from '@/api/product';
  import type { Product } from '@/types';
  import { formatCount } from '@/utils/format';
  import { resolveImage } from '@/utils/image';

  defineOptions({ name: 'ProductList' });

  const route = useRoute();
  const router = useRouter();

  const keyword = ref(typeof route.query.keyword === 'string' ? route.query.keyword : '');

  const { list, loading, finished, refreshing, total, error, onLoad, onRefresh, search } =
    usePaging<Product, { keyword?: string }>((params) => getProductPage(params), {
      defaultParams: { keyword: keyword.value },
    });

  function onSearch(): void {
    void search({ keyword: keyword.value });
  }

  function toDetail(id: number): void {
    void router.push(`/product/${id}`);
  }
</script>

<template>
  <div class="app-page">
    <AppNavBar title="商品列表" />

    <van-sticky>
      <van-search
        v-model="keyword"
        shape="round"
        placeholder="搜索商品名称 / 编码"
        show-action
        @search="onSearch"
      >
        <template #action>
          <div class="product-list__action" @click="onSearch">搜索</div>
        </template>
      </van-search>
    </van-sticky>

    <van-pull-refresh v-model="refreshing" @refresh="onRefresh">
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
        <div v-if="list.length" class="product-list__count">共 {{ total }} 件商品</div>
        <div v-if="list.length" class="product-list__wrap">
          <div
            v-for="product in list"
            :key="product.id"
            class="product-list__item app-card"
            @click="toDetail(product.id)"
          >
            <van-image
              class="product-list__img"
              :src="resolveImage(product.picUrl)"
              fit="cover"
              radius="8"
              lazy-load
            />
            <div class="product-list__info">
              <div class="text-ellipsis-2 product-list__name">{{ product.name }}</div>
              <div class="text-ellipsis product-list__sub">{{ product.subTitle }}</div>
              <div class="flex-between mt-1">
                <PriceText :value="product.price" size="large" />
                <span class="product-list__sales"
                  >已订 {{ formatCount(product.salesCount ?? 0) }}</span
                >
              </div>
              <div class="product-list__tags">
                <van-tag type="primary" plain>库存 {{ product.stock }}</van-tag>
              </div>
            </div>
          </div>
        </div>
      </van-list>

      <van-empty v-if="!loading && !list.length" image="search" description="没有找到相关商品" />
    </van-pull-refresh>
  </div>
</template>

<style scoped lang="scss">
  .product-list {
    &__action {
      padding-left: 12px;
      font-size: 14px;
      color: var(--app-primary-color);
    }

    &__count {
      padding: 12px 12px 0;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__wrap {
      display: flex;
      flex-direction: column;
      gap: 10px;
      padding: 12px;
    }

    &__item {
      display: flex;
      gap: 10px;
      padding: 10px;
    }

    &__img {
      flex: none;
      width: 96px;
      height: 96px;
    }

    &__info {
      flex: 1;
      min-width: 0;
    }

    &__name {
      font-size: 14px;
      font-weight: 500;
      line-height: 1.4;
    }

    &__sub {
      margin-top: 2px;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__sales {
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__tags {
      display: flex;
      gap: 6px;
      margin-top: 6px;
    }
  }
</style>
