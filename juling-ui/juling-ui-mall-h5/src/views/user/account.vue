<script setup lang="ts">
  import { getStoreAccountPage, getStoreAccountSummary } from '@/api/storeAccount';
  import type { StoreAccountBill, StoreAccountSummary } from '@/types/storeAccount';
  import { formatDate } from '@/utils/format';

  defineOptions({ name: 'UserAccount' });

  /**
   * 我的账（门店往来台账）—— **只读**。
   *
   * 门店最关心三件事：欠总部多少、已经付了多少、每一笔是什么。
   * 代理人账号名下可能有多家门店，所以顶部按门店分行展示余额，点门店看该门店的逐笔明细；
   * 台账数据全部由业务动作自动产生（配送出库审核挂应收、收款审批冲减、收货差异调整），
   * 因此本页**不提供任何记账 / 修改入口**，避免门店以为可以自己改账。
   *
   * 口径：后端金额单位是**元**（ERP BigDecimal），正数 = 门店欠总部。
   */

  /** 门店筛选哨兵值：customerId 是自增主键，0 不会与真实门店冲突 */
  const ALL_STORES = 0;

  const summary = ref<StoreAccountSummary[]>([]);
  const summaryLoading = ref(true);
  const summaryError = ref(false);
  /** 明细当前查看的门店；ALL_STORES = 全部门店混排 */
  const activeCustomerId = ref<number>(ALL_STORES);

  /* -------------------------------- 金额展示 -------------------------------- */

  /**
   * 台账金额（元）格式化：千分位 + 两位小数。
   *
   * 注意不能套 `formatPrice`（它按「分 → 元」换算），台账单位本来就是元。
   */
  function formatYuan(value: number): string {
    const num = Number.isFinite(value) ? value : 0;
    const [int, dec] = Math.abs(num).toFixed(2).split('.');
    const withSeparator = (int ?? '0').replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    return `${num < 0 ? '-' : ''}${withSeparator}.${dec ?? '00'}`;
  }

  /** 明细金额带符号：正数 = 挂账（门店欠总部增加），负数 = 冲减 / 已收 */
  function signedYuan(value: number): string {
    return `${value > 0 ? '+' : ''}${formatYuan(value)}`;
  }

  /** 金额配色：正数（欠总部）警示色、负数（冲减）成功色、0 次要色 */
  function amountClass(value: number): string {
    if (value > 0) return 'account__amount--debit';
    if (value < 0) return 'account__amount--credit';
    return 'account__amount--zero';
  }

  /* --------------------------------- 汇总 --------------------------------- */

  /** 合计（多门店 = 各门店之和） */
  const totals = computed(() =>
    summary.value.reduce(
      (acc, item) => ({
        totalReceivable: acc.totalReceivable + item.totalReceivable,
        totalReceived: acc.totalReceived + item.totalReceived,
        balance: acc.balance + item.balance,
      }),
      { totalReceivable: 0, totalReceived: 0, balance: 0 },
    ),
  );

  /** 多门店：展示门店分行与「全部门店」入口；单门店不展示（没有可切换的对象） */
  const multiStore = computed(() => summary.value.length > 1);

  const activeStoreName = computed(() => {
    if (activeCustomerId.value === ALL_STORES) return '';
    const store = summary.value.find((item) => item.customerId === activeCustomerId.value);
    return store?.customerName || `门店 ${activeCustomerId.value}`;
  });

  const detailScopeText = computed(() => {
    const scope = activeCustomerId.value === ALL_STORES ? '全部门店' : activeStoreName.value;
    return `${scope} · 共 ${total.value} 笔`;
  });

  async function loadSummary(): Promise<void> {
    summaryLoading.value = true;
    try {
      summary.value = await getStoreAccountSummary();
      summaryError.value = false;
      // 之前选中的门店在本次汇总里不存在了（门店被解绑）→ 回到全部门店
      if (
        activeCustomerId.value !== ALL_STORES &&
        !summary.value.some((item) => item.customerId === activeCustomerId.value)
      ) {
        await onPickStore(ALL_STORES);
      }
    } catch (error) {
      // 拦截器已提示
      summaryError.value = true;
      console.warn('[account] 拉取门店往来汇总失败:', error);
    } finally {
      summaryLoading.value = false;
    }
  }

  /* -------------------------------- 明细分页 -------------------------------- */

  const { list, loading, finished, refreshing, total, error, onLoad, onRefresh, search } =
    usePaging<StoreAccountBill, { customerId?: number }>((params) => getStoreAccountPage(params));

  /** 下拉刷新：门店汇总与逐笔明细一起刷新（两者口径必须一致） */
  async function onRefreshAll(): Promise<void> {
    await Promise.all([loadSummary(), onRefresh()]);
  }

  /** 切换查看的门店：明细回到第一页重新加载 */
  async function onPickStore(customerId: number): Promise<void> {
    if (activeCustomerId.value === customerId) return;
    activeCustomerId.value = customerId;
    await search({ customerId: customerId === ALL_STORES ? undefined : customerId });
  }

  onMounted(() => {
    void loadSummary();
  });
</script>

<template>
  <div class="app-page account">
    <AppNavBar title="我的账" />

    <van-pull-refresh v-model="refreshing" @refresh="onRefreshAll">
      <!-- 汇总：累计应收 / 累计已收 / 当前余额（正数 = 门店欠总部） -->
      <div v-if="summaryLoading && !summary.length" class="account__skeleton">
        <van-skeleton title :row="3" />
      </div>

      <template v-else-if="summary.length">
        <div class="account__summary">
          <div class="account__summary-label">当前余额（正数表示门店欠总部）</div>
          <div class="account__summary-value" :class="amountClass(totals.balance)">
            ¥{{ formatYuan(totals.balance) }}
          </div>
          <div class="account__summary-row">
            <div class="account__summary-item">
              <div class="account__summary-item-label">累计应收</div>
              <div class="account__summary-item-value">
                ¥{{ formatYuan(totals.totalReceivable) }}
              </div>
            </div>
            <div class="account__summary-item">
              <div class="account__summary-item-label">累计已收 / 冲减</div>
              <div class="account__summary-item-value">¥{{ formatYuan(totals.totalReceived) }}</div>
            </div>
          </div>
          <div class="account__summary-tip">
            <template v-if="multiStore"
              >名下共 {{ summary.length }} 家门店，点门店可只看它的账</template
            >
            <template v-else>{{
              activeStoreName || summary[0]!.customerName || '当前门店'
            }}</template>
          </div>
        </div>

        <!-- 多门店：按门店分行展示余额，点一行把明细收敛到该门店 -->
        <van-cell-group v-if="multiStore" inset class="account__stores">
          <van-cell
            title="全部门店"
            :label="`${summary.length} 家门店合计`"
            clickable
            :class="{ 'account__store--active': activeCustomerId === ALL_STORES }"
            @click="onPickStore(ALL_STORES)"
          >
            <template #value>
              <span class="account__store-value" :class="amountClass(totals.balance)">
                ¥{{ formatYuan(totals.balance) }}
              </span>
            </template>
          </van-cell>
          <van-cell
            v-for="store in summary"
            :key="store.customerId"
            :title="store.customerName || `门店 ${store.customerId}`"
            :label="`累计应收 ¥${formatYuan(store.totalReceivable)} · 累计已收 ¥${formatYuan(store.totalReceived)}`"
            clickable
            :class="{ 'account__store--active': activeCustomerId === store.customerId }"
            @click="onPickStore(store.customerId)"
          >
            <template #value>
              <span class="account__store-value" :class="amountClass(store.balance)">
                ¥{{ formatYuan(store.balance) }}
              </span>
            </template>
          </van-cell>
        </van-cell-group>

        <div class="account__detail-head">
          <span class="account__detail-title">往来明细</span>
          <span class="account__detail-sub">{{ detailScopeText }}</span>
        </div>
      </template>

      <!-- 还没有任何往来：给出原因与下一步，不留白 -->
      <van-empty
        v-else
        :image="summaryError ? 'error' : 'default'"
        :description="summaryError ? '加载失败，请检查网络后重试' : '暂无可查看的门店往来账'"
      >
        <van-button
          v-if="summaryError"
          round
          type="primary"
          size="small"
          class="mt-3"
          @click="loadSummary"
        >
          重新加载
        </van-button>
        <div v-else class="account__empty-tip">
          当前账号还没有绑定门店，或还没有产生往来账（配送发货、收款审批、收货差异都会自动记账）。如有疑问请联系总部。
        </div>
      </van-empty>

      <template v-if="summary.length">
        <van-list
          v-model:loading="loading"
          :finished="finished"
          :error="error"
          :loading-text="list.length ? '加载中...' : ''"
          finished-text="没有更多了"
          error-text="加载失败，点击重试"
          @load="onLoad"
        >
          <ListSkeleton v-if="!list.length && loading && !refreshing" variant="order" :rows="3" />

          <div v-if="list.length" class="account__bills">
            <div v-for="bill in list" :key="bill.id" class="account__bill app-card">
              <div class="flex-between account__bill-head">
                <span class="account__bill-type">{{ bill.bizTypeName || '往来记账' }}</span>
                <span class="account__bill-amount" :class="amountClass(bill.amount)">
                  {{ signedYuan(bill.amount) }}
                </span>
              </div>

              <div v-if="multiStore" class="account__bill-row">
                <span class="account__bill-label">门店</span>
                <span class="text-ellipsis account__bill-value">
                  {{ bill.customerName || `门店 ${bill.customerId}` }}
                </span>
              </div>
              <div v-if="bill.sourceNo" class="account__bill-row">
                <span class="account__bill-label">来源单号</span>
                <span class="text-ellipsis account__bill-value">{{ bill.sourceNo }}</span>
              </div>
              <div class="account__bill-row">
                <span class="account__bill-label">业务时间</span>
                <span class="account__bill-value">
                  {{ bill.billTime ? formatDate(bill.billTime, 'YYYY-MM-DD HH:mm') : '—' }}
                </span>
              </div>
              <div v-if="bill.remark" class="account__bill-remark">{{ bill.remark }}</div>
              <div class="account__bill-balance"> 记账后余额 ¥{{ formatYuan(bill.balance) }} </div>
            </div>
          </div>
        </van-list>

        <van-empty v-if="!loading && !list.length" description="暂无往来记录" />
      </template>
    </van-pull-refresh>

    <!-- 只读声明：台账由业务动作自动产生，页面不提供任何记账入口 -->
    <div class="account__footer">
      台账由系统按业务动作自动生成（配送发货、收款审批、收货差异），本页仅供查看；如有疑问请联系总部核对。
    </div>
  </div>
</template>

<style scoped lang="scss">
  .account {
    &__skeleton {
      padding: 24px 16px;
    }

    /* 汇总头部 */
    &__summary {
      padding: 20px 16px;
      background: var(--app-primary-gradient);
      color: #fff;
    }

    &__summary-label {
      font-size: 12px;
      opacity: 0.9;
    }

    &__summary-value {
      margin-top: 6px;
      font-size: 28px;
      font-weight: 600;
      line-height: 1.2;
    }

    &__summary-row {
      display: flex;
      margin-top: 16px;
    }

    &__summary-item {
      flex: 1;
    }

    &__summary-item-label {
      font-size: 12px;
      opacity: 0.9;
    }

    &__summary-item-value {
      margin-top: 2px;
      font-size: 15px;
      font-weight: 600;
    }

    &__summary-tip {
      margin-top: 12px;
      font-size: 11px;
      opacity: 0.85;
    }

    /* 汇总卡里的金额是白底渐变上的文字，统一用白色，不套欠款/冲减配色 */
    &__summary-value,
    &__summary-item-value {
      color: #fff;
    }

    /* 门店分行 */
    &__stores {
      margin-top: 12px;
    }

    &__store--active {
      :deep(.van-cell__title) {
        font-weight: 600;
      }

      :deep(.van-cell) {
        background: var(--app-bg-color);
      }
    }

    &__store-value {
      font-weight: 600;
    }

    /* 明细 */
    &__detail-head {
      display: flex;
      align-items: baseline;
      justify-content: space-between;
      padding: 16px 16px 0;
    }

    &__detail-title {
      font-size: 15px;
      font-weight: 600;
    }

    &__detail-sub {
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__bills {
      display: flex;
      flex-direction: column;
      gap: 10px;
      padding: 12px;
    }

    &__bill {
      padding: 12px;
    }

    &__bill-head {
      padding-bottom: 8px;
      border-bottom: 1px solid var(--app-border-color);
    }

    &__bill-type {
      font-size: 14px;
      font-weight: 600;
    }

    &__bill-amount {
      font-size: 15px;
      font-weight: 600;
    }

    &__bill-row {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-top: 8px;
      font-size: 12px;
    }

    &__bill-label {
      flex: none;
      width: 60px;
      color: var(--app-text-color-secondary);
    }

    &__bill-value {
      flex: 1;
      min-width: 0;
    }

    &__bill-remark {
      margin-top: 6px;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__bill-balance {
      margin-top: 8px;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    /* 金额配色：正数 = 门店欠总部（挂账），负数 = 冲减 / 已收 */
    &__amount--debit {
      color: var(--app-danger-color);
    }

    &__amount--credit {
      color: var(--app-success-color);
    }

    &__amount--zero {
      color: var(--app-text-color-secondary);
    }

    &__empty-tip {
      padding: 0 24px;
      font-size: 12px;
      line-height: 1.6;
      color: var(--app-text-color-secondary);
    }

    &__footer {
      padding: 8px 16px calc(20px + env(safe-area-inset-bottom));
      font-size: 11px;
      line-height: 1.6;
      color: var(--app-text-color-secondary);
    }
  }
</style>
