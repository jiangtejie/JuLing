<script lang="ts" setup>
import type { MallOrderApi } from '#/api/mall/trade/order';

import { computed, onMounted, ref } from 'vue';

import { DICT_TYPE } from '@vben/constants';
import { fenToYuan, formatDateTime } from '@vben/utils';

import {
  Descriptions,
  DescriptionsItem,
  Empty,
  Image,
  Space,
  Spin,
  Table,
} from 'ant-design-vue';

import { getOrder, getPaymentProofList } from '#/api/mall/trade/order';
import { DictTag } from '#/components/dict-tag';

/**
 * 门店要货审核 —— 审批页的**只读**业务摘要（BPM 业务表单）
 *
 * 为什么不直接嵌订单详情页：详情页带发货/调价等操作入口，审批人只需要看
 * 「哪家门店、什么货、多少钱、门店申报了多少收款」这几件事，避免误操作。
 *
 * 路径被配置在 BPM 流程模型的 formCustomViewPath 上，BPM 会把订单编号通过 id 属性传入。
 * 注意：本组件被 BPM 审批页内嵌（不在独立路由里），不要引入依赖路由 / 页面容器的组件。
 */
const props = defineProps<{ id?: number | string }>();

const loading = ref(false);
const order = ref<MallOrderApi.Order | null>(null);
/** 该订单的付款凭证（后端按提交时间倒序返回，最新的在最前） */
const proofs = ref<MallOrderApi.PaymentProof[]>([]);

/** 审批页只看「交没交、交了多少、截图是否可信」，缩略图最多展示几张 */
const MAX_PROOF_IMAGES = 3;

/** 凭证状态（后端按行存储）：0 待审核、1 已认定（审批通过）、2 已驳回 */
const PROOF_STATUS_TEXT: Record<number, string> = {
  0: '待审核',
  1: '已认定',
  2: '已驳回',
};

/**
 * 门店申报金额：与后端同口径，取「未被驳回」凭证的申报金额合计
 * （订单 paidAmount 就是这个口径；审批驳回后凭证置已驳回、金额归零）
 */
const declaredAmount = computed(() =>
  proofs.value
    .filter((proof) => proof.status !== 2)
    .reduce((sum, proof) => sum + (proof.amount ?? 0), 0),
);

/** 差额 = 应收 - 门店申报：大于 0 表示门店申报不足，是财务审批要确认的重点 */
const declaredDiff = computed(
  () => (order.value?.payPrice ?? 0) - declaredAmount.value,
);

/** 凭证缩略图：取最近提交的最多 3 张（一条凭证可能有多张图） */
const proofImages = computed(() =>
  proofs.value
    .flatMap((proof) =>
      (proof.urls ?? []).map((url) => ({
        amount: proof.amount ?? 0,
        status: proof.status ?? 0,
        url,
      })),
    )
    .slice(0, MAX_PROOF_IMAGES),
);

const columns = [
  { title: '商品', dataIndex: 'spuName', key: 'spuName', width: 200 },
  { title: '规格', dataIndex: 'properties', key: 'properties', width: 160 },
  { title: '单价', dataIndex: 'price', key: 'price', width: 100 },
  { title: '数量', dataIndex: 'count', key: 'count', width: 80 },
  // 订单行没有 totalPrice 字段：实付小计取 payPrice（商品实付金额·总）
  { title: '实付小计', dataIndex: 'payPrice', key: 'payPrice', width: 110 },
];

onMounted(async () => {
  const id = Number(props.id);
  if (!Number.isFinite(id) || id <= 0) {
    return;
  }
  loading.value = true;
  try {
    order.value = await getOrder(id);
    // 凭证是审批的补充信息：接口或权限异常时不影响主表单展示
    try {
      proofs.value = await getPaymentProofList(id);
    } catch {
      proofs.value = [];
    }
  } finally {
    loading.value = false;
  }
});

/** 属性数组 → 可读规格文本 */
function formatProperties(properties: any): string {
  if (!Array.isArray(properties)) {
    return '-';
  }
  return (
    properties
      .map((item: any) => item?.valueName)
      .filter(Boolean)
      .join(' / ') || '-'
  );
}
</script>

<template>
  <Spin :spinning="loading">
    <Empty v-if="!order && !loading" description="未能加载要货单信息" />
    <div v-else-if="order">
      <Descriptions bordered :column="2" size="small" title="门店要货单">
        <DescriptionsItem label="订单号">
          {{ order.no }}
        </DescriptionsItem>
        <DescriptionsItem label="下单时间">
          {{ formatDateTime(order.createTime) }}
        </DescriptionsItem>
        <DescriptionsItem label="门店客户编号">
          {{ order.customerId ?? '-' }}
        </DescriptionsItem>
        <DescriptionsItem label="所属部门编号">
          {{ order.deptId ?? '-' }}
        </DescriptionsItem>
        <DescriptionsItem label="结算模式">
          <DictTag
            :type="DICT_TYPE.TRADE_SETTLEMENT_MODE"
            :value="order.settlementMode"
          />
        </DescriptionsItem>
        <DescriptionsItem label="审核状态">
          <DictTag
            :type="DICT_TYPE.TRADE_ORDER_AUDIT_STATUS"
            :value="order.auditStatus ?? 0"
          />
        </DescriptionsItem>
        <DescriptionsItem label="收款状态">
          <DictTag
            :type="DICT_TYPE.TRADE_PAYMENT_PROOF_STATUS"
            :value="order.paymentProofStatus ?? 0"
          />
        </DescriptionsItem>
        <DescriptionsItem label="应收金额">
          ¥{{ fenToYuan(order.payPrice ?? 0) }}
        </DescriptionsItem>
        <DescriptionsItem label="门店申报金额">
          ¥{{ fenToYuan(declaredAmount) }}
        </DescriptionsItem>
        <DescriptionsItem label="差额（应收 - 门店申报）" :span="2">
          <span :class="declaredDiff > 0 ? 'text-red-500' : 'text-green-600'">
            ¥{{ fenToYuan(declaredDiff) }}
          </span>
          <span v-if="declaredDiff > 0" class="ml-2 text-xs text-gray-400">
            门店申报不足，审批通过则差额挂门店往来
          </span>
          <span v-else-if="declaredDiff < 0" class="ml-2 text-xs text-gray-400">
            门店申报多于应收，请核实
          </span>
        </DescriptionsItem>
        <DescriptionsItem label="收货人">
          {{ order.receiverName }} {{ order.receiverMobile }}
        </DescriptionsItem>
        <DescriptionsItem label="收货地址">
          {{ order.receiverDetailAddress || '-' }}
        </DescriptionsItem>
        <DescriptionsItem label="审核意见" :span="2">
          {{ order.auditRemark || '-' }}
        </DescriptionsItem>
        <DescriptionsItem label="订单备注" :span="2">
          {{ order.remark || '-' }}
        </DescriptionsItem>
      </Descriptions>

      <Table
        class="mt-4"
        :columns="columns"
        :data-source="order.items || []"
        :pagination="false"
        row-key="id"
        size="small"
      >
        <template #bodyCell="{ column, record }">
          <template v-if="column.key === 'properties'">
            {{ formatProperties(record.properties) }}
          </template>
          <template v-else-if="column.key === 'price'">
            {{ fenToYuan(record.price ?? 0) }}
          </template>
          <template v-else-if="column.key === 'payPrice'">
            {{ fenToYuan(record.payPrice ?? 0) }}
          </template>
        </template>
      </Table>

      <!-- 付款凭证：审批人只需快速核对「有没有交、交了多少、截图是否可信」 -->
      <div class="mt-4">
        <div class="mb-2 font-medium">
          付款凭证（门店申报 ¥{{ fenToYuan(declaredAmount) }}）
        </div>
        <template v-if="proofImages.length > 0">
          <Image.PreviewGroup>
            <Space :size="12" wrap>
              <div
                v-for="(item, index) in proofImages"
                :key="index"
                class="flex flex-col items-center gap-1"
              >
                <Image
                  :src="item.url"
                  :width="140"
                  class="rounded border border-gray-200"
                />
                <span class="text-xs text-gray-400">
                  申报 ¥{{ fenToYuan(item.amount) }} ·
                  {{ PROOF_STATUS_TEXT[item.status] ?? '待审核' }}
                </span>
              </div>
            </Space>
          </Image.PreviewGroup>
          <div
            v-if="proofs.length > proofImages.length"
            class="mt-1 text-xs text-gray-400"
          >
            共 {{ proofs.length }} 条凭证，此处展示最近
            {{ proofImages.length }} 张图片
          </div>
        </template>
        <div v-else class="text-gray-400">门店尚未上传付款凭证</div>
        <div class="mt-2 text-xs text-gray-400">
          审批通过即认定该收款金额（认定金额 = 门店申报金额）；驳回则门店需重新上传凭证，重传后会自动再次提交审批。
        </div>
      </div>
    </div>
  </Spin>
</template>
