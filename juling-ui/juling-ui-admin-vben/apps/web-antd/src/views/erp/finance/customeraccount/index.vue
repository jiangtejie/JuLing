<script lang="ts" setup>
import type { TableColumnsType } from 'ant-design-vue';
import type { VbenFormSchema } from '#/adapter/form';
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { ErpCustomerAccountApi } from '#/api/erp/finance/customerAccount';

import { computed, h, ref } from 'vue';

import { useAccess } from '@vben/access';
import { DocAlert, Page } from '@vben/common-ui';
import { downloadFileFromBlobPart, erpNumberFormatter } from '@vben/utils';

import { Card, Table, Tag } from 'ant-design-vue';

import { ACTION_ICON, TableAction, useVbenVxeGrid } from '#/adapter/vxe-table';
import {
  exportCustomerAccount,
  getCustomerAccountPage,
  getCustomerAccountSummary,
} from '#/api/erp/finance/customerAccount';
import { getCustomerSimpleList } from '#/api/erp/sale/customer';
import { getSimpleDeptList } from '#/api/system/dept';
import { getRangePickerDefaultProps } from '#/utils';
import { usePageActivateLoad } from '#/utils/usePageActivateLoad';

/** 门店往来台账（应收 / 收款 / 差异调整），本期只做查询展示 */
defineOptions({ name: 'ErpCustomerAccount' });

const { hasAccessByCodes } = useAccess();

/**
 * 业务类型 → 展示口径。
 *
 * 取值与后端 trade/erp 侧的记账口径一一对应：
 * 1 配送应收 / 2 直拨应收 / 3 收款（含预收） / 4 收货差异调整
 * 5 退货冲减 / 11 配送应收冲销 / 12 直拨应收冲销
 */
const BIZ_TYPE_META: Record<number, { color: string; label: string }> = {
  1: { color: 'blue', label: '配送应收' },
  2: { color: 'geekblue', label: '直拨应收' },
  3: { color: 'green', label: '收款' },
  4: { color: 'orange', label: '收货差异调整' },
  5: { color: 'purple', label: '退货冲减' },
  11: { color: 'default', label: '配送应收冲销' },
  12: { color: 'default', label: '直拨应收冲销' },
};

const BIZ_TYPE_OPTIONS = Object.entries(BIZ_TYPE_META).map(([value, meta]) => ({
  label: meta.label,
  value: Number(value),
}));

/** 金额展示：保留 2 位 */
function amountText(value?: number) {
  if (value === undefined || value === null) return '-';
  return erpNumberFormatter(value, 2);
}

/** 变动金额展示：带正负号（正数 = 门店欠总部增加） */
function signedAmountText(value?: number) {
  if (value === undefined || value === null) return '-';
  const amount = Number(value);
  return `${amount > 0 ? '+' : ''}${erpNumberFormatter(amount, 2)}`;
}

/** 变动金额颜色：增加（欠总部变多）标红、减少标绿 */
function amountClass(value?: number) {
  const amount = Number(value ?? 0);
  if (amount > 0) return 'text-red-500';
  if (amount < 0) return 'text-green-600';
  return 'text-gray-500';
}

/* ==================== 门店往来汇总 ==================== */

const summaryList = ref<ErpCustomerAccountApi.CustomerAccountSummary[]>([]);
const summaryLoading = ref(false);
/** 汇总当前使用的过滤条件，避免与列表查询重复请求 */
const summaryKey = ref('[null,null]');

/** 汇总合计：应收 / 已收 / 余额 */
const summaryTotals = computed(() => {
  const totals = { balance: 0, receivable: 0, received: 0 };
  summaryList.value.forEach((row) => {
    totals.receivable += Number(row.totalReceivable ?? 0);
    totals.received += Number(row.totalReceived ?? 0);
    totals.balance += Number(row.balance ?? 0);
  });
  return totals;
});

/** 加载门店往来汇总（customerId / deptId 可空 = 全部） */
async function loadSummary(params?: { customerId?: number; deptId?: number }) {
  const next = params ?? {};
  summaryKey.value = JSON.stringify([
    next.customerId ?? null,
    next.deptId ?? null,
  ]);
  summaryLoading.value = true;
  try {
    summaryList.value = (await getCustomerAccountSummary(next)) ?? [];
  } finally {
    summaryLoading.value = false;
  }
}

// 首屏加载 + 切回页签刷新（原因见 #/utils/usePageActivateLoad）
usePageActivateLoad(async () => {
  await loadSummary();
});

/** 汇总表列 */
const summaryColumns: TableColumnsType<ErpCustomerAccountApi.CustomerAccountSummary> =
  [
    { title: '门店', dataIndex: 'customerName', key: 'customerName' },
    { title: '部门', dataIndex: 'deptName', key: 'deptName' },
    {
      title: '累计应收',
      dataIndex: 'totalReceivable',
      key: 'totalReceivable',
      width: 130,
      align: 'right',
      customRender: ({ text }: any) => amountText(text),
    },
    {
      title: '累计已收',
      dataIndex: 'totalReceived',
      key: 'totalReceived',
      width: 130,
      align: 'right',
      customRender: ({ text }: any) => amountText(text),
    },
    {
      title: '当前余额',
      dataIndex: 'balance',
      key: 'balance',
      width: 130,
      align: 'right',
      customRender: ({ text }: any) =>
        h(
          'span',
          { class: Number(text ?? 0) > 0 ? 'text-red-500' : 'text-green-600' },
          amountText(text),
        ),
    },
  ];

/* ==================== 台账列表 ==================== */

/** 列表的搜索表单 */
function useGridFormSchema(): VbenFormSchema[] {
  return [
    {
      fieldName: 'customerId',
      label: '门店',
      component: 'ApiSelect',
      componentProps: {
        placeholder: '请选择门店',
        allowClear: true,
        showSearch: true,
        api: getCustomerSimpleList,
        labelField: 'name',
        valueField: 'id',
      },
    },
    {
      fieldName: 'deptId',
      label: '部门',
      component: 'ApiSelect',
      componentProps: {
        placeholder: '请选择部门',
        allowClear: true,
        showSearch: true,
        api: getSimpleDeptList,
        labelField: 'name',
        valueField: 'id',
      },
    },
    {
      fieldName: 'bizType',
      label: '业务类型',
      component: 'Select',
      componentProps: {
        placeholder: '请选择业务类型',
        allowClear: true,
        options: BIZ_TYPE_OPTIONS,
      },
    },
    {
      fieldName: 'sourceNo',
      label: '来源单号',
      component: 'Input',
      componentProps: {
        placeholder: '请输入来源单号',
        allowClear: true,
      },
    },
    {
      fieldName: 'billTime',
      label: '账单时间',
      component: 'RangePicker',
      componentProps: {
        ...getRangePickerDefaultProps(),
        allowClear: true,
      },
    },
  ];
}

/** 列表的字段 */
function useGridColumns(): VxeTableGridOptions<ErpCustomerAccountApi.CustomerAccount>['columns'] {
  return [
    { field: 'customerName', title: '门店', minWidth: 180, fixed: 'left' },
    { field: 'deptName', title: '部门', minWidth: 140 },
    {
      field: 'bizType',
      title: '业务类型',
      width: 140,
      slots: { default: 'bizType' },
    },
    {
      field: 'amount',
      title: '变动金额',
      width: 130,
      align: 'right',
      slots: { default: 'amount' },
    },
    {
      field: 'balance',
      title: '记账后余额',
      width: 130,
      align: 'right',
      formatter: 'formatAmount2',
    },
    {
      field: 'billTime',
      title: '账单时间',
      width: 170,
      formatter: 'formatDateTime',
    },
    { field: 'sourceType', title: '来源类型', width: 130 },
    { field: 'sourceNo', title: '来源单号', minWidth: 180, showOverflow: 'tooltip' },
    { field: 'remark', title: '备注', minWidth: 180, showOverflow: 'tooltip' },
    {
      field: 'createTime',
      title: '创建时间',
      width: 170,
      formatter: 'formatDateTime',
    },
  ];
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
          const values = formValues as {
            customerId?: number;
            deptId?: number;
          } & Record<string, any>;
          // 汇总跟随列表的「门店 / 部门」筛选一起收窄，条件没变就不重复请求
          const key = JSON.stringify([
            values.customerId ?? null,
            values.deptId ?? null,
          ]);
          if (key !== summaryKey.value) {
            void loadSummary({
              customerId: values.customerId,
              deptId: values.deptId,
            });
          }
          return await getCustomerAccountPage({
            pageNo: page.currentPage,
            pageSize: page.pageSize,
            ...values,
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
  } as VxeTableGridOptions<ErpCustomerAccountApi.CustomerAccount>,
});

/** 导出门店往来台账 */
async function handleExport() {
  const data = await exportCustomerAccount(await gridApi.formApi.getValues());
  downloadFileFromBlobPart({ fileName: '门店往来台账.xls', source: data });
}
</script>

<template>
  <Page auto-content-height>
    <template #doc>
      <DocAlert
        title="【财务】门店往来台账"
        url="https://github.com/jiangtejie/JuLing#readme"
      />
    </template>

    <div class="flex h-full min-h-0 flex-col">
      <Card
        size="small"
        class="mb-2 shrink-0"
        :body-style="{ padding: '8px' }"
        :loading="summaryLoading"
      >
        <template #title>
          <span class="text-sm">门店往来汇总</span>
          <span class="ml-3 text-xs text-gray-500">
            累计应收 {{ amountText(summaryTotals.receivable) }} / 累计已收
            {{ amountText(summaryTotals.received) }} / 当前余额
            <span
              :class="
                summaryTotals.balance > 0 ? 'text-red-500' : 'text-green-600'
              "
            >
              {{ amountText(summaryTotals.balance) }}
            </span>
          </span>
        </template>
        <Table
          :columns="summaryColumns"
          :data-source="summaryList"
          :pagination="false"
          :scroll="{ y: 180 }"
          bordered
          row-key="customerId"
          size="small"
        >
          <template #emptyText>暂无门店往来数据</template>
        </Table>
      </Card>

      <!-- 网格自己读父容器高度（height: auto），因此外面必须再包一层定了高的 flex 项 -->
      <div class="min-h-0 flex-1">
        <Grid table-title="门店往来台账">
          <template #toolbar-tools>
            <TableAction
              v-if="hasAccessByCodes(['erp:customer-account:export'])"
              :actions="[
                {
                  label: '导出',
                  type: 'primary',
                  icon: ACTION_ICON.DOWNLOAD,
                  onClick: handleExport,
                },
              ]"
            />
          </template>
          <template #bizType="{ row }">
            <Tag :color="BIZ_TYPE_META[row.bizType ?? -1]?.color ?? 'default'">
              {{
                row.bizTypeName ?? BIZ_TYPE_META[row.bizType ?? -1]?.label ?? '-'
              }}
            </Tag>
          </template>
          <template #amount="{ row }">
            <span :class="amountClass(row.amount)">
              {{ signedAmountText(row.amount) }}
            </span>
          </template>
        </Grid>
      </div>
    </div>
  </Page>
</template>
