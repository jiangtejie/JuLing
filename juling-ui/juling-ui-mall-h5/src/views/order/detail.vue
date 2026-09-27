<script setup lang="ts">
  import { showImagePreview, showSuccessToast, showToast } from 'vant';
  import { cancelOrder, confirmOrder, getOrderDetail, getPaymentProofList } from '@/api/order';
  import {
    ORDER_STATUS_MAP,
    ORDER_STATUS_STEPS,
    PROOF_STATUS_MAP,
    RECEIVE_STATUS_MAP,
  } from '@/constants';
  import type { Order, PaymentProof } from '@/types';
  import { confirmDialog } from '@/utils/confirm';
  import { formatDate, formatPrice, maskMobile } from '@/utils/format';
  import { resolveImage } from '@/utils/image';
  import { copyText } from '@/utils/index';
  import { BizError } from '@/utils/request';

  defineOptions({ name: 'OrderDetail' });

  const route = useRoute();
  const router = useRouter();
  const orderId = computed(() => Number(route.params.id));

  const order = ref<Order | null>(null);
  /** 付款凭证记录（含历史与驳回记录） */
  const proofs = ref<PaymentProof[]>([]);
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

  /** 待收金额：应付 - 已确认收款，负数归零 */
  const remainAmount = computed(() => {
    const current = order.value;
    if (!current) return 0;
    return Math.max(0, current.payPrice - current.paidAmount);
  });

  /** 订单维度的收款状态展示配置（未知码兜底「待上传凭证」） */
  const receiveBadge = computed(
    () => RECEIVE_STATUS_MAP[order.value?.paymentProofStatus ?? 0] ?? RECEIVE_STATUS_MAP[0],
  );

  /** 最近一条被驳回的凭证：用于在卡片上直接提示驳回原因 */
  const rejectedProof = computed(() => proofs.value.find((item) => item.status === 2));

  /** 还能上传凭证：货款未收齐，且订单不在取消 / 售后等异常态 */
  const canUpload = computed(() => remainAmount.value > 0 && !isAbnormal.value);
  const uploadText = computed(() =>
    proofs.value.length ? '重新上传付款凭证' : '上传付款凭证',
  );

  function toPayment(): void {
    void router.push(`/order/${orderId.value}/payment`);
  }

  async function load(): Promise<void> {
    loading.value = true;
    try {
      const [detail, proofList] = await Promise.all([
        getOrderDetail(orderId.value),
        getPaymentProofList(orderId.value),
      ]);
      order.value = detail;
      proofs.value = proofList;
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

        <!-- 线下收款：收款状态 + 应付/已收/待收 + 凭证与驳回原因（客户自助查看核验进度） -->
        <div class="order-detail__card app-card">
          <div class="flex-between">
            <span class="order-detail__title">货款收款</span>
            <span
              class="order-detail__chip"
              :style="{ color: receiveBadge.color, borderColor: receiveBadge.color }"
            >
              {{ receiveBadge.text }}
            </span>
          </div>

          <div class="order-detail__receive">
            <div class="order-detail__receive-item">
              <div class="order-detail__receive-label">应付</div>
              <div class="order-detail__receive-value">¥{{ formatPrice(order.payPrice) }}</div>
            </div>
            <div class="order-detail__receive-item">
              <div class="order-detail__receive-label">已收</div>
              <div class="order-detail__receive-value">¥{{ formatPrice(order.paidAmount) }}</div>
            </div>
            <div class="order-detail__receive-item">
              <div class="order-detail__receive-label">待收</div>
              <div class="order-detail__receive-value order-detail__receive-value--strong">
                ¥{{ formatPrice(remainAmount) }}
              </div>
            </div>
          </div>

          <div v-if="rejectedProof" class="order-detail__reject">
            凭证被驳回：{{ rejectedProof.auditRemark || '未填写原因' }}
          </div>

          <!-- 凭证图片：点击看大图 -->
          <div v-if="proofs.length" class="order-detail__proofs">
            <div v-for="proof in proofs" :key="proof.id" class="order-detail__proof">
              <div class="flex-between order-detail__proof-head">
                <span>
                  申报 ¥{{ formatPrice(proof.amount) }}
                  <template v-if="proof.confirmedAmount != null">
                    · 核定 ¥{{ formatPrice(proof.confirmedAmount) }}
                  </template>
                </span>
                <span :style="{ color: PROOF_STATUS_MAP[proof.status]?.color }">
                  {{ PROOF_STATUS_MAP[proof.status]?.text ?? '未知' }}
                </span>
              </div>
              <div class="order-detail__proof-imgs">
                <van-image
                  v-for="(url, index) in proof.urls"
                  :key="index"
                  class="order-detail__proof-img"
                  :src="resolveImage(url)"
                  fit="cover"
                  radius="4"
                  @click="showImagePreview({ images: proof.urls, startPosition: index })"
                />
              </div>
              <div class="order-detail__proof-meta">
                {{ formatDate(proof.createTime, 'YYYY-MM-DD HH:mm') }}
                <template v-if="proof.payerName"> · {{ proof.payerName }}</template>
              </div>
            </div>
          </div>

          <van-button
            v-if="canUpload"
            class="mt-3"
            type="primary"
            block
            round
            size="small"
            :text="uploadText"
            @click="toPayment"
          />
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
          v-if="canUpload"
          type="primary"
          text="上传凭证"
          @click="toPayment"
        />
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

    &__chip {
      padding: 1px 6px;
      font-size: 11px;
      line-height: 16px;
      border: 1px solid currentcolor;
      border-radius: 4px;
    }

    &__receive {
      display: flex;
      margin-top: 12px;
    }

    &__receive-item {
      flex: 1;
      text-align: center;
    }

    &__receive-label {
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__receive-value {
      margin-top: 4px;
      font-size: 15px;
      font-weight: 600;

      &--strong {
        color: var(--app-danger-color);
      }
    }

    &__reject {
      margin-top: 10px;
      padding: 8px 10px;
      font-size: 12px;
      line-height: 1.5;
      color: var(--app-danger-color);
      background: #fff7f6;
      border-radius: 8px;
    }

    &__proofs {
      margin-top: 4px;
    }

    &__proof {
      padding: 10px 0;

      & + & {
        border-top: 1px solid var(--app-border-color);
      }
    }

    &__proof-head {
      font-size: 13px;
    }

    &__proof-imgs {
      display: flex;
      gap: 8px;
      margin-top: 8px;
    }

    &__proof-img {
      width: 72px;
      height: 72px;
    }

    &__proof-meta {
      margin-top: 6px;
      font-size: 12px;
      color: var(--app-text-color-secondary);
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
