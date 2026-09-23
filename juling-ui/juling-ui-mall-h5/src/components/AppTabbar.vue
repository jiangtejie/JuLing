<script setup lang="ts">
  defineOptions({ name: 'AppTabbar' });

  /**
   * 底部主导航。
   *
   * 说明：原「订货单」tab 已移除——订货单改为分类页底部的悬浮购物车栏
   * （美团外卖点菜式），通过「去结算 / 查看明细」进入 /cart 与 /order/confirm。
   */
  const tabs = [
    { name: 'Home', to: '/home', icon: 'home-o', label: '首页' },
    { name: 'Category', to: '/category', icon: 'apps-o', label: '分类' },
    { name: 'User', to: '/user', icon: 'user-o', label: '我的' },
  ] as const;
</script>

<template>
  <van-tabbar route fixed placeholder safe-area-inset-bottom>
    <van-tabbar-item v-for="tab in tabs" :key="tab.name" :to="tab.to" :icon="tab.icon">
      {{ tab.label }}
    </van-tabbar-item>
  </van-tabbar>
</template>
