<script setup lang="ts">
  import { showConfirmDialog, showToast } from 'vant';
  import { getOrderCount, type OrderCountMap } from '@/api/order';
  import { ORDER_STATUS_MAP } from '@/constants';
  import { useUserStore } from '@/stores/user';
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
    { label: '我的订货单', icon: 'i-carbon-shopping-cart', to: '/cart' },
    { label: '收货地址', icon: 'i-carbon-location', to: '' },
    { label: '企业资料', icon: 'i-carbon-building', to: '' },
    { label: '联系客服', icon: 'i-carbon-headset', to: '' },
    { label: '系统设置', icon: 'i-carbon-settings', to: '' },
  ];

  function toLogin(): void {
    void router.push('/login');
  }

  function toOrderList(status?: string): void {
    void router.push({ path: '/order/list', query: status ? { status } : {} });
  }

  async function onLogout(): Promise<void> {
    await showConfirmDialog({ title: '提示', message: '确认退出当前账号？' });
    await userStore.logout();
    showToast('已退出登录');
  }

  onMounted(() => {
    if (!userStore.isLogin) return;

    void getOrderCount()
      .then((res) => {
        orderCount.value = res;
      })
      .catch((err) => {
        console.warn('[user] 拉取订单数量失败:', err);
      });

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
            <!-- 后端未提供订货客户认证标识（verified / customerName），降级展示会员等级 -->
            <van-tag v-if="userStore.userInfo?.levelName" type="success" plain>
              {{ userStore.userInfo.levelName }}
            </van-tag>
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
        :clickable="Boolean(menu.to)"
        @click="menu.to && router.push(menu.to)"
      >
        <template #icon>
          <i :class="menu.icon" class="user__menu-icon" />
        </template>
      </van-cell>
    </van-cell-group>

    <div class="user__footer">
      <van-button v-if="userStore.isLogin" block round @click="onLogout">退出登录</van-button>
      <van-button v-else block round type="primary" @click="toLogin">立即登录</van-button>
      <div v-if="userStore.userInfo?.mobile" class="user__mobile">
        账号：{{ maskMobile(userStore.userInfo.mobile) }}
      </div>
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
      background: linear-gradient(135deg, #0081ff, #41b0ff);
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

    &__mobile {
      margin-top: 12px;
      text-align: center;
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }
  }
</style>
