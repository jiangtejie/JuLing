<script lang="ts" setup>
import { ref } from 'vue';

import { useVbenModal } from '@vben/common-ui';
import { DICT_TYPE } from '@vben/constants';
import { getDictOptions } from '@vben/hooks';

import { message } from 'ant-design-vue';

import { useVbenForm } from '#/adapter/form';
import { createStore } from '#/api/erp/store';
import { $t } from '#/locales';

const emit = defineEmits(['success']);
const parentName = ref('');

const [Form, formApi] = useVbenForm({
  commonConfig: { componentProps: { class: 'w-full' }, labelWidth: 100 },
  wrapperClass: 'grid-cols-2',
  layout: 'vertical',
  schema: [
    {
      fieldName: 'name',
      label: '门店名称',
      component: 'Input',
      rules: 'required',
      formItemClass: 'col-span-2',
      componentProps: { placeholder: '如：萍姐鸡煲香水门店' },
    },
    {
      fieldName: 'storeType',
      label: '店型',
      component: 'Select',
      rules: 'selectRequired',
      componentProps: {
        placeholder: '请选择店型',
        options: getDictOptions(DICT_TYPE.ERP_STORE_TYPE),
      },
    },
    {
      fieldName: 'settlementMode',
      label: '结算方式',
      component: 'Select',
      componentProps: {
        placeholder: '请选择结算方式',
        allowClear: true,
        options: getDictOptions(DICT_TYPE.TRADE_SETTLEMENT_MODE),
      },
    },
    {
      fieldName: 'creditDays',
      label: '账期天数',
      component: 'InputNumber',
      componentProps: { placeholder: '如 30', min: 0, class: '!w-full' },
    },
    {
      fieldName: 'creditLimit',
      label: '授信额度',
      component: 'InputNumber',
      componentProps: { placeholder: '如 10000', min: 0, precision: 2, class: '!w-full' },
    },
    {
      fieldName: 'contact',
      label: '联系人',
      component: 'Input',
      componentProps: { placeholder: '请输入联系人', allowClear: true },
    },
    {
      fieldName: 'mobile',
      label: '联系手机',
      component: 'Input',
      componentProps: { placeholder: '请输入手机号', allowClear: true },
    },
  ],
  showDefaultActions: false,
});

const [Modal, modalApi] = useVbenModal({
  async onConfirm() {
    const { valid } = await formApi.validate();
    if (!valid) {
      return;
    }
    modalApi.lock();
    try {
      const data = await formApi.getValues();
      await createStore(data as any);
      await modalApi.close();
      emit('success');
      message.success($t('ui.actionMessage.operationSuccess'));
    } finally {
      modalApi.unlock();
    }
  },
  async onOpenChange(isOpen: boolean) {
    if (!isOpen) {
      return;
    }
    const data = modalApi.getData() as { parentId?: number; parentName?: string };
    parentName.value = data.parentName ?? '';
    await formApi.setValues({ parentId: data.parentId });
  },
});
</script>

<template>
  <Modal title="新建门店" class="w-2/3">
    <div class="mx-3 mb-2 rounded bg-blue-50 p-2 text-sm text-gray-600">
      将建在组织节点「<span class="font-medium">{{ parentName }}</span>」下，
      并**同时**建立对应的客户档案 —— 两者强制一对一，所以必须一次建完。
      门店应直接挂在品牌或公司节点下，不要再建中间分组层。
    </div>
    <Form class="mx-3" />
  </Modal>
</template>
