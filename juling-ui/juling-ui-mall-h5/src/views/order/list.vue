<script setup lang="ts">
  import { motion } from 'motion-v';
  import { getOrderPage } from '@/api/order';
  import { useReorder } from '@/composables/useReorder';
  import {
    AUDIT_STATUS_MAP,
    AUDIT_TAG_STATUSES,
    deriveOrderStatusView,
    ORDER_TABS,
    RECEIVE_STATUS_MAP,
  } from '@/constants';
  import { useStoreStore } from '@/stores/store';
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

  /** 已发货（待收货）订单：进入门店收货页逐行登记实收数量（多收 / 少收 / 破损） */
  function toReceipt(order: Order): void {
    void router.push(`/order/receipt-confirm/${order.id}`);
  }

  /** 已完成 / 已取消订单支持「再来一单」：按当前商品重新加入订货单 */
  const { canReorder, reorder, reordering } = useReorder();

  function onReorder(order: Order): void {
    void reorder(order);
  }

  /**
   * 是否展示收款状态：已取消的订单不再需要收款，展示只会干扰阅读。
   * 已收齐（4）时收款已完成，也无需重复提示。
   *
   * 新流程下提交凭证的订单收款状态是 3（部分收款）或 4（已收齐），判断口径不用变：
   * 未上传（0）/ 已提交待审核（1，历史单兜底）/ 已驳回（2）/ 部分收款（3）都继续露出 chip。
   */
  function showReceive(order: Order): boolean {
    return order.status !== 'CANCELED' && order.paymentProofStatus !== 4;
  }

  /** 收款状态展示配置（未知码兜底「待上传凭证」） */
  function receiveBadge(status: number) {
    return RECEIVE_STATUS_MAP[status] ?? RECEIVE_STATUS_MAP[0];
  }

  /* ------------------------------ 门店（下单方） ------------------------------ */

  /**
   * 门店筛选。
   *
   * 代理人账号管多家门店，订单混在一起看不出是哪家店的。后端 `/trade/order/page`
   * 目前只支持 status 过滤（AppTradeOrderPageReqVO 没有 customerId），所以这里按
   * **已加载的分页数据**做前端筛选：继续下滑会把后面的页加载进来一起参与筛选。
   * （若后续数据量大，需要后端在分页接口上支持 customerId 才能真正做到服务端过滤。）
   */
  const ALL_STORES = 0;
  const storeStore = useStoreStore();
  const { stores } = storeToRefs(storeStore);
  const filterStoreId = ref<number>(ALL_STORES);

  const visibleList = computed(() =>
    filterStoreId.value === ALL_STORES
      ? list.value
      : list.value.filter((order) => order.customerId === filterStoreId.value),
  );

  const storeFilterOptions = computed(() => [
    { text: '全部门店', value: ALL_STORES },
    ...stores.value.map((store) => ({ text: store.customerName, value: store.customerId })),
  ]);

  const filterStoreName = computed(
    () =>
      stores.value.find((store) => store.customerId === filterStoreId.value)?.customerName ?? '',
  );

  /** 列表计数：筛选态下说清「筛的是已加载数据」，未加载完提示继续下滑 */
  const countText = computed(() => {
    if (filterStoreId.value === ALL_STORES) return `共 ${total.value} 笔订单`;
    const base = `筛选「${filterStoreName.value || '当前门店'}」：${visibleList.value.length} 笔`;
    return finished.value ? base : `${base}（继续下滑加载更多）`;
  });

  const emptyText = computed(() =>
    filterStoreId.value === ALL_STORES ? '暂无相关订单' : '该门店暂无可显示的订单',
  );

  /**
   * 审核轻标记：只给「审核中 / 已驳回」两态（门店需要关注的），
   * 已通过 / 待提交不挂标签 —— 既避免每张卡片多一个无信息量的角标，
   * 也不占用主状态位（主状态位归订单状态）。
   */
  const auditTags = computed<Record<number, { text: string; color: string }>>(() => {
    const map: Record<number, { text: string; color: string }> = {};
    list.value.forEach((order) => {
      const status = order.auditStatus;
      if (status == null || !AUDIT_TAG_STATUSES.includes(status)) return;
      const badge = AUDIT_STATUS_MAP[status];
      if (badge) map[order.id] = badge;
    });
    return map;
  });

  onMounted(() => {
    // 门店账号只有一家店（后端只返回自己），此时不展示筛选项；
    // 拉取失败（未绑定门店 / 网络异常）静默降级为「不展示筛选」，不影响订单列表本身
    void storeStore.fetchStores().catch((error) => {
      console.warn('[order-list] 拉取门店列表失败，门店筛选不可用:', error);
    });
  });
</script>

<template>
  <div class="app-page">
    <AppNavBar title="我的订单" />

    <van-tabs v-model:active="activeTab" sticky @change="onTabChange">
      <van-tab v-for="tab in ORDER_TABS" :key="tab.key" :title="tab.title" />
    </van-tabs>

    <!-- 门店筛选：代理人账号管多家门店，先按门店收敛再看单（门店账号只有自己，不展示） -->
    <van-dropdown-menu v-if="stores.length > 1" class="order-list__filter">
      <van-dropdown-item v-model="filterStoreId" :options="storeFilterOptions" title="全部门店" />
    </van-dropdown-menu>

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
        <div v-if="visibleList.length" class="order-list__count">{{ countText }}</div>
        <div v-if="visibleList.length" class="order-list__wrap">
          <motion.div
            v-for="(order, index) in visibleList"
            :key="order.id"
            class="order-list__item app-card"
            :initial="{ opacity: 0, y: 12 }"
            :animate="{ opacity: 1, y: 0 }"
            :transition="{ delay: Math.min(index, 8) * 0.035, duration: 0.22, ease: 'easeOut' }"
            @click="toDetail(order.id)"
          >
            <div class="flex-between order-list__head">
              <span class="order-list__no">{{ order.orderNo }}</span>
              <span
                class="order-list__status"
                :style="{
                  color: deriveOrderStatusView(order.status, order.auditStatus)
                    .color,
                }"
              >
                {{
                  deriveOrderStatusView(order.status, order.auditStatus).text
                }}
              </span>
            </div>

            <!-- 下单门店：订单只快照 customerId，代理人账号必须能看出这是哪家店的单 -->
            <div class="order-list__store">
              <van-icon name="shop-o" class="order-list__store-icon" />
              <span class="text-ellipsis order-list__store-name">
                {{ order.customerName || '未关联门店' }}
              </span>
              <span
                v-if="auditTags[order.id]"
                class="order-list__chip"
                :style="{
                  color: auditTags[order.id]!.color,
                  borderColor: auditTags[order.id]!.color,
                }"
              >
                {{ auditTags[order.id]!.text }}
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

            <!-- 卡片底部操作：待收货 → 逐行登记实收；已完成 / 已取消 → 再来一单 -->
            <div v-if="canReorder(order) || order.status === 'SHIPPED'" class="order-list__actions">
              <van-button
                v-if="order.status === 'SHIPPED'"
                size="small"
                round
                type="primary"
                @click.stop="toReceipt(order)"
              >
                确认收货
              </van-button>
              <van-button
                v-if="canReorder(order)"
                size="small"
                round
                plain
                type="primary"
                :loading="reordering"
                @click.stop="onReorder(order)"
              >
                再来一单
              </van-button>
            </div>

            <!-- 线下收款状态：客户一眼看出「还要不要传凭证 / 审核结果如何」 -->
            <div v-if="showReceive(order)" class="order-list__receive">
              <span
                class="order-list__chip"
                :style="{
                  color: receiveBadge(order.paymentProofStatus).color,
                  borderColor: receiveBadge(order.paymentProofStatus).color,
                }"
              >
                {{ receiveBadge(order.paymentProofStatus).text }}
              </span>
              <span v-if="order.paidAmount > 0" class="order-list__paid">
                已收 ¥{{ formatPrice(order.paidAmount) }}
              </span>
            </div>
          </motion.div>
        </div>
      </van-list>

      <van-empty v-if="!loading && !visibleList.length" :description="emptyText" />
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

    /* 门店筛选：贴住 tabs，去掉组件默认投影，避免看起来像浮在上面的一层 */
    &__filter {
      :deep(.van-dropdown-menu__bar) {
        height: 44px;
        border-bottom: 1px solid var(--app-border-color);
        box-shadow: none;
      }
    }

    /* 下单门店行：门店名 + 审核轻标记（审核中 / 已驳回） */
    &__store {
      display: flex;
      align-items: center;
      gap: 6px;
      padding-top: 10px;
      font-size: 13px;
    }

    &__store-icon {
      flex: none;
      color: var(--app-primary-color);
    }

    &__store-name {
      flex: 1;
      min-width: 0;
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

    &__receive {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-top: 8px;
    }

    &__chip {
      padding: 1px 6px;
      font-size: 11px;
      line-height: 16px;
      border: 1px solid currentcolor;
      border-radius: 4px;
    }

    &__paid {
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    /* 卡片底部操作：右对齐的次要按钮，不抢「实付金额」的视觉重心 */
    &__actions {
      display: flex;
      justify-content: flex-end;
      padding-top: 10px;
    }
  }
</style>
