<script setup lang="ts">
  import { showSuccessToast, showToast } from 'vant';
  import { cancelOrder, confirmOrder, getOrderDetail } from '@/api/order';
  import { ORDER_STATUS_MAP, ORDER_STATUS_STEPS } from '@/constants';
  import type { Order } from '@/types';
  import { confirmDialog } from '@/utils/confirm';
  import { formatDate, formatPrice, maskMobile } from '@/utils/format';
  import { resolveImage } from '@/utils/image';
  import { copyText } from '@/utils/index';
  import { BizError } from '@/utils/request';

  defineOptions({ name: 'OrderDetail' });

  const route = useRoute();
  const orderId = computed(() => Number(route.params.id));

  const order = ref<Order | null>(null);
  const loading = ref(true);
  /** 加载失败（网络 / 服务异常）——与「订单不存在」区分，可重试 */
  const loadError = ref(false);
  /** 取消 / 确认收货进行中：按钮显示 loading，避免重复提交 */
  const acting = ref(false);

  /** 各步骤对应的发生时间，作为步骤条副标题展示 */
  const stepTimes = computed<Record<string, string | undefined>>(() => {
    const current = order.value;
    if (!current) return {};
    return {
      UNPAID: current.createTime ? formatDate(current.createTime, 'MM-DD HH:mm') : undefined,
      PAID: current.payTime ? formatDate(current.payTime, 'MM-DD HH:mm') : undefined,
      SHIPPED: current.deliveryTime ? formatDate(current.deliveryTime, 'MM-DD HH:mm') : undefined,
      COMPLETED: undefined,
    };
  });

  /** 当前状态在正向流程中的位置，供 van-steps 高亮 */
  const activeStep = computed(() => {
    const status = order.value?.status;
    if (!status) return 0;
    const index = ORDER_STATUS_STEPS.findIndex((step) => step.key === status);
    return index < 0 ? 0 : index;
  });

  /** 已取消 / 售后中不属于正向流程，用步骤条展示会误导，改回色块 */
  const isAbnormal = computed(
    () => order.value?.status === 'CANCELED' || order.value?.status === 'AFTER_SALE',
  );

  async function load(): Promise<void> {
    loading.value = true;
    try {
      order.value = await getOrderDetail(orderId.value);
      loadError.value = false;
    } catch (error) {
      // 拦截器已提示。业务错误（订单不存在）与网络异常要区分：后者给重试入口
      loadError.value = !(error instanceof BizError);
    } finally {
      loading.value = false;
    }
  }

  async function onCancel(): Promise<void> {
    if (!(await confirmDialog('确认取消该订单？'))) return;
    acting.value = true;
    try {
      await cancelOrder(orderId.value);
      showSuccessToast('订单已取消');
      await load();
    } catch {
      // 拦截器已提示
    } finally {
      acting.value = false;
    }
  }

  async function onReceive(): Promise<void> {
    if (!(await confirmDialog('确认已收到货物？'))) return;
    acting.value = true;
    try {
      await confirmOrder(orderId.value);
      showSuccessToast('已确认收货');
      await load();
    } catch {
      // 拦截器已提示
    } finally {
      acting.value = false;
    }
  }

  function onCopy(): void {
    if (!order.value) return;
    void copyText(order.value.orderNo).then((ok) => {
      showToast(ok ? '订单号已复制' : '复制失败');
    });
  }

  onMounted(() => {
    void load();
  });
</script>

<template>
  <div class="app-page order-detail">
    <AppNavBar title="订单详情" />

    <!-- 加载态：骨架屏（贴合内容结构，避免居中转圈带来的跳动） -->
    <div v-if="loading" class="order-detail__skeleton">
      <van-skeleton title :row="3" />
      <van-skeleton title :row="4" class="mt-3" />
    </div>

    <!-- 加载失败：网络 / 服务异常，给一个重试入口（与「订单不存在」区分开） -->
    <div v-else-if="loadError" class="order-detail__error">
      <van-empty image="error" description="加载失败，请检查网络后重试">
        <van-button round type="primary" size="small" class="mt-3" @click="load">
          重新加载
        </van-button>
      </van-empty>
    </div>

    <template v-else-if="order">
      <div class="app-scroll">
        <!-- 状态：正向流程用垂直步骤条展示进度（含各节点时间）；取消 / 售后用色块 -->
        <van-steps
          v-if="!isAbnormal"
          direction="vertical"
          :active="activeStep"
          active-color="var(--app-primary-color)"
          class="order-detail__steps"
        >
          <van-step v-for="step in ORDER_STATUS_STEPS" :key="step.key">
            {{ step.text }}
            <div v-if="stepTimes[step.key]" class="order-detail__step-time">
              {{ stepTimes[step.key] }}
            </div>
          </van-step>
        </van-steps>
        <div
          v-else
          class="order-detail__status"
          :style="{ background: ORDER_STATUS_MAP[order.status].color }"
        >
          <div class="order-detail__status-text">{{ ORDER_STATUS_MAP[order.status].text }}</div>
          <div class="order-detail__status-tip">订单号 {{ order.orderNo }}</div>
        </div>

        <!-- 收货信息 -->
        <van-cell-group inset class="order-detail__group">
          <van-cell title="收货人" :value="order.receiverName" />
          <van-cell title="联系电话" :value="maskMobile(order.receiverMobile)" />
          <van-cell title="收货地址" :label="order.receiverAddress" />
        </van-cell-group>

        <!-- 商品 -->
        <div class="order-detail__card app-card">
          <div class="order-detail__title">商品信息</div>
          <div v-for="item in order.items" :key="item.id" class="order-detail__item">
            <van-image
              class="order-detail__img"
              :src="resolveImage(item.picUrl)"
              fit="cover"
              radius="6"
              lazy-load
            />
            <div class="order-detail__info">
              <div class="text-ellipsis-2 order-detail__name">{{ item.name }}</div>
              <div class="order-detail__spec text-ellipsis">{{ item.specText }}</div>
            </div>
            <div class="order-detail__amount">
              <div>¥{{ formatPrice(item.price) }}</div>
              <div class="order-detail__qty">× {{ item.quantity }}</div>
            </div>
          </div>
        </div>

        <!-- 金额 -->
        <van-cell-group inset class="order-detail__group">
          <van-cell title="商品总额" :value="`¥${formatPrice(order.totalPrice)}`" />
          <van-cell title="运费" :value="`¥${formatPrice(order.freightPrice ?? 0)}`" />
          <van-cell title="优惠" :value="`-¥${formatPrice(order.discountPrice ?? 0)}`" />
          <van-cell title="实付金额">
            <template #value>
              <PriceText :value="order.payPrice" />
            </template>
          </van-cell>
        </van-cell-group>

        <!-- 时间线 -->
        <van-cell-group inset class="order-detail__group">
          <van-cell title="下单时间" :value="formatDate(order.createTime)" />
          <van-cell v-if="order.payTime" title="支付时间" :value="formatDate(order.payTime)" />
          <van-cell
            v-if="order.deliveryTime"
            title="发货时间"
            :value="formatDate(order.deliveryTime)"
          />
        </van-cell-group>
      </div>

      <!-- 底部固定操作栏：无需滚到底即可操作 -->
      <van-action-bar class="order-detail__bar">
        <van-action-bar-button type="default" text="复制订单号" @click="onCopy" />
        <van-action-bar-button
          v-if="order.status === 'UNPAID'"
          type="danger"
          text="取消订单"
          :loading="acting"
          @click="onCancel"
        />
        <van-action-bar-button
          v-if="order.status === 'SHIPPED'"
          type="primary"
          :loading="acting"
          text="确认收货"
          @click="onReceive"
        />
      </van-action-bar>
    </template>

    <van-empty v-else description="订单不存在" />
  </div>
</template>

<style scoped lang="scss">
  /* 内容区避让底部固定操作栏（van-action-bar 无 placeholder） */
  :deep(.app-scroll) {
    padding-bottom: 56px;
  }

  .order-detail {
    &__skeleton {
      padding: 24px 16px;
    }

    &__error {
      display: flex;
      flex: 1;
      align-items: center;
      justify-content: center;
    }

    &__steps {
      padding: 16px 0;
      background: #fff;
    }

    &__step-time {
      margin-top: 2px;
      font-size: 11px;
      color: var(--app-text-color-secondary);
    }

    &__status {
      padding: 20px 16px;
      color: #fff;
    }

    &__status-text {
      font-size: 20px;
      font-weight: 600;
    }

    &__status-tip {
      margin-top: 6px;
      font-size: 12px;
      opacity: 0.9;
    }

    &__group {
      margin-top: 12px;
    }

    &__card {
      margin: 12px;
      padding: 12px;
    }

    &__title {
      margin-bottom: 8px;
      font-size: 14px;
      font-weight: 600;
    }

    &__item {
      display: flex;
      gap: 10px;
      padding: 8px 0;

      & + & {
        border-top: 1px solid var(--app-border-color);
      }
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
  }
</style>
