<script setup lang="ts">
  import { getOrderPage } from '@/api/order';
  import { ORDER_STATUS_MAP, ORDER_TABS } from '@/constants';
  import type { Order } from '@/types';
  import { formatDate, formatPrice } from '@/utils/format';
  import { resolveImage } from '@/utils/image';

  defineOptions({ name: 'OrderList' });

  const route = useRoute();
  const router = useRouter();

  const initialKey = typeof route.query.status === 'string' ? route.query.status : 'all';
  const activeTab = ref(
    Math.max(
      0,
      ORDER_TABS.findIndex((tab) => tab.key === initialKey),
    ),
  );

  const { list, loading, finished, refreshing, total, error, onLoad, onRefresh, search } =
    usePaging<Order, { status?: string }>(
      (params) =>
        getOrderPage({ ...params, status: params.status === 'all' ? undefined : params.status }),
      { defaultParams: { status: ORDER_TABS[activeTab.value].key } },
    );

  async function onTabChange(index: number): Promise<void> {
    await search({ status: ORDER_TABS[index]?.key ?? 'all' });
  }

  function toDetail(id: number): void {
    void router.push(`/order/${id}`);
  }
</script>

<template>
  <div class="app-page">
    <AppNavBar title="我的订单" />

    <van-tabs v-model:active="activeTab" sticky @change="onTabChange">
      <van-tab v-for="tab in ORDER_TABS" :key="tab.key" :title="tab.title" />
    </van-tabs>

    <van-pull-refresh v-model="refreshing" @refresh="onRefresh">
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
        <ListSkeleton v-if="!list.length && loading && !refreshing" variant="order" :rows="3" />
        <div v-if="list.length" class="order-list__count">共 {{ total }} 笔订单</div>
        <div v-if="list.length" class="order-list__wrap">
          <div
            v-for="order in list"
            :key="order.id"
            class="order-list__item app-card"
            @click="toDetail(order.id)"
          >
            <div class="flex-between order-list__head">
              <span class="order-list__no">{{ order.orderNo }}</span>
              <span
                class="order-list__status"
                :style="{ color: ORDER_STATUS_MAP[order.status].color }"
              >
                {{ ORDER_STATUS_MAP[order.status].text }}
              </span>
            </div>

            <div v-for="item in order.items" :key="item.id" class="order-list__goods">
              <van-image
                class="order-list__img"
                :src="resolveImage(item.picUrl)"
                fit="cover"
                radius="6"
                lazy-load
              />
              <div class="order-list__info">
                <div class="text-ellipsis-2 order-list__name">{{ item.name }}</div>
                <div class="text-ellipsis order-list__spec">{{ item.specText }}</div>
              </div>
              <div class="order-list__amount">
                <div>¥{{ formatPrice(item.price) }}</div>
                <div class="order-list__qty">× {{ item.quantity }}</div>
              </div>
            </div>

            <div class="flex-between order-list__foot">
              <span class="order-list__time">{{
                formatDate(order.createTime, 'YYYY-MM-DD HH:mm')
              }}</span>
              <span class="order-list__total"> 实付 <PriceText :value="order.payPrice" /> </span>
            </div>
          </div>
        </div>
      </van-list>

      <van-empty v-if="!loading && !list.length" description="暂无相关订单" />
    </van-pull-refresh>
  </div>
</template>

<style scoped lang="scss">
  .order-list {
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
      padding: 12px;
    }

    &__head {
      padding-bottom: 10px;
      border-bottom: 1px solid var(--app-border-color);
    }

    &__no {
      font-size: 13px;
      color: var(--app-text-color-secondary);
    }

    &__status {
      font-size: 13px;
      font-weight: 600;
    }

    &__goods {
      display: flex;
      gap: 10px;
      padding: 10px 0;
    }

    &__img {
      flex: none;
      width: 64px;
      height: 64px;
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

    &__amount {
      flex: none;
      text-align: right;
      font-size: 13px;
    }

    &__qty {
      margin-top: 2px;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__foot {
      padding-top: 10px;
      border-top: 1px solid var(--app-border-color);
      font-size: 12px;
    }

    &__time {
      color: var(--app-text-color-secondary);
    }

    &__total {
      display: flex;
      align-items: baseline;
      gap: 2px;
    }
  }
</style>
