<script setup lang="ts">
  interface Props {
    /** 骨架卡片数量 */
    rows?: number;
    /** 骨架形态：product = 商品行（左图右文）；order = 订单卡（编号 + 商品行 + 底部） */
    variant?: 'product' | 'order';
  }

  // eslint 规则 vue/define-macros-order 要求宏紧邻且按 defineOptions → defineProps 排列，
  // 类型定义需在宏之前，故 interface 放在最上方。
  defineOptions({ name: 'ListSkeleton' });

  withDefaults(defineProps<Props>(), {
    rows: 3,
    variant: 'product',
  });
</script>

<template>
  <div class="list-skeleton">
    <!--
      用 van-skeleton 的 template 插槽自定义骨架形态：
      动画由 .van-skeleton--animate 作用在根元素上（整块淡入淡出），
      因此自定义模板同样是「会呼吸」的，无需额外类名。
    -->
    <van-skeleton
      v-for="row in rows"
      :key="row"
      class="list-skeleton__card app-card"
      :animate="true"
    >
      <template #template>
        <!-- 商品行：左图 + 三行文字（末行更粗，对应价格） -->
        <div v-if="variant === 'product'" class="list-skeleton__row">
          <div class="list-skeleton__img" />
          <div class="list-skeleton__lines">
            <div class="list-skeleton__line" :style="{ width: '78%' }" />
            <div class="list-skeleton__line" :style="{ width: '52%' }" />
            <div
              class="list-skeleton__line list-skeleton__line--strong"
              :style="{ width: '34%' }"
            />
          </div>
        </div>

        <!-- 订单卡：编号行 + 商品行 + 底部金额行 -->
        <div v-else class="list-skeleton__col">
          <div class="list-skeleton__line" :style="{ width: '42%' }" />
          <div class="list-skeleton__row list-skeleton__row--mid">
            <div class="list-skeleton__img list-skeleton__img--sm" />
            <div class="list-skeleton__lines">
              <div class="list-skeleton__line" :style="{ width: '88%' }" />
              <div class="list-skeleton__line" :style="{ width: '46%' }" />
            </div>
          </div>
          <div class="list-skeleton__line" :style="{ width: '32%' }" />
        </div>
      </template>
    </van-skeleton>
  </div>
</template>

<style scoped lang="scss">
  .list-skeleton {
    display: flex;
    flex-direction: column;
    gap: 10px;
    padding: 12px;

    &__card {
      /* 覆盖 van-skeleton 默认的 0 16px 内边距，改由卡片自身控制（与其后的真实卡片对齐） */
      padding: 10px;
    }

    &__row {
      display: flex;
      gap: 10px;
    }

    &__row--mid {
      margin: 10px 0;
    }

    &__col {
      display: flex;
      flex-direction: column;
      gap: 10px;
    }

    &__img {
      flex: none;
      width: 90px;
      height: 90px;
      background: var(--van-skeleton-paragraph-background);
      border-radius: var(--app-radius-md);
    }

    &__img--sm {
      width: 64px;
      height: 64px;
    }

    &__lines {
      display: flex;
      flex: 1;
      flex-direction: column;
      gap: 8px;
      min-width: 0;
    }

    &__line {
      height: 12px;
      background: var(--van-skeleton-paragraph-background);
      border-radius: 6px;
    }

    &__line--strong {
      height: 16px;
      border-radius: 8px;
    }
  }
</style>
