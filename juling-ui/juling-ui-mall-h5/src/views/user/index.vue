<script setup lang="ts">
  import { showToast } from 'vant';
  import { getOrderCount, type OrderCountMap } from '@/api/order';
  import { ORDER_STATUS_MAP } from '@/constants';
  import { useUserStore } from '@/stores/user';
  import { confirmDialog } from '@/utils/confirm';
  import { maskMobile } from '@/utils/format';
  import { resolveImage } from '@/utils/image';

  defineOptions({ name: 'User' });

  const router = useRouter();
  const userStore = useUserStore();

  /**
   * 订单状态入口。
   * `countKey` 对应后端 `/trade/order/get-count` 的返回字段；
   * 「已完成」后端没有独立计数，置 null —— 不显示角标。
   */
  const statusEntries = [
    { key: 'UNPAID', icon: 'pending-payment', countKey: 'unpaidCount' },
    { key: 'PAID', icon: 'send-gift-o', countKey: 'undeliveredCount' },
    { key: 'SHIPPED', icon: 'logistics', countKey: 'deliveredCount' },
    { key: 'COMPLETED', icon: 'passed', countKey: null },
  ] as const;

  const orderCount = ref<OrderCountMap | null>(null);

  /** 某状态入口的角标数（未登录 / 无数据时为 0，配合 show-zero 不显示） */
  function countOf(entry: (typeof statusEntries)[number]): number {
    const key = entry.countKey;
    if (!key || !orderCount.value) return 0;
    return orderCount.value[key] ?? 0;
  }

  const menus = [
    // 「我的订货单」= 已提交的门店订货单，落点应是订单列表；
    // 原先指向 /cart（底部「订货单」tab 的购物车），文案与落点不符，这里改到 /order/list
    { label: '我的订货单', icon: 'i-carbon-receipt', to: '/order/list' },
    // 我的账：门店往来台账（只读），名下多门店时可按门店看逐笔明细
    { label: '我的账', icon: 'i-carbon-wallet', to: '/user/account' },
    { label: '修改密码', icon: 'i-carbon-password', to: '/user/password' },
  ];

  /**
   * 展示用账号：优先订货账号（username，总部下发的门店账号），
   * 旧账号没有 username 时回退打码手机号；两者都没有则整行不展示。
   */
  const displayAccount = computed(() => {
    const info = userStore.userInfo;
    const username = info?.username?.trim();
    if (username) return username;
    return info?.mobile ? maskMobile(info.mobile) : '';
  });

  function toLogin(): void {
    void router.push('/login');
  }

  function toOrderList(status?: string): void {
    // 待收货：直接进入门店收货列表（逐行确认实收，含多收 / 少收 / 破损）
    if (status === 'SHIPPED') {
      void router.push('/order/receipt-list');
      return;
    }
    void router.push({ path: '/order/list', query: status ? { status } : {} });
  }

  /** 菜单点击：本页菜单全部已接入（会员中心已下线，不再有占位入口） */
  function onMenuClick(menu: { label: string; to: string }): void {
    void router.push(menu.to);
  }

  async function onLogout(): Promise<void> {
    if (!(await confirmDialog('确认退出当前账号？'))) return;
    await userStore.logout();
    showToast('已退出登录');
  }

  /** 拉取订单数量（进入页面、以及每次回到本 tab 时都会调用） */
  async function refreshOrderCount(): Promise<void> {
    if (!userStore.isLogin) return;
    try {
      orderCount.value = await getOrderCount();
    } catch (error) {
      console.warn('[user] 拉取订单数量失败:', error);
    }
  }

  /**
   * 本页是 keep-alive 的 tab 页：确认收货、下单等操作都发生在别的页面，
   * 回到本页不会重新 mount，只在 onMounted 拉一次会让「待收货」等角标一直是旧值。
   * onActivated 在首次挂载后也会触发一次，这里跳过首次，避免与 onMounted 重复请求。
   */
  let activatedOnce = false;
  onActivated(() => {
    if (!activatedOnce) {
      activatedOnce = true;
      return;
    }
    void refreshOrderCount();
  });

  onMounted(() => {
    void refreshOrderCount();

    if (!userStore.userInfo) {
      void userStore.fetchProfile().catch((err) => {
        console.warn('[user] 拉取会员信息失败:', err);
      });
    }
  });
</script>

<template>
  <div class="app-page">
    <!-- 头部 -->
    <div class="user__header" @click="!userStore.isLogin && toLogin()">
      <!-- 无头像时用默认人像，避免回退成「商品占位图」那种明显不搭的图标 -->
      <van-image
        v-if="userStore.avatar"
        class="user__avatar"
        round
        :src="resolveImage(userStore.avatar)"
        fit="cover"
      />
      <div v-else class="user__avatar user__avatar--empty">
        <van-icon name="manager" size="28" />
      </div>
      <div class="user__info">
        <template v-if="userStore.isLogin">
          <div class="user__name">{{ userStore.nickname }}</div>
          <div class="user__sub">
            <!-- 会员等级已随会员中心下线，这里只展示订货账号（= 订货人姓名） -->
            <van-tag v-if="displayAccount" type="success" plain>{{ displayAccount }}</van-tag>
          </div>
        </template>
        <template v-else>
          <div class="user__name">点击登录</div>
          <div class="user__sub">登录后可查看专属订货价</div>
        </template>
      </div>
      <van-icon name="arrow" color="#fff" />
    </div>

    <!-- 我的订单 -->
    <div class="user__orders app-card">
      <div class="flex-between user__orders-head">
        <span class="user__orders-title">我的订单</span>
        <span class="user__orders-more" @click="toOrderList()">
          全部订单 <van-icon name="arrow" />
        </span>
      </div>
      <div class="user__orders-grid">
        <div
          v-for="entry in statusEntries"
          :key="entry.key"
          class="user__orders-item"
          @click="toOrderList(entry.key)"
        >
          <!-- 角标挂在图标上，避免压住下方文字 -->
          <van-badge :content="countOf(entry) || ''" :show-zero="false">
            <van-icon :name="entry.icon" class="user__orders-icon" />
          </van-badge>
          <span class="user__orders-text">{{ ORDER_STATUS_MAP[entry.key].text }}</span>
        </div>
      </div>
    </div>

    <!-- 功能菜单 -->
    <van-cell-group inset class="user__menus">
      <van-cell
        v-for="menu in menus"
        :key="menu.label"
        :title="menu.label"
        is-link
        @click="onMenuClick(menu)"
      >
        <template #icon>
          <i :class="menu.icon" class="user__menu-icon" />
        </template>
      </van-cell>
    </van-cell-group>

    <div class="user__footer">
      <van-button v-if="userStore.isLogin" block round @click="onLogout">退出登录</van-button>
      <van-button v-else block round type="primary" @click="toLogin">立即登录</van-button>
      <div v-if="displayAccount" class="user__account">账号：{{ displayAccount }}</div>
    </div>
  </div>
</template>

<style scoped lang="scss">
  .user {
    &__header {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: calc(24px + env(safe-area-inset-top)) 16px 32px;
      background: var(--app-primary-gradient);
      color: #fff;
    }

    &__avatar {
      flex: none;
      width: 56px;
      height: 56px;
      background: rgb(255 255 255 / 30%);
    }

    &__avatar--empty {
      display: flex;
      align-items: center;
      justify-content: center;
      color: rgb(255 255 255 / 90%);
    }

    &__info {
      flex: 1;
      min-width: 0;
    }

    &__name {
      font-size: 18px;
      font-weight: 600;
      color: #fff;
    }

    &__sub {
      display: flex;
      align-items: center;
      margin-top: 6px;
      font-size: 12px;
      opacity: 0.92;
    }

    &__orders {
      margin: -16px 12px 0;
      padding: 18px 0 20px;
    }

    &__menus {
      margin-top: 20px;
    }

    &__orders-head {
      padding: 0 16px 4px;
    }

    &__orders-title {
      font-size: 15px;
      font-weight: 600;
    }

    &__orders-more {
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__orders-grid {
      display: flex;
      padding-top: 16px;
    }

    &__orders-item {
      display: flex;
      flex: 1;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      cursor: pointer;
    }

    &__orders-icon {
      font-size: 24px;
      color: var(--app-primary-color);
    }

    &__orders-text {
      font-size: 12px;
      line-height: 1;
      color: var(--app-text-color);
    }

    &__menu-icon {
      margin-right: 8px;
      color: var(--app-primary-color);
      font-size: 18px;
    }

    &__footer {
      padding: 24px 16px calc(24px + env(safe-area-inset-bottom));
    }

    &__account {
      margin-top: 12px;
      text-align: center;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }
  }
</style>
