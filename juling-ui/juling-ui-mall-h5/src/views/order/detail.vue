<script setup lang="ts">
  import { motion } from 'motion-v';
  import { showImagePreview, showSuccessToast, showToast } from 'vant';
  import { cancelOrder, getOrderDetail, getPaymentProofList } from '@/api/order';
  import {
    AUDIT_STATUS_MAP,
    deriveOrderStatusView,
    ORDER_RECEIPT_STATUS_MAP,
    ORDER_STATUS_STEPS,
    PROOF_STATUS_MAP,
    RECEIVE_STATUS_MAP,
    STORE_TYPE_MAP,
  } from '@/constants';
  import type { Order, OrderItem, PaymentProof } from '@/types';
  import { useReorder } from '@/composables/useReorder';
  import { confirmDialog } from '@/utils/confirm';
  import { formatDate, formatPrice, formatQuantity, maskMobile } from '@/utils/format';
  import { resolveUploadAction } from '@/utils/order-actions';
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

  /**
   * 已取消 / 售后中 / 未识别状态（UNKNOWN）不属于正向流程，用步骤条展示会误导，改回色块。
   * UNKNOWN 是「后端新增了前端还没识别的状态码」，文案由 ORDER_STATUS_MAP 给中性结论。
   */
  const isAbnormal = computed(
    () =>
      order.value?.status === 'CANCELED' ||
      order.value?.status === 'AFTER_SALE' ||
      order.value?.status === 'UNKNOWN',
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

  /** 展示状态：待发货要按审核状态细分（审核中 / 审核已驳回 / 待发货） */
  const orderStatusView = computed(() =>
    deriveOrderStatusView(order.value?.status, order.value?.auditStatus),
  );

  /** 最近一条被驳回的凭证：用于在卡片上直接提示驳回原因 */
  const rejectedProof = computed(() => proofs.value.find((item) => item.status === 2));

  /**
   * 还能上传凭证：货款未收齐、订单不在取消/售后异常态，且后端允许补传
   * （后端只允许「待支付」或「待发货且审核状态为 待提交/已驳回」时上传：
   *   审核中(10) 不允许追加，避免重复上传把申报金额叠高；已通过(20) 则收款已认定）
   */
  const uploadAction = computed(() =>
    resolveUploadAction({
      auditStatus: order.value?.auditStatus,
      isAbnormal: isAbnormal.value,
      proofs: proofs.value,
      remainAmount: remainAmount.value,
    }),
  );
  /** 还能上传/重新上传付款凭证（凭证已提交待审核、审核中、已通过都收起入口） */
  const canUpload = computed(() => uploadAction.value.visible);

  /**
   * 订单审核中（auditStatus = 10）：门店提交付款凭证后后端自动提交审批，此时不允许取消
   * （后端同样会拦，提示「订单正在审核中，暂不能取消，如需取消请联系总部」），
   * 前端提前把「为什么不能取消」讲清楚，避免点下去才报错。
   */
  const auditInProgress = computed(() => order.value?.auditStatus === 10);
  /** 已完成 / 已取消订单：支持「再来一单」 */
  const { canReorder, reorder, reordering } = useReorder();

  function onReorder(): void {
    if (order.value) void reorder(order.value);
  }

  /** 允许取消：只有「待支付」且不在审核中的订单（审核中不可取消） */
  const canCancel = computed(() => order.value?.status === 'UNPAID' && !auditInProgress.value);
  const uploadText = computed(() => uploadAction.value.text);

  /* ------------------- 门店订货链：归属 · 审核 · 数量进度 ------------------- */

  /** 下单门店类型文案（DIRECT 直营 / FRANCHISE 加盟）；未知值原样展示，不猜 */
  const storeTypeText = computed(() => {
    const type = order.value?.storeType;
    if (!type) return '';
    return STORE_TYPE_MAP[type] ?? type;
  });

  /** 直营门店免审核闸门（后端 TradeOrderAuditService#validateCanDelivery 同口径） */
  const isDirectStore = computed(() => order.value?.storeType === 'DIRECT');

  /**
   * 要货审核状态（粗粒度结论）。
   *
   * 后端未下发（null，历史订单 / 老接口）时按「待提交」展示 —— 与后端
   * TradeOrderAuditStatusEnum.isDraft 同口径，避免详情页出现空白。
   * 展示纪律：只给「待提交 / 审核中 / 已通过 / 已驳回」，不展示审批人、审批节点、
   * 当前在谁手里，文案也不出现具体岗位或人名。
   */
  const auditBadge = computed(
    () => AUDIT_STATUS_MAP[order.value?.auditStatus ?? 0] ?? AUDIT_STATUS_MAP[0]!,
  );

  /** 审核状态的一句话说明：中性、可执行 */
  const auditHint = computed(() => {
    switch (order.value?.auditStatus ?? 0) {
      case 10:
        return '审核中，通过后即可安排发货';
      case 20:
        return '审核已通过，等待发货';
      case 30:
        return '审核未通过，请重新上传付款凭证';
      default:
        return isDirectStore.value ? '直营门店免审核' : '已提交，等待审核';
    }
  });

  /**
   * 已付款但还没发货（订单处于「待发货」，含审核中）。
   *
   * 这一阶段门店侧没有自助取消入口（后端同样会拦），必须给出明确的下一步，
   * 否则门店只会看到「没有任何按钮」而不知道该怎么办。
   */
  const waitingDelivery = computed(() => order.value?.status === 'PAID');

  /** 数量兜底：后端 decimal 可能为 null / 字符串 */
  function toQuantity(value: number | string | null | undefined): number {
    const num = Number(value ?? 0);
    return Number.isFinite(num) ? num : 0;
  }

  /**
   * 商品行数量进度：下单 / 已发 / 已收。
   *
   * - 已发数量为 0 时不展示（未发货的单每行都挂「已发 0」只会干扰阅读）；
   * - 已收在「已发货」之后才展示，这样发货以后的行必然是「下单 · 已发 · 已收」三个数量，
   *   未发货的行只留「下单 N」，读起来干净。
   */
  const itemProgress = computed<
    Record<
      number,
      { delivered: number; received: number; showDelivered: boolean; showReceived: boolean }
    >
  >(() => {
    const map: Record<
      number,
      { delivered: number; received: number; showDelivered: boolean; showReceived: boolean }
    > = {};
    (order.value?.items ?? []).forEach((item: OrderItem) => {
      const delivered = toQuantity(item.deliveredCount);
      const received = toQuantity(item.receiptCount);
      map[item.id] = {
        delivered,
        received,
        showDelivered: delivered > 0,
        showReceived: delivered > 0 || received > 0,
      };
    });
    return map;
  });

  /** 订单收货进度（0 未收货 / 10 部分收货 / 20 已收货）：未收货不占一行 */
  const receiptBadge = computed(() => {
    const status = order.value?.receiptStatus;
    if (status == null || status === 0) return null;
    return ORDER_RECEIPT_STATUS_MAP[status] ?? null;
  });

  /* ---------------------------- 收款进度（van-steps） ---------------------------- */

  /**
   * 收款进度两步：上传凭证 → 等待发货。
   *
   * 门店提交凭证后订单立刻进入「待发货」并自动提交两级审批，收款不再是独立的核验环节，
   * 所以不再有「财务核验 / 收款完成」两步。
   */
  const RECEIVE_STEPS = ['上传凭证', '等待发货'] as const;

  /** 由订单收款状态推导当前处于哪一步 */
  const receiveStepActive = computed(() => {
    const status = order.value?.paymentProofStatus ?? 0;
    if (status === 0 || status === 2) return 0; // 未上传 / 已驳回：回到上传环节
    return 1; // 已提交（1 为历史单兜底）/ 部分收款 / 已收齐：等待发货
  });

  /** 已驳回时进度条用警示色，避免看起来「一切正常」 */
  const receiveStepColor = computed(() =>
    order.value?.paymentProofStatus === 2 ? 'var(--app-danger-color)' : 'var(--app-primary-color)',
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
    return lastAudit ? `提交 ${first} · 审核 ${lastAudit}` : `提交 ${first}`;
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
      order.value?.status === 'SHIPPED' ||
      canReorder(order.value),
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
      activeProofs.value = proofList.length ? [String(proofList[proofList.length - 1]!.id)] : [];
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

  /**
   * 确认收货：进入门店收货页逐行登记实收数量（多收 / 少收 / 破损）。
   *
   * 这里不再走「一键确认收货」的老接口：实收数量与差异原因必须逐行登记，
   * 后端据此写入门店仓库存与门店往来账。
   */
  function toReceipt(): void {
    void router.push(`/order/receipt-confirm/${orderId.value}`);
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
          :style="{ background: orderStatusView.color }"
        >
          <div class="order-detail__status-text">{{ orderStatusView.text }}</div>
          <div class="order-detail__status-tip">订单号 {{ order.orderNo }}</div>
        </div>

        <!--
          已付款但还没发货（待发货 / 审核中）：门店侧没有自助取消入口（后端同样会拦），
          这里必须明确给出下一步，不能静默地「没有任何操作」
        -->
        <van-notice-bar
          v-if="waitingDelivery"
          class="order-detail__notice order-detail__notice--standalone"
          left-icon="info-o"
          color="var(--app-warning-color)"
          background="#fffbe8"
          wrapable
          text="订单已付款、等待发货；如需取消订单请联系总部"
        />

        <!-- 下单门店：代理人账号管多家门店，详情页必须能看出这是哪家店的单 -->
        <van-cell-group inset class="order-detail__group">
          <van-cell title="下单门店" :value="order.customerName || '未关联门店'" />
          <van-cell v-if="storeTypeText" title="门店类型" :value="storeTypeText" />
        </van-cell-group>

        <!-- 货款收款：收款进度（van-steps）+ 金额 + 驳回提示 + 凭证（van-collapse） -->
        <div class="order-detail__card app-card">
          <div class="flex-between">
            <span class="order-detail__title">货款收款</span>
            <van-tag class="order-detail__tag" :color="receiveBadge.color" plain round>
              {{ receiveBadge.text }}
            </van-tag>
          </div>

          <!-- 收款进度：上传凭证 → 等待发货（提交后直接进入两级审批） -->
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

          <!-- 审核中：说明为什么暂时不能取消，客户不必去点按钮撞报错 -->
          <van-notice-bar
            v-if="auditInProgress"
            class="order-detail__notice"
            left-icon="info-o"
            color="var(--app-warning-color)"
            background="#fffbe8"
            wrapable
            text="订单审核中，暂不能取消订单；如需取消请联系总部"
          />

          <!-- 驳回原因：用 notice-bar 直接带出审批意见，引导客户重传（重传后自动再次提交审批） -->
          <van-notice-bar
            v-if="rejectedProof"
            class="order-detail__notice"
            left-icon="warning-o"
            color="var(--app-danger-color)"
            background="#fff7f6"
            wrapable
            :text="`凭证审核未通过：${rejectedProof.auditRemark || '未填写原因'}，请重新上传`"
          />

          <van-divider v-if="proofs.length" class="order-detail__divider" />

          <!-- 凭证记录：折叠面板，默认展开最新一条，历史可展开查看 -->
          <van-collapse v-if="proofs.length" v-model="activeProofs" class="order-detail__proofs">
            <van-collapse-item v-for="proof in proofs" :key="proof.id" :name="String(proof.id)">
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
                审批意见：{{ proof.auditRemark }}
              </div>
            </van-collapse-item>
          </van-collapse>
          <div v-else class="order-detail__proof-empty">还没有上传付款凭证</div>

          <!-- 主操作按钮加轻微点按反馈 -->
          <motion.div
            v-if="canUpload"
            class="order-detail__upload"
            :while-tap="{ scale: 0.97 }"
            :transition="{ duration: 0.1 }"
          >
            <van-button
              type="primary"
              block
              round
              size="small"
              :text="uploadText"
              @click="toPayment"
            />
          </motion.div>
        </div>

        <!--
          要货审核：门店侧只给粗粒度结论（待提交 / 审核中 / 已通过 / 已驳回），
          不展示审批人、审批节点、当前在谁手里；驳回时把审核意见原样带出来
        -->
        <div class="order-detail__card app-card">
          <div class="flex-between">
            <span class="order-detail__title">要货审核</span>
            <van-tag class="order-detail__tag" :color="auditBadge.color" plain round>
              {{ auditBadge.text }}
            </van-tag>
          </div>
          <div class="order-detail__audit-hint">{{ auditHint }}</div>
          <van-notice-bar
            v-if="order.auditStatus === 30 && order.auditRemark"
            class="order-detail__notice"
            left-icon="warning-o"
            color="var(--app-danger-color)"
            background="#fff7f6"
            wrapable
            :text="`驳回原因：${order.auditRemark}`"
          />
        </div>

        <!-- 收货信息 -->
        <van-cell-group inset class="order-detail__group">
          <van-cell title="收货人" :value="order.receiverName" />
          <van-cell title="联系电话" :value="maskMobile(order.receiverMobile)" />
          <van-cell title="收货地址" :label="order.receiverAddress" />
        </van-cell-group>

        <!-- 商品信息：van-card 展示订单行 + 数量进度（下单 / 已发 / 已收） -->
        <div class="order-detail__card app-card">
          <div class="order-detail__title">商品信息</div>
          <van-card
            v-for="item in order.items"
            :key="item.id"
            class="order-detail__goods"
            :title="item.name"
            :desc="item.specText"
            :price="formatPrice(item.price)"
            :thumb="resolveImage(item.picUrl)"
          >
            <!-- 数量进度：已发为 0 时不展示；已收在发货后才出现，保证一行的数量口径一致 -->
            <template #tags>
              <div class="order-detail__progress">
                <span class="order-detail__progress-item">
                  下单 {{ formatQuantity(item.quantity) }}
                </span>
                <span
                  v-if="itemProgress[item.id]?.showDelivered"
                  class="order-detail__progress-item"
                >
                  已发 {{ formatQuantity(itemProgress[item.id]!.delivered) }}
                </span>
                <span
                  v-if="itemProgress[item.id]?.showReceived"
                  class="order-detail__progress-item order-detail__progress-item--received"
                >
                  已收 {{ formatQuantity(itemProgress[item.id]!.received) }}
                </span>
              </div>
            </template>
          </van-card>
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
          <van-cell v-if="receiptBadge" title="收货进度" :value="receiptBadge.text" />
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
        <!-- 文案随凭证状态变化（已提交过就是「重新上传凭证」），不再写死「上传凭证」 -->
        <van-action-bar-button
          v-if="canUpload"
          type="primary"
          :text="uploadAction.barText"
          @click="toPayment"
        />
        <van-action-bar-button
          v-if="canCancel"
          type="danger"
          text="取消订单"
          :loading="acting"
          @click="onCancel"
        />
        <van-action-bar-button
          v-if="order.status === 'SHIPPED'"
          type="primary"
          text="确认收货"
          @click="toReceipt"
        />
        <!-- 已完成 / 已取消：一键把商品重新加入订货单 -->
        <van-action-bar-button
          v-if="canReorder(order)"
          type="primary"
          :loading="reordering"
          text="再来一单"
          @click="onReorder"
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

    /* 卡片外的 notice-bar（已付款待发货提示）：不做负边距出血，与卡片列表左右对齐 */
    &__notice--standalone {
      margin: 12px 0 0;
    }

    /* 审核状态说明：一句话讲清当前处于哪一步、下一步是什么 */
    &__audit-hint {
      margin-top: 6px;
      font-size: 12px;
      line-height: 1.5;
      color: var(--app-text-color-secondary);
    }

    /* 商品行数量进度：下单 / 已发 / 已收 */
    &__progress {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 4px;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__progress-item {
      white-space: nowrap;

      &--received {
        color: var(--app-success-color);
      }
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
