<script setup lang="ts">
  import { showSuccessToast, showToast } from 'vant';
  import { updatePasswordByOld } from '@/api/auth';
  import { confirmDialog } from '@/utils/confirm';
  import {
    PASSWORD_MAX_LENGTH,
    PASSWORD_MIN_LENGTH,
    validatePasswordChange,
  } from '@/utils/password';

  defineOptions({ name: 'UserPassword' });

  const router = useRouter();

  const form = reactive({
    oldPassword: '',
    newPassword: '',
    confirmPassword: '',
  });

  /* -------------------------------- 提交修改 -------------------------------- */
  async function onSubmit(): Promise<void> {
    const error = validatePasswordChange(form);
    if (error) {
      showToast(error);
      return;
    }

    if (!(await confirmDialog('确认修改密码？'))) return;

    try {
      // 原密码错误时后端返回 1004001006，提示由 axios 响应拦截器统一展示
      await updatePasswordByOld({
        oldPassword: form.oldPassword,
        newPassword: form.newPassword,
      });
    } catch {
      return;
    }

    // 后端不会踢掉当前 token：改密成功后无需重新登录，直接返回上一页
    showSuccessToast('密码已修改');
    if (window.history.length > 1) {
      router.back();
    } else {
      void router.replace('/user');
    }
  }

  /** 防重复提交 */
  const { loading, run } = useSubmit(onSubmit);
</script>

<template>
  <div class="app-page password">
    <AppNavBar title="修改密码" />

    <van-form class="password__form" @submit="run">
      <van-cell-group inset>
        <van-field
          v-model="form.oldPassword"
          name="oldPassword"
          type="password"
          label="原密码"
          placeholder="请输入原密码"
          clearable
        />

        <van-field
          v-model="form.newPassword"
          name="newPassword"
          type="password"
          label="新密码"
          :placeholder="`请输入新密码（${PASSWORD_MIN_LENGTH}-${PASSWORD_MAX_LENGTH} 位）`"
          :maxlength="PASSWORD_MAX_LENGTH"
          clearable
        />

        <van-field
          v-model="form.confirmPassword"
          name="confirmPassword"
          type="password"
          label="确认新密码"
          placeholder="请再次输入新密码"
          :maxlength="PASSWORD_MAX_LENGTH"
          clearable
        />
      </van-cell-group>

      <div class="password__tips">
        新密码长度 {{ PASSWORD_MIN_LENGTH }}-{{ PASSWORD_MAX_LENGTH }} 位，请牢记后妥善保管。
      </div>

      <div class="password__submit">
        <van-button block round type="primary" native-type="submit" :loading="loading">
          确认修改
        </van-button>
      </div>
    </van-form>
  </div>
</template>

<style scoped lang="scss">
  .password {
    background: #fff;

    &__form {
      margin-top: 8px;
    }

    &__tips {
      padding: 16px 24px 0;
      font-size: 12px;
      line-height: 1.6;
      color: var(--app-text-color-secondary);
    }

    &__submit {
      padding: 20px 16px 0;
    }
  }
</style>
