<script setup lang="ts">
  interface Props {
    /** 标题 */
    title?: string;
    /** 是否显示返回箭头 */
    leftArrow?: boolean;
    /** 是否固定在顶部 */
    fixed?: boolean;
    /** 固定时是否生成等高占位，避免内容被遮挡 */
    placeholder?: boolean;
    /** 是否显示底部分割线 */
    border?: boolean;
    zIndex?: number;
  }

  withDefaults(defineProps<Props>(), {
    title: '',
    leftArrow: true,
    fixed: true,
    placeholder: true,
    border: false,
    zIndex: 100,
  });

  const emit = defineEmits<{ clickLeft: [] }>();
  const slots = useSlots();
  const router = useRouter();

  function onClickLeft(): void {
    emit('clickLeft');
    if (window.history.length > 1) {
      router.back();
    } else {
      void router.replace('/');
    }
  }
</script>

<template>
  <van-nav-bar
    :title="title"
    :left-arrow="leftArrow"
    :fixed="fixed"
    :placeholder="placeholder"
    :border="border"
    :z-index="zIndex"
    @click-left="onClickLeft"
  >
    <template v-if="slots.left" #left>
      <slot name="left" />
    </template>
    <template v-if="slots.right" #right>
      <slot name="right" />
    </template>
  </van-nav-bar>
</template>
