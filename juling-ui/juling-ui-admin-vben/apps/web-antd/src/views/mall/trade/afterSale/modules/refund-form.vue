<script setup lang="ts">
import type { MallAfterSaleApi } from '#/api/mall/trade/afterSale';

import { computed, ref } from 'vue';

import { useVbenModal } from '@vben/common-ui';
import { fenToYuan } from '@vben/utils';

import { Alert, message } from 'ant-design-vue';

import { useVbenForm } from '#/adapter/form';
import { refundAfterSale } from '#/api/mall/trade/afterSale';

import { useRefundFormSchema } from '../data';

/**
 * 确认退款 - 线下退款登记弹窗。
 *
 * 商城只走线下转账，没有线上退款单可发起：商家先在线下把钱退给客户，
 * 再在这里登记退款渠道、回执凭证与备注，登记即视为退款完成。
 */
const emit = defineEmits(['success']);
const afterSale = ref<MallAfterSaleApi.AfterSale>();

/** 退款金额（元） */
const refundPrice = computed(() =>
  fenToYuan(afterSale.value?.refundPrice ?? 0),
);

const [Form, formApi] = useVbenForm({
  commonConfig: {
    componentProps: {
      class: 'w-full',
    },
    formItemClass: 'col-span-2',
    labelWidth: 80,
  },
  layout: 'horizontal',
  schema: useRefundFormSchema(),
  showDefaultActions: false,
});

const [Modal, modalApi] = useVbenModal({
  async onConfirm() {
    const { valid } = await formApi.validate();
    if (!valid) {
      return;
    }
    if (!afterSale.value?.id) {
      return;
    }
    modalApi.lock();
    try {
      const values = await formApi.getValues();
      const proofUrls = values.refundProofUrls;
      // 提交登记：登记即视为退款完成，售后单由后端置为「已完成」
      await refundAfterSale({
        id: afterSale.value.id,
        refundChannelCode: values.refundChannelCode,
        refundProofUrls:
          Array.isArray(proofUrls) && proofUrls.length > 0
            ? proofUrls
            : undefined,
        refundRemark: values.refundRemark?.trim() || undefined,
      });
      await modalApi.close();
      emit('success');
      message.success('线下退款已登记，售后单已标记为已完成');
    } finally {
      modalApi.unlock();
    }
  },
  async onOpenChange(isOpen: boolean) {
    if (!isOpen) {
      afterSale.value = undefined;
      return;
    }
    // 加载数据
    const formData = modalApi.getData() as {
      afterSale: MallAfterSaleApi.AfterSale;
    };
    if (!formData?.afterSale?.id) {
      return;
    }
    afterSale.value = formData.afterSale;
    modalApi.lock();
    try {
      // 重置表单（退款渠道回到默认值，凭证与备注清空）
      await formApi.resetForm();
    } finally {
      modalApi.unlock();
    }
  },
});
</script>

<template>
  <Modal title="确认退款（线下退款登记）" class="w-2/5">
    <div class="mx-4">
      <Alert
        show-icon
        type="info"
        message="请先在线下把款项退还给买家，再在此登记退款信息。登记后售后单将直接标记为「已完成」。"
      />
      <div class="mt-4">
        退款金额：
        <span class="font-bold text-red-500">￥{{ refundPrice }}</span>
      </div>
    </div>
    <Form class="mx-4 mt-4" />
  </Modal>
</template>
