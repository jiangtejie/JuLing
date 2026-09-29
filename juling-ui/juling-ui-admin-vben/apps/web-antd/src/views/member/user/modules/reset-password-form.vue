<script lang="ts" setup>
import type { MemberUserApi } from '#/api/member/user';

import { ref } from 'vue';

import { useVbenModal } from '@vben/common-ui';
import { useClipboard } from '@vueuse/core';

import { Button, message, Modal as AntModal } from 'ant-design-vue';

import { useVbenForm } from '#/adapter/form';
import { resetUserPassword } from '#/api/member/user';
import { $t } from '#/locales';

import { suggestOrderPassword, useResetPasswordFormSchema } from '../data';

defineOptions({ name: 'MemberResetPasswordForm' });

const emit = defineEmits(['success']);

/** 重置成功后的明文结果：管理员要转告门店，所以重置成功后先明文展示再关窗 */
const result = ref<null | { password: string; username: string }>(null);
/** 当前会员（取列表行数据，避免为了取账号名再多打一次接口） */
const user = ref<MemberUserApi.User>();

/** legacy: 兼容 http 环境下没有 navigator.clipboard 的情况 */
const { copy } = useClipboard({ legacy: true });

const [Form, formApi] = useVbenForm({
  commonConfig: {
    componentProps: {
      class: 'w-full',
    },
    formItemClass: 'col-span-2',
    labelWidth: 90,
  },
  layout: 'horizontal',
  schema: useResetPasswordFormSchema(),
  showDefaultActions: false,
});

/** 二次确认：重置会把该账号踢下线，避免误点 */
function confirmReset(username: string): Promise<boolean> {
  return new Promise((resolve) => {
    AntModal.confirm({
      title: '确认重置密码？',
      content: `重置后「${username}」会被强制下线，需要用新密码重新登录。`,
      okText: '确认重置',
      cancelText: $t('common.cancel'),
      onCancel: () => resolve(false),
      onOk: () => resolve(true),
    });
  });
}

/** 复制新密码（管理员要转告门店） */
async function handleCopyPassword() {
  if (!result.value) {
    return;
  }
  await copy(result.value.password);
  message.success('新密码已复制');
}

const [Modal, modalApi] = useVbenModal({
  async onConfirm() {
    // 已经重置成功：这一步只负责关窗，避免重复提交
    if (result.value) {
      await modalApi.close();
      return;
    }
    const { valid } = await formApi.validate();
    if (!valid) {
      return;
    }
    const values = await formApi.getValues();
    // 老会员可能还没有订货账号，退化成昵称，避免确认框里出现「空账号」
    const username = (values.username as string) || user.value?.nickname || '该账号';
    const ok = await confirmReset(username);
    if (!ok) {
      return;
    }
    modalApi.lock();
    try {
      await resetUserPassword({
        id: values.id as number,
        password: values.password as string,
      });
      result.value = {
        username,
        password: values.password as string,
      };
      // 明文结果已经展示，按钮改成「完成」
      modalApi.setState({
        cancelText: '关闭',
        confirmText: '完成',
        showCancelButton: false,
      });
      // 重置已经落库：先刷新列表，避免管理员用右上角关闭时列表还是旧数据
      emit('success');
      message.success('密码已重置，请把新密码告知门店');
    } finally {
      modalApi.unlock();
    }
  },
  async onOpenChange(isOpen: boolean) {
    if (!isOpen) {
      result.value = null;
      user.value = undefined;
      return;
    }
    result.value = null;
    modalApi.setState({
      cancelText: $t('common.cancel'),
      confirmText: $t('common.confirm'),
      showCancelButton: true,
    });
    const data = modalApi.getData() as MemberUserApi.User;
    if (!data?.id) {
      return;
    }
    user.value = data;
    // 预填默认建议密码：yt@ + 手机号后 6 位；没手机号取账号名后 6 位
    await formApi.setValues({
      id: data.id,
      nickname: data.nickname ?? data.name ?? '',
      password: suggestOrderPassword(data.mobile, data.username),
      username: data.username ?? '',
    });
  },
});
</script>

<template>
  <Modal :title="result ? '重置成功' : '重置订货账号密码'" class="w-1/2">
    <Form v-if="!result" class="mx-4" />
    <div v-else class="mx-4">
      <div class="mb-3 text-[13px]">
        订货账号 <span class="font-medium">{{ result.username }}</span> 的密码已重置，
        该账号已被强制下线，需要用新密码重新登录。
      </div>
      <div
        class="bg-muted mb-3 flex items-center justify-between rounded px-3 py-2"
      >
        <span>
          新密码：<span class="font-bold">{{ result.password }}</span>
        </span>
        <Button type="link" @click="handleCopyPassword">复制</Button>
      </div>
      <div class="text-muted-foreground text-[13px]">
        请把新密码告知门店（关闭本窗口后将不再显示明文密码）。
      </div>
    </div>
  </Modal>
</template>
