<script lang="ts" setup>
import type { VbenFormSchema } from '#/adapter/form';
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { TradeStoreReceiptApi } from '#/api/mall/trade/storeReceipt';

import { computed, onBeforeUnmount, ref } from 'vue';

import { useAccess } from '@vben/access';
import { Page, prompt, useVbenDrawer, useVbenModal } from '@vben/common-ui';
import { downloadFileFromBlobPart, erpNumberFormatter } from '@vben/utils';

import {
  DatePicker,
  Form,
  FormItem,
  Input,
  InputNumber,
  message,
  Select,
  Tag,
  Textarea,
} from 'ant-design-vue';

import { ACTION_ICON, TableAction, useVbenVxeGrid } from '#/adapter/vxe-table';
import { getCustomerSimpleList } from '#/api/erp/sale/customer';
import { getOrderPage } from '#/api/mall/trade/order';
import {
  cancelStoreReceipt,
  createStoreReceipt,
  exportStoreReceipt,
  getStoreReceiptPage,
} from '#/api/mall/trade/storeReceipt';
import { getSimpleDeptList } from '#/api/system/dept';
import { FileUpload } from '#/components/upload';
import { getRangePickerDefaultProps } from '#/utils';
import { usePageActivateLoad } from '#/utils/usePageActivateLoad';

import Detail from './modules/detail.vue';

/** 门店收货单列表 */
defineOptions({ name: 'TradeStoreReceipt' });

const { hasAccessByCodes } = useAccess();

/** 收货单状态：0 待确认 / 10 已确认 / 20 已作废 */
const STATUS_OPTIONS = [
  { label: '待确认', value: 0 },
  { label: '已确认', value: 10 },
  { label: '已作废', value: 20 },
];

/** 差异类型：0 无差异 / 1 少收 / 2 多收 / 3 破损 / 4 混合 */
const DIFF_TYPE_OPTIONS = [
  { label: '无差异', value: 0 },
  { label: '少收', value: 1 },
  { label: '多收', value: 2 },
  { label: '破损', value: 3 },
  { label: '混合', value: 4 },
];

/** 状态标签色：待确认黄、已确认绿、已作废灰 */
const STATUS_COLOR: Record<number, string> = {
  0: 'orange',
  10: 'green',
  20: 'default',
};

/** 差异标签色：无差异绿、少收黄、多收红、破损橙红、混合紫 */
const DIFF_TYPE_COLOR: Record<number, string> = {
  0: 'green',
  1: 'orange',
  2: 'red',
  3: 'volcano',
  4: 'purple',
};

/** 列表的搜索表单 */
function useGridFormSchema(): VbenFormSchema[] {
  return [
    {
      fieldName: 'no',
      label: '收货单号',
      component: 'Input',
      componentProps: {
        placeholder: '请输入收货单号',
        allowClear: true,
      },
    },
    {
      fieldName: 'orderNo',
      label: '要货单号',
      component: 'Input',
      componentProps: {
        placeholder: '请输入要货单号',
        allowClear: true,
      },
    },
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
      fieldName: 'status',
      label: '状态',
      component: 'Select',
      componentProps: {
        placeholder: '请选择状态',
        allowClear: true,
        options: STATUS_OPTIONS,
      },
    },
    {
      fieldName: 'diffType',
      label: '差异类型',
      component: 'Select',
      componentProps: {
        placeholder: '请选择差异类型',
        allowClear: true,
        options: DIFF_TYPE_OPTIONS,
      },
    },
    {
      fieldName: 'receiveTime',
      label: '收货时间',
      component: 'RangePicker',
      componentProps: {
        ...getRangePickerDefaultProps(),
        allowClear: true,
      },
    },
  ];
}

/** 列表的字段 */
function useGridColumns(): VxeTableGridOptions<TradeStoreReceiptApi.StoreReceipt>['columns'] {
  return [
    { field: 'no', title: '收货单号', width: 190, fixed: 'left' },
    { field: 'orderNo', title: '要货单号', width: 190 },
    { field: 'customerName', title: '门店', minWidth: 180 },
    {
      field: 'status',
      title: '状态',
      width: 100,
      slots: { default: 'status' },
    },
    {
      field: 'diffType',
      title: '差异类型',
      width: 110,
      slots: { default: 'diffType' },
    },
    {
      field: 'totalCount',
      title: '应收数量',
      width: 110,
      align: 'right',
      formatter: 'formatAmount3',
    },
    {
      field: 'receiptCount',
      title: '实收数量',
      width: 110,
      align: 'right',
      formatter: 'formatAmount3',
    },
    {
      field: 'diffCount',
      title: '差异数量',
      width: 110,
      align: 'right',
      slots: { default: 'diffCount' },
    },
    {
      field: 'totalPrice',
      title: '应收金额',
      width: 110,
      align: 'right',
      formatter: 'formatAmount2',
    },
    {
      field: 'receiptPrice',
      title: '实收金额',
      width: 110,
      align: 'right',
      formatter: 'formatAmount2',
    },
    {
      field: 'diffAmount',
      title: '差异金额',
      width: 110,
      align: 'right',
      formatter: 'formatAmount2',
    },
    { field: 'saleOutNo', title: '配送出库单', width: 190 },
    { field: 'warehouseName', title: '收货门店仓', minWidth: 140 },
    {
      field: 'receiveTime',
      title: '收货时间',
      width: 170,
      formatter: 'formatDateTime',
    },
    { field: 'receiverName', title: '收货人', width: 110 },
    { field: 'remark', title: '备注', minWidth: 160, showOverflow: 'tooltip' },
    {
      title: '操作',
      width: 150,
      fixed: 'right',
      slots: { default: 'actions' },
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
          return await getStoreReceiptPage({
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
  } as VxeTableGridOptions<TradeStoreReceiptApi.StoreReceipt>,
});

/** 刷新表格 */
function handleRefresh() {
  gridApi.query();
}

/** 作废收货单：先让用户填写作废原因，取消填写视为放弃操作 */
async function handleCancel(row: TradeStoreReceiptApi.StoreReceipt) {
  let reason: string | undefined;
  try {
    reason = await prompt<string>({
      content: `请输入作废原因（${row.no}）`,
      defaultValue: '',
    });
  } catch {
    // 用户取消填写，直接返回
    return;
  }
  if (!reason) {
    message.warning('作废原因不能为空');
    return;
  }
  const hide = message.loading({ content: '作废中...', duration: 0 });
  try {
    await cancelStoreReceipt(row.id!, reason);
    message.success('作废成功');
    handleRefresh();
  } finally {
    hide();
  }
}

/** 导出门店收货单 */
async function handleExport() {
  const data = await exportStoreReceipt(await gridApi.formApi.getValues());
  downloadFileFromBlobPart({ fileName: '门店收货单.xls', source: data });
}

/** 详情抽屉 */
const [DetailDrawer, detailDrawerApi] = useVbenDrawer({
  connectedComponent: Detail,
  destroyOnClose: true,
});

/** 查看详情 */
function handleDetail(row: TradeStoreReceiptApi.StoreReceipt) {
  detailDrawerApi.setData({ id: row.id }).open();
}

/* ==================== 后台代录 ==================== */

/** 代录明细行（前端编辑态） */
interface CreateItemRow {
  orderItemId: number; // 要货单行编号
  spuName?: string; // 商品名称
  properties?: string; // 规格属性
  expectCount: number; // 应收数量（要货数量）
  receiptCount?: number; // 实收数量
  diffReason?: string; // 差异原因
  batchNo?: string; // 批次号
  productionDate?: string; // 生产日期 yyyy-MM-dd
  expiryDate?: string; // 有效期 yyyy-MM-dd
}

/** 代录表单 */
const createForm = ref<{
  fileUrls: string[];
  orderId?: number;
  receiverMobile?: string;
  receiverName?: string;
  remark?: string;
}>({ fileUrls: [] });
/** 代录明细行 */
const createItems = ref<CreateItemRow[]>([]);
/** 要货单下拉候选 */
const orderOptions = ref<{ label: string; value: number }[]>([]);
const orderLoading = ref(false);
/** 已选要货单（用于回显门店） */
const selectedOrder = ref<null | {
  customerId?: number;
  deptId?: number;
  items?: any[];
  no?: string;
}>(null);
/** 门店编号 → 门店名称（下拉候选的标签里带上门店，避免只看单号选错） */
const customerNameMap = ref<Record<number, string>>({});

/** 搜索结果缓存：orderId → 要货单（含明细行），选中时不必再发一次请求 */
const orderCache = ref<Record<number, any>>({});

let orderSearchTimer: ReturnType<typeof setTimeout> | undefined;

/** 已选要货单对应的门店名称（门店编号 → 名称映射在首屏预载） */
const selectedOrderCustomerName = computed(() => {
  const customerId = selectedOrder.value?.customerId;
  if (customerId === undefined) {
    return '-';
  }
  return customerNameMap.value[customerId] ?? '-';
});

/** 门店下拉：把要货单号与门店名称拼在一起展示 */
function orderLabel(order: any) {
  const customerName = customerNameMap.value[order.customerId];
  return customerName ? `${order.no}（${customerName}）` : String(order.no ?? '');
}

/** 按单号远程搜索要货单 */
async function searchOrders(keyword?: string) {
  orderLoading.value = true;
  try {
    const result = await getOrderPage({
      pageNo: 1,
      pageSize: 20,
      no: keyword || undefined,
    });
    const list = result?.list ?? [];
    orderOptions.value = list.map((order) => ({
      label: orderLabel(order),
      value: order.id!,
    }));
    // 缓存本次结果，选中时不必再发一次请求
    list.forEach((order) => {
      orderCache.value[order.id!] = order;
    });
  } finally {
    orderLoading.value = false;
  }
}

/** 输入要货单号时防抖搜索 */
function handleOrderSearch(keyword: string) {
  if (orderSearchTimer) {
    clearTimeout(orderSearchTimer);
  }
  orderSearchTimer = setTimeout(() => {
    void searchOrders(keyword);
  }, 300);
}

/** 选中要货单后，按要货数量预置实收数量 */
function handleOrderChange(orderId: unknown) {
  const order = orderCache.value[Number(orderId)];
  selectedOrder.value = order ?? null;
  createItems.value = (order?.items ?? []).map((item: any) => ({
    orderItemId: item.id,
    spuName: item.spuName,
    properties: formatProperties(item.properties),
    expectCount: Number(item.count ?? 0),
    receiptCount: Number(item.count ?? 0),
    diffReason: '',
    batchNo: '',
    productionDate: undefined,
    expiryDate: undefined,
  }));
}

/** 规格属性数组 → 文本 */
function formatProperties(properties?: any[] | string) {
  if (!properties) return '';
  if (typeof properties === 'string') return properties;
  return properties
    .map((property) => property?.valueName ?? property?.propertyName ?? '')
    .filter(Boolean)
    .join(' / ');
}

/** 单行差异数量 = 实收 − 应收 */
function rowDiffCount(item: CreateItemRow) {
  return Number(item.receiptCount ?? 0) - Number(item.expectCount ?? 0);
}

/** 差异行的底色：少收黄、多收红 */
function rowDiffClass(item: CreateItemRow) {
  const diff = rowDiffCount(item);
  if (diff > 0) return 'bg-red-50';
  if (diff < 0) return 'bg-amber-50';
  return '';
}

/** 打开代录弹窗 */
function handleCreate() {
  orderOptions.value = [];
  orderCache.value = {};
  selectedOrder.value = null;
  createItems.value = [];
  createForm.value = { fileUrls: [] };
  createModalApi.open();
  // 打开即给出最近 20 张要货单，避免空白下拉
  void searchOrders();
}

const [CreateModal, createModalApi] = useVbenModal({
  async onConfirm() {
    if (!createForm.value.orderId) {
      message.warning('请选择要货单');
      return;
    }
    if (createItems.value.length === 0) {
      message.warning('该要货单没有可收货的明细行');
      return;
    }
    const invalid = createItems.value.find(
      (item) =>
        !Number.isFinite(Number(item.receiptCount)) ||
        Number(item.receiptCount) < 0,
    );
    if (invalid) {
      message.warning('实收数量不能为空且不能小于 0');
      return;
    }
    const missingReason = createItems.value.find(
      (item) => rowDiffCount(item) !== 0 && !item.diffReason,
    );
    if (missingReason) {
      message.warning('存在差异的行必须填写差异原因');
      return;
    }
    createModalApi.lock();
    try {
      await createStoreReceipt({
        orderId: createForm.value.orderId,
        receiverName: createForm.value.receiverName,
        receiverMobile: createForm.value.receiverMobile,
        fileUrls: createForm.value.fileUrls ?? [],
        remark: createForm.value.remark,
        items: createItems.value.map((item) => ({
          orderItemId: item.orderItemId,
          receiptCount: Number(item.receiptCount),
          diffReason: item.diffReason || undefined,
          batchNo: item.batchNo || undefined,
          productionDate: item.productionDate || undefined,
          expiryDate: item.expiryDate || undefined,
        })),
      });
      await createModalApi.close();
      message.success('代录成功');
      handleRefresh();
    } finally {
      createModalApi.unlock();
    }
  },
});

/** 差异数量文本：带正负号，正数 = 多收 */
function diffCountText(value?: number) {
  const count = Number(value ?? 0);
  if (count === 0) return '0';
  return `${count > 0 ? '+' : ''}${erpNumberFormatter(count, 3)}`;
}

/** 实收数量合计 */
const createReceiptTotal = computed(() =>
  createItems.value.reduce((sum, item) => sum + Number(item.receiptCount ?? 0), 0),
);

/** 应收数量合计 */
const createExpectTotal = computed(() =>
  createItems.value.reduce((sum, item) => sum + Number(item.expectCount ?? 0), 0),
);

onBeforeUnmount(() => {
  if (orderSearchTimer) {
    clearTimeout(orderSearchTimer);
  }
});

/**
 * 首屏加载 + 切回页签刷新（原因见 #/utils/usePageActivateLoad）。
 * 列表本身由 vxe 的 proxyConfig 自动加载，这里只预载门店名称映射，
 * 供代录弹窗的「要货单」下拉拼标签用。
 */
usePageActivateLoad(async () => {
  const customers = await getCustomerSimpleList().catch(() => []);
  const map: Record<number, string> = {};
  (customers ?? []).forEach((customer: any) => {
    if (customer?.id !== undefined) {
      map[customer.id] = customer.name;
    }
  });
  customerNameMap.value = map;
});
</script>

<template>
  <Page auto-content-height>
    <DetailDrawer />

    <CreateModal
      :title="'代录门店收货单'"
      class="w-4/5"
      :close-on-click-modal="false"
    >
      <Form layout="vertical" class="mx-1">
        <div class="grid grid-cols-2 gap-x-4">
          <FormItem label="要货单" required>
            <Select
              v-model:value="createForm.orderId"
              :options="orderOptions"
              :loading="orderLoading"
              :filter-option="false"
              placeholder="输入要货单号搜索"
              show-search
              allow-clear
              @search="handleOrderSearch"
              @change="handleOrderChange"
            />
          </FormItem>
          <FormItem label="门店">
            <span class="text-gray-600">{{ selectedOrderCustomerName }}</span>
          </FormItem>
          <FormItem label="收货人">
            <Input
              v-model:value="createForm.receiverName"
              placeholder="请输入收货人"
              :maxlength="64"
            />
          </FormItem>
          <FormItem label="收货人手机">
            <Input
              v-model:value="createForm.receiverMobile"
              placeholder="请输入收货人手机"
              :maxlength="32"
            />
          </FormItem>
          <FormItem label="收货凭证" class="col-span-2">
            <FileUpload
              v-model:value="createForm.fileUrls"
              :max-number="3"
              :max-size="10"
              :accept="['jpg', 'jpeg', 'png', 'webp']"
              multiple
              show-description
            />
          </FormItem>
          <FormItem label="备注" class="col-span-2">
            <Textarea
              v-model:value="createForm.remark"
              :rows="2"
              :maxlength="500"
              show-count
              placeholder="请输入备注"
            />
          </FormItem>
        </div>
      </Form>

      <div class="mt-2 mb-1 text-sm text-gray-500">
        收货明细（应收合计 {{ createExpectTotal }} / 实收合计
        {{ createReceiptTotal }}）
      </div>
      <div class="max-h-80 overflow-auto rounded border border-gray-200">
        <table class="w-full text-sm">
          <thead class="sticky top-0 bg-gray-50">
            <tr class="text-left text-gray-500">
              <th class="px-2 py-2 font-normal">商品</th>
              <th class="w-20 px-2 py-2 text-right font-normal">应收</th>
              <th class="w-28 px-2 py-2 font-normal">实收</th>
              <th class="w-20 px-2 py-2 text-right font-normal">差异</th>
              <th class="w-40 px-2 py-2 font-normal">差异原因</th>
              <th class="w-36 px-2 py-2 font-normal">批次号</th>
              <th class="w-36 px-2 py-2 font-normal">生产日期</th>
              <th class="w-36 px-2 py-2 font-normal">有效期</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="createItems.length === 0">
              <td colspan="8" class="px-2 py-6 text-center text-gray-400">
                请先选择要货单
              </td>
            </tr>
            <tr
              v-for="item in createItems"
              :key="item.orderItemId"
              class="border-t border-gray-100"
              :class="rowDiffClass(item)"
            >
              <td class="px-2 py-2">
                {{ item.spuName }}
                <div v-if="item.properties" class="text-xs text-gray-400">
                  {{ item.properties }}
                </div>
              </td>
              <td class="px-2 py-2 text-right">{{ item.expectCount }}</td>
              <td class="px-2 py-2">
                <InputNumber
                  v-model:value="item.receiptCount"
                  :min="0"
                  :precision="3"
                  size="small"
                  class="w-24"
                />
              </td>
              <td
                class="px-2 py-2 text-right"
                :class="
                  rowDiffCount(item) === 0
                    ? 'text-gray-500'
                    : rowDiffCount(item) > 0
                      ? 'text-red-500'
                      : 'text-orange-500'
                "
              >
                {{ diffCountText(rowDiffCount(item)) }}
              </td>
              <td class="px-2 py-2">
                <Input
                  v-model:value="item.diffReason"
                  size="small"
                  placeholder="差异必填"
                  :maxlength="255"
                />
              </td>
              <td class="px-2 py-2">
                <Input
                  v-model:value="item.batchNo"
                  size="small"
                  placeholder="批次号"
                  :maxlength="64"
                />
              </td>
              <td class="px-2 py-2">
                <DatePicker
                  v-model:value="item.productionDate"
                  value-format="YYYY-MM-DD"
                  size="small"
                  class="w-full"
                />
              </td>
              <td class="px-2 py-2">
                <DatePicker
                  v-model:value="item.expiryDate"
                  value-format="YYYY-MM-DD"
                  size="small"
                  class="w-full"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </CreateModal>

    <Grid table-title="门店收货单列表">
      <template #toolbar-tools>
        <TableAction
          v-if="hasAccessByCodes(['trade:store-receipt:create'])"
          :actions="[
            {
              label: '代录',
              type: 'primary',
              icon: ACTION_ICON.ADD,
              onClick: handleCreate,
            },
          ]"
        />
        <TableAction
          v-if="hasAccessByCodes(['trade:store-receipt:export'])"
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
      <template #status="{ row }">
        <Tag :color="STATUS_COLOR[row.status ?? -1] ?? 'default'">
          {{ row.statusName ?? '-' }}
        </Tag>
      </template>
      <template #diffType="{ row }">
        <Tag :color="DIFF_TYPE_COLOR[row.diffType ?? -1] ?? 'default'">
          {{ row.diffTypeName ?? '-' }}
        </Tag>
      </template>
      <template #diffCount="{ row }">
        <span
          :class="
            Number(row.diffCount ?? 0) === 0
              ? 'text-gray-500'
              : Number(row.diffCount) > 0
                ? 'text-red-500'
                : 'text-orange-500'
          "
        >
          {{ diffCountText(row.diffCount) }}
        </span>
      </template>
      <template #actions="{ row }">
        <TableAction
          :actions="[
            {
              label: '详情',
              type: 'link',
              icon: ACTION_ICON.VIEW,
              auth: ['trade:store-receipt:query'],
              onClick: handleDetail.bind(null, row),
            },
            {
              label: '作废',
              type: 'link',
              danger: true,
              icon: ACTION_ICON.DELETE,
              auth: ['trade:store-receipt:cancel'],
              // 只有「待确认 / 已确认」的单据可以作废，已作废的不再展示入口
              ifShow: () => row.status !== 20,
              onClick: handleCancel.bind(null, row),
            },
          ]"
        />
      </template>
    </Grid>
  </Page>
</template>
