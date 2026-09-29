<script lang="ts" setup>
import type { TableColumnsType } from 'ant-design-vue';
import type { VbenFormSchema } from '#/adapter/form';
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { ErpStockBatchApi } from '#/api/erp/stock/batch';

import { ref } from 'vue';

import { DocAlert, Page } from '@vben/common-ui';
import { erpCountInputFormatter, erpNumberFormatter } from '@vben/utils';

import { Card, Table, Tag } from 'ant-design-vue';

import { useVbenVxeGrid } from '#/adapter/vxe-table';
import { getProductSimpleList } from '#/api/erp/product/product';
import { getCustomerSimpleList } from '#/api/erp/sale/customer';
import {
  getStockBatchPage,
  getStoreStockSummary,
} from '#/api/erp/stock/batch';
import { usePageActivateLoad } from '#/utils/usePageActivateLoad';
import {
  buildFooterMethod,
  EXPIRY_STATUS_META,
  formatBatchDate,
} from '#/views/erp/stock/batch/data';

/** 门店库存（门店仓批次明细 + 门店维度汇总） */
defineOptions({ name: 'ErpStoreStock' });

/** 末级兜底：后端给不出效期状态时按「无有效期」展示 */
const EXPIRY_FALLBACK = { color: 'default', label: '无有效期' };

/** 门店库存汇总（门店仓维度） */
const summaryList = ref<ErpStockBatchApi.StoreStockSummary[]>([]);
const summaryLoading = ref(false);
/** 门店客户 → 门店仓：汇总接口已给出映射，明细列表靠它把「门店」翻译成 warehouseId */
const storeWarehouseMap = ref<Record<number, number>>({});
/** 当前筛选的门店客户（用于高亮汇总行） */
const activeCustomerId = ref<number | undefined>(undefined);

/**
 * 加载门店库存汇总。
 *
 * 门店库存明细走的是批次库存分页接口，它只认 warehouseId，
 * 所以这里先用汇总接口（/erp/stock-batch/store-summary）拿到「门店 → 门店仓」的映射，
 * 之后按门店筛选时直接用映射出来的 warehouseId 查明细。
 */
async function loadSummary() {
  summaryLoading.value = true;
  try {
    const list = (await getStoreStockSummary()) ?? [];
    summaryList.value = list;
    const map: Record<number, number> = {};
    list.forEach((row) => {
      if (row.customerId !== undefined && row.warehouseId !== undefined) {
        map[row.customerId] = row.warehouseId;
      }
    });
    storeWarehouseMap.value = map;
  } finally {
    summaryLoading.value = false;
  }
}

// 首屏加载 + 切回页签刷新（原因见 #/utils/usePageActivateLoad）
usePageActivateLoad(async () => {
  await loadSummary();
});

/** 汇总表列 */
const summaryColumns: TableColumnsType<ErpStockBatchApi.StoreStockSummary> = [
  { title: '门店', dataIndex: 'customerName', key: 'customerName' },
  { title: '门店仓', dataIndex: 'warehouseName', key: 'warehouseName' },
  {
    title: '物料数',
    dataIndex: 'productCount',
    key: 'productCount',
    width: 100,
    align: 'right',
  },
  {
    title: '库存数量',
    dataIndex: 'totalCount',
    key: 'totalCount',
    width: 130,
    align: 'right',
    customRender: ({ text }: any) => erpCountInputFormatter(text ?? 0),
  },
  {
    title: '库存金额',
    dataIndex: 'totalAmount',
    key: 'totalAmount',
    width: 130,
    align: 'right',
    customRender: ({ text }: any) => erpNumberFormatter(text ?? 0, 2),
  },
];

/** 汇总行点击：按该门店过滤下方明细；再次点击同店则取消过滤 */
async function handleSummarySelect(row: ErpStockBatchApi.StoreStockSummary) {
  const next = activeCustomerId.value === row.customerId ? undefined : row.customerId;
  activeCustomerId.value = next;
  // vxe 的 query 会合并「最近一次提交值」，因此这里显式写回表单并刷新提交快照
  await gridApi.formApi.setFieldValue('customerId', next);
  const formValues = await gridApi.formApi.getValues();
  gridApi.formApi.setLatestSubmissionValues(formValues);
  await gridApi.reload(formValues);
}

/** 汇总行样式：可点击 + 选中行高亮 */
function summaryRowProps(row: ErpStockBatchApi.StoreStockSummary) {
  return {
    style: { cursor: 'pointer' },
    class:
      activeCustomerId.value !== undefined &&
      activeCustomerId.value === row.customerId
        ? 'bg-blue-50'
        : '',
    onClick: () => {
      void handleSummarySelect(row);
    },
  };
}

/** 列表的搜索表单（门店 → 门店仓，物料 / 批次号 → 批次） */
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
      fieldName: 'productId',
      label: '物料',
      component: 'ApiSelect',
      componentProps: {
        placeholder: '请选择物料',
        allowClear: true,
        showSearch: true,
        api: getProductSimpleList,
        labelField: 'name',
        valueField: 'id',
      },
    },
    {
      fieldName: 'batchNo',
      label: '批次号',
      component: 'Input',
      componentProps: {
        placeholder: '请输入批次号（模糊）',
        allowClear: true,
      },
    },
    {
      fieldName: 'onlyStock',
      label: '只看有量',
      component: 'Switch',
      defaultValue: true,
      componentProps: {
        checkedChildren: '只看有量',
        unCheckedChildren: '含零',
      },
    },
  ];
}

/** 列表的字段（沿用批次库存的口径，仅去掉「仓库类型」维度） */
function useGridColumns(): VxeTableGridOptions<ErpStockBatchApi.StockBatch>['columns'] {
  return [
    { field: 'productName', title: '物料', minWidth: 140 },
    { field: 'warehouseName', title: '门店仓', minWidth: 130 },
    {
      field: 'batchNo',
      title: '批次号',
      minWidth: 160,
      showOverflow: 'tooltip',
    },
    {
      field: 'productionDate',
      title: '生产日期',
      width: 110,
      formatter: ({ cellValue }: any) => formatBatchDate(cellValue) || '-',
    },
    { field: 'expiryDate', title: '有效期', width: 170, slots: { default: 'expiry' } },
    {
      field: 'count',
      title: '在仓',
      width: 110,
      align: 'right',
      formatter: 'formatAmount3',
    },
    {
      field: 'occupiedCount',
      title: '占用',
      width: 110,
      align: 'right',
      formatter: 'formatAmount3',
    },
    {
      field: 'transitCount',
      title: '在途',
      width: 110,
      align: 'right',
      formatter: 'formatAmount3',
    },
    {
      field: 'inspectingCount',
      title: '待检',
      width: 110,
      align: 'right',
      formatter: 'formatAmount3',
    },
    {
      field: 'availableCount',
      title: '可用量',
      width: 110,
      align: 'right',
      formatter: 'formatAmount3',
    },
    {
      field: 'unitCost',
      title: '单位成本',
      width: 110,
      align: 'right',
      formatter: 'formatAmount2',
    },
    {
      field: 'totalCost',
      title: '总成本',
      width: 120,
      align: 'right',
      formatter: 'formatAmount2',
    },
    {
      field: 'sourceBizNo',
      title: '来源单据号',
      minWidth: 180,
      showOverflow: 'tooltip',
    },
    {
      field: 'sourceReversed',
      title: '来源冲销',
      width: 100,
      slots: { default: 'sourceReversed' },
    },
  ];
}

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
          const { customerId, onlyStock = true, ...rest } = formValues as {
            customerId?: number;
            onlyStock?: boolean;
          } & Record<string, any>;
          activeCustomerId.value = customerId ?? undefined;
          // 只在门店仓里查（warehouseType = STORE 由 sql/local/38 脚本引入）
          const baseParams: ErpStockBatchApi.StockBatchPageReqVO = {
            pageNo: page.currentPage,
            pageSize: page.pageSize,
            warehouseType: 'STORE',
            ...rest,
          };
          if (customerId !== undefined && customerId !== null) {
            const warehouseId = storeWarehouseMap.value[customerId];
            if (warehouseId === undefined) {
              // 门店还没有门店仓（汇总接口没有该门店），明细必然为空，直接短路
              return { list: [], total: 0 };
            }
            baseParams.warehouseId = warehouseId;
          }
          const result = await getStockBatchPage(baseParams);
          const list = result?.list ?? [];
          if (onlyStock === false) {
            return { list, total: result?.total ?? list.length };
          }
          // 与批次库存页同口径：后端 /page 暂无 onlyPositive，先对当前页做行过滤
          return {
            list: list.filter((row) => Number(row.count ?? 0) > 0),
            total: result?.total ?? list.length,
          };
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
</script>

<template>
  <Page auto-content-height>
    <template #doc>
      <DocAlert
        title="【库存】门店库存"
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
          <span class="text-sm">门店库存汇总</span>
          <span class="ml-2 text-xs text-gray-400">
            点击门店行可按门店过滤下方明细，再次点击取消
          </span>
        </template>
        <Table
          :columns="summaryColumns"
          :custom-row="summaryRowProps"
          :data-source="summaryList"
          :pagination="false"
          :scroll="{ y: 180 }"
          bordered
          row-key="customerId"
          size="small"
        >
          <template #emptyText>暂无门店库存</template>
        </Table>
      </Card>

      <!-- 网格自己读父容器高度（height: auto），因此外面必须再包一层定了高的 flex 项 -->
      <div class="min-h-0 flex-1">
        <Grid table-title="门店库存明细（门店仓批次）">
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
          <template #sourceReversed="{ row }">
            <Tag :color="row.sourceReversed ? 'red' : 'default'">
              {{ row.sourceReversed ? '已冲销' : '未冲销' }}
            </Tag>
          </template>
        </Grid>
      </div>
    </div>
  </Page>
</template>
