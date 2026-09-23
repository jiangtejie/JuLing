<script setup lang="ts">
  import { showSuccessToast, showToast } from 'vant';
  import { useUserStore } from '@/stores/user';
  import { isMobile } from '@/utils/is';

  defineOptions({ name: 'Login' });

  const route = useRoute();
  const router = useRouter();
  const userStore = useUserStore();

  const form = reactive({
    mobile: '',
    password: '',
  });

  const agreed = ref(true);

  async function onSubmit(): Promise<void> {
    if (!isMobile(form.mobile)) {
      showToast('请输入正确的手机号');
      return;
    }
    if (!form.password) {
      showToast('请输入登录密码');
      return;
    }
    if (!agreed.value) {
      showToast('请先阅读并同意《用户服务协议》');
      return;
    }

    try {
      await userStore.login({ mobile: form.mobile, password: form.password });
    } catch {
      // 错误提示已由 axios 响应拦截器统一处理
      return;
    }

    showSuccessToast('登录成功');
    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/home';
    await router.replace(redirect);
  }

  /** 防重复提交 */
  const { loading, run } = useSubmit(onSubmit);
</script>

<template>
  <div class="app-page login">
    <AppNavBar title="登录" />

    <div class="login__brand">
      <div class="login__logo">矩</div>
      <div class="login__title">矩灵订货商城</div>
      <div class="login__subtitle">企业专属订货价 · 阶梯价更优惠</div>
    </div>

    <van-form class="login__form" @submit="run">
      <van-cell-group inset>
        <van-field
          v-model="form.mobile"
          name="mobile"
          type="tel"
          label="手机号"
          placeholder="请输入手机号"
          maxlength="11"
          clearable
          :rules="[{ required: true, message: '请输入手机号' }]"
        />
        <van-field
          v-model="form.password"
          name="password"
          type="password"
          label="登录密码"
          placeholder="请输入登录密码"
          clearable
          :rules="[{ required: true, message: '请输入密码' }]"
        />
      </van-cell-group>

      <div class="login__tips">
        <van-checkbox v-model="agreed" icon-size="14px" shape="square">
          我已阅读并同意《用户服务协议》与《隐私政策》
        </van-checkbox>
      </div>

      <div class="login__submit">
        <van-button block round type="primary" native-type="submit" :loading="loading">
          登录
        </van-button>
      </div>
    </van-form>
  </div>
</template>

<style scoped lang="scss">
  .login {
    background: #fff;

    &__brand {
      padding: 32px 0 24px;
      text-align: center;
    }

    &__logo {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 64px;
      height: 64px;
      font-size: 30px;
      font-weight: 700;
      color: #fff;
      background: linear-gradient(135deg, #0081ff, #41b0ff);
      border-radius: 16px;
    }

    &__title {
      margin-top: 12px;
      font-size: 20px;
      font-weight: 600;
    }

    &__subtitle {
      margin-top: 6px;
      font-size: 13px;
      color: var(--app-text-color-secondary);
    }

    &__form {
      margin-top: 8px;
    }

    &__tips {
      padding: 16px 24px 0;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

      &__submit {
        padding: 20px 16px 0;
      }
    }
</style>
