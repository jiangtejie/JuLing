<script lang="ts" setup>
import type { ErpProductApi } from '#/api/erp/product/product';
import type { ErpPurchaseOrderApi } from '#/api/erp/purchase/order';

import { computed, nextTick, onMounted, ref, watch } from 'vue';

import {
  erpCountInputFormatter,
  erpPriceInputFormatter,
  erpPriceMultiply,
} from '@vben/utils';

import { Input, InputNumber, Select } from 'ant-design-vue';

import { TableAction, useVbenVxeGrid } from '#/adapter/vxe-table';
import { getProductSimpleList } from '#/api/erp/product/product';
import { matchPurchasePrice } from '#/api/erp/purchase/price';
import { getStockCount } from '#/api/erp/stock/stock';

import { useFormItemColumns } from '../data';

interface Props {
  items?: ErpPurchaseOrderApi.PurchaseOrderItem[];
  disabled?: boolean;
  discountPercent?: number;
  /**
   * 供应商的开票税点：新增订单行时作为税率默认值
   *
   * 留空也可以 —— 后端建单时会用供应商的开票税点兜底（见 ErpPurchaseOrderServiceImpl）。
   * 这里只是让用户新增行时就能看到默认值，不必等保存。
   */
  supplierTaxPercent?: number;
  /** 当前选中的供应商编号：取价要用（价目表按供应商匹配） */
  supplierId?: number;
}

const props = withDefaults(defineProps<Props>(), {
  items: () => [],
  disabled: false,
  discountPercent: 0,
});

const emit = defineEmits([
  'update:items',
  'update:discountPrice',
  'update:totalPrice',
]);

const tableData = ref<ErpPurchaseOrderApi.PurchaseOrderItem[]>([]); // 表格数据
const productOptions = ref<ErpProductApi.Product[]>([]); // 物料下拉选项

/** 获取表格合计数据 */
const summaries = computed(() => {
  return {
    count: tableData.value.reduce((sum, item) => sum + (item.count || 0), 0),
    totalProductPrice: tableData.value.reduce(
      (sum, item) => sum + (item.totalProductPrice || 0),
      0,
    ),
    taxPrice: tableData.value.reduce(
      (sum, item) => sum + (item.taxPrice || 0),
      0,
    ),
    totalPrice: tableData.value.reduce(
      (sum, item) => sum + (item.totalPrice || 0),
      0,
    ),
  };
});

/** 表格配置 */
const [Grid, gridApi] = useVbenVxeGrid({
  gridOptions: {
    columns: useFormItemColumns(props.disabled),
    data: tableData.value,
    minHeight: 250,
    autoResize: true,
    border: true,
    rowConfig: {
      keyField: 'seq',
      isHover: true,
    },
    pagerConfig: {
      enabled: false,
    },
    toolbarConfig: {
      enabled: false,
    },
  },
});

/** 监听外部传入的列数据 */
watch(
  () => props.items,
  async (items) => {
    if (!items) {
      return;
    }
    items.forEach((item) => initRow(item));
    tableData.value = [...items];
    await nextTick(); // 特殊：保证 gridApi 已经初始化
    await gridApi.grid.reloadData(tableData.value);
  },
  {
    immediate: true,
  },
);

/** 计算 discountPrice、totalPrice 价格 */
watch(
  () => [tableData.value, props.discountPercent],
  () => {
    if (!tableData.value || tableData.value.length === 0) {
      return;
    }
    const totalPrice = tableData.value.reduce(
      (prev, curr) => prev + (curr.totalPrice || 0),
      0,
    );
    const discountPrice =
      props.discountPercent === null
        ? 0
        : erpPriceMultiply(totalPrice, props.discountPercent / 100);
    const finalTotalPrice = totalPrice - discountPrice!;
    // 通知父组件更新
    emit('update:discountPrice', discountPrice);
    emit('update:totalPrice', finalTotalPrice);
  },
  { deep: true },
);

/** 处理新增 */
function handleAdd() {
  const newRow = {
    id: undefined,
    productId: undefined,
    productUnitName: undefined, // 物料单位
    productBarCode: undefined, // 物料条码
    productPrice: undefined,
    stockCount: undefined,
    count: 1,
    totalProductPrice: undefined,
    // 默认带出供应商的开票税点；未选供应商时为 undefined，由后端兜底
    taxPercent: props.supplierTaxPercent,
    taxPrice: undefined,
    totalPrice: undefined,
    remark: undefined,
  };
  tableData.value.push(newRow);
  // 通知父组件更新
  emit('update:items', [...tableData.value]);
}

/** 处理删除 */
function handleDelete(row: ErpPurchaseOrderApi.PurchaseOrderItem) {
  // TODO 亚特
  const index = tableData.value.findIndex((item) => item.seq === row.seq);
  if (index !== -1) {
    tableData.value.splice(index, 1);
  }
  // 通知父组件更新
  emit('update:items', [...tableData.value]);
}

/** 处理物料变更 */
async function handleProductChange(productId: any, row: any) {
  const product = productOptions.value.find((p) => p.id === productId);
  if (!product) {
    return;
  }
  row.productId = productId;
  row.productUnitId = product.unitId;
  row.productBarCode = product.barCode;
  row.productUnitName = product.unitName;
  row.productName = product.name;
  row.stockCount = (await getStockCount(productId)) || 0;
  row.count = row.count || 1;
  // 取价：采购价目表优先（按 供应商 + 物料 + 数量 匹配），没命中时后端兜底到物料主数据的采购价。
  // 用户之后仍可手工改这个单价（允许按单覆盖）。
  row.productPrice = product.purchasePrice || 0;
  try {
    // 注意：不再传数量 —— 价目表已去掉数量区间（阶梯价），见 sql/local/68 的说明
    const match = await matchPurchasePrice({
      supplierId: props.supplierId,
      productId,
    });
    if (match?.price !== null && match?.price !== undefined) {
      row.productPrice = match.price;
      if (match.taxPercent !== null && match.taxPercent !== undefined) {
        row.taxPercent = match.taxPercent;
      }
    }
  } catch {
    // 取价失败不阻断录入：保留物料主数据的采购价
  }
  handleRowChange(row);
}

/** 处理行数据变更 */
function handleRowChange(row: any) {
  const index = tableData.value.findIndex((item) => item.seq === row.seq);
  if (index === -1) {
    tableData.value.push(row);
  } else {
    tableData.value[index] = row;
  }
  emit('update:items', [...tableData.value]);
}

/** 初始化行数据 */
function initRow(row: ErpPurchaseOrderApi.PurchaseOrderItem) {
  if (row.productPrice && row.count) {
    row.totalProductPrice = erpPriceMultiply(row.productPrice, row.count) ?? 0;
    row.taxPrice =
      erpPriceMultiply(row.totalProductPrice, (row.taxPercent || 0) / 100) ?? 0;
    row.totalPrice = row.totalProductPrice + row.taxPrice;
  }
}

/** 表单校验 */
function validate() {
  for (let i = 0; i < tableData.value.length; i++) {
    const item = tableData.value[i];
    if (item) {
      if (!item.productId) {
        throw new Error(`第 ${i + 1} 行：物料不能为空`);
      }
      if (!item.count || item.count <= 0) {
        throw new Error(`第 ${i + 1} 行：物料数量不能为空`);
      }
      if (!item.productPrice || item.productPrice <= 0) {
        throw new Error(`第 ${i + 1} 行：物料单价不能为空`);
      }
    }
  }
}

defineExpose({
  validate,
});

/** 初始化 */
onMounted(async () => {
  productOptions.value = await getProductSimpleList();
  // 目的：新增时，默认添加一行
  if (tableData.value.length === 0) {
    handleAdd();
  }
});
</script>

<template>
  <Grid class="w-full">
    <template #productId="{ row }">
      <Select
        v-model:value="row.productId"
        :options="productOptions"
        :field-names="{ label: 'name', value: 'id' }"
        class="w-full"
        placeholder="请选择物料"
        show-search
        @change="handleProductChange($event, row)"
      />
    </template>
    <template #count="{ row }">
      <InputNumber
        v-if="!disabled"
        v-model:value="row.count"
        :min="0"
        :precision="3"
        @change="handleRowChange(row)"
      />
      <span v-else>{{ erpCountInputFormatter(row.count) || '-' }}</span>
    </template>
    <template #productPrice="{ row }">
      <InputNumber
        v-if="!disabled"
        v-model:value="row.productPrice"
        :min="0"
        :precision="2"
        @change="handleRowChange(row)"
      />
      <span v-else>{{ erpPriceInputFormatter(row.productPrice) || '-' }}</span>
    </template>
    <template #remark="{ row }">
      <Input v-if="!disabled" v-model:value="row.remark" class="w-full" />
      <span v-else>{{ row.remark || '-' }}</span>
    </template>
    <template #taxPercent="{ row }">
      <InputNumber
        v-if="!disabled"
        v-model:value="row.taxPercent"
        :min="0"
        :max="100"
        :precision="2"
        @change="handleRowChange(row)"
      />
      <span v-else>{{ row.taxPercent || '-' }}</span>
    </template>
    <template #actions="{ row }">
      <TableAction
        :actions="[
          {
            label: '删除',
            type: 'link',
            danger: true,
            popConfirm: {
              title: '确认删除该物料吗？',
              confirm: handleDelete.bind(null, row),
            },
          },
        ]"
      />
    </template>

    <template #bottom>
      <div class="mt-2 rounded border border-border bg-muted p-2">
        <div class="flex justify-between text-sm text-muted-foreground">
          <span class="font-medium text-foreground">合计：</span>
          <div class="flex space-x-4">
            <span>数量：{{ erpCountInputFormatter(summaries.count) }}</span>
            <span>
              金额：{{ erpPriceInputFormatter(summaries.totalProductPrice) }}
            </span>
            <span>税额：{{ erpPriceInputFormatter(summaries.taxPrice) }}</span>
            <span>
              税额合计：{{ erpPriceInputFormatter(summaries.totalPrice) }}
            </span>
          </div>
        </div>
      </div>
      <TableAction
        v-if="!disabled"
        class="mt-2 flex justify-center"
        :actions="[
          {
            label: '添加采购物料',
            type: 'default',
            onClick: handleAdd,
          },
        ]"
      />
    </template>
  </Grid>
</template>
