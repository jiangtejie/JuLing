<script lang="ts" setup>
import type { ErpStockBatchApi } from '#/api/erp/stock/batch';

import { computed, ref } from 'vue';

import { useVbenModal } from '@vben/common-ui';

import { message } from 'ant-design-vue';

import { useVbenForm } from '#/adapter/form';
import { updateStockBatchState } from '#/api/erp/stock/batch';
import { $t } from '#/locales';

import { useStateFormSchema } from '../data';

const emit = defineEmits(['success']);

/** 当前登记的批次行 */
const batch = ref<ErpStockBatchApi.StockBatch>();

const title = computed(() =>
  batch.value?.batchNo
    ? `批次状态登记 - ${batch.value.batchNo}`
    : '批次状态登记',
);

const [Form, formApi] = useVbenForm({
  commonConfig: {
    componentProps: {
      class: 'w-full',
    },
    labelWidth: 100,
  },
  layout: 'horizontal',
  schema: useStateFormSchema(),
  showDefaultActions: false,
  wrapperClass: 'grid-cols-1',
});

const [Modal, modalApi] = useVbenModal({
  async onConfirm() {
    const { valid } = await formApi.validate();
    if (!valid) {
      return;
    }
    modalApi.lock();
    try {
      const values = await formApi.getValues();
      await updateStockBatchState({
        warehouseId: batch.value!.warehouseId,
        productId: batch.value!.productId,
        batchNo: batch.value!.batchNo,
        state: values.state,
        delta: values.delta,
        remark: values.remark,
      });
      await modalApi.close();
      emit('success');
      message.success($t('ui.actionMessage.operationSuccess'));
    } finally {
      modalApi.unlock();
    }
  },
  async onOpenChange(isOpen: boolean) {
    if (!isOpen) {
      batch.value = undefined;
      return;
    }
    batch.value = modalApi.getData() as ErpStockBatchApi.StockBatch;
    await formApi.reset();
  },
});
</script>

<template>
  <Modal :title="title" class="w-1/2">
    <div class="text-foreground mb-4 grid grid-cols-3 gap-2 text-sm">
      <div>物料：{{ batch?.productName || '-' }}</div>
      <div>仓库：{{ batch?.warehouseName || '-' }}</div>
      <div>批次号：{{ batch?.batchNo || '-' }}</div>
    </div>
    <Form class="mx-4" />
  </Modal>
</template>
