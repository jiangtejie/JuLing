<script lang="ts" setup>
import type { MallOrderApi } from '#/api/mall/trade/order';

import { onMounted, ref } from 'vue';

import { DICT_TYPE } from '@vben/constants';
import { fenToYuan, formatDateTime } from '@vben/utils';

import { Descriptions, DescriptionsItem, Empty, Spin, Table } from 'ant-design-vue';

import { getOrder } from '#/api/mall/trade/order';
import { DictTag } from '#/components/dict-tag';

/**
 * 门店要货审核 —— 审批页的**只读**业务摘要（BPM 业务表单）
 *
 * 为什么不直接嵌订单详情页：详情页带发货/核验收款/调价等操作入口，审批人只需要看
 * 「哪家门店、什么货、多少钱、收款到没到」这几件事，避免误操作。
 *
 * 路径被配置在 BPM 流程模型的 formCustomViewPath 上，BPM 会把订单编号通过 id 属性传入。
 */
const props = defineProps<{ id?: number | string }>();

const loading = ref(false);
const order = ref<MallOrderApi.Order | null>(null);

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
        <DescriptionsItem label="应收 / 已收">
          {{ fenToYuan(order.payPrice ?? 0) }} /
          {{ fenToYuan(order.paidAmount ?? 0) }}
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
    </div>
  </Spin>
</template>
