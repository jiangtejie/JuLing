<script lang="ts" setup>
import type { ErpProductApi } from '#/api/erp/product/product';
import type { ErpPurchasePriceApi } from '#/api/erp/purchase/price';

import { nextTick, onMounted, onUnmounted, ref, watch } from 'vue';

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

const rootRef = ref<HTMLElement>(); // 外层容器：用于监听宽度变化后让表格重新量宽
const tableData = ref<ErpPurchasePriceApi.Item[]>([]); // 表格数据
const productOptions = ref<ErpProductApi.Product[]>([]); // 物料下拉选项
let rowSeq = 0; // 行序号：vxe 的 rowConfig.keyField 需要每行唯一（新增行还没有 id）
let resizeObserver: ResizeObserver | undefined;
let lastWidth = 0;

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
  resizeObserver = new ResizeObserver((entries) => {
    const width = entries[0]?.contentRect.width ?? 0;
    if (width > 0 && Math.abs(width - lastWidth) > 1) {
      lastWidth = width;
      (gridApi.grid as any)?.recalculate?.();
    }
  });
  if (rootRef.value) {
    resizeObserver.observe(rootRef.value);
  }
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
    seq: ++rowSeq,
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

/** 选择物料后带出计价单位与规格（都取自物料，见 sql/local/65、67 的设计说明） */
async function handleProductChange(productId: number, row: ErpPurchasePriceApi.Item) {
  const product = productOptions.value.find((p) => p.id === productId);
  row.unitName = product?.unitName;
  row.spec = (product as any)?.standard;
  await notify();
}

/** 税率 → 百分数小数 */
function rateOf(row: ErpPurchasePriceApi.Item) {
  return Number(row.taxPercent ?? 0) / 100;
}

/** 改不含税单价 → 重算含税单价 */
async function handlePriceChange(row: ErpPurchasePriceApi.Item) {
  row.taxPrice = row.price === undefined || row.price === null
    ? undefined
    : Number((row.price * (1 + rateOf(row))).toFixed(6));
  await notify();
}

/** 改含税单价 → 反算不含税单价（后端只存不含税） */
async function handleTaxPriceChange(row: ErpPurchasePriceApi.Item) {
  row.price = row.taxPrice === undefined || row.taxPrice === null
    ? undefined
    : Number((row.taxPrice / (1 + rateOf(row))).toFixed(6));
  await notify();
}

/** 改税率 → 按不含税单价重算含税单价 */
async function handleTaxPercentChange(row: ErpPurchasePriceApi.Item) {
  if (row.price !== undefined && row.price !== null) {
    row.taxPrice = Number((row.price * (1 + rateOf(row))).toFixed(6));
  }
  await notify();
}

onUnmounted(() => {
  resizeObserver?.disconnect();
});

defineExpose({ handleAdd });
</script>

<template>
  <!-- 外层容器固定 w-full 并监听它自己的宽度变化：
       vxe 在弹窗展开动画期间量到的容器宽度会偏窄（表格被压到实际宽度的一半左右），
       而它自己的元素宽度没变、autoResize 就不会触发，所以这里主动 recalculate 一次 -->
  <div ref="rootRef" class="w-full">
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
        @change="handlePriceChange(row)"
      />
    </template>
    <template #taxPrice="{ row }">
      <InputNumber
        v-model:value="row.taxPrice"
        :disabled="disabled"
        :min="0"
        :precision="6"
        placeholder="含税单价"
        style="width: 100%"
        @change="handleTaxPriceChange(row)"
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
        @change="handleTaxPercentChange(row)"
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
  </div>
</template>
