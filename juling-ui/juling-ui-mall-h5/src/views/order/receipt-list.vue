<script setup lang="ts">
  import { motion } from 'motion-v';
  import { getStoreReceiptPage } from '@/api/storeReceipt';
  import { RECEIPT_DIFF_TYPE_MAP, RECEIPT_STATUS_MAP } from '@/constants';
  import type { StoreReceiptSummary } from '@/types';
  import { formatDate, formatQuantity } from '@/utils/format';

  defineOptions({ name: 'StoreReceiptList' });

  const router = useRouter();

  /**
   * 待收货列表（门店收货单）。
   * 沿用订单列表的分页写法：下拉刷新 + 触底加载 + 骨架屏 + 空态。
   */
  const { list, loading, finished, refreshing, total, error, onLoad, onRefresh } = usePaging<
    StoreReceiptSummary,
    { pageNo?: number; pageSize?: number }
  >((params) => getStoreReceiptPage(params));

  /** 进入确认收货页；已确认 / 已作废的收货单在页面内以只读方式展示 */
  function toDetail(item: StoreReceiptSummary): void {
    void router.push(`/order/receipt-confirm/${item.orderId}`);
  }

  /** 状态展示配置：未知码兜底后端下发的文案 */
  function statusBadge(item: StoreReceiptSummary): { text: string; color: string } {
    return (
      RECEIPT_STATUS_MAP[item.status] ?? {
        text: item.statusName || '未知状态',
        color: 'var(--app-text-color-secondary)',
      }
    );
  }

  /** 差异标签：无差异（0）不展示，避免每张卡片都挂一个「无差异」 */
  function diffBadge(item: StoreReceiptSummary): { text: string; color: string } {
    return (
      RECEIPT_DIFF_TYPE_MAP[item.diffType] ?? {
        text: item.diffTypeName || '有差异',
        color: 'var(--app-warning-color)',
      }
    );
  }
</script>

<template>
  <div class="app-page">
    <AppNavBar title="待收货" />

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
        <!-- 首屏骨架：列表为空且首屏加载中时用骨架屏代替空白 -->
        <ListSkeleton v-if="!list.length && loading && !refreshing" variant="order" :rows="3" />

        <div v-if="list.length" class="receipt-list__count">共 {{ total }} 笔待收货</div>

        <div v-if="list.length" class="receipt-list__wrap">
          <motion.div
            v-for="(item, index) in list"
            :key="item.id"
            class="receipt-list__item app-card"
            :initial="{ opacity: 0, y: 12 }"
            :animate="{ opacity: 1, y: 0 }"
            :transition="{ delay: Math.min(index, 8) * 0.035, duration: 0.22, ease: 'easeOut' }"
            @click="toDetail(item)"
          >
            <div class="flex-between receipt-list__head">
              <span class="receipt-list__no">{{ item.no || item.orderNo }}</span>
              <span class="receipt-list__status" :style="{ color: statusBadge(item).color }">
                {{ statusBadge(item).text }}
              </span>
            </div>

            <div class="receipt-list__row">
              <span class="receipt-list__label">订单号</span>
              <span class="text-ellipsis receipt-list__value">{{ item.orderNo }}</span>
            </div>
            <div class="receipt-list__row">
              <span class="receipt-list__label">配送出库单</span>
              <span class="text-ellipsis receipt-list__value">{{ item.saleOutNo || '—' }}</span>
            </div>
            <div class="receipt-list__row">
              <span class="receipt-list__label">门店</span>
              <span class="text-ellipsis receipt-list__value">{{ item.customerName || '—' }}</span>
            </div>

            <div class="flex-between receipt-list__foot">
              <span class="receipt-list__meta">
                应收数量 {{ formatQuantity(item.totalCount) }}
                <van-tag
                  v-if="item.diffType"
                  class="receipt-list__tag"
                  plain
                  round
                  :color="diffBadge(item).color"
                >
                  {{ diffBadge(item).text }}
                </van-tag>
              </span>
              <span class="receipt-list__total">
                应收合计 <PriceText :value="item.totalPrice" />
              </span>
            </div>

            <div class="receipt-list__time">
              {{
                item.receiveTime ? formatDate(item.receiveTime, 'YYYY-MM-DD HH:mm') : '待确认收货'
              }}
            </div>

            <div class="receipt-list__actions">
              <van-button
                size="small"
                round
                type="primary"
                :plain="item.status !== 0"
                @click.stop="toDetail(item)"
              >
                {{ item.status === 0 ? '确认收货' : '查看详情' }}
              </van-button>
            </div>
          </motion.div>
        </div>
      </van-list>

      <van-empty v-if="!loading && !list.length" description="暂无待收货订单" />
    </van-pull-refresh>
  </div>
</template>

<style scoped lang="scss">
  .receipt-list {
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

    &__row {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-top: 8px;
      font-size: 13px;
    }

    &__label {
      flex: none;
      width: 72px;
      color: var(--app-text-color-secondary);
    }

    &__value {
      flex: 1;
      min-width: 0;
    }

    &__foot {
      margin-top: 10px;
      padding-top: 10px;
      border-top: 1px solid var(--app-border-color);
      font-size: 12px;
    }

    &__meta {
      display: flex;
      align-items: center;
      gap: 6px;
      color: var(--app-text-color-secondary);
    }

    &__tag {
      flex: none;
    }

    &__total {
      display: flex;
      align-items: baseline;
      gap: 2px;
    }

    &__time {
      margin-top: 6px;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    /* 卡片底部操作：右对齐的次要按钮，不抢金额的视觉重心 */
    &__actions {
      display: flex;
      justify-content: flex-end;
      padding-top: 10px;
    }
  }
</style>
