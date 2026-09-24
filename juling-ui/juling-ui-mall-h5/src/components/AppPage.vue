<script setup lang="ts">
  interface Props {
    /** 导航栏标题，为空时不渲染导航栏 */
    title?: string;
    /** 是否使用系统安全区留白（刘海屏） */
    safeArea?: boolean;
    /** 页面背景色 */
    background?: string;
    /** 页面是否可滚动（弹窗类页面可关闭） */
    scrollable?: boolean;
  }

  withDefaults(defineProps<Props>(), {
    title: '',
    safeArea: false,
    background: '',
    scrollable: true,
  });

  const slots = useSlots();
</script>

<template>
  <div
    class="app-page"
    :class="{ 'pt-safe': safeArea }"
    :style="background ? { backgroundColor: background } : undefined"
  >
    <AppNavBar v-if="title" :title="title">
      <template v-if="slots.navRight" #right>
        <slot name="navRight" />
      </template>
    </AppNavBar>

    <div :class="scrollable ? 'app-scroll' : 'flex-1 overflow-hidden'">
      <slot />
    </div>

    <!-- 固定在底部的操作区（如提交订单栏） -->
    <slot name="footer" />
  </div>
</template>
