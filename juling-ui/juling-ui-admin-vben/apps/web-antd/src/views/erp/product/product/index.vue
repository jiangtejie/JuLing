<script lang="ts" setup>
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { ErpProductApi } from '#/api/erp/product/product';

import { DocAlert, Page, useVbenModal } from '@vben/common-ui';
import { downloadFileFromBlobPart } from '@vben/utils';

import { message } from 'ant-design-vue';

import { ACTION_ICON, TableAction, useVbenVxeGrid } from '#/adapter/vxe-table';
import {
  deleteProduct,
  exportProduct,
  getProductPage,
} from '#/api/erp/product/product';
import { $t } from '#/locales';

import { useGridColumns, useGridFormSchema } from './data';
import ItemLogModal from '#/views/erp/price-list/modules/item-log-modal.vue';

import Form from './modules/form.vue';

const [FormModal, formModalApi] = useVbenModal({
  connectedComponent: Form,
  destroyOnClose: true,
});

// 价格变更历史：**这是核算真正要用的入口** —— 回答「某物料的价什么时候、从多少改成多少」
const [ItemLogModalComp, itemLogModalApi] = useVbenModal({
  connectedComponent: ItemLogModal,
  destroyOnClose: true,
});

function handleItemLog(row: ErpProductApi.Product) {
  itemLogModalApi.setData({ productId: row.id, name: row.name }).open();
}

/** 刷新表格 */
function handleRefresh() {
  gridApi.query();
}

/** 导出表格 */
async function handleExport() {
  const data = await exportProduct(await gridApi.formApi.getValues());
  downloadFileFromBlobPart({ fileName: '物料信息.xls', source: data });
}

/** 创建物料 */
function handleCreate() {
  formModalApi.setData(null).open();
}

/** 编辑物料 */
function handleEdit(row: ErpProductApi.Product) {
  formModalApi.setData(row).open();
}

/** 删除物料 */
async function handleDelete(row: ErpProductApi.Product) {
  const hideLoading = message.loading({
    content: $t('ui.actionMessage.deleting', [row.name]),
    duration: 0,
  });
  try {
    await deleteProduct(row.id as number);
    message.success($t('ui.actionMessage.deleteSuccess', [row.name]));
    handleRefresh();
  } finally {
    hideLoading();
  }
}

const [Grid, gridApi] = useVbenVxeGrid({
  formOptions: {
    schema: useGridFormSchema(),
  },
  gridOptions: {
    columns: useGridColumns(),
    height: 'auto',
    keepSource: true,
    proxyConfig: {
      ajax: {
        query: async ({ page }, formValues) => {
          return await getProductPage({
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
    toolbarConfig: {
      refresh: true,
      search: true,
    },
  } as VxeTableGridOptions<ErpProductApi.Product>,
});
</script>

<template>
  <Page auto-content-height>
    <template #doc>
      <DocAlert
        title="【物料】物料信息、分类、单位"
        url="https://github.com/jiangtejie/JuLing#readme"
      />
    </template>

    <FormModal @success="handleRefresh" />
    <ItemLogModalComp />
    <Grid table-title="物料列表">
      <template #toolbar-tools>
        <TableAction
          :actions="[
            {
              label: $t('ui.actionTitle.create', ['物料']),
              type: 'primary',
              icon: ACTION_ICON.ADD,
              auth: ['erp:product:create'],
              onClick: handleCreate,
            },
            {
              label: $t('ui.actionTitle.export'),
              type: 'primary',
              icon: ACTION_ICON.DOWNLOAD,
              auth: ['erp:product:export'],
              onClick: handleExport,
            },
          ]"
        />
      </template>
      <template #actions="{ row }">
        <TableAction
          :actions="[
            {
              label: '价格变更历史',
              type: 'link',
              auth: ['erp:price-list:query'],
              onClick: handleItemLog.bind(null, row),
            },
            {
              label: $t('common.edit'),
              type: 'link',
              icon: ACTION_ICON.EDIT,
              auth: ['erp:product:update'],
              onClick: handleEdit.bind(null, row),
            },
            {
              label: $t('common.delete'),
              type: 'link',
              danger: true,
              icon: ACTION_ICON.DELETE,
              auth: ['erp:product:delete'],
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
