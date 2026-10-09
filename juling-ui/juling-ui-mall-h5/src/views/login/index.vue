<script setup lang="ts">
  import { showDialog, showSuccessToast, showToast } from 'vant';
  import { useUserStore } from '@/stores/user';
  import { isAccount } from '@/utils/is';

  defineOptions({ name: 'Login' });

  const route = useRoute();
  const router = useRouter();
  const userStore = useUserStore();

  /**
   * 私域订货登录：只有「订货账号 + 密码」一种方式。
   * 短信渠道未配置，短信登录 tab、验证码输入框与倒计时逻辑已整体移除。
   */
  const form = reactive({
    account: '',
    password: '',
  });

  // 默认不勾选：协议需由用户主动确认（合规要求）
  const agreed = ref(false);

  /**
   * 查看协议正文。
   * 正式的协议页面尚未接入（待法务提供文本），先用弹窗给出要点说明，
   * 避免「点了没反应」——接入协议页后把这里替换为路由跳转即可。
   */
  function showAgreement(type: 'service' | 'privacy'): void {
    const isService = type === 'service';
    showDialog({
      title: isService ? '用户服务协议' : '隐私政策',
      message: isService
        ? '本协议说明亚特订货商城提供的服务范围、账号使用规则与订单履约方式。\n正式文本以平台发布版本为准。'
        : '我们仅收集完成订货与配送所必需的信息（订货账号、收货人姓名、联系电话、收货地址），不用于其它用途。\n正式文本以平台发布版本为准。',
    });
  }

  /* -------------------------------- 提交登录 -------------------------------- */
  async function onSubmit(): Promise<void> {
    // 账号名是订货人姓名（中文 / 字母），只校验长度，不做手机号格式校验
    const account = form.account.trim();
    if (!account) {
      showToast('请输入订货账号');
      return;
    }
    if (!isAccount(account)) {
      showToast('订货账号长度为 2-64 位');
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
      await userStore.login({ account, password: form.password });
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
      <div class="login__logo">亚</div>
      <div class="login__title">亚特订货商城</div>
      <div class="login__subtitle">企业专属订货价 · 登录后可见</div>
    </div>

    <van-form class="login__form" @submit="run">
      <van-cell-group inset>
        <van-field
          v-model="form.account"
          name="account"
          type="text"
          label="订货账号"
          placeholder="请输入订货账号"
          maxlength="64"
          clearable
        />

        <van-field
          v-model="form.password"
          name="password"
          type="password"
          label="登录密码"
          placeholder="请输入登录密码"
          clearable
        />
      </van-cell-group>

      <div class="login__tips">
        请使用总部下发的<b>订货账号</b>登录（就是订货人姓名，如「张三」）；忘记密码请联系总部管理员。
      </div>

      <div class="login__agree">
        <van-checkbox v-model="agreed" icon-size="14px" shape="square">
          我已阅读并同意
          <span class="login__link" @click.stop="showAgreement('service')"> 《用户服务协议》 </span>
          与
          <span class="login__link" @click.stop="showAgreement('privacy')">《隐私政策》</span>
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
      background: var(--app-primary-gradient);
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

    /** 登录方式说明：账号由总部下发，不提供短信登录 */
    &__tips {
      padding: 16px 24px 0;
      font-size: 12px;
      line-height: 1.6;
      color: var(--app-text-color-secondary);
    }

    &__agree {
      padding: 16px 24px 0;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__link {
      color: var(--app-primary-color);
    }

    &__submit {
      padding: 20px 16px 0;
    }
  }
</style>
