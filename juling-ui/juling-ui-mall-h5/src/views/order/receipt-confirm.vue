<script setup lang="ts">
  import { motion } from 'motion-v';
  import { showDialog, showToast } from 'vant';
  import type { UploaderFileListItem } from 'vant';
  import {
    createStoreReceipt,
    getStoreReceiptDetail,
    uploadStoreReceiptImage,
  } from '@/api/storeReceipt';
  import {
    RECEIPT_DIFF_TYPE_MAP,
    RECEIPT_DIFF_TYPE_OPTIONS,
    RECEIPT_STATUS_MAP,
  } from '@/constants';
  import { useUserStore } from '@/stores/user';
  import type { StoreReceipt, StoreReceiptDiffType, StoreReceiptItem } from '@/types';
  import { confirmDialog } from '@/utils/confirm';
  import { formatDate, formatPrice, formatQuantity } from '@/utils/format';
  import { resolveImage } from '@/utils/image';
  import { isMobile } from '@/utils/is';
  import { BizError } from '@/utils/request';

  defineOptions({ name: 'StoreReceiptConfirm' });

  /** 行编辑态：应收数量来自后端，实收数量 / 差异类型 / 差异原因由门店填写 */
  interface ReceiptRow {
    item: StoreReceiptItem;
    /** 实收数量：van-stepper 开启 decimal-length 后回写的是字符串，统一按 number | string 存 */
    receiptCount: number | string;
    /** 行级差异类型：1 少收 / 2 多收 / 3 破损（0 表示无差异） */
    diffType: StoreReceiptDiffType;
    diffReason: string;
  }

  const route = useRoute();
  const router = useRouter();
  const orderId = computed(() => Number(route.params.orderId));

  const userStore = useUserStore();
  const { userInfo } = storeToRefs(userStore);

  const receipt = ref<StoreReceipt | null>(null);
  const rows = ref<ReceiptRow[]>([]);
  const loading = ref(true);
  /** 加载失败（网络 / 服务异常）——与「收货单不存在」区分，可重试 */
  const loadError = ref(false);

  const form = reactive({ receiverName: '', receiverMobile: '', remark: '' });
  const fileList = ref<UploaderFileListItem[]>([]);

  /** 待确认（status=0）可编辑提交；已确认（10）/ 已作废（20）只读展示 */
  const editable = computed(() => receipt.value?.status === 0);

  /** 状态展示配置（未知码兜底后端下发的文案） */
  const statusBadge = computed(() => {
    const current = receipt.value;
    return (
      RECEIPT_STATUS_MAP[current?.status ?? 0] ?? {
        text: current?.statusName || '未知状态',
        color: 'var(--app-text-color-secondary)',
      }
    );
  });

  /* ------------------------------- 数量与差异 ------------------------------- */

  /** 实收保留 3 位小数，差值的半个最小单位以内视为「无差异」，避免浮点误差误判 */
  const EPSILON = 0.0005;

  function toNumber(value: number | string | undefined): number {
    const num = Number(value ?? 0);
    return Number.isFinite(num) ? num : 0;
  }

  /** 差异数量：实收 − 应收（正数=多收） */
  function diffOf(row: ReceiptRow): number {
    return Number((toNumber(row.receiptCount) - row.item.expectCount).toFixed(3));
  }

  function hasDiff(row: ReceiptRow): boolean {
    return Math.abs(diffOf(row)) > EPSILON;
  }

  /**
   * 实收是否超过应收（多收）。
   *
   * 后端允许多收：超出部分照实记入门店仓，并按配送价增加门店应收、差异类型记「多收」，
   * 因此这里只用于给出提示文案，不拦截提交。非法值只有「实收为负」。
   */
  function isOverReceipt(row: ReceiptRow): boolean {
    return diffOf(row) > EPSILON;
  }

  /** 多收提示：把「多收多少、会多挂多少应付」直接讲清楚，避免门店事后对账才发现 */
  function overTip(row: ReceiptRow): string {
    const diff = diffOf(row);
    return `多收 ${formatQuantity(diff)}，将按配送价增加门店应付 ¥${formatPrice(Math.round(diff * row.item.price))}`;
  }

  /** 差异数量展示：多收带 + 号，少收保留负号 */
  function diffText(row: ReceiptRow): string {
    const diff = diffOf(row);
    return `${diff > 0 ? '+' : ''}${formatQuantity(diff)}`;
  }

  /**
   * 差异类型：少收 / 多收由数量符号自动判定；破损在数量上看不出来，
   * 门店手工选过（3）之后就不再被自动值覆盖。
   */
  function syncDiffType(row: ReceiptRow): void {
    if (!hasDiff(row)) {
      row.diffType = 0;
      return;
    }
    if (row.diffType === 3) return;
    row.diffType = diffOf(row) < 0 ? 1 : 2;
  }

  function onCountChange(row: ReceiptRow): void {
    syncDiffType(row);
  }

  function onPickDiffType(row: ReceiptRow, type: StoreReceiptDiffType): void {
    if (!editable.value) return;
    row.diffType = type;
  }

  /* -------------------------------- 金额合计 -------------------------------- */

  /** 实收合计：Σ 配送价 × 实收数量（提交前预览用，最终以后端按出库单核算为准） */
  const liveReceiptPrice = computed(() =>
    rows.value.reduce(
      (sum, row) => sum + Math.round(toNumber(row.receiptCount) * row.item.price),
      0,
    ),
  );

  /** 展示用金额：待确认按当前输入实时算，已确认 / 已作废用后端落库值 */
  const shownReceiptPrice = computed(() =>
    editable.value ? liveReceiptPrice.value : (receipt.value?.receiptPrice ?? 0),
  );
  const shownDiffAmount = computed(() =>
    editable.value
      ? liveReceiptPrice.value - (receipt.value?.totalPrice ?? 0)
      : (receipt.value?.diffAmount ?? 0),
  );

  /** 有差异的行数与差异数量合计，用于提交前的二次确认文案 */
  const diffRowCount = computed(() => rows.value.filter(hasDiff).length);

  /**
   * 是否有差异：待确认时按当前输入实时判断；已确认 / 已作废按后端落库的差异类型。
   */
  const hasAnyDiff = computed(() =>
    editable.value ? diffRowCount.value > 0 : (receipt.value?.diffType ?? 0) !== 0,
  );

  /**
   * 差异后的下一步引导。
   *
   * 差异不是「填完就算了」：它会按配送价计入门店往来账（多收增加应付、少收冲减应付），
   * 门店需要立刻知道后续该找谁补货 / 退货，所以这里把去向和动作都写清楚。
   */
  const diffGuideText = computed(() => {
    if (editable.value) {
      return `本次有 ${diffRowCount.value} 项差异：提交后差异会计入门店往来账（多收增加应付、少收冲减应付），如需补货 / 退货请联系总部。`;
    }
    return '本单存在收货差异：差异已同步到门店往来账，如需补货 / 退货请联系总部。';
  });

  /** 多收行：确认框里额外说明「会增加门店应付」 */
  const overRows = computed(() => rows.value.filter(isOverReceipt));
  const diffCount = computed(() =>
    Number(rows.value.reduce((sum, row) => sum + diffOf(row), 0).toFixed(3)),
  );

  /* -------------------------------- 数据加载 -------------------------------- */

  function applyDetail(detail: StoreReceipt): void {
    receipt.value = detail;
    rows.value = (detail.items ?? []).map((item) => {
      const row: ReceiptRow = {
        item,
        // 待确认单据默认按应收「全收」带出，门店只需改动有差异的行；后端已回填则沿用
        receiptCount:
          detail.status === 0 && item.receiptCount <= 0 ? item.expectCount : item.receiptCount,
        diffType: 0,
        diffReason: item.diffReason ?? '',
      };
      syncDiffType(row);
      return row;
    });
    form.receiverName = detail.receiverName ?? '';
    form.receiverMobile = detail.receiverMobile ?? '';
    form.remark = detail.remark ?? '';
    // 已上传 / 已落库的照片回填到上传组件（只读态下同样是纯预览）
    fileList.value = (detail.fileUrls ?? []).map(
      (url) => ({ url, status: 'done' }) as UploaderFileListItem,
    );
  }

  async function load(): Promise<void> {
    loading.value = true;
    try {
      const detail = await getStoreReceiptDetail(orderId.value);
      if (detail) {
        applyDetail(detail);
      } else {
        receipt.value = null;
        rows.value = [];
      }
      loadError.value = false;
    } catch (error) {
      // 拦截器已提示。业务错误（收货单不存在 / 无权查看）与网络异常区分：后者给重试入口
      loadError.value = !(error instanceof BizError);
    } finally {
      loading.value = false;
    }
  }

  /* -------------------------------- 图片上传 -------------------------------- */

  /**
   * 选图后立即上传：拿到后端返回的文件地址再算「有效照片」。
   * 上传失败的条目保留在列表里并标记失败，提交时会拦下。
   */
  async function onAfterRead(items: UploaderFileListItem | UploaderFileListItem[]): Promise<void> {
    const list = Array.isArray(items) ? items : [items];
    for (const item of list) {
      item.status = 'uploading';
      item.message = '上传中';
      try {
        item.url = await uploadStoreReceiptImage(item.file as File);
        item.status = 'done';
        item.message = '';
      } catch {
        item.status = 'failed';
        item.message = '上传失败';
      }
    }
  }

  /* --------------------------------- 提交 --------------------------------- */

  /**
   * 差异原因落库文案。
   *
   * 冻结契约里每行只有 diffReason 一个自由文本字段，没有行级差异类型，
   * 因此把门店选的类型作为前缀写进原因（破损：外箱挤压变形）。
   * 后端 TradeStoreReceiptServiceImpl 正是按原因文本里是否含「破损」来汇总
   * 收货单级差异类型（少收 / 多收按数量符号判定），前缀与它保持一致。
   */
  function buildDiffReason(row: ReceiptRow): string {
    const label = RECEIPT_DIFF_TYPE_MAP[row.diffType]?.text ?? '差异';
    const reason = row.diffReason.trim();
    return reason.startsWith(label) ? reason : `${label}：${reason}`;
  }

  async function onSubmit(): Promise<void> {
    const current = receipt.value;
    if (!current || !editable.value) return;

    const receiverName = form.receiverName.trim();
    if (!receiverName) {
      showToast('请输入收货人姓名');
      return;
    }
    const receiverMobile = form.receiverMobile.trim();
    if (!isMobile(receiverMobile)) {
      showToast('请输入正确的联系电话');
      return;
    }
    if (!rows.value.length) {
      showToast('没有可收货的商品明细');
      return;
    }
    if (fileList.value.some((item) => item.status && item.status !== 'done')) {
      showToast('有图片未上传成功，请删除后重试');
      return;
    }

    // 逐行校验：实收数量必须是非负数字（空值不能当 0 提交），有差异必须写原因。
    // 多收（实收 > 应收）后端允许：超出部分照实入门店仓、按配送价增加门店应收（即门店应付），故这里不拦截。
    for (const row of rows.value) {
      const raw = row.receiptCount;
      if (
        raw === '' ||
        raw === undefined ||
        raw === null ||
        !Number.isFinite(Number(raw)) ||
        Number(raw) < 0
      ) {
        showToast(`「${row.item.name}」的实收数量填写不正确`);
        return;
      }
      if (hasDiff(row) && !row.diffReason.trim()) {
        showToast(`「${row.item.name}」实收与应收不一致，请填写差异原因`);
        return;
      }
    }

    const diffTip = diffRowCount.value
      ? `本次有 ${diffRowCount.value} 项差异（差异数量合计 ${formatQuantity(diffCount.value)}），差异将计入门店往来账。`
      : '实收数量与应收一致。';
    const overTipText = overRows.value.length
      ? `其中 ${overRows.value.length} 项多收，将按配送价增加门店应付。`
      : '';
    const confirmed = await confirmDialog(
      `提交后实收数量将写入门店仓库存，且不可修改。${diffTip}${overTipText}`,
      '确认收货',
    );
    if (!confirmed) return;

    try {
      await createStoreReceipt({
        orderId: current.orderId,
        receiverName,
        receiverMobile,
        fileUrls: fileList.value
          .map((item) => item.url)
          .filter((url): url is string => Boolean(url)),
        remark: form.remark.trim() || undefined,
        items: rows.value.map((row) => ({
          orderItemId: row.item.orderItemId,
          // 后端数量精度是 3 位小数（numeric(24,6) 展示口径）
          receiptCount: Number(toNumber(row.receiptCount).toFixed(3)),
          diffReason: hasDiff(row) ? buildDiffReason(row) : undefined,
        })),
      });
    } catch {
      // 拦截器已提示
      return;
    }

    // 提交成功后的下一步说明：不能只弹一个「成功」就把人送走 ——
    // 差异写入门店往来账后，门店要知道该找谁补货 / 退货。
    const resultTip = diffRowCount.value
      ? `本次有 ${diffRowCount.value} 项差异，已记录并同步到门店往来账（多收增加应付、少收冲减应付）；如需补货 / 退货请联系总部。`
      : '实收数量已写入门店仓库存；如需补货请联系总部。';
    try {
      await showDialog({
        title: '收货提交成功',
        message: resultTip,
        confirmButtonText: '知道了',
      });
    } catch {
      // 点遮罩 / 返回关闭弹窗时 Vant 会 reject，此时提交已经成功，照常进列表
    }
    await router.replace('/order/receipt-list');
  }

  const { loading: submitting, run } = useSubmit(onSubmit);

  onMounted(async () => {
    // 收货人 / 联系电话默认取当前会员信息：已有缓存直接用，避免多一次请求
    const profileTask = userInfo.value
      ? Promise.resolve()
      : userStore.fetchProfile().catch(() => undefined);
    await load();
    await profileTask;
    if (!form.receiverName) form.receiverName = userInfo.value?.nickname ?? '';
    if (!form.receiverMobile) form.receiverMobile = userInfo.value?.mobile ?? '';
  });

  /**
   * 路由参数变化时重新拉取：
   * 从 /order/receipt-confirm/18 跳到 /23 时组件会被复用，不监听就会一直显示上一单。
   */
  watch(orderId, () => {
    if (orderId.value) void load();
  });
</script>

<template>
  <div class="app-page receipt-confirm">
    <AppNavBar title="确认收货" />

    <!-- 加载态：骨架屏，避免居中转圈带来的跳动 -->
    <div v-if="loading" class="receipt-confirm__skeleton">
      <van-skeleton title :row="3" />
      <van-skeleton title :row="4" class="mt-3" />
    </div>

    <!-- 加载失败：网络 / 服务异常，给一个重试入口（与「收货单不存在」区分开） -->
    <div v-else-if="loadError" class="receipt-confirm__error">
      <van-empty image="error" description="加载失败，请检查网络后重试">
        <van-button round type="primary" size="small" class="mt-3" @click="load">
          重新加载
        </van-button>
      </van-empty>
    </div>

    <template v-else-if="receipt">
      <div class="app-scroll" :class="{ 'app-scroll--with-bar': editable }">
        <!-- 只读提示：已确认 / 已作废的收货单不能再改实收数量 -->
        <van-notice-bar
          v-if="!editable"
          class="receipt-confirm__notice"
          color="var(--app-text-color-secondary)"
          background="#f7f8fa"
          left-icon="info-o"
          wrapable
          :text="`该收货单状态为「${statusBadge.text}」，仅可查看，不能再提交`"
        />

        <!-- 金额概览：应收 / 实收 / 差异（待确认时随输入实时变化） -->
        <div class="receipt-confirm__summary">
          <div class="receipt-confirm__summary-item">
            <div class="receipt-confirm__summary-label">应收合计</div>
            <div class="receipt-confirm__summary-value">¥{{ formatPrice(receipt.totalPrice) }}</div>
          </div>
          <div class="receipt-confirm__summary-item">
            <div class="receipt-confirm__summary-label">实收合计</div>
            <div class="receipt-confirm__summary-value">¥{{ formatPrice(shownReceiptPrice) }}</div>
          </div>
          <div class="receipt-confirm__summary-item">
            <div class="receipt-confirm__summary-label">差异金额</div>
            <div
              class="receipt-confirm__summary-value"
              :class="{ 'receipt-confirm__summary-value--strong': shownDiffAmount !== 0 }"
            >
              ¥{{ formatPrice(shownDiffAmount) }}
            </div>
          </div>
        </div>

        <!-- 单据信息：订单号 / 配送出库单 / 门店 -->
        <van-cell-group inset class="receipt-confirm__group">
          <van-cell title="订单号" :value="receipt.orderNo" />
          <van-cell title="配送出库单" :value="receipt.saleOutNo || '—'" />
          <van-cell title="收货门店" :value="receipt.customerName || '—'" />
          <van-cell
            v-if="receipt.diffType"
            title="差异类型"
            :value="
              receipt.diffTypeName || RECEIPT_DIFF_TYPE_MAP[receipt.diffType]?.text || '有差异'
            "
          />
          <van-cell
            v-if="receipt.receiveTime"
            title="收货时间"
            :value="formatDate(receipt.receiveTime)"
          />
        </van-cell-group>

        <div class="receipt-confirm__hint">
          实收数量默认按应收带出，请按实际到货核对修改；实收与应收不一致时，必须选择差异类型并填写原因。多收部分会按配送价增加门店应付。
        </div>

        <!-- 差异引导：有差异就明确讲清差异去了哪、下一步找谁，不留白 -->
        <van-notice-bar
          v-if="hasAnyDiff"
          class="receipt-confirm__notice"
          left-icon="info-o"
          color="var(--app-warning-color)"
          background="#fffbe8"
          wrapable
          :text="diffGuideText"
        />

        <!-- 逐行收货：商品 / 应收数量 / 实收数量 / 差异原因 -->
        <div v-for="row in rows" :key="row.item.id" class="receipt-confirm__item app-card">
          <div class="receipt-confirm__goods">
            <van-image
              class="receipt-confirm__img"
              :src="resolveImage(row.item.picUrl)"
              fit="cover"
              radius="6"
              lazy-load
            />
            <div class="receipt-confirm__info">
              <div class="text-ellipsis-2 receipt-confirm__name">{{ row.item.name }}</div>
              <div class="text-ellipsis receipt-confirm__spec">{{ row.item.specText || '—' }}</div>
              <div
                v-if="row.item.productName && row.item.productName !== row.item.name"
                class="text-ellipsis receipt-confirm__product"
              >
                ERP：{{ row.item.productName }}
              </div>
              <div v-if="row.item.batchNo || row.item.expiryDate" class="receipt-confirm__batch">
                <template v-if="row.item.batchNo">批次 {{ row.item.batchNo }}</template>
                <template v-if="row.item.expiryDate">
                  {{ row.item.batchNo ? ' · ' : '' }}效期
                  {{ formatDate(row.item.expiryDate, 'YYYY-MM-DD') }}
                </template>
              </div>
            </div>
          </div>

          <div class="receipt-confirm__row">
            <span class="receipt-confirm__row-label">应收数量</span>
            <span class="receipt-confirm__row-value">{{
              formatQuantity(row.item.expectCount)
            }}</span>
          </div>
          <div class="receipt-confirm__row">
            <span class="receipt-confirm__row-label">实收数量</span>
            <!-- 数量精度 3 位小数（后端 numeric(24,6)），整数也允许直接改 -->
            <van-stepper
              v-if="editable"
              v-model="row.receiptCount"
              :min="0"
              :decimal-length="3"
              input-width="72"
              button-size="22"
              @change="() => onCountChange(row)"
            />
            <span v-else class="receipt-confirm__row-value">
              {{ formatQuantity(row.item.receiptCount) }}
            </span>
          </div>
          <div class="receipt-confirm__row">
            <span class="receipt-confirm__row-label">配送价</span>
            <span class="receipt-confirm__row-value">¥{{ formatPrice(row.item.price) }}</span>
          </div>

          <!-- 实收 ≠ 应收：必须选差异类型并填写原因 -->
          <div
            v-if="hasDiff(row)"
            class="receipt-confirm__diff"
            :class="{ 'receipt-confirm__diff--over': isOverReceipt(row) }"
          >
            <div class="flex-between receipt-confirm__diff-head">
              <span class="receipt-confirm__diff-label">差异数量</span>
              <span class="receipt-confirm__diff-value">{{ diffText(row) }}</span>
            </div>

            <!-- 多收：后端允许，超出部分照实入门店仓并按配送价增加门店应付，这里只提示不拦截 -->
            <div v-if="isOverReceipt(row)" class="receipt-confirm__over">
              {{ overTip(row) }}
            </div>

            <template v-if="editable">
              <div class="receipt-confirm__types">
                <span
                  v-for="option in RECEIPT_DIFF_TYPE_OPTIONS"
                  :key="option.value"
                  class="receipt-confirm__type"
                  :class="{ 'receipt-confirm__type--active': row.diffType === option.value }"
                  @click="onPickDiffType(row, option.value)"
                >
                  {{ option.label }}
                </span>
              </div>
              <van-field
                v-model="row.diffReason"
                class="receipt-confirm__reason"
                type="textarea"
                rows="1"
                autosize
                maxlength="100"
                :border="false"
                placeholder="请填写差异原因（必填），如：少 1 箱、外箱破损"
              />
            </template>

            <div v-else class="receipt-confirm__reason-text">
              {{ row.item.diffReason || '未填写差异原因' }}
            </div>
          </div>
        </div>

        <!-- 收货人 / 联系电话 / 备注：默认取会员信息，可改 -->
        <van-cell-group inset class="receipt-confirm__group">
          <van-field
            v-model="form.receiverName"
            label="收货人"
            placeholder="请输入收货人姓名"
            input-align="right"
            required
            :readonly="!editable"
          />
          <van-field
            v-model="form.receiverMobile"
            label="联系电话"
            type="tel"
            maxlength="11"
            placeholder="请输入联系电话"
            input-align="right"
            required
            :readonly="!editable"
          />
          <van-field
            v-model="form.remark"
            label="备注"
            type="textarea"
            rows="2"
            autosize
            maxlength="100"
            show-word-limit
            placeholder="如：2 号箱外包装破损已拍照"
            :readonly="!editable"
          />
        </van-cell-group>

        <!-- 收货照片：破损 / 少件建议拍照留存，最多 6 张 -->
        <div class="receipt-confirm__card app-card">
          <div class="receipt-confirm__card-title">
            收货照片
            <span v-if="editable" class="receipt-confirm__card-tip">（选填，最多 6 张）</span>
          </div>
          <van-uploader
            v-model="fileList"
            :max-count="6"
            accept="image/*"
            :readonly="!editable"
            :after-read="onAfterRead"
          />
          <div class="receipt-confirm__card-hint">
            建议对有差异的行拍照留存（破损外箱 / 少件现场），便于后续与财务对账。
          </div>
        </div>
      </div>

      <!-- 底部固定提交栏：无需滚到底即可提交 -->
      <div v-if="editable" class="receipt-confirm__footer">
        <motion.div :while-tap="{ scale: 0.97 }" :transition="{ duration: 0.1 }">
          <van-button
            type="primary"
            block
            round
            :loading="submitting"
            text="提交收货"
            @click="run"
          />
        </motion.div>
      </div>
    </template>

    <!-- 收货单不存在：配送出库单审核通过后才会生成，给出下一步指引而非空白页 -->
    <van-empty v-else description="暂无待确认的收货单">
      <div class="receipt-confirm__empty-tip">
        配送出库单审核通过后才会生成待收货单据，可稍后再试或联系门店管理员确认发货进度。
      </div>
    </van-empty>
  </div>
</template>

<style scoped lang="scss">
  /* 内容区避让底部固定提交栏（van-action-bar 无 placeholder） */
  :deep(.app-scroll--with-bar) {
    padding-bottom: 72px;
  }

  .receipt-confirm {
    &__skeleton {
      padding: 24px 16px;
    }

    &__error {
      display: flex;
      flex: 1;
      align-items: center;
      justify-content: center;
    }

    &__notice {
      margin-top: 0;
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

    &__group {
      margin-top: 12px;
    }

    &__hint {
      padding: 12px 16px 0;
      font-size: 12px;
      line-height: 1.5;
      color: var(--app-text-color-secondary);
    }

    &__item {
      margin: 12px;
      padding: 12px;
    }

    &__goods {
      display: flex;
      gap: 10px;
      padding-bottom: 10px;
      border-bottom: 1px solid var(--app-border-color);
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

    &__spec,
    &__product,
    &__batch {
      margin-top: 2px;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
      padding-top: 10px;
      font-size: 13px;
    }

    &__row-label {
      color: var(--app-text-color-secondary);
    }

    &__row-value {
      font-weight: 600;
    }

    /* 差异区：浅色底 + 左侧色条，和「正常行」区分开 */
    &__diff {
      margin-top: 10px;
      padding: 10px;
      background: #fff7f6;
      border-left: 3px solid var(--app-danger-color);
      border-radius: 6px;

      /* 多收是合法差异（会增加门店应付），用警示色与「少收 / 破损」的错误色区分 */
      &--over {
        background: #fffbe8;
        border-left-color: var(--app-warning-color);

        .receipt-confirm__diff-value {
          color: var(--app-warning-color);
        }
      }
    }

    &__diff-head {
      font-size: 13px;
    }

    &__diff-label {
      color: var(--app-text-color-secondary);
    }

    &__diff-value {
      font-weight: 600;
      color: var(--app-danger-color);
    }

    /* 多收提示：告知会多挂多少应付，属于提示而非错误 */
    &__over {
      margin-top: 6px;
      font-size: 12px;
      line-height: 1.5;
      color: var(--app-warning-color);
    }

    &__types {
      display: flex;
      gap: 8px;
      margin-top: 8px;
    }

    /* 差异类型胶囊：选中态用实心主色，未选中为描边灰 */
    &__type {
      padding: 3px 12px;
      font-size: 12px;
      line-height: 18px;
      color: var(--app-text-color-secondary);
      background: var(--app-white);
      border: 1px solid var(--app-border-color);
      border-radius: 12px;

      &--active {
        color: var(--app-white);
        background: var(--app-danger-color);
        border-color: var(--app-danger-color);
      }
    }

    /* 差异原因输入：白底输入区，去掉 van-field 默认内边距与分隔线 */
    &__reason {
      margin-top: 8px;
      padding: 8px 10px;
      background: var(--app-white);
      border-radius: 6px;
    }

    &__reason-text {
      margin-top: 6px;
      font-size: 12px;
      line-height: 1.5;
      color: var(--app-danger-color);
    }

    &__card {
      margin: 12px;
      padding: 12px;
    }

    &__card-title {
      font-size: 14px;
      font-weight: 600;
    }

    &__card-tip,
    &__card-hint {
      font-size: 12px;
      font-weight: 400;
      color: var(--app-text-color-secondary);
    }

    &__card-hint {
      margin-top: 8px;
      line-height: 1.5;
    }

    &__empty-tip {
      padding: 0 24px;
      font-size: 12px;
      line-height: 1.6;
      color: var(--app-text-color-secondary);
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
