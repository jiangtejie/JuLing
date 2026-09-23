<script setup lang="ts">
  import { showSuccessToast, showToast } from 'vant';
  import { sendSmsCode } from '@/api/auth';
  import { useUserStore } from '@/stores/user';
  import { isMobile } from '@/utils/is';

  defineOptions({ name: 'Login' });

  const route = useRoute();
  const router = useRouter();
  const userStore = useUserStore();

  /** 登录方式：password 账号密码 / sms 短信验证码 */
  const mode = ref<'password' | 'sms'>('password');

  const form = reactive({
    mobile: '',
    password: '',
    code: '',
  });

  const agreed = ref(true);

  /* ---------------------------- 短信验证码倒计时 ---------------------------- */
  const SEND_INTERVAL = 60;
  const countdown = ref(0);
  let countdownTimer: ReturnType<typeof setInterval> | undefined;

  onUnmounted(() => {
    if (countdownTimer) clearInterval(countdownTimer);
  });

  const smsButtonText = computed(() =>
    countdown.value > 0 ? `${countdown.value}s 后重发` : '获取验证码',
  );

  async function onSendSms(): Promise<void> {
    if (countdown.value > 0) return;
    if (!isMobile(form.mobile)) {
      showToast('请输入正确的手机号');
      return;
    }
    try {
      await sendSmsCode(form.mobile);
    } catch {
      // 失败提示已由 axios 响应拦截器统一处理
      return;
    }
    showSuccessToast('验证码已发送');
    countdown.value = SEND_INTERVAL;
    countdownTimer = setInterval(() => {
      countdown.value -= 1;
      if (countdown.value <= 0 && countdownTimer) {
        clearInterval(countdownTimer);
        countdownTimer = undefined;
      }
    }, 1000);
  }

  /* -------------------------------- 提交登录 -------------------------------- */
  async function onSubmit(): Promise<void> {
    if (!isMobile(form.mobile)) {
      showToast('请输入正确的手机号');
      return;
    }
    if (mode.value === 'password' && !form.password) {
      showToast('请输入登录密码');
      return;
    }
    if (mode.value === 'sms' && !form.code) {
      showToast('请输入短信验证码');
      return;
    }
    if (!agreed.value) {
      showToast('请先阅读并同意《用户服务协议》');
      return;
    }

    try {
      if (mode.value === 'password') {
        await userStore.login({ mobile: form.mobile, password: form.password });
      } else {
        await userStore.loginBySms({ mobile: form.mobile, code: form.code });
      }
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

    <!-- 登录方式切换 -->
    <van-tabs v-model:active="mode" class="login__tabs" shrink line-width="28">
      <van-tab title="密码登录" name="password" />
      <van-tab title="短信登录" name="sms" />
    </van-tabs>

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
        />

        <van-field
          v-if="mode === 'password'"
          v-model="form.password"
          name="password"
          type="password"
          label="登录密码"
          placeholder="请输入登录密码"
          clearable
        />

        <van-field
          v-else
          v-model="form.code"
          name="code"
          type="digit"
          label="验证码"
          placeholder="请输入短信验证码"
          maxlength="6"
        >
          <template #button>
            <van-button
              size="small"
              type="primary"
              plain
              :disabled="countdown > 0"
              @click="onSendSms"
            >
              {{ smsButtonText }}
            </van-button>
          </template>
        </van-field>
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

    &__tabs {
      --van-tabs-line-height: 40px;
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
