<script lang="ts" setup>
import type { MallOrderApi } from '#/api/mall/trade/order';

import { computed, ref } from 'vue';

import { useVbenModal } from '@vben/common-ui';
import { DICT_TYPE } from '@vben/constants';
import { fenToYuan, formatDateTime, yuanToFen } from '@vben/utils';

import {
  Alert,
  Descriptions,
  DescriptionsItem,
  Empty,
  Image,
  Input,
  InputNumber,
  message,
  Radio,
  Space,
} from 'ant-design-vue';

import { auditPaymentProof, getPaymentProofList } from '#/api/mall/trade/order';
import { DictTag } from '#/components/dict-tag';

/**
 * 线下收款 - 付款凭证核验弹窗。
 *
 * 财务在这里核对客户上传的转账截图：确认收款（可填实际到账金额，支持部分收款）
 * 或驳回并写明原因（客户在商城可看到原因并重新上传）。
 */
const emit = defineEmits(['success']);

const order = ref<MallOrderApi.Order>();
const proofs = ref<MallOrderApi.PaymentProof[]>([]);
/** 当前核验的凭证编号（存在多张待核验时可切换） */
const activeId = ref<number>();
const approved = ref(true);
const confirmedYuan = ref<number>();
const auditRemark = ref('');

/** 待核验的凭证 */
const pendingProofs = computed(() =>
  proofs.value.filter((item) => item.status === 0),
);
const activeProof = computed(() =>
  proofs.value.find((item) => item.id === activeId.value),
);
/** 待收金额（元） */
const remainYuan = computed(
  () =>
    Math.max(
      0,
      (order.value?.payPrice ?? 0) - (order.value?.paidAmount ?? 0),
    ) / 100,
);
/** 已核验的历史凭证摘要 */
const historySummary = computed(() => {
  const confirmed = proofs.value.filter((item) => item.status === 1);
  const rejected = proofs.value.filter((item) => item.status === 2);
  const parts: string[] = [];
  if (confirmed.length > 0) {
    const total = confirmed.reduce(
      (sum, item) => sum + (item.confirmedAmount ?? 0),
      0,
    );
    parts.push(`已确认 ${confirmed.length} 笔（合计 ${fenToYuan(total)} 元）`);
  }
  if (rejected.length > 0) {
    parts.push(`已驳回 ${rejected.length} 笔`);
  }
  return parts.join('，') || '暂无历史核验记录';
});

/** 切换核验对象：默认带出客户申报金额，确认时可直接提交 */
function selectProof(id?: number) {
  activeId.value = id;
  const proof = proofs.value.find((item) => item.id === id);
  approved.value = true;
  // fenToYuan 返回的是字符串（用于展示），InputNumber 需要数值
  confirmedYuan.value = proof ? Number(fenToYuan(proof.amount ?? 0)) : undefined;
  auditRemark.value = '';
}

const [Modal, modalApi] = useVbenModal({
  async onConfirm() {
    const proof = activeProof.value;
    if (!proof?.id) {
      message.warning('该订单没有待核验的付款凭证');
      return;
    }
    if (approved.value && (!confirmedYuan.value || confirmedYuan.value <= 0)) {
      message.warning('请输入核定收款金额');
      return;
    }
    if (!approved.value && !auditRemark.value.trim()) {
      message.warning('驳回时请填写原因，方便客户重新上传');
      return;
    }
    modalApi.lock();
    try {
      await auditPaymentProof({
        id: proof.id,
        approved: approved.value,
        confirmedAmount: approved.value
          ? yuanToFen(confirmedYuan.value ?? 0)
          : undefined,
        auditRemark: auditRemark.value.trim() || undefined,
      });
      await modalApi.close();
      emit('success');
      message.success(approved.value ? '已确认收款' : '已驳回付款凭证');
    } finally {
      modalApi.unlock();
    }
  },
  async onOpenChange(isOpen: boolean) {
    if (!isOpen) {
      proofs.value = [];
      order.value = undefined;
      activeId.value = undefined;
      return;
    }
    const data = modalApi.getData() as MallOrderApi.Order;
    if (!data?.id) {
      return;
    }
    order.value = data;
    modalApi.lock();
    try {
      proofs.value = await getPaymentProofList(data.id);
      const latest = pendingProofs.value.at(-1);
      selectProof(latest?.id);
    } finally {
      modalApi.unlock();
    }
  },
});
</script>

<template>
  <Modal title="核验收款（付款凭证）" class="w-3/5">
    <div class="mx-4 space-y-4">
      <Descriptions :column="3" bordered size="small">
        <DescriptionsItem label="订单号">{{ order?.no }}</DescriptionsItem>
        <DescriptionsItem label="应付金额">
          {{ fenToYuan(order?.payPrice ?? 0) }} 元
        </DescriptionsItem>
        <DescriptionsItem label="已收 / 待收">
          {{ fenToYuan(order?.paidAmount ?? 0) }} 元 /
          <span class="text-red-500">{{ remainYuan.toFixed(2) }} 元</span>
        </DescriptionsItem>
      </Descriptions>

      <Empty v-if="proofs.length === 0" description="该订单还没有提交付款凭证" />

      <template v-else>
        <div v-if="pendingProofs.length > 1">
          <div class="mb-2 font-medium">选择要核验的凭证</div>
          <Radio.Group
            :value="activeId"
            @change="(e: any) => selectProof(e.target.value)"
          >
            <Radio v-for="item in pendingProofs" :key="item.id" :value="item.id">
              #{{ item.id }} 申报 {{ fenToYuan(item.amount ?? 0) }} 元（{{
                formatDateTime(item.createTime)
              }}）
            </Radio>
          </Radio.Group>
        </div>

        <div v-if="activeProof">
          <Descriptions :column="3" size="small">
            <DescriptionsItem label="申报金额">
              {{ fenToYuan(activeProof.amount ?? 0) }} 元
            </DescriptionsItem>
            <DescriptionsItem label="付款人">
              {{ activeProof.payerName || '-' }}
            </DescriptionsItem>
            <DescriptionsItem label="收款渠道">
              <DictTag
                :type="DICT_TYPE.PAY_CHANNEL_CODE"
                :value="activeProof.payChannelCode"
              />
            </DescriptionsItem>
            <DescriptionsItem label="转账时间">
              {{ formatDateTime(activeProof.transferTime) || '-' }}
            </DescriptionsItem>
            <DescriptionsItem label="客户备注" :span="2">
              {{ activeProof.remark || '-' }}
            </DescriptionsItem>
          </Descriptions>

          <div class="mt-3">
            <div class="mb-2 font-medium">付款凭证图片（点击可放大核对）</div>
            <Image.PreviewGroup>
              <Space :size="12" wrap>
                <Image
                  v-for="(url, index) in activeProof.urls"
                  :key="index"
                  :src="url"
                  :width="160"
                  class="rounded border border-gray-200"
                />
              </Space>
            </Image.PreviewGroup>
          </div>
        </div>

        <Alert
          v-else
          show-icon
          type="success"
          message="该订单没有待核验的付款凭证，可直接关闭窗口"
        />

        <div
          v-if="activeProof"
          class="rounded border border-gray-200 p-3"
        >
          <div class="mb-3 font-medium">核验结果</div>
          <Space direction="vertical" class="w-full">
            <Radio.Group v-model:value="approved">
              <Radio.Button :value="true">确认收款</Radio.Button>
              <Radio.Button :value="false">驳回重传</Radio.Button>
            </Radio.Group>

            <div v-if="approved" class="flex items-center gap-2">
              <span class="whitespace-nowrap">核定收款金额</span>
              <InputNumber
                v-model:value="confirmedYuan"
                :min="0"
                :precision="2"
                addon-after="元"
                class="w-40"
              />
              <span class="text-xs text-gray-400">
                与申报金额不一致时（如实际到账更少）在此填写实际到账金额，将按部分收款处理
              </span>
            </div>

            <Input.TextArea
              v-else
              v-model:value="auditRemark"
              :rows="3"
              :maxlength="255"
              show-count
              placeholder="驳回原因，客户在商城可看到并重新上传。例如：截图金额与申报不一致"
            />
          </Space>
        </div>

        <div class="text-xs text-gray-400">
          历史核验：{{ historySummary }}
        </div>
      </template>
    </div>
  </Modal>
</template>
