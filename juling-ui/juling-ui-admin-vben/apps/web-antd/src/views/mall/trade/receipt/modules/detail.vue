<script lang="ts" setup>
import type { TableColumnsType } from 'ant-design-vue';
import type { TradeStoreReceiptApi } from '#/api/mall/trade/storeReceipt';

import { computed, ref } from 'vue';

import { useVbenDrawer } from '@vben/common-ui';
import { formatDateTime } from '@vben/utils';

import {
  Descriptions,
  DescriptionsItem,
  Image,
  Table,
  Tag,
} from 'ant-design-vue';

import { getStoreReceipt } from '#/api/mall/trade/storeReceipt';
import { formatBatchDate } from '#/views/erp/stock/batch/data';

/** 门店收货单详情抽屉 */
defineOptions({ name: 'TradeStoreReceiptDetail' });

/** 状态标签色（与列表页保持一致） */
const STATUS_COLOR: Record<number, string> = {
  0: 'orange',
  10: 'green',
  20: 'default',
};

/** 差异标签色（与列表页保持一致） */
const DIFF_TYPE_COLOR: Record<number, string> = {
  0: 'green',
  1: 'orange',
  2: 'red',
  3: 'volcano',
  4: 'purple',
};

const receipt = ref<TradeStoreReceiptApi.StoreReceipt>({});

const drawerTitle = computed(() =>
  receipt.value.no ? `门店收货单 ${receipt.value.no}` : '门店收货单详情',
);

/** 收货凭证：后端 text 列可能是数组，也可能是逗号串 */
const fileUrls = computed<string[]>(() => {
  const urls = receipt.value.fileUrls;
  if (!urls) return [];
  if (Array.isArray(urls)) return urls.filter(Boolean);
  return String(urls)
    .split(',')
    .map((url) => url.trim())
    .filter(Boolean);
});

/** 金额展示：保留 2 位 */
function amountText(value?: number) {
  if (value === undefined || value === null) return '-';
  return Number(value).toFixed(2);
}

/** 数量展示：最多 3 位小数 */
function countText(value?: number) {
  if (value === undefined || value === null) return '-';
  return String(Number(value));
}

/** 差异数量展示：带正负号（正数 = 多收） */
function diffCountText(value?: number) {
  const count = Number(value ?? 0);
  if (count === 0) return '0';
  return `${count > 0 ? '+' : ''}${count}`;
}

/** 明细行底色：少收标黄、多收标红，便于在长表格里一眼看到差异 */
function itemRowClass(record: TradeStoreReceiptApi.StoreReceiptItem) {
  const diff = Number(record.diffCount ?? 0);
  if (diff > 0) return 'receipt-row-over';
  if (diff < 0) return 'receipt-row-short';
  return '';
}

/** 表格行样式回调（模板里不写类型注解，交给函数签名约束） */
function handleRowClass(record: TradeStoreReceiptApi.StoreReceiptItem) {
  return itemRowClass(record);
}

/** 明细列 */
const itemColumns: TableColumnsType<TradeStoreReceiptApi.StoreReceiptItem> = [
  { title: '商品', dataIndex: 'spuName', key: 'spuName', width: 180 },
  { title: '物料', dataIndex: 'productName', key: 'productName', width: 140 },
  {
    title: '应收数量',
    dataIndex: 'expectCount',
    key: 'expectCount',
    width: 100,
    align: 'right',
    customRender: ({ text }: any) => countText(text),
  },
  {
    title: '实收数量',
    dataIndex: 'receiptCount',
    key: 'receiptCount',
    width: 100,
    align: 'right',
    customRender: ({ text }: any) => countText(text),
  },
  {
    title: '差异数量',
    dataIndex: 'diffCount',
    key: 'diffCount',
    width: 100,
    align: 'right',
    customRender: ({ text }: any) => diffCountText(text),
  },
  {
    title: '差异原因',
    dataIndex: 'diffReason',
    key: 'diffReason',
    width: 150,
  },
  {
    title: '配送价',
    dataIndex: 'price',
    key: 'price',
    width: 100,
    align: 'right',
    customRender: ({ text }: any) => amountText(text),
  },
  {
    title: '差异金额',
    dataIndex: 'diffAmount',
    key: 'diffAmount',
    width: 100,
    align: 'right',
    customRender: ({ text }: any) => amountText(text),
  },
  { title: '批次号', dataIndex: 'batchNo', key: 'batchNo', width: 130 },
  {
    title: '生产日期',
    dataIndex: 'productionDate',
    key: 'productionDate',
    width: 110,
    // LocalDate 会被序列化成数组（如 [2026,9,25]），统一走 formatBatchDate
    customRender: ({ text }: any) => formatBatchDate(text) || '-',
  },
  {
    title: '有效期',
    dataIndex: 'expiryDate',
    key: 'expiryDate',
    width: 110,
    customRender: ({ text }: any) => formatBatchDate(text) || '-',
  },
  { title: '备注', dataIndex: 'remark', key: 'remark', width: 150 },
];

const [Drawer, drawerApi] = useVbenDrawer({
  // 纯展示，不需要底部「确定 / 取消」
  footer: false,
  class: 'w-3/4',
  async onOpenChange(isOpen: boolean) {
    if (!isOpen) {
      receipt.value = {};
      return;
    }
    const data = drawerApi.getData() as undefined | { id?: number };
    if (!data?.id) {
      return;
    }
    drawerApi.lock();
    try {
      // 重新拉一次详情，保证明细行与后端最新一致
      receipt.value = (await getStoreReceipt(data.id)) ?? {};
    } finally {
      drawerApi.unlock();
    }
  },
});
</script>

<template>
  <Drawer :title="drawerTitle">
    <Descriptions bordered :column="3" size="small">
      <DescriptionsItem label="收货单号">
        {{ receipt.no ?? '-' }}
      </DescriptionsItem>
      <DescriptionsItem label="状态">
        <Tag :color="STATUS_COLOR[receipt.status ?? -1] ?? 'default'">
          {{ receipt.statusName ?? '-' }}
        </Tag>
      </DescriptionsItem>
      <DescriptionsItem label="差异类型">
        <Tag :color="DIFF_TYPE_COLOR[receipt.diffType ?? -1] ?? 'default'">
          {{ receipt.diffTypeName ?? '-' }}
        </Tag>
      </DescriptionsItem>

      <DescriptionsItem label="要货单号">
        {{ receipt.orderNo ?? '-' }}
      </DescriptionsItem>
      <DescriptionsItem label="门店">
        {{ receipt.customerName ?? '-' }}
      </DescriptionsItem>
      <DescriptionsItem label="部门">
        {{ receipt.deptName ?? '-' }}
      </DescriptionsItem>

      <DescriptionsItem label="配送出库单">
        {{ receipt.saleOutNo ?? '-' }}
      </DescriptionsItem>
      <DescriptionsItem label="收货门店仓">
        {{ receipt.warehouseName ?? '-' }}
      </DescriptionsItem>
      <DescriptionsItem label="收货时间">
        {{ formatDateTime(receipt.receiveTime) || '-' }}
      </DescriptionsItem>

      <DescriptionsItem label="应收 / 实收 / 差异（数量）">
        {{ countText(receipt.totalCount) }} /
        {{ countText(receipt.receiptCount) }} /
        {{ diffCountText(receipt.diffCount) }}
      </DescriptionsItem>
      <DescriptionsItem label="应收 / 实收 / 差异（金额）">
        {{ amountText(receipt.totalPrice) }} /
        {{ amountText(receipt.receiptPrice) }} /
        {{ amountText(receipt.diffAmount) }}
      </DescriptionsItem>
      <DescriptionsItem label="收货人">
        {{ receipt.receiverName ?? '-' }}
        <span v-if="receipt.receiverMobile" class="text-gray-400">
          （{{ receipt.receiverMobile }}）
        </span>
      </DescriptionsItem>

      <DescriptionsItem label="创建人">
        {{ receipt.creatorName ?? '-' }}
      </DescriptionsItem>
      <DescriptionsItem label="创建时间" :span="2">
        {{ formatDateTime(receipt.createTime) || '-' }}
      </DescriptionsItem>

      <DescriptionsItem label="备注" :span="3">
        {{ receipt.remark || '-' }}
      </DescriptionsItem>
      <DescriptionsItem v-if="receipt.cancelReason" label="作废原因" :span="3">
        <span class="text-red-500">{{ receipt.cancelReason }}</span>
      </DescriptionsItem>
      <DescriptionsItem v-if="fileUrls.length > 0" label="收货凭证" :span="3">
        <div class="flex flex-wrap gap-2">
          <Image
            v-for="url in fileUrls"
            :key="url"
            :src="url"
            :width="80"
            :height="80"
            class="rounded object-cover"
          />
        </div>
      </DescriptionsItem>
    </Descriptions>

    <div class="mt-3 mb-2 text-sm font-medium">收货明细</div>
    <Table
      :columns="itemColumns"
      :data-source="receipt.items ?? []"
      :pagination="false"
      :row-class-name="handleRowClass"
      bordered
      size="small"
      :scroll="{ x: 1400 }"
      row-key="id"
    >
      <template #emptyText>暂无明细</template>
    </Table>
  </Drawer>
</template>

<style scoped>
/* 少收：整行标黄；多收：整行标红（与列表页的差异配色一致） */
:deep(.receipt-row-short) > td {
  background-color: #fffbe6 !important;
}

:deep(.receipt-row-over) > td {
  background-color: #fff1f0 !important;
}
</style>
