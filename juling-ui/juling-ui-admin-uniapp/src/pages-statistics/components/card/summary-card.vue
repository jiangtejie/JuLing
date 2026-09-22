<template>
  <!-- 单个总结卡片：标签 + 数值 + 环比，复用基础 card 壳 -->
  <view v-if="!item" class="rounded-12rpx p-20rpx" :class="highlight ? 'bg-[#ecf5ff]' : 'yd-bg-subtle'">
    <view class="yd-text-hint text-24rpx">
      {{ title }}
    </view>
    <view class="mt-8rpx text-32rpx font-semibold" :class="simpleValueClass">
      {{ prefix }}{{ simpleValueText }}
    </view>
  </view>
  <Card v-else>
    <text class="yd-text-hint text-26rpx">{{ item.label }}</text>
    <view class="mt-12rpx flex items-end gap-4rpx">
      <text v-if="item.prefix" class="yd-text-main text-28rpx font-semibold">{{ item.prefix }}</text>
      <text class="yd-text-main text-40rpx font-semibold leading-none">{{ formattedValue }}</text>
    </view>
    <view v-if="item.reference !== undefined" class="mt-12rpx flex items-center gap-6rpx text-24rpx">
      <text class="yd-text-muted">{{ referenceLabel }}</text>
      <text :class="rateClass">{{ rateText }}</text>
    </view>
  </Card>
</template>

<script lang="ts" setup>
import type { SummaryItem } from './summary-grid.vue'
import { computed } from 'vue'
import { calculateRelativeRate } from '@/pages-statistics/utils/statistics'
import Card from './card.vue'

const props = withDefaults(defineProps<{
  item?: SummaryItem
  title?: string // 标题
  value?: number // 数值
  highlight?: boolean // 是否高亮
  prefix?: string // 数值前缀
  referenceLabel?: string // 对比说明文案
}>(), {
  title: '',
  value: 0,
  highlight: false,
  prefix: '￥',
  referenceLabel: '较昨日',
})

const formattedValue = computed(() => { // 金额前缀场景保留两位小数
  const value = Number(props.item?.value || 0)
  if (Number.isNaN(value)) {
    return String(props.item?.value ?? '-')
  }
  return props.item?.prefix ? value.toFixed(2) : String(value)
})

const simpleValue = computed(() => {
  const value = Number(props.value || 0)
  return Number.isNaN(value) ? 0 : value
}) // 简单数值
const simpleValueText = computed(() => simpleValue.value.toFixed(2)) // 简单数值文案
const simpleValueClass = computed(() => simpleValue.value >= 0 ? 'yd-text-link' : 'yd-text-danger') // 正负数颜色
const rateValue = computed(() => calculateRelativeRate(props.item?.value || 0, props.item?.reference)) // 环比增长率
const rateText = computed(() => `${rateValue.value > 0 ? '+' : ''}${rateValue.value}%`)
const rateClass = computed(() => {
  if (rateValue.value > 0) {
    return 'yd-text-danger' // 增长红
  }
  if (rateValue.value < 0) {
    return 'yd-text-success' // 下降绿
  }
  return 'yd-text-hint'
})
</script>
