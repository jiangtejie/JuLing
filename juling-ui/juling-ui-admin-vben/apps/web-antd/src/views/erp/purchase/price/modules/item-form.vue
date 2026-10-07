<script lang="ts" setup>
import type { ErpProductApi } from '#/api/erp/product/product';
import type { ErpPurchasePriceApi } from '#/api/erp/purchase/price';

import { nextTick, onMounted, ref, watch } from 'vue';

import { Button, Input, InputNumber, Select } from 'ant-design-vue';

import { TableAction, useVbenVxeGrid } from '#/adapter/vxe-table';
import { getProductSimpleList } from '#/api/erp/product/product';

import { useItemColumns } from '../data';

interface Props {
  items?: ErpPurchasePriceApi.Item[];
  disabled?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  items: () => [],
  disabled: false,
});

const emit = defineEmits(['update:items']);

const tableData = ref<ErpPurchasePriceApi.Item[]>([]); // 表格数据
const productOptions = ref<ErpProductApi.Product[]>([]); // 物料下拉选项

/** 物料下拉选项（带编码，便于区分同名物料） */
const productSelectOptions = ref<{ label: string; value: number }[]>([]);

/** 表格配置（写法对齐采购订单的明细表：data 传初始值，变更后 gridApi.grid.reloadData） */
const [Grid, gridApi] = useVbenVxeGrid({
  gridOptions: {
    columns: useItemColumns(),
    data: tableData.value,
    minHeight: 320,
    autoResize: true,
    border: true,
    rowConfig: { keyField: 'seq', isHover: true },
    pagerConfig: { enabled: false },
    toolbarConfig: { enabled: false },
  },
});

/** 监听外部传入的明细 */
watch(
  () => props.items,
  async (items) => {
    if (!items) {
      return;
    }
    tableData.value = [...items];
    await nextTick(); // 特殊：保证 gridApi 已经初始化
    await gridApi.grid.reloadData(tableData.value);
  },
  { immediate: true, deep: true },
);

onMounted(async () => {
  productOptions.value = (await getProductSimpleList()) as ErpProductApi.Product[];
  productSelectOptions.value = productOptions.value.map((p) => ({
    label: [p.code, p.name].filter(Boolean).join(' '),
    value: p.id!,
  }));
});

/** 通知父组件 + 刷新表格 */
async function notify() {
  emit('update:items', [...tableData.value]);
  await gridApi.grid.reloadData(tableData.value);
}

/** 新增一行 */
async function handleAdd() {
  tableData.value.push({
    productId: undefined,
    unitName: undefined,
    fromQty: undefined,
    toQty: undefined,
    price: undefined,
    taxPercent: undefined,
    remark: undefined,
  });
  await notify();
}

/** 删除一行 */
async function handleDelete(row: ErpPurchasePriceApi.Item) {
  const index = tableData.value.indexOf(row);
  if (index !== -1) {
    tableData.value.splice(index, 1);
  }
  await notify();
}

/** 选择物料后带出计价单位（单位由物料决定，见 sql/local/65 的设计说明） */
async function handleProductChange(productId: number, row: ErpPurchasePriceApi.Item) {
  const product = productOptions.value.find((p) => p.id === productId);
  row.unitName = product?.unitName;
  await notify();
}

defineExpose({ handleAdd });
</script>

<template>
  <Grid class="w-full">
    <template #productId="{ row }">
      <Select
        v-model:value="row.productId"
        :disabled="disabled"
        :options="productSelectOptions"
        option-filter-prop="label"
        placeholder="请选择物料"
        show-search
        style="width: 100%"
        @change="(val: any) => handleProductChange(val, row)"
      />
    </template>
    <template #fromQty="{ row }">
      <InputNumber
        v-model:value="row.fromQty"
        :disabled="disabled"
        :min="0"
        placeholder="不限"
        style="width: 100%"
        @change="notify"
      />
    </template>
    <template #toQty="{ row }">
      <InputNumber
        v-model:value="row.toQty"
        :disabled="disabled"
        :min="0"
        placeholder="不限"
        style="width: 100%"
        @change="notify"
      />
    </template>
    <template #price="{ row }">
      <InputNumber
        v-model:value="row.price"
        :disabled="disabled"
        :min="0"
        :precision="6"
        placeholder="不含税单价"
        style="width: 100%"
        @change="notify"
      />
    </template>
    <template #taxPercent="{ row }">
      <InputNumber
        v-model:value="row.taxPercent"
        :disabled="disabled"
        :max="100"
        :min="0"
        :precision="2"
        placeholder="如 13"
        style="width: 100%"
        @change="notify"
      />
    </template>
    <template #remark="{ row }">
      <Input
        v-model:value="row.remark"
        :disabled="disabled"
        placeholder="备注"
        @blur="notify"
      />
    </template>
    <template #actions="{ row }">
      <Button v-if="!disabled" danger size="small" type="link" @click="handleDelete(row)">
        删除
      </Button>
    </template>
    <!-- 注意：必须放进 vxe 的 #bottom 插槽，直接写在 Grid 里会落到默认插槽而不渲染
         （写法对齐采购订单的明细表） -->
    <template #bottom>
      <TableAction
        v-if="!disabled"
        class="mt-2 flex justify-center"
        :actions="[
          {
            label: '添加明细行',
            type: 'default',
            onClick: handleAdd,
          },
        ]"
      />
    </template>
  </Grid>
</template>
