<template>
  <Card class="mb-24rpx" :title="section.title">
    <template #extra>
      <wd-tag type="primary" variant="plain">
        {{ rows.length }} 条
      </wd-tag>
    </template>

    <!-- 统计图表 -->
    <YdChart
      v-if="chartOption"
      class="mb-20rpx"
      :option="chartOption"
      :height="getChartHeight(section, { rank })"
    />

    <view v-if="rows.length > 0">
      <view
        v-for="(row, index) in visibleRows"
        :key="index"
        class="yd-border-light border-t py-16rpx"
      >
        <template v-if="section.columns?.length">
          <view
            v-for="column in section.columns"
            :key="column.prop"
            class="mb-8rpx flex items-center justify-between gap-16rpx text-28rpx"
          >
            <text class="yd-text-hint shrink-0">{{ column.label }}</text>
            <text class="yd-text-main min-w-0 flex-1 text-right">{{ formatColumnValue(row, column) }}</text>
          </view>
        </template>
        <template v-else>
          <view
            v-for="entry in formatEntries(row)"
            :key="entry.label"
            class="mb-8rpx flex items-center justify-between gap-16rpx text-28rpx"
          >
            <text class="yd-text-hint shrink-0">{{ entry.label }}</text>
            <text class="yd-text-main min-w-0 flex-1 text-right">{{ entry.value }}</text>
          </view>
        </template>
      </view>

      <!-- 展开更多 / 收起：超过默认展示行数时出现 -->
      <view
        v-if="rows.length > DEFAULT_VISIBLE_ROWS"
        class="yd-border-light border-t pt-16rpx text-center text-26rpx text-[--wot-color-theme]"
        @click="expanded = !expanded"
      >
        {{ expanded ? '收起' : `展开更多（共 ${rows.length} 条）` }}
      </view>
      <!-- 数据量过大时仅展示前 MAX_VISIBLE_ROWS 条 -->
      <view
        v-if="rows.length > MAX_VISIBLE_ROWS"
        class="yd-text-muted pt-8rpx text-center text-24rpx"
      >
        仅展示前 {{ MAX_VISIBLE_ROWS }} 条
      </view>
    </view>
    <!-- add by 棱信矩灵：区分「加载中 / 加载失败 / 确实没有数据」三种状态 -->
    <!-- 此前请求失败与加载中都会被渲染成「暂无统计数据」，用户无法区分，且没有重试入口 -->
    <view v-else-if="loading" class="flex justify-center py-40rpx">
      <wd-loading />
    </view>
    <view v-else-if="error" class="py-40rpx text-center">
      <text class="yd-text-hint text-28rpx">加载失败</text>
      <text class="ml-16rpx text-28rpx text-[--wot-color-theme]" @click="emit('retry')">重新加载</text>
    </view>
    <wd-empty v-else icon="content" tip="暂无统计数据" />
  </Card>
</template>

<script lang="ts" setup>
import type { StatisticsSection } from '@/pages-statistics/utils/statistics'
import { computed, ref, watch } from 'vue'
import {
  buildAxisOption,
  buildFunnelOption,
  buildPieOption,
  DEFAULT_VISIBLE_ROWS,
  formatColumnValue,
  formatEntries,
  getChartHeight,
  MAX_VISIBLE_ROWS,
} from '@/pages-statistics/utils/statistics'
import YdChart from '@/pages-statistics/components/yd-chart/yd-chart.vue'
import { toNumber } from '@/utils/format'
import Card from './card.vue'

const props = withDefaults(defineProps<{
  rank?: boolean
  rows?: Record<string, any>[]
  section: StatisticsSection
  loading?: boolean // 加载中（不传则维持原有行为）
  error?: boolean // 加载失败（不传则维持原有行为）
}>(), {
  rank: false,
  rows: () => [],
  loading: false,
  error: false,
})

const emit = defineEmits<{
  retry: [] // 加载失败时点击「重新加载」
}>()

const expanded = ref(false) // 展开状态

// 图表配置：按 chart.type 就地分发，不再走单独的 buildChartOption 包装
const chartOption = computed(() => {
  const chart = props.section.chart
  if (!chart || props.rows.length === 0) {
    return undefined
  }
  if (chart.type === 'pie') {
    return buildPieOption(props.section, props.rows)
  }
  if (chart.type === 'funnel') {
    // 漏斗各阶段 = columns（如客户数/商机数/赢单数），取值来自 rows[0]
    const row = props.rows[0] || {}
    return buildFunnelOption((props.section.columns || []).map(col => ({ name: col.label, value: toNumber(row[col.prop]) })), props.section.title)
  }
  return buildAxisOption(props.section, props.rows, { rank: props.rank })
})

const visibleRows = computed(() => { // 当前可见数据
  if (expanded.value) {
    return props.rows.slice(0, MAX_VISIBLE_ROWS)
  }
  return props.rows.slice(0, DEFAULT_VISIBLE_ROWS)
})

watch(() => props.section.title, () => {
  expanded.value = false // 切换统计分类时重置展开状态，避免跨 tab 继承
})
</script>
