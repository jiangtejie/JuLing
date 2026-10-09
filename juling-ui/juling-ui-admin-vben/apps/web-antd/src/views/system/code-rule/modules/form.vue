<script lang="ts" setup>
import type { SystemCodeRuleApi } from '#/api/system/code-rule';

import { computed, ref } from 'vue';

import { useVbenModal } from '@vben/common-ui';

import { message } from 'ant-design-vue';

import { useVbenForm } from '#/adapter/form';
import {
  createCodeRule,
  getCodeRule,
  updateCodeRule,
} from '#/api/system/code-rule';
import { $t } from '#/locales';

import { useFormSchema } from '../data';

const emit = defineEmits(['success']);
const formData = ref<SystemCodeRuleApi.CodeRule>();
const getTitle = computed(() => {
  return formData.value?.id
    ? $t('ui.actionTitle.edit', ['编码规则'])
    : $t('ui.actionTitle.create', ['编码规则']);
});

const [Form, formApi] = useVbenForm({
  commonConfig: {
    componentProps: {
      class: 'w-full',
    },
    formItemClass: 'col-span-2',
    labelWidth: 90,
  },
  layout: 'horizontal',
  schema: useFormSchema(),
  showDefaultActions: false,
});

const [Modal, modalApi] = useVbenModal({
  async onConfirm() {
    const { valid } = await formApi.validate();
    if (!valid) {
      return;
    }
    modalApi.lock();
    const data = (await formApi.getValues()) as SystemCodeRuleApi.CodeRule;
    try {
      await (formData.value?.id
        ? updateCodeRule(data)
        : createCodeRule(data));
      await modalApi.close();
      emit('success');
      message.success($t('ui.actionMessage.operationSuccess'));
    } finally {
      modalApi.unlock();
    }
  },
  async onOpenChange(isOpen: boolean) {
    if (!isOpen) {
      formData.value = undefined;
      return;
    }
    const data = modalApi.getData() as SystemCodeRuleApi.CodeRule;
    if (!data || !data.id) {
      return;
    }
    modalApi.lock();
    try {
      formData.value = await getCodeRule(data.id);
      await formApi.setValues(formData.value);
    } finally {
      modalApi.unlock();
    }
  },
});
</script>

<template>
  <Modal :title="getTitle" class="w-1/2">
    <Form class="mx-4" />
    <div class="text-muted-foreground mx-4 mt-2 text-[13px]">
      编码 = 前缀 + 流水左补零（如 KH + 000001）。主数据建档时按这里的配置自动发号；
      当前流水由系统维护，改小会让同一个编码被发出两次，请勿手改。
    </div>
  </Modal>
</template>
