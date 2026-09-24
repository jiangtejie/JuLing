<script setup lang="ts">
  import { storeToRefs } from 'pinia';
  import { useRoute } from 'vue-router';
  import { useNetworkNotice } from '@/composables/useNetworkNotice';
  import { useAppStore } from '@/stores/app';

  defineOptions({ name: 'App' });

  const route = useRoute();
  const { cachedViews } = storeToRefs(useAppStore());

  // 全局网络状态横幅（断网 / 恢复）
  useNetworkNotice();
</script>

<template>
  <router-view v-slot="{ Component }">
    <keep-alive :include="cachedViews">
      <component :is="Component" />
    </keep-alive>
  </router-view>

  <!-- tabbar 放在 router-view 之外，切换页面时不会重新渲染 -->
  <AppTabbar v-if="route.meta.tabbar" />
</template>
