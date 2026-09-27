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
  /** 凭证折叠面板展开项：默认展开最新一条，避免历史凭证把页面撑长 */
  const activeProofs = ref<string[]>([]);

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

  /* ---------------------------- 收款进度（van-steps） ---------------------------- */

  /** 收款进度三步：客户上传 → 财务核验 → 收款完成 */
  const RECEIVE_STEPS = ['上传凭证', '财务核验', '收款完成'] as const;

  /** 由订单收款状态推导当前处于哪一步 */
  const receiveStepActive = computed(() => {
    const status = order.value?.paymentProofStatus ?? 0;
    if (status === 4) return 2; // 已收齐
    if (status === 1 || status === 3) return 1; // 待核验 / 部分收款：核验环节
    return 0; // 未上传 / 已驳回：回到上传环节
  });

  /** 已驳回时进度条用警示色，避免看起来「一切正常」 */
  const receiveStepColor = computed(() =>
    order.value?.paymentProofStatus === 2
      ? 'var(--app-danger-color)'
      : 'var(--app-primary-color)',
  );

  /**
   * 收款进度的时间摘要。
   *
   * 刻意不放进 van-step 里：横向步骤条的最后一个步骤是绝对定位且宽度 auto，
   * 往标题里塞第二行文字会把它撑出容器（表现为内容溢出/边距错乱）。
   */
  const receiveHint = computed(() => {
    const list = [...proofs.value].sort((a, b) => a.id - b.id);
    if (!list.length) return '';
    const first = formatDate(list[0]!.createTime, 'MM-DD HH:mm');
    const audited = list.filter((item) => item.auditTime);
    const lastAudit = audited.length
      ? formatDate(audited[audited.length - 1]!.auditTime, 'MM-DD HH:mm')
      : '';
    return lastAudit
      ? `首次提交 ${first} · 最近核验 ${lastAudit}`
      : `首次提交 ${first} · 等待财务核验`;
  });

  /**
   * 底部是否还有可执行操作。
   *
   * 线下收款下，货款已收齐且订单已发货/完成的订单可能一个操作都没有，
   * 此时整条操作栏应当隐藏，否则会留下一条没有任何按钮的空白栏。
   */
  const hasActions = computed(
    () =>
      canUpload.value ||
      order.value?.status === 'UNPAID' ||
      order.value?.status === 'SHIPPED',
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
      // 默认展开最新一条凭证，历史记录收起
      activeProofs.value = proofList.length
        ? [String(proofList[proofList.length - 1]!.id)]
        : [];
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

  /**
   * 路由参数变化时重新拉取。
   *
   * 从 /order/18 直接跳到 /order/23 时 vue-router 会复用同一组件、不再触发 onMounted，
   * 不监听就会一直显示上一个订单的数据。
   */
  watch(orderId, () => {
    if (orderId.value) void load();
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
      <div class="app-scroll" :class="{ 'app-scroll--with-bar': hasActions }">
        <!-- 订单状态：正向流程用垂直步骤条展示进度（含各节点时间）；取消 / 售后用色块 -->
        <van-steps
          v-if="!isAbnormal"
          direction="vertical"
          :active="activeStep"
          active-color="var(--app-primary-color)"
          inactive-color="#c8c9cc"
          class="order-detail__steps"
        >
          <van-step v-for="step in ORDER_STATUS_STEPS" :key="step.key">
            <div class="order-detail__step-title">{{ step.text }}</div>
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

        <!-- 货款收款：收款进度（van-steps）+ 金额 + 驳回提示 + 凭证（van-collapse） -->
        <div class="order-detail__card app-card">
          <div class="flex-between">
            <span class="order-detail__title">货款收款</span>
            <van-tag class="order-detail__tag" :color="receiveBadge.color" plain round>
              {{ receiveBadge.text }}
            </van-tag>
          </div>

          <!-- 收款进度：客户上传 → 财务核验 → 收款完成 -->
          <van-steps
            :active="receiveStepActive"
            :active-color="receiveStepColor"
            inactive-color="#c8c9cc"
            class="order-detail__receive-steps"
          >
            <van-step v-for="label in RECEIVE_STEPS" :key="label">
              {{ label }}
            </van-step>
          </van-steps>
          <div v-if="receiveHint" class="order-detail__receive-hint">
            {{ receiveHint }}
          </div>

          <!-- 金额：应付 / 已收 / 待收 -->
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
              <div
                class="order-detail__receive-value"
                :class="{ 'order-detail__receive-value--strong': remainAmount > 0 }"
              >
                ¥{{ formatPrice(remainAmount) }}
              </div>
            </div>
          </div>

          <!-- 驳回原因：用 notice-bar 直接带出后台核验意见，引导客户重传 -->
          <van-notice-bar
            v-if="rejectedProof"
            class="order-detail__notice"
            left-icon="warning-o"
            color="var(--app-danger-color)"
            background="#fff7f6"
            wrapable
            :text="`凭证未通过：${rejectedProof.auditRemark || '未填写原因'}，请重新上传`"
          />

          <van-divider v-if="proofs.length" class="order-detail__divider" />

          <!-- 凭证记录：折叠面板，默认展开最新一条，历史可展开查看 -->
          <van-collapse v-if="proofs.length" v-model="activeProofs" class="order-detail__proofs">
            <van-collapse-item
              v-for="proof in proofs"
              :key="proof.id"
              :name="String(proof.id)"
            >
              <template #title>
                <div class="order-detail__proof-title">
                  <span>
                    申报 ¥{{ formatPrice(proof.amount) }}
                    <template v-if="proof.confirmedAmount != null">
                      · 核定 ¥{{ formatPrice(proof.confirmedAmount) }}
                    </template>
                  </span>
                  <van-tag
                    class="order-detail__tag"
                    :color="PROOF_STATUS_MAP[proof.status]?.color"
                    plain
                    round
                  >
                    {{ PROOF_STATUS_MAP[proof.status]?.text ?? '未知' }}
                  </van-tag>
                </div>
              </template>

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
              <div v-if="proof.auditRemark" class="order-detail__proof-remark">
                核验意见：{{ proof.auditRemark }}
              </div>
            </van-collapse-item>
          </van-collapse>
          <div v-else class="order-detail__proof-empty">还没有上传付款凭证</div>

          <van-button
            v-if="canUpload"
            class="order-detail__upload"
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

        <!-- 商品信息：用 van-card 展示订单行 -->
        <div class="order-detail__card app-card">
          <div class="order-detail__title">商品信息</div>
          <van-card
            v-for="item in order.items"
            :key="item.id"
            class="order-detail__goods"
            :title="item.name"
            :desc="item.specText"
            :num="item.quantity"
            :price="formatPrice(item.price)"
            :thumb="resolveImage(item.picUrl)"
          />
        </div>

        <!-- 金额明细 -->
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

        <!-- 订单信息与时间 -->
        <van-cell-group inset class="order-detail__group">
          <van-cell title="订单号" class="order-detail__no" @click="onCopy">
            <template #value>
              <span class="order-detail__no-text">{{ order.orderNo }}</span>
            </template>
            <template #right-icon>
              <span class="order-detail__copy" @click.stop="onCopy">复制</span>
            </template>
          </van-cell>
          <van-cell title="下单时间" :value="formatDate(order.createTime)" />
          <van-cell v-if="order.payTime" title="收款时间" :value="formatDate(order.payTime)" />
          <van-cell
            v-if="order.deliveryTime"
            title="发货时间"
            :value="formatDate(order.deliveryTime)"
          />
        </van-cell-group>
      </div>

      <!-- 底部固定操作栏：无需滚到底即可操作 -->
      <van-action-bar v-if="hasActions" class="order-detail__bar">
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
  /* 内容区避让底部固定操作栏（van-action-bar 无 placeholder），没有操作栏时不留白 */
  :deep(.app-scroll--with-bar) {
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

    /*
     * 竖向步骤条的圆点/竖线按 left:-15px 定位，容器左内边距必须保留 Vant 默认值
     * （--van-padding-xl），改小会被 .van-steps 的 overflow:hidden 裁掉。
     */
    &__steps {
      padding: 16px 16px 4px var(--van-padding-xl);
      background: var(--app-white);
    }

    &__step-title {
      font-size: 14px;
      line-height: 1.4;
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
      font-size: 14px;
      font-weight: 600;
    }

    /* 横向步骤条：只抵消卡片左右内边距，让进度线与卡片等宽；内边距交给组件自己 */
    &__receive-steps {
      margin: 4px -12px 0;
    }

    /* 进度时间摘要：单行小字，超长省略，避免撑破卡片 */
    &__receive-hint {
      overflow: hidden;
      font-size: 11px;
      color: var(--app-text-color-secondary);
      text-align: center;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    &__receive {
      display: flex;
      margin-top: 4px;
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

    /* notice-bar 默认自带左右内边距，这里向两侧出血对齐卡片边缘 */
    &__notice {
      margin: 8px -12px 0;
    }

    &__divider {
      margin: 12px 0 4px;
    }

    /* 折叠面板：去掉组件默认的外边框与背景，融进卡片 */
    &__proofs {
      :deep(.van-collapse-item__title) {
        padding: 10px 0;
      }

      :deep(.van-collapse-item__content) {
        padding: 0 0 10px;
        color: inherit;
      }
    }

    &__proof-title {
      display: flex;
      align-items: center;
      justify-content: space-between;
      /* 右侧给折叠箭头留出间距，避免标签贴到箭头上 */
      padding-right: 8px;
      font-size: 13px;
    }

    /* 状态标签：统一圆角描边风格，且不参与 flex 压缩 */
    &__tag {
      flex: none;
      margin-left: 8px;
      font-weight: 400;
    }

    /* 订单号行：数值可省略、右侧跟一个「复制」小胶囊 */
    &__no {
      :deep(.van-cell__value) {
        display: flex;
        align-items: center;
        justify-content: flex-end;
        min-width: 0;
      }

      :deep(.van-cell__right-icon) {
        display: flex;
        align-items: center;
        margin-left: 8px;
        line-height: 1;
      }
    }

    &__no-text {
      overflow: hidden;
      color: var(--app-text-color);
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    &__copy {
      padding: 1px 8px;
      font-size: 11px;
      line-height: 16px;
      color: var(--app-primary-color);
      border: 1px solid currentcolor;
      border-radius: 10px;
    }

    &__proof-imgs {
      display: flex;
      flex-wrap: wrap;
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

    &__proof-remark {
      margin-top: 4px;
      font-size: 12px;
      color: var(--app-danger-color);
    }

    &__proof-empty {
      padding: 4px 0 8px;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__upload {
      margin-top: 12px;
    }

    /* van-card 自带背景与内边距，这里融入卡片后只做分隔 */
    &__goods {
      background: transparent;
      padding: 8px 0;

      &:not(:last-child) {
        border-bottom: 1px solid var(--app-border-color);
      }

      :deep(.van-card__thumb) {
        width: 68px;
        height: 68px;
        margin-right: 10px;
      }

      :deep(.van-card__title) {
        font-size: 14px;
        line-height: 1.4;
      }
    }
  }
</style>
