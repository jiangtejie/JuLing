<script lang="ts" setup>
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { ErpStockBatchApi } from '#/api/erp/stock/batch';

import { DocAlert, Page, useVbenModal } from '@vben/common-ui';

import { Tag } from 'ant-design-vue';

import { TableAction, useVbenVxeGrid } from '#/adapter/vxe-table';

import {
  buildFooterMethod,
  EXPIRY_STATUS_META,
  formatBatchDate,
  queryStockBatchPage,
  useGridColumns,
  useGridFormSchema,
} from './data';
import StateForm from './modules/state-form.vue';

/** 批次库存与效期预警 */
defineOptions({ name: 'ErpStockBatch' });

/** 末级兜底：后端给不出效期状态时按「无有效期」展示 */
const EXPIRY_FALLBACK = { color: 'default', label: '无有效期' };

const [StateModal, stateModalApi] = useVbenModal({
  connectedComponent: StateForm,
});

const [Grid, gridApi] = useVbenVxeGrid({
  formOptions: {
    schema: useGridFormSchema(),
  },
  gridOptions: {
    columns: useGridColumns(),
    footerMethod: buildFooterMethod(),
    height: 'auto',
    keepSource: true,
    proxyConfig: {
      ajax: {
        query: async ({ page }, formValues) => {
          return await queryStockBatchPage({
            pageNo: page.currentPage,
            pageSize: page.pageSize,
            ...formValues,
          });
        },
      },
    },
    rowConfig: {
      keyField: 'id',
      isHover: true,
    },
    showFooter: true,
    toolbarConfig: {
      refresh: true,
      search: true,
    },
  } as VxeTableGridOptions<ErpStockBatchApi.StockBatch>,
});

/** 效期标签：已过期 = 红、临期 = 黄、正常 = 绿、无有效期 = 默认灰 */
function getExpiryMeta(row: ErpStockBatchApi.StockBatch) {
  const base = EXPIRY_STATUS_META[row.expiryStatus ?? ''] ?? EXPIRY_FALLBACK;
  const days =
    row.expiryDays === null || row.expiryDays === undefined
      ? undefined
      : Math.abs(row.expiryDays);
  if (days === undefined) {
    return base;
  }
  if (row.expiryStatus === 'EXPIRED') {
    return { ...base, label: `已过期 ${days} 天` };
  }
  if (row.expiryStatus === 'WARNING') {
    return { ...base, label: `临期 ${days} 天` };
  }
  return base;
}

/** 打开批次状态登记弹窗 */
function handleStateRegister(row: ErpStockBatchApi.StockBatch) {
  stateModalApi.setData(row).open();
}

/** 登记成功后刷新列表 */
function handleStateSuccess() {
  gridApi.query();
}
</script>

<template>
  <Page auto-content-height>
    <template #doc>
      <DocAlert
        title="【库存】批次库存、效期预警"
        url="https://github.com/jiangtejie/JuLing#readme"
      />
    </template>

    <StateModal @success="handleStateSuccess" />

    <Grid table-title="批次库存列表">
      <template #expiry="{ row }">
        <div class="flex flex-col items-center gap-1">
          <Tag :color="getExpiryMeta(row).color">
            {{ getExpiryMeta(row).label }}
          </Tag>
          <span class="text-xs text-gray-500">
            {{ formatBatchDate(row.expiryDate) || '-' }}
          </span>
        </div>
      </template>
      <template #operation="{ row }">
        <TableAction
          :actions="[
            {
              label: '状态登记',
              type: 'link',
              // 后端 update-state 实际校验 erp:stock:update，两个权限码都由
              // sql/local/37_stock_batch_menu.sql 一起授予角色
              auth: ['erp:stock:batch:update'],
              onClick: handleStateRegister.bind(null, row),
            },
          ]"
        />
      </template>
    </Grid>
  </Page>
</template>
