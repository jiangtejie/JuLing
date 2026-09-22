<template>
  <!-- 财务指标卡片：横向滚动，点击选中指标联动图表 -->
  <view class="overflow-hidden rounded-12rpx bg-white shadow-sm">
    <view class="flex items-center justify-between border-b border-b-[#f0f0f0] px-24rpx py-20rpx">
      <text class="yd-text-main text-30rpx font-semibold">
        财务指标
      </text>
      <text class="yd-text-hint text-24rpx">
        {{ home?.currentMonth }} 当期数据
      </text>
    </view>
    <scroll-view scroll-x>
      <view class="inline-flex gap-16rpx p-24rpx">
        <view
          v-for="(metric, index) in home?.metrics || []"
          :key="metric.key"
          class="w-300rpx flex-shrink-0 border rounded-12rpx px-20rpx py-24rpx"
          :class="selectedMetricKey === metric.key
            ? 'border-[#1677ff] bg-[#e6f0ff]'
            : 'yd-border-light yd-bg-subtle'"
          @click="emit('select', metric)"
        >
          <view class="flex items-center gap-8rpx">
            <view
              class="h-24rpx w-8rpx flex-shrink-0 rounded-4rpx"
              :style="{ backgroundColor: FMS_HOME_METRIC_COLORS[index % FMS_HOME_METRIC_COLORS.length] }"
            />
            <text class="yd-text-sub min-w-0 truncate text-26rpx">
              {{ metric.name }}
            </text>
          </view>
          <view class="yd-text-main mt-12rpx truncate text-36rpx font-semibold">
            {{ formatFmsAmount(metric.amount) }}
          </view>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script lang="ts" setup>
import type { FmsHome, FmsHomeMetric } from '@/api/fms/home'
import { FMS_HOME_METRIC_COLORS } from '@/pages-fms/utils/constants'
import { formatFmsAmount } from '@/pages-fms/utils/format'

defineProps<{
  home?: FmsHome
  selectedMetricKey?: string
}>()

const emit = defineEmits<{
  (e: 'select', metric: FmsHomeMetric): void
}>()
</script>
