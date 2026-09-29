<script lang="ts" setup>
import type { WorkbenchItem } from './data';

import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { TradeWorkbenchApi } from '#/api/mall/trade/workbench';

import { computed, onMounted, reactive, ref } from 'vue';

import { Page } from '@vben/common-ui';

import { InputNumber, message, Select, Tag } from 'ant-design-vue';

import { ACTION_ICON, TableAction, useVbenVxeGrid } from '#/adapter/vxe-table';
import { getSupplierSimpleList } from '#/api/erp/purchase/supplier';
import { getWarehouseSimpleList } from '#/api/erp/stock/warehouse';
import {
  getWorkbenchItems,
  getWorkbenchPage,
  pushWorkbenchItems,
} from '#/api/mall/trade/workbench';

import {
  fenToYuanText,
  useAllocModeOptions,
  useGridColumns,
  useGridFormSchema,
  useItemColumns,
} from './data';

/** 已展开明细的订单编号（用于按钮文案：分料 / 收起） */
const expandedOrderIds = ref<number[]>([]);
/** 展开后的明细行缓存：orderId -> items */
const itemsMap = reactive<Record<number, WorkbenchItem[]>>({});
/** 明细加载中 */
const loadingOrderIds = reactive<Record<number, boolean>>({});

/** 供应商候选（直拨用） */
const suppliers = ref<any[]>([]);
/** 发货仓库候选（统配用，默认中心库） */
const warehouses = ref<any[]>([]);
const warehouseId = ref<number | undefined>(undefined);
const defaultSupplierId = ref<number | undefined>(undefined);

const itemColumns = useItemColumns();

const [Grid, gridApi] = useVbenVxeGrid({
  formOptions: {
    schema: useGridFormSchema(),
  },
  gridOptions: {
    columns: useGridColumns(),
    height: 'auto',
    keepSource: true,
    expandConfig: {
      padding: true,
    },
    proxyConfig: {
      ajax: {
        query: async ({ page }, formValues) => {
          const result = await getWorkbenchPage({
            pageNo: page.currentPage,
            pageSize: page.pageSize,
            ...formValues,
          });
          return result;
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
  } as VxeTableGridOptions<TradeWorkbenchApi.Order>,
});

function handleRefresh() {
  expandedOrderIds.value = [];
  gridApi.query();
}

function isExpanded(row: TradeWorkbenchApi.Order): boolean {
  return row.id !== undefined && expandedOrderIds.value.includes(row.id);
}

/** 展开 / 收起明细，并在展开时拉取明细行 */
async function toggleExpand(row: TradeWorkbenchApi.Order) {
  const id = row.id;
  if (id === undefined) return;
  const expanded = isExpanded(row);
  const grid = gridApi.grid as unknown as {
    setRowExpand?: (rows: any[], expanded: boolean) => void;
    toggleRowExpand?: (row: any) => void;
  };
  if (grid?.setRowExpand) {
    grid.setRowExpand([row], !expanded);
  } else {
    grid?.toggleRowExpand?.(row);
  }
  expandedOrderIds.value = expanded
    ? expandedOrderIds.value.filter((item) => item !== id)
    : [...expandedOrderIds.value, id];
  if (!expanded) {
    await loadItems(id);
  }
}

/** 拉取明细行，并按物料的分料属性预置分料方式与数量 */
async function loadItems(orderId: number) {
  loadingOrderIds[orderId] = true;
  try {
    const items: WorkbenchItem[] = await getWorkbenchItems(orderId);
    items.forEach((item) => {
      if (item.allocMode) {
        // 已下推：只读展示
        item.pushMode = item.allocMode;
        item.pushCount = Number(item.allocCount ?? item.count ?? 0);
        return;
      }
      const options = useAllocModeOptions(item.allowCentral, item.allowDirect);
      // 只允许一种时自动选中并锁定（选项里只有一个）
      item.pushMode = options.length === 1 ? options[0]!.value : undefined;
      item.pushCount = Number(item.availableCount ?? item.count ?? 0);
      item.supplierId = defaultSupplierId.value;
    });
    itemsMap[orderId] = items;
  } finally {
    loadingOrderIds[orderId] = false;
  }
}

/** 某行的分料方式是否锁定（物料只允许一种，或已下推） */
function isModeLocked(item: TradeWorkbenchApi.Item): boolean {
  if (item.allocMode) return true;
  return useAllocModeOptions(item.allowCentral, item.allowDirect).length <= 1;
}

function modeOptions(item: TradeWorkbenchApi.Item) {
  return useAllocModeOptions(item.allowCentral, item.allowDirect);
}

/** 该单待下推的行 */
function pendingItems(orderId: number): WorkbenchItem[] {
  return (itemsMap[orderId] ?? []).filter((item) => !item.allocMode);
}

/**
 * ERP 真实可用量是否小于本次要货数量（不足时高亮提示）
 *
 * 可用量 = 在仓 − 占用 + 在途，由后端按默认发货仓（中心库）统计。
 */
function isStockShort(item: WorkbenchItem): boolean {
  const available = Number(item.erpAvailableCount ?? 0);
  const need = Number(item.count ?? 0);
  return available < need;
}

const pushDisabledReason = (row: TradeWorkbenchApi.Order) => {
  if (loadingOrderIds[row.id!]) return '明细加载中';
  const pending = pendingItems(row.id!);
  if (pending.length === 0) return '没有待分料的行';
  if (pending.some((item) => !item.pushMode)) return '还有行未选择分料方式';
  return '';
};

/** 下推：把已选分料方式的明细行推到 ERP（统配→配送出库；直拨→采购订单） */
async function handlePush(row: TradeWorkbenchApi.Order) {
  const orderId = row.id!;
  const reason = pushDisabledReason(row);
  if (reason) {
    message.warning(reason);
    return;
  }
  const items = pendingItems(orderId).map((item) => ({
    itemId: item.id!,
    allocMode: item.pushMode!,
    count: item.pushCount,
    supplierId: item.pushMode === 'DIRECT' ? item.supplierId : undefined,
  }));
  const hide = message.loading({ content: '下推中...', duration: 0 });
  try {
    const result = await pushWorkbenchItems({
      orderId,
      warehouseId: warehouseId.value,
      supplierId: defaultSupplierId.value,
      items,
    });
    const bills = (result?.results ?? [])
      .map((item) => `${allocModeText(item.allocMode)} → ${item.billNo}`)
      .join('；');
    message.success(`下推成功：${bills}`);
    handleRefresh();
  } finally {
    hide();
  }
}

function allocModeText(mode?: string) {
  if (mode === 'CENTRAL') return '统配';
  if (mode === 'DIRECT') return '直拨';
  return mode ?? '-';
}

const supplierOptions = computed(() =>
  suppliers.value.map((supplier) => ({
    label: supplier.name,
    value: supplier.id,
  })),
);

const warehouseOptions = computed(() =>
  warehouses.value.map((warehouse) => ({
    label: warehouse.defaultStatus
      ? `${warehouse.name}（默认）`
      : warehouse.name,
    value: warehouse.id,
  })),
);

onMounted(async () => {
  const [supplierList, warehouseList] = await Promise.all([
    getSupplierSimpleList().catch(() => []),
    getWarehouseSimpleList().catch(() => []),
  ]);
  suppliers.value = supplierList ?? [];
  warehouses.value = warehouseList ?? [];
  defaultSupplierId.value = suppliers.value[0]?.id;
  warehouseId.value =
    warehouses.value.find((item) => item.defaultStatus)?.id ??
    warehouses.value[0]?.id;
});
</script>

<template>
  <Page auto-content-height>
    <Grid table-title="待处理要货单（订单工作台）">
      <template #toolbar-tools>
        <div class="mr-2 flex items-center gap-2">
          <span class="text-sm text-gray-500">发货仓</span>
          <Select
            v-model:value="warehouseId"
            :options="warehouseOptions"
            class="w-40"
            placeholder="默认仓库"
          />
          <span class="text-sm text-gray-500">默认供应商</span>
          <Select
            v-model:value="defaultSupplierId"
            :options="supplierOptions"
            class="w-52"
            placeholder="直拨默认供应商"
          />
        </div>
      </template>
      <template #expand_content="{ row }">
        <div class="px-2 py-1">
          <div v-if="loadingOrderIds[row.id]" class="text-gray-400">
            明细加载中...
          </div>
          <table v-else class="w-full text-sm">
            <thead>
              <tr class="text-left text-gray-500">
                <th
                  v-for="column in itemColumns"
                  :key="column.key"
                  class="py-1 pr-3 font-normal"
                >
                  {{ column.title }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="item in itemsMap[row.id] ?? []"
                :key="item.id"
                class="border-t border-gray-100"
              >
                <td class="py-2 pr-3">
                  {{ item.spuName }}
                  <Tag v-if="item.erpProductBarCode" color="blue">
                    {{ item.erpProductBarCode }}
                  </Tag>
                </td>
                <td class="py-2 pr-3">{{ item.count }}</td>
                <td class="py-2 pr-3">
                  {{ item.price === undefined ? '-' : fenToYuanText(item.price) }}
                </td>
                <td class="py-2 pr-3">
                  {{
                    item.payPrice === undefined
                      ? '-'
                      : fenToYuanText(item.payPrice)
                  }}
                </td>
                <td class="py-2 pr-3">
                  <span
                    :class="
                      item.allocMode
                        ? 'text-green-600'
                        : isStockShort(item)
                          ? 'text-red-500'
                          : 'text-gray-600'
                    "
                  >
                    {{ item.availableHint }}
                  </span>
                </td>
                <td class="py-2 pr-3">
                  <Select
                    v-model:value="item.pushMode"
                    :options="modeOptions(item)"
                    :disabled="isModeLocked(item)"
                    :placeholder="
                      item.allowCentral || item.allowDirect
                        ? '请选择分料方式'
                        : '物料未建档'
                    "
                    class="w-44"
                    size="small"
                  />
                </td>
                <td class="py-2 pr-3">
                  <InputNumber
                    v-model:value="item.pushCount"
                    :min="1"
                    :max="item.count"
                    :disabled="!!item.allocMode"
                    size="small"
                    class="w-28"
                  />
                </td>
                <td class="py-2 pr-3">
                  <Select
                    v-if="item.pushMode === 'DIRECT' && !item.allocMode"
                    v-model:value="item.supplierId"
                    :options="supplierOptions"
                    class="w-44"
                    placeholder="请选择供应商"
                    size="small"
                  />
                  <span v-else class="text-gray-400">-</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>
      <template #actions="{ row }">
        <TableAction
          :actions="[
            {
              label: isExpanded(row) ? '收起' : '分料',
              type: 'link',
              icon: ACTION_ICON.VIEW,
              auth: ['trade:workbench:query'],
              onClick: toggleExpand.bind(null, row),
            },
            {
              label: '下推',
              type: 'link',
              auth: ['trade:workbench:push'],
              disabled: !!pushDisabledReason(row),
              onClick: handlePush.bind(null, row),
            },
          ]"
        />
      </template>
    </Grid>
  </Page>
</template>
