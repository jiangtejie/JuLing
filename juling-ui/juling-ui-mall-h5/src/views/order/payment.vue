<script setup lang="ts">
  import { motion } from 'motion-v';
  import type { UploaderFileListItem } from 'vant';
  import { showImagePreview, showSuccessToast, showToast } from 'vant';
  import {
    createPaymentProof,
    getOrderDetail,
    getPaymentProofList,
    uploadPaymentImage,
  } from '@/api/order';
  import type { Order, PaymentProof } from '@/types';
  import { OFFLINE_PAY_CHANNELS, PROOF_STATUS_MAP } from '@/constants';
  import { formatDate, formatPrice, yuanToFen } from '@/utils/format';
  import { resolveImage } from '@/utils/image';
  import { BizError } from '@/utils/request';

  defineOptions({ name: 'OrderPayment' });

  const route = useRoute();
  const router = useRouter();
  const orderId = computed(() => Number(route.params.id));

  const order = ref<Order | null>(null);
  const proofs = ref<PaymentProof[]>([]);
  const loading = ref(true);
  /** 加载失败（网络 / 服务异常）——与「订单不存在」区分，可重试 */
  const loadError = ref(false);

  /** 待收金额：应付 - 已确认收款，负数归零 */
  const remainAmount = computed(() => {
    const current = order.value;
    if (!current) return 0;
    return Math.max(0, current.payPrice - current.paidAmount);
  });

  /** 最近一条被驳回的凭证：在表单上方给出驳回原因，引导重传 */
  const rejectedProof = computed(() => proofs.value.find((item) => item.status === 2));

  /**
   * 当前不允许再提交凭证：审核中（10）或已通过（20）
   * 与后端 TradeOrderPaymentProofServiceImpl#canUploadProof 保持一致，
   * 避免门店把表单填完才被后端拦（1_011_000_043「订单已通过审核，无法再上传付款凭证」）
   */
  const uploadBlocked = computed(
    () =>
      order.value?.auditStatus === 10 ||
      order.value?.auditStatus === 20 ||
      // 已提交过、还在等审批结果的凭证：同样不该再引导门店提交（后端会拒）
      proofs.value.some((proof) => proof.status === 0),
  );

  const form = reactive({
    /** 图片地址：上传成功后回填 */
    urls: [] as string[],
    /** 本次转账金额（元），提交时转成分 */
    amountYuan: '',
    payerName: '',
    payChannelCode: 'offline_transfer' as string,
    /** 转账时间（用 Vant 日期+时间选择器选出，格式 yyyy-MM-dd HH:mm:ss） */
    transferTime: '',
    remark: '',
  });

  const fileList = ref<UploaderFileListItem[]>([]);
  const channelName = computed(
    () => OFFLINE_PAY_CHANNELS.find((item) => item.code === form.payChannelCode)?.name ?? '请选择',
  );
  const channelSheet = ref(false);

  function onSelectChannel(action: { code: string }): void {
    form.payChannelCode = action.code;
    channelSheet.value = false;
  }

  /* ------------------------- 转账时间（日期 + 时间选择器） ------------------------- */

  const pad2 = (value: number): string => String(value).padStart(2, '0');

  /** 选择器气泡是否展示 */
  const showTransferPicker = ref(false);
  /** van-date-picker 的值（字符串数组，如 ['2026','09','27']） */
  const transferDate = ref<string[]>([]);
  /** van-time-picker 的值（字符串数组，如 ['10','30']） */
  const transferClock = ref<string[]>([]);
  /** 可选范围：近半年内、不晚于今天（转账不可能发生在未来） */
  const transferMinDate = new Date(Date.now() - 180 * 24 * 60 * 60 * 1000);
  const transferMaxDate = new Date();

  /** 打开选择器：已有值则回填，否则默认当前时间，减少手工操作 */
  function openTransferPicker(): void {
    if (form.transferTime) {
      const [date = '', clock = ''] = form.transferTime.split(' ');
      transferDate.value = date.split('-');
      transferClock.value = clock.split(':').slice(0, 2);
    } else {
      const now = new Date();
      transferDate.value = [
        String(now.getFullYear()),
        pad2(now.getMonth() + 1),
        pad2(now.getDate()),
      ];
      transferClock.value = [pad2(now.getHours()), pad2(now.getMinutes())];
    }
    showTransferPicker.value = true;
  }

  /** 确认：拼成后端要求的 yyyy-MM-dd HH:mm:ss */
  function onTransferConfirm(): void {
    const [year, month, day] = transferDate.value;
    const [hour, minute] = transferClock.value;
    if (year && month && day && hour && minute) {
      form.transferTime = `${year}-${month}-${day} ${hour}:${minute}:00`;
    }
    showTransferPicker.value = false;
  }

  /**
   * 选图后立即上传：拿到后端返回的文件地址再算「有效凭证」。
   * 上传失败的条目保留在列表里并标记失败，提交时会拦下。
   */
  async function onAfterRead(items: UploaderFileListItem | UploaderFileListItem[]): Promise<void> {
    const list = Array.isArray(items) ? items : [items];
    for (const item of list) {
      item.status = 'uploading';
      item.message = '上传中';
      try {
        item.url = await uploadPaymentImage(item.file as File);
        item.status = 'done';
        item.message = '';
      } catch {
        item.status = 'failed';
        item.message = '上传失败';
      }
    }
    form.urls = fileList.value
      .filter((item) => item.status === 'done' && item.url)
      .map((item) => item.url as string);
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
      // 默认带上待收金额与收货人，减少手工输入
      if (!form.amountYuan) form.amountYuan = String(remainAmount.value / 100);
      if (!form.payerName) form.payerName = detail.receiverName ?? '';
      loadError.value = false;
    } catch (error) {
      // 拦截器已提示。业务错误（订单不存在）与网络异常要区分：后者给重试入口，
      // 否则 order 为 null 会直接渲染成「订单不存在」，把网络故障说成订单没了
      loadError.value = !(error instanceof BizError);
    } finally {
      loading.value = false;
    }
  }

  async function onSubmit(): Promise<void> {
    if (!form.urls.length) {
      showToast('请先上传付款凭证');
      return;
    }
    if (fileList.value.some((item) => item.status !== 'done')) {
      showToast('有图片未上传成功，请删除后重试');
      return;
    }
    const amount = yuanToFen(form.amountYuan);
    if (amount <= 0) {
      showToast('请输入本次转账金额');
      return;
    }
    try {
      await createPaymentProof({
        orderId: orderId.value,
        urls: form.urls,
        amount,
        payerName: form.payerName.trim() || undefined,
        payChannelCode: form.payChannelCode,
        transferTime: form.transferTime || undefined,
        remark: form.remark.trim() || undefined,
      });
    } catch {
      return;
    }
    showSuccessToast('已提交，等待审核');
    await router.replace(`/order/${orderId.value}`);
  }

  const { loading: submitting, run } = useSubmit(onSubmit);

  onMounted(() => {
    void load();
  });
</script>

<template>
  <div class="app-page order-payment">
    <AppNavBar title="上传付款凭证" />

    <div v-if="loading" class="order-payment__skeleton">
      <van-skeleton title :row="4" />
    </div>

    <!-- 加载失败：网络 / 服务异常，给一个重试入口（与「订单不存在」区分开） -->
    <div v-else-if="loadError" class="order-payment__error">
      <van-empty image="error" description="加载失败，请检查网络后重试">
        <van-button round type="primary" size="small" class="mt-3" @click="load">
          重新加载
        </van-button>
      </van-empty>
    </div>

    <template v-else-if="order">
      <div class="app-scroll">
        <!-- 订单收款概览：应付 / 已收 / 待收 -->
        <div class="order-payment__summary">
          <div class="order-payment__summary-item">
            <div class="order-payment__summary-label">应付金额</div>
            <div class="order-payment__summary-value">¥{{ formatPrice(order.payPrice) }}</div>
          </div>
          <div class="order-payment__summary-item">
            <div class="order-payment__summary-label">已确认收款</div>
            <div class="order-payment__summary-value">¥{{ formatPrice(order.paidAmount) }}</div>
          </div>
          <div class="order-payment__summary-item">
            <div class="order-payment__summary-label">待收</div>
            <div class="order-payment__summary-value order-payment__summary-value--strong">
              ¥{{ formatPrice(remainAmount) }}
            </div>
          </div>
        </div>

        <!-- 驳回提示：把审批意见原样带出来，避免客户反复试错（重传后后端会自动再次提交审批） -->
        <van-notice-bar
          v-if="rejectedProof"
          class="order-payment__notice"
          color="var(--app-danger-color)"
          background="#fff7f6"
          left-icon="warning-o"
          :text="`上次凭证审核未通过：${rejectedProof.auditRemark || '未填写原因'}，请重新上传`"
          wrapable
        />

        <van-notice-bar
          v-if="remainAmount <= 0"
          class="order-payment__notice"
          color="var(--app-success-color)"
          background="#f2fbf5"
          left-icon="passed"
          text="该订单货款已收齐，无需再上传凭证"
          wrapable
        />

        <van-notice-bar
          v-else-if="uploadBlocked"
          class="order-payment__notice"
          color="var(--app-primary-color)"
          background="#f2f7ff"
          left-icon="info-o"
          :text="
            order?.auditStatus === 10
              ? '订单已提交审核，审核期间不能再补充凭证；如需修改请联系总部驳回后重传'
              : '订单已通过审批，收款金额已认定，无需再上传凭证'
          "
          wrapable
        />

        <template v-if="remainAmount > 0 && !uploadBlocked">
          <!-- 凭证图片 -->
          <div class="order-payment__card app-card">
            <div class="order-payment__label">
              付款凭证
              <span class="order-payment__required">*</span>
            </div>
            <van-uploader
              v-model="fileList"
              :max-count="3"
              accept="image/*"
              :after-read="onAfterRead"
            />
            <div class="order-payment__tip">请上传转账回单 / 付款截图，最多 3 张</div>
          </div>

          <van-cell-group inset class="order-payment__group">
            <van-field
              v-model="form.amountYuan"
              label="本次转账金额"
              type="number"
              placeholder="请输入金额"
              input-align="right"
              required
            >
              <template #extra><span class="order-payment__unit">元</span></template>
            </van-field>
            <van-field
              v-model="form.payerName"
              label="付款人"
              placeholder="请输入付款人姓名"
              input-align="right"
            />
            <van-field
              :model-value="channelName"
              label="收款渠道"
              input-align="right"
              readonly
              is-link
              @click="channelSheet = true"
            />
            <van-field
              :model-value="form.transferTime"
              label="转账时间"
              placeholder="请选择转账时间"
              input-align="right"
              readonly
              is-link
              @click="openTransferPicker"
            />
            <van-field
              v-model="form.remark"
              label="备注"
              type="textarea"
              rows="2"
              autosize
              maxlength="100"
              show-word-limit
              placeholder="如：对公转账，附言 9 月货款"
            />
          </van-cell-group>

          <div class="order-payment__hint">
            提交后直接进入供应链 / 财务两级审批，审批通过即安排发货；金额不符会被驳回，可重新上传。
          </div>

          <!-- 历史凭证 -->
          <div v-if="proofs.length" class="order-payment__card app-card">
            <div class="order-payment__label">已提交的凭证</div>
            <div v-for="proof in proofs" :key="proof.id" class="order-payment__proof">
              <div class="flex-between order-payment__proof-head">
                <span class="order-payment__proof-amount">
                  申报 ¥{{ formatPrice(proof.amount) }}
                  <template v-if="proof.confirmedAmount != null">
                    · 核定 ¥{{ formatPrice(proof.confirmedAmount) }}
                  </template>
                </span>
                <span :style="{ color: PROOF_STATUS_MAP[proof.status]?.color }">
                  {{ PROOF_STATUS_MAP[proof.status]?.text ?? '未知' }}
                </span>
              </div>
              <div class="order-payment__proof-imgs">
                <van-image
                  v-for="(url, index) in proof.urls"
                  :key="index"
                  class="order-payment__proof-img"
                  :src="resolveImage(url)"
                  fit="cover"
                  radius="4"
                  @click="showImagePreview({ images: proof.urls, startPosition: index })"
                />
              </div>
              <div class="order-payment__proof-meta">
                {{ formatDate(proof.createTime, 'YYYY-MM-DD HH:mm') }}
                <template v-if="proof.payerName"> · {{ proof.payerName }}</template>
              </div>
              <div v-if="proof.auditRemark" class="order-payment__proof-remark">
                审批意见：{{ proof.auditRemark }}
              </div>
            </div>
          </div>
        </template>
      </div>

      <div v-if="remainAmount > 0 && !uploadBlocked" class="order-payment__footer">
        <!-- 主操作按钮加轻微点按反馈：移动端点下去「有回应」 -->
        <motion.div :while-tap="{ scale: 0.97 }" :transition="{ duration: 0.1 }">
          <van-button
            type="primary"
            block
            round
            :loading="submitting"
            text="提交付款凭证"
            @click="run"
          />
        </motion.div>
      </div>
    </template>

    <van-empty v-else description="订单不存在" />

    <van-action-sheet
      v-model:show="channelSheet"
      :actions="OFFLINE_PAY_CHANNELS.map((item) => ({ ...item, name: item.name }))"
      cancel-text="取消"
      close-on-click-action
      @select="onSelectChannel"
    />

    <!-- 转账时间：Vant 日期 + 时间选择器（van-picker-group 内置「选择日期 / 选择时间」两个页签） -->
    <van-popup v-model:show="showTransferPicker" position="bottom" round>
      <van-picker-group
        title="转账时间"
        :tabs="['选择日期', '选择时间']"
        @confirm="onTransferConfirm"
        @cancel="showTransferPicker = false"
      >
        <van-date-picker
          v-model="transferDate"
          :min-date="transferMinDate"
          :max-date="transferMaxDate"
        />
        <van-time-picker v-model="transferClock" />
      </van-picker-group>
    </van-popup>
  </div>
</template>

<style scoped lang="scss">
  /* 内容区避让固定提交按钮 */
  :deep(.app-scroll) {
    padding-bottom: 72px;
  }

  .order-payment {
    &__skeleton {
      padding: 24px 16px;
    }

    &__error {
      display: flex;
      flex: 1;
      align-items: center;
      justify-content: center;
    }

    &__summary {
      display: flex;
      padding: 16px;
      background: var(--app-white);
    }

    &__summary-item {
      flex: 1;
      text-align: center;
    }

    &__summary-label {
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__summary-value {
      margin-top: 4px;
      font-size: 15px;
      font-weight: 600;

      &--strong {
        color: var(--app-danger-color);
      }
    }

    &__notice {
      margin-top: 12px;
    }

    &__card {
      margin: 12px;
      padding: 12px;
    }

    &__group {
      margin-top: 12px;
    }

    &__label {
      margin-bottom: 8px;
      font-size: 14px;
      font-weight: 600;
    }

    &__required {
      color: var(--app-danger-color);
    }

    &__tip,
    &__hint {
      font-size: 12px;
      line-height: 1.5;
      color: var(--app-text-color-secondary);
    }

    &__tip {
      margin-top: 8px;
    }

    &__hint {
      padding: 0 16px;
    }

    &__unit {
      font-size: 13px;
      color: var(--app-text-color-secondary);
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

    &__proof-amount {
      font-weight: 600;
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

    &__proof-remark {
      margin-top: 4px;
      font-size: 12px;
      color: var(--app-danger-color);
    }

    &__footer {
      position: fixed;
      right: 0;
      bottom: 0;
      left: 0;
      z-index: 10;
      padding: 8px 16px calc(8px + env(safe-area-inset-bottom));
      background: var(--app-white);
      border-top: 1px solid var(--app-border-color);
    }
  }
</style>
