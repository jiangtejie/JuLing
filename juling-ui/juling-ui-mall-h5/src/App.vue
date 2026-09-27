<script setup lang="ts">
  import { MotionConfig } from 'motion-v';
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
  <!--
    全局动效配置：reduced-motion="user" 表示遵循系统「减少动态效果」设置，
    用户在系统里关掉动效时，motion 的动画会自动降级为直接切换（不产生包裹元素，不影响布局）。
  -->
  <MotionConfig reduced-motion="user">
    <router-view v-slot="{ Component }">
      <keep-alive :include="cachedViews">
        <component :is="Component" />
      </keep-alive>
    </router-view>

    <!-- tabbar 放在 router-view 之外，切换页面时不会重新渲染 -->
    <AppTabbar v-if="route.meta.tabbar" />
  </MotionConfig>
</template>
