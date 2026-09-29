<script lang="ts" setup>
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { MemberUserApi } from '#/api/member/user';

import { useRouter } from 'vue-router';

import { useAccess } from '@vben/access';
import { DocAlert, Page, useVbenModal } from '@vben/common-ui';

import { ACTION_ICON, TableAction, useVbenVxeGrid } from '#/adapter/vxe-table';
import { getUserPage } from '#/api/member/user';
import { $t } from '#/locales';

import { useGridColumns, useGridFormSchema } from './data';
import Form from './modules/form.vue';
import OrderAccountForm from './modules/order-account-form.vue';
import ResetPasswordForm from './modules/reset-password-form.vue';

const router = useRouter();
/**
 * 权限编码与后端 @PreAuthorize 对齐：member:user:create / member:user:reset-password。
 * 行操作是数组配置项（不支持模板 v-if），所以走 TableAction 的 ifShow + hasAccessByCodes。
 */
const { hasAccessByCodes } = useAccess();

const [FormModal, formModalApi] = useVbenModal({
  connectedComponent: Form,
  destroyOnClose: true,
});

const [OrderAccountFormModal, orderAccountFormModalApi] = useVbenModal({
  connectedComponent: OrderAccountForm,
  destroyOnClose: true,
});

const [ResetPasswordFormModal, resetPasswordFormModalApi] = useVbenModal({
  connectedComponent: ResetPasswordForm,
  destroyOnClose: true,
});

/** 刷新表格 */
function handleRefresh() {
  gridApi.query();
}

/** 编辑订货账号 */
function handleEdit(row: MemberUserApi.User) {
  formModalApi.setData(row).open();
}

/** 开订货账号（订货人账号名 + 初始密码 + 绑定订货主体：门店或代理客户） */
function handleCreateOrderAccount() {
  orderAccountFormModalApi.open();
}

/** 重置订货账号密码（重置后该账号会被强制下线） */
function handleResetPassword(row: MemberUserApi.User) {
  resetPasswordFormModalApi.setData(row).open();
}

/** 查看订货账号详情 */
function handleViewDetail(row: MemberUserApi.User) {
  router.push({
    name: 'MemberUserDetail',
    query: {
      id: row.id,
    },
  });
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
          return await getUserPage({
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
  } as VxeTableGridOptions<MemberUserApi.User>,
});
</script>

<template>
  <Page auto-content-height>
    <template #doc>
      <DocAlert
        title="订货账号"
        url="https://github.com/jiangtejie/JuLing#readme"
      />
    </template>

    <FormModal @success="handleRefresh" />
    <OrderAccountFormModal @success="handleRefresh" />
    <ResetPasswordFormModal @success="handleRefresh" />
    <Grid table-title="订货账号列表">
      <template #toolbar-tools>
        <TableAction
          v-if="hasAccessByCodes(['member:user:create'])"
          :actions="[
            {
              label: '开订货账号',
              type: 'primary',
              icon: 'lucide:user-plus',
              onClick: handleCreateOrderAccount,
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
              icon: ACTION_ICON.VIEW,
              onClick: handleViewDetail.bind(null, row),
            },
          ]"
          :drop-down-actions="[
            {
              label: $t('common.edit'),
              type: 'link',
              auth: ['member:user:update'],
              onClick: handleEdit.bind(null, row),
            },
            {
              label: '重置密码',
              type: 'link',
              ifShow: () => hasAccessByCodes(['member:user:reset-password']),
              onClick: handleResetPassword.bind(null, row),
            },
          ]"
        />
      </template>
    </Grid>
  </Page>
</template>
