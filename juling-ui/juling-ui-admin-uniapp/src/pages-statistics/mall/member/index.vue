<template>
  <view class="yd-page-container">
    <!-- 顶部导航栏 -->
    <wd-navbar
      title="会员统计"
      left-arrow placeholder safe-area-inset-top fixed
      @click-left="handleBack"
    />

    <scroll-view scroll-y class="min-h-0 flex-1">
      <view class="p-24rpx">
        <!-- 会员累计 -->
        <SummaryGrid class="mb-24rpx" :items="summaryItems" />

        <!-- 搜索组件 -->
        <SearchForm
          class="mb-24rpx"
          :initial-start-time="defaultStartTime"
          :initial-end-time="defaultEndTime"
          @search="handleQuery"
          @reset="handleReset"
        />

        <view class="mb-24rpx flex justify-end">
          <wd-button size="small" type="primary" variant="plain" :loading="loading" @click="loadData">
            刷新
          </wd-button>
        </view>

        <!-- 分组切换 -->
        <wd-tabs v-model="activeTab" @change="handleTabChange">
          <wd-tab title="会员概览" />
          <wd-tab title="终端性别" />
          <wd-tab title="地域分布" />
        </wd-tabs>

        <!-- 会员概览 -->
        <view v-if="activeTab === 0" class="mt-24rpx rounded-12rpx bg-white p-24rpx shadow-sm">
          <view class="mb-20rpx flex items-center justify-between">
            <text class="yd-text-main text-30rpx font-semibold">会员概览</text>
            <text class="yd-text-hint text-26rpx">客单价 ￥{{ atvText }}</text>
          </view>
          <view class="mb-20rpx flex gap-16rpx">
            <view
              v-for="item in overviewItems"
              :key="item.label"
              class="yd-bg-subtle flex-1 rounded-12rpx px-16rpx py-20rpx"
            >
              <text class="yd-text-hint block text-24rpx">{{ item.label }}</text>
              <text class="yd-text-main mt-8rpx block text-36rpx font-semibold">{{ item.value }}</text>
              <text class="mt-4rpx block text-22rpx" :class="item.rate >= 0 ? 'yd-text-danger' : 'yd-text-success'">
                环比 {{ item.rate >= 0 ? '+' : '' }}{{ item.rate }}%
              </text>
            </view>
          </view>
          <YdChart v-if="funnelOption" :option="funnelOption" height="480rpx" />
          <wd-empty v-else icon="content" tip="暂无统计数据" />
        </view>

        <!-- 终端分布 + 性别比例 -->
        <view v-if="activeTab === 1" class="pt-24rpx">
          <StatisticsCard :section="terminalSection" :rows="terminalRows" :loading="loading" :error="tabError" @retry="handleRetryTab" />
          <StatisticsCard :section="sexSection" :rows="sexRows" :loading="loading" :error="tabError" @retry="handleRetryTab" />
        </view>

        <!-- 地域分布（移动端以排行表呈现，不渲染地图） -->
        <view v-if="activeTab === 2" class="pt-24rpx">
          <StatisticsCard :section="areaSection" :rows="areaRows" :loading="loading" :error="tabError" @retry="handleRetryTab" />
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script lang="ts" setup>
import type { SummaryItem } from '@/pages-statistics/components/card/summary-grid.vue'
import type { StatisticsSection } from '@/pages-statistics/utils/statistics'
import { computed, onMounted, reactive, ref } from 'vue'
import {
  getMemberAnalyse,
  getMemberAreaStatisticsList,
  getMemberSexStatisticsList,
  getMemberSummary,
  getMemberTerminalStatisticsList,
} from '@/api/mall/statistics'
import { getDictLabel } from '@/hooks/useDict'
import { navigateBackPlus } from '@/utils'
import { DICT_TYPE } from '@/utils/constants'
import { formatDateRange } from '@/utils/date'
import YdChart from '../../components/yd-chart/yd-chart.vue'
import SearchForm from '../components/search-form.vue'
import { fenToYuan } from '@/utils/format'
import { buildFunnelOption, calculateRelativeRate, normalizeRows } from '@/pages-statistics/utils/statistics'
import StatisticsCard from '@/pages-statistics/components/card/statistics-card.vue'
import SummaryGrid from '@/pages-statistics/components/card/summary-grid.vue'

definePage({
  style: {
    navigationBarTitleText: '',
    navigationStyle: 'custom',
  },
})

const now = new Date()
const defaultStartTime = now.getTime() - 3600 * 1000 * 24 * 30 // 默认开始日期
const defaultEndTime = now.getTime() // 默认结束日期
const filters = reactive({
  startTime: defaultStartTime,
  endTime: defaultEndTime,
}) // 筛选条件
const loading = ref(false) // 统计加载状态
const activeTab = ref(0) // 当前分组：0 概览 / 1 终端性别 / 2 地域
const summary = ref<Record<string, any>>({}) // 会员累计概览（累计值）
const cache = reactive<Record<string, any>>({}) // 分组数据缓存：key=`分组@时间区间`
const tabError = ref(false) // 当前分组的加载失败标记（与「确实没有数据」区分开）

const times = computed(() => formatDateRange([filters.startTime, filters.endTime])) // 查询时间区间
function tabCacheKey(tab: number) {
  return `${tab}@${times.value}`
}
const analyse = computed<Record<string, any>>(() => cache[tabCacheKey(0)] ?? {}) // 会员漏斗分析
const terminalRows = computed<Record<string, any>[]>(() => cache[tabCacheKey(1)]?.terminal ?? []) // 终端分布（含字典标签）
const sexRows = computed<Record<string, any>[]>(() => cache[tabCacheKey(1)]?.sex ?? []) // 性别分布（含字典标签）
const areaRows = computed<Record<string, any>[]>(() => cache[tabCacheKey(2)] ?? []) // 地域分布（已转元）
const atvText = computed(() => fenToYuan(analyse.value.atv).toFixed(2)) // 客单价（分转元）
const overviewItems = computed(() => {
  const comparison = analyse.value.comparison || {}
  const value = comparison.value || {}
  const reference = comparison.reference || {}
  return [
    { label: '注册用户数', value: value.registerUserCount || 0, rate: calculateRelativeRate(value.registerUserCount, reference.registerUserCount) },
    { label: '活跃用户数', value: value.visitUserCount || 0, rate: calculateRelativeRate(value.visitUserCount, reference.visitUserCount) },
    { label: '充值用户数', value: value.rechargeUserCount || 0, rate: calculateRelativeRate(value.rechargeUserCount, reference.rechargeUserCount) },
  ]
}) // 会员概览：注册/活跃/充值用户数 + 环比

const summaryItems = computed<SummaryItem[]>(() => [
  { label: '累计会员数', value: summary.value.userCount || 0 },
  { label: '累计充值人数', value: summary.value.rechargeUserCount || 0 },
  { label: '累计充值金额', value: fenToYuan(summary.value.rechargePrice), prefix: '￥' },
  { label: '累计消费金额', value: fenToYuan(summary.value.expensePrice), prefix: '￥' },
]) // 会员概览卡片

const funnelOption = computed(() => {
  const value = analyse.value
  if (!value || value.visitUserCount === undefined) {
    return undefined
  }
  // 访客→下单→成交
  return buildFunnelOption([
    { name: '访客', value: value.visitUserCount || 0 },
    { name: '下单', value: value.orderUserCount || 0 },
    { name: '成交', value: value.payUserCount || 0 },
  ], '会员漏斗')
}) // 会员漏斗图配置

const terminalSection: StatisticsSection = {
  title: '终端分布',
  columns: [
    { prop: 'terminalName', label: '终端' },
    { prop: 'userCount', label: '会员数' },
  ],
  chart: { type: 'pie', categoryProp: 'terminalName', valueProp: 'userCount' },
} // 终端分布分组配置

const sexSection: StatisticsSection = {
  title: '性别比例',
  columns: [
    { prop: 'sexName', label: '性别' },
    { prop: 'userCount', label: '会员数' },
  ],
  chart: { type: 'pie', categoryProp: 'sexName', valueProp: 'userCount' },
} // 性别比例分组配置

const areaSection: StatisticsSection = {
  title: '地域分布',
  columns: [
    { prop: 'areaName', label: '省份' },
    { prop: 'userCount', label: '会员数' },
    { prop: 'orderCreateUserCount', label: '下单数' },
    { prop: 'orderPayUserCount', label: '支付数' },
    { prop: 'orderPayPrice', label: '支付金额', type: 'money' },
  ],
} // 地域分布分组配置

/** 返回上一页 */
function handleBack() {
  navigateBackPlus()
}

/** 加载会员累计概览 */
async function loadSummary() {
  const data = await getMemberSummary().catch(() => ({}))
  summary.value = data || {}
}

/** 加载指定分组数据（按时间区间缓存，命中则跳过） */
async function loadTab(tab: number) {
  const key = tabCacheKey(tab)
  if (cache[key] !== undefined) {
    tabError.value = false
    return
  }
  // add by 棱信矩灵：失败不写缓存（否则一次网络抖动后该分组永久显示「暂无统计数据」），改为置错误态
  tabError.value = false
  if (tab === 0) {
    const analyse = await getMemberAnalyse({ times: times.value }).catch(() => undefined)
    if (analyse === undefined) {
      tabError.value = true
      return
    }
    cache[key] = analyse || {}
    return
  }
  if (tab === 1) {
    const [terminalData, sexData] = await Promise.all([
      getMemberTerminalStatisticsList().catch(() => undefined),
      getMemberSexStatisticsList().catch(() => undefined),
    ])
    if (terminalData === undefined || sexData === undefined) {
      tabError.value = true
      return
    }
    // 终端/性别用字典标签，而非原始 code
    cache[key] = {
      terminal: normalizeRows(terminalData).map(item => ({
        ...item,
        terminalName: getDictLabel(DICT_TYPE.TERMINAL, item.terminal) || '未知',
      })),
      sex: normalizeRows(sexData).map(item => ({
        ...item,
        sexName: getDictLabel(DICT_TYPE.SYSTEM_USER_SEX, item.sex) || '未知',
      })),
    }
    return
  }
  // 地域支付金额由分转元
  const areaData = await getMemberAreaStatisticsList().catch(() => undefined)
  if (areaData === undefined) {
    tabError.value = true
    return
  }
  cache[key] = normalizeRows(areaData).map(item => ({
    ...item,
    orderPayPrice: fenToYuan(item.orderPayPrice),
  }))
}

/** add by 棱信矩灵：加载失败后重试当前分组 */
async function handleRetryTab() {
  delete cache[tabCacheKey(activeTab.value)]
  loading.value = true
  try {
    await loadTab(activeTab.value)
  } finally {
    loading.value = false
  }
}

/** 切换分组 */
async function handleTabChange({ index }: { index: number }) {
  activeTab.value = index
  loading.value = true
  try {
    await loadTab(index)
  } finally {
    loading.value = false
  }
}

/** 搜索 / 刷新：强制刷新当前分组并重载概览 */
async function loadData() {
  delete cache[tabCacheKey(activeTab.value)]
  loading.value = true
  try {
    await Promise.all([loadSummary(), loadTab(activeTab.value)])
  } finally {
    loading.value = false
  }
}

/** 搜索按钮操作 */
function handleQuery(data: { endTime: number, startTime: number }) {
  filters.startTime = data.startTime
  filters.endTime = data.endTime
  loadData()
}

/** 重置按钮操作 */
function handleReset() {
  filters.startTime = defaultStartTime
  filters.endTime = defaultEndTime
  loadData()
}

/** 初始化 */
onMounted(() => {
  loadData()
})
</script>
