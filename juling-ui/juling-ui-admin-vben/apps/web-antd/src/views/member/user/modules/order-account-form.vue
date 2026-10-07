<script lang="ts" setup>
import type { VbenFormApi } from '#/adapter/form';
import type { MemberUserApi } from '#/api/member/user';

import type { OrderAccountCustomer, OrderAccountFormValues } from '../data';

import { ref } from 'vue';

import { useVbenModal } from '@vben/common-ui';

import { message } from 'ant-design-vue';

import { useVbenForm } from '#/adapter/form';
import { getCustomerSimpleList } from '#/api/erp/sale/customer';
import { createUser } from '#/api/member/user';

import { suggestOrderPassword, useOrderAccountFormSchema } from '../data';

defineOptions({ name: 'MemberOrderAccountForm' });

const emit = defineEmits(['success']);

/** 上一次自动生成的建议密码：管理员手动改过密码后就不再覆盖 */
const lastSuggestedPassword = ref('');

/** 授权门店下拉数据源（simple-list 已透出 id/name/storeType） */
async function fetchCustomerList() {
  return ((await getCustomerSimpleList()) ?? []) as OrderAccountCustomer[];
}

/** 账号名 / 手机号变化后刷新默认建议密码（管理员自己改过就不覆盖） */
function handlePasswordSourceChange(
  values: Partial<OrderAccountFormValues>,
  form: VbenFormApi,
) {
  const suggested = suggestOrderPassword(values.mobile, values.username);
  const current = values.password ?? '';
  if (current && current !== lastSuggestedPassword.value) {
    return;
  }
  lastSuggestedPassword.value = suggested;
  void form.setFieldValue('password', suggested);
}

const [Form, formApi] = useVbenForm({
  commonConfig: {
    componentProps: {
      class: 'w-full',
    },
    labelWidth: 90,
  },
  layout: 'horizontal',
  schema: useOrderAccountFormSchema({
    getCustomerList: fetchCustomerList,
    onPasswordSourceChange: handlePasswordSourceChange,
  }),
  showDefaultActions: false,
  wrapperClass: 'grid-cols-2',
});

/** 过滤空值：后端按「不传」取默认（status 默认开启、nickname 默认取账号名） */
function buildPayload(
  values: OrderAccountFormValues,
): MemberUserApi.UserCreateReqVO {
  const payload: Record<string, any> = {};
  Object.entries(values).forEach(([key, value]) => {
    if (value === undefined || value === null || value === '') {
      return;
    }
    payload[key] = value;
  });
  return payload as MemberUserApi.UserCreateReqVO;
}

const [Modal, modalApi] = useVbenModal({
  async onConfirm() {
    const { valid } = await formApi.validate();
    if (!valid) {
      return;
    }
    modalApi.lock();
    try {
      const values = (await formApi.getValues()) as OrderAccountFormValues;
      await createUser(buildPayload(values));
      await modalApi.close();
      emit('success');
      // 密码只在这里出现一次，提示管理员转告订货人
      message.success('账号已创建，请把账号和密码告知订货人');
    } finally {
      modalApi.unlock();
    }
  },
  onOpenChange() {
    lastSuggestedPassword.value = '';
  },
});
</script>

<template>
  <Modal title="开订货账号" class="w-1/2">
    <Form class="mx-4" />
    <div class="text-muted-foreground mx-4 mt-2 text-[13px]">
      订货账号就是订货人登录用的账号名（填订货人名字，如「张三」）；「授权门店」决定这个账号能给哪些门店下单——
      一家门店＝加盟店自己的账号，多家＝片区订货管理人（登录后可在 H5 切换下单门店）；
      创建后请把「账号 + 初始密码」告知订货人。
    </div>
  </Modal>
</template>
