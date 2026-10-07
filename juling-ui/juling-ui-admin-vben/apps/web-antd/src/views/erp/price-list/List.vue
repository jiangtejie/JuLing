<script lang="ts" setup>
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { ErpPurchasePriceApi } from '#/api/erp/price-list';

import { ref } from 'vue';

import { Page, useVbenModal } from '@vben/common-ui';
import { downloadFileFromBlobPart } from '@vben/utils';

import { message } from 'ant-design-vue';

import { ACTION_ICON, TableAction, useVbenVxeGrid } from '#/adapter/vxe-table';
import {
  deletePurchasePrice,
  deletePurchasePriceList,
  exportPurchasePrice,
  getPurchasePricePage,
} from '#/api/erp/price-list';
import { $t } from '#/locales';

import { useGridColumns, useGridFormSchema } from './data';
import PriceForm from './modules/form.vue';
import ItemLogModal from './modules/item-log-modal.vue';

const props = withDefaults(defineProps<{ priceType?: 'DELIVERY' | 'PURCHASE' }>(), {
  priceType: 'PURCHASE',
});

defineOptions({ name: 'ErpPurchasePrice' });

const [ItemLogModalComp, itemLogModalApi] = useVbenModal({
  connectedComponent: ItemLogModal,
  destroyOnClose: true,
});

function handleItemLog(row: ErpPurchasePriceApi.Price) {
  itemLogModalApi.setData({ priceId: row.id, name: row.name }).open();
}

const [FormModal, formModalApi] = useVbenModal({
  connectedComponent: PriceForm,
  destroyOnClose: true,
});

function handleRefresh() {
  gridApi.query();
}

function handleCreate() {
  formModalApi.setData({ formType: 'create' }).open();
}

function handleEdit(row: ErpPurchasePriceApi.Price) {
  formModalApi.setData({ formType: 'edit', id: row.id }).open();
}

function handleDetail(row: ErpPurchasePriceApi.Price) {
  formModalApi.setData({ formType: 'detail', id: row.id }).open();
}

async function handleDelete(row: ErpPurchasePriceApi.Price) {
  const hideLoading = message.loading({
    content: $t('ui.actionMessage.deleting', [row.name]),
    duration: 0,
  });
  try {
    await deletePurchasePrice(row.id!);
    message.success($t('ui.actionMessage.deleteSuccess', [row.name]));
    handleRefresh();
  } finally {
    hideLoading();
  }
}

async function handleDeleteBatch() {
  if (checkedIds.value.length === 0) {
    return;
  }
  const hideLoading = message.loading({
    content: $t('ui.actionMessage.deletingBatch'),
    duration: 0,
  });
  try {
    await deletePurchasePriceList(checkedIds.value);
    checkedIds.value = [];
    message.success($t('ui.actionMessage.deleteSuccess'));
    handleRefresh();
  } finally {
    hideLoading();
  }
}

async function handleExport() {
  const data = await exportPurchasePrice(await gridApi.formApi.getValues());
  downloadFileFromBlobPart({ fileName: '价目表.xls', source: data });
}

const checkedIds = ref<number[]>([]);
function handleRowCheckboxChange({ records }: { records: ErpPurchasePriceApi.Price[] }) {
  checkedIds.value = records.map((item) => item.id!);
}

const [Grid, gridApi] = useVbenVxeGrid({
  formOptions: { schema: useGridFormSchema() },
  gridOptions: {
    columns: useGridColumns(),
    height: 'auto',
    keepSource: true,
    proxyConfig: {
      ajax: {
        query: async ({ page }, formValues) => {
          return await getPurchasePricePage({
            priceType: props.priceType,
            pageNo: page.currentPage,
            pageSize: page.pageSize,
            ...formValues,
          });
        },
      },
    },
    rowConfig: { keyField: 'id', isHover: true },
    toolbarConfig: { refresh: true, search: true },
    checkboxConfig: { checkMethod: () => true },
  } as VxeTableGridOptions<ErpPurchasePriceApi.Price>,
});
</script>

<template>
  <Page auto-content-height>
    <FormModal :price-type="props.priceType" @success="handleRefresh" />
    <ItemLogModalComp />
    <Grid table-title="采购价目表" @checkbox-change="handleRowCheckboxChange" @checkbox-all="handleRowCheckboxChange">
      <template #toolbar-tools>
        <TableAction
          :actions="[
            {
              label: $t('ui.actionTitle.create', ['采购价目表']),
              type: 'primary',
              icon: ACTION_ICON.ADD,
              auth: ['erp:price-list:create'],
              onClick: handleCreate,
            },
            {
              label: $t('ui.actionTitle.export'),
              type: 'primary',
              icon: ACTION_ICON.DOWNLOAD,
              auth: ['erp:price-list:export'],
              onClick: handleExport,
            },
            {
              label: $t('ui.actionTitle.deleteBatch'),
              type: 'primary',
              danger: true,
              auth: ['erp:price-list:delete'],
              onClick: handleDeleteBatch,
            },
          ]"
        />
      </template>
      <template #actions="{ row }">
        <TableAction
          :actions="[
            {
              label: $t('common.detail'),
              type: 'link',
              onClick: handleDetail.bind(null, row),
            },
            {
              label: $t('common.edit'),
              type: 'link',
              icon: ACTION_ICON.EDIT,
              auth: ['erp:price-list:update'],
              onClick: handleEdit.bind(null, row),
            },
            {
              label: '变更历史',
              type: 'link',
              onClick: handleItemLog.bind(null, row),
            },
            {
              label: $t('common.delete'),
              type: 'link',
              danger: true,
              icon: ACTION_ICON.DELETE,
              auth: ['erp:price-list:delete'],
              popConfirm: {
                title: $t('ui.actionMessage.deleteConfirm', [row.name]),
                confirm: handleDelete.bind(null, row),
              },
            },
          ]"
        />
      </template>
    </Grid>
  </Page>
</template>
