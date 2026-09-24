<script setup lang="ts">
  import { formatPrice } from '@/utils/format';

  interface Props {
    /** 金额，单位：分 */
    value: number | string;
    /** 字号 */
    size?: 'small' | 'normal' | 'large';
    /** 颜色 */
    color?: string;
    /** 货币符号 */
    symbol?: string;
    /** 小数位 */
    digits?: number;
    /** 是否显示删除线（划线价） */
    lineThrough?: boolean;
  }

  const props = withDefaults(defineProps<Props>(), {
    size: 'normal',
    color: 'var(--app-danger-color)',
    symbol: '¥',
    digits: 2,
    lineThrough: false,
  });

  const fontSize = computed(() => {
    const map = { small: '12px', normal: '14px', large: '20px' };
    return map[props.size];
  });

  const text = computed(() => formatPrice(props.value, props.digits));
</script>

<template>
  <span
    class="price-text"
    :style="{ color, fontSize, textDecoration: lineThrough ? 'line-through' : 'none' }"
  >
    <span class="price-text__symbol">{{ symbol }}</span>
    <span class="price-text__value">{{ text }}</span>
  </span>
</template>

<style scoped lang="scss">
  .price-text {
    display: inline-flex;
    align-items: baseline;
    font-weight: 600;
    line-height: 1;

    &__symbol {
      margin-right: 1px;
      font-size: 0.72em;
      font-weight: 500;
    }
  }
</style>
