<script lang="ts" setup>
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { MemberUserApi } from '#/api/member/user';

import { useRouter } from 'vue-router';

import { useAccess } from '@vben/access';
import { confirm, DocAlert, Page, useVbenModal } from '@vben/common-ui';

import { message } from 'ant-design-vue';

import { ACTION_ICON, TableAction, useVbenVxeGrid } from '#/adapter/vxe-table';
import {
  deleteUser,
  getUserPage,
  updateUserStatus,
} from '#/api/member/user';
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

/** 账号展示名：优先订货账号，其次昵称 / 手机号 */
function accountLabel(row: MemberUserApi.User) {
  return row.username || row.nickname || row.mobile || `#${row.id}`;
}

/** 停用 / 启用订货账号（停用后登不进来，但历史订单与往来台账仍可追溯） */
async function handleUpdateStatus(row: MemberUserApi.User) {
  const disabled = row.status === 1;
  await confirm(
    disabled
      ? `启用订货账号「${accountLabel(row)}」？启用后该账号可以重新登录下单`
      : `停用订货账号「${accountLabel(row)}」？停用后无法登录，历史订单与台账不受影响`,
  );
  await updateUserStatus(row.id!, disabled ? 0 : 1);
  message.success(disabled ? '已启用' : '已停用');
  handleRefresh();
}

/** 删除订货账号（已绑定门店/部门的账号后端会拒绝删除，请改用停用） */
async function handleDelete(row: MemberUserApi.User) {
  await confirm(
    `删除订货账号「${accountLabel(row)}」？删除后该账号无法登录且不可恢复；如只是暂停使用，请改用「停用」`,
  );
  await deleteUser(row.id!);
  message.success('删除成功');
  handleRefresh();
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
            {
              // 停用后无法登录，历史订单与台账仍可追溯；启用即恢复登录
              label: row.status === 1 ? '启用' : '停用',
              type: 'link',
              auth: ['member:user:update-status'],
              onClick: handleUpdateStatus.bind(null, row),
            },
            {
              // 已绑定门店/部门的账号后端会拒绝删除（历史订单会失去归属），提示改用停用
              label: $t('common.delete'),
              type: 'link',
              danger: true,
              auth: ['member:user:delete'],
              onClick: handleDelete.bind(null, row),
            },
          ]"
        />
      </template>
    </Grid>
  </Page>
</template>
