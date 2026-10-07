<script lang="ts" setup>
import type { ErpPurchasePriceApi } from '#/api/erp/price-list';

import { computed, ref } from 'vue';

import { useVbenModal } from '@vben/common-ui';

import { message } from 'ant-design-vue';

import { useVbenForm } from '#/adapter/form';
import {
  createPurchasePrice,
  getPurchasePrice,
  updatePurchasePrice,
} from '#/api/erp/price-list';
import { $t } from '#/locales';

import { useFormSchema } from '../data';
import PriceItemForm from './item-form.vue';

type FormType = 'create' | 'detail' | 'edit';
type PriceType = 'DELIVERY' | 'PURCHASE';

const props = withDefaults(defineProps<{ priceType?: PriceType }>(), {
  priceType: 'PURCHASE',
});

const emit = defineEmits(['success']);
const formData = ref<ErpPurchasePriceApi.Price>();
const formType = ref<FormType>('create');

const getTitle = computed(() => {
  if (formType.value === 'create') {
    return $t('ui.actionTitle.create', ['采购价目表']);
  }
  if (formType.value === 'edit') {
    return $t('ui.actionTitle.edit', ['采购价目表']);
  }
  return '采购价目表详情';
});

const [Form, formApi] = useVbenForm({
  commonConfig: {
    componentProps: { class: 'w-full' },
    labelWidth: 120,
  },
  wrapperClass: 'grid-cols-2',
  // 与采购订单等 ERP 表单保持一致用 vertical：
  // horizontal 下「默认价目表」这类较长的 label 会换行，且明细表会被 label 挤到右侧错位
  layout: 'vertical',
  schema: useFormSchema('create', props.priceType),
  showDefaultActions: false,
});

const [Modal, modalApi] = useVbenModal({
  async onConfirm() {
    const { valid } = await formApi.validate();
    if (!valid) {
      return;
    }
    const items = formData.value?.items ?? [];
    if (items.length === 0) {
      message.error('请至少添加一行价目表明细');
      return;
    }
    modalApi.lock();
    const data = (await formApi.getValues()) as ErpPurchasePriceApi.Price;
    data.priceType = props.priceType;
    data.items = items;
    // 适用范围：界面是「多选对象 + 一个默认开关」，落库拆成 N 行（数据库支持逐行默认，后续可细化）
    data.scopes = (data.scopePartnerIds ?? []).map((partnerId) => ({
      partnerId,
      isDefault: data.scopeIsDefault,
    }));
    if (data.scopes.length === 0) {
      data.scopes = [{ partnerId: undefined, isDefault: data.scopeIsDefault }];
    }
    try {
      await (formType.value === 'create'
        ? createPurchasePrice(data)
        : updatePurchasePrice(data));
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
    const data = modalApi.getData() as { formType: FormType; id?: number };
    formType.value = data.formType ?? 'create';
    formApi.setDisabled(formType.value === 'detail');
    formApi.updateSchema(useFormSchema(formType.value, props.priceType));
    if (!data || !data.id) {
      formData.value = { items: [] };
      await formApi.setValues({ status: 0, isDefault: false });
      return;
    }
    modalApi.lock();
    try {
      formData.value = await getPurchasePrice(data.id);
      await formApi.setValues({
        ...formData.value,
        scopePartnerIds: (formData.value.scopes ?? [])
          .map((s) => s.partnerId)
          .filter((id): id is number => id !== null && id !== undefined),
        scopeIsDefault: (formData.value.scopes ?? []).some((s) => s.isDefault),
      });
    } finally {
      modalApi.unlock();
    }
  },
});

/** 明细变更 */
function handleUpdateItems(items: ErpPurchasePriceApi.Item[]) {
  if (formData.value) {
    formData.value.items = items;
  }
}
</script>

<template>
  <Modal
    :title="getTitle"
    class="w-2/3"
    :show-confirm-button="formType !== 'detail'"
  >
    <Form class="mx-3">
      <template #items>
        <div class="w-full">
          <PriceItemForm
            :items="formData?.items ?? []"
            :disabled="formType === 'detail'"
            @update:items="handleUpdateItems"
          />
        </div>
      </template>
    </Form>
  </Modal>
</template>
