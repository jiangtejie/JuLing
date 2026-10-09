<script lang="ts" setup>
import type { PriceItemLog } from '#/api/erp/price-list';

import { ref } from 'vue';

import { useVbenModal } from '@vben/common-ui';

import { useVbenVxeGrid } from '#/adapter/vxe-table';
import { getPriceItemLog } from '#/api/erp/price-list';

const rows = ref<PriceItemLog[]>([]);
const title = ref('价格变更历史');

const [Grid, gridApi] = useVbenVxeGrid({
  gridOptions: {
    columns: [
      {
        field: 'changeType',
        title: '变更类型',
        width: 100,
        formatter: ({ cellValue }: { cellValue: string }) =>
          ({ CREATE: '新增', DELETE: '删行', UPDATE: '改价' })[cellValue] ?? cellValue,
      },
      { field: 'productCode', title: '物料编码', width: 120 },
      { field: 'productName', title: '物料名称', minWidth: 160 },
      { field: 'beforePrice', title: '原单价(不含税)', width: 130 },
      { field: 'afterPrice', title: '新单价(不含税)', width: 130 },
      { field: 'beforeTaxPercent', title: '原税率%', width: 90 },
      { field: 'afterTaxPercent', title: '新税率%', width: 90 },
      { field: 'priceName', title: '价目表', minWidth: 160 },
      { field: 'creator', title: '操作人', width: 100 },
      { field: 'createTime', title: '操作时间', width: 170 },
    ],
    data: rows.value,
    minHeight: 320,
    autoResize: true,
    border: true,
    pagerConfig: { enabled: false },
    toolbarConfig: { enabled: false },
  },
});

const [Modal, modalApi] = useVbenModal({
  showCancelButton: false,
  confirmText: '关闭',
  async onOpenChange(isOpen: boolean) {
    if (!isOpen) {
      rows.value = [];
      return;
    }
    // 两种入口：从价目表行进来（看这张表的历次改价）、从物料行进来（看这个物料的历次改价）。
    // 「按物料查」才是核算真正要用的 —— 它要回答的是「3 月份五花肉的配送价是多少」。
    const data = modalApi.getData() as {
      name?: string;
      priceId?: number;
      productId?: number;
    };
    title.value = data.productId
      ? `价格变更历史 - 物料：${data.name ?? ''}`
      : `价格变更历史 - ${data.name ?? ''}`;
    modalApi.lock();
    try {
      rows.value =
        (await getPriceItemLog(
          data.productId ? { productId: data.productId } : { priceId: data.priceId },
        )) ?? [];
      await gridApi.grid.reloadData(rows.value);
    } finally {
      modalApi.unlock();
    }
  },
});

defineExpose({ modalApi });
</script>

<template>
  <Modal :title="title" class="w-3/4">
    <div class="mb-2 text-sm text-gray-500">
      记录每次改价前后的价格与税率（表头字段的变更不留痕 —— 对核算没有价值）。保存价目表时系统自动比对，不需要手动维护。
    </div>
    <Grid />
  </Modal>
</template>
