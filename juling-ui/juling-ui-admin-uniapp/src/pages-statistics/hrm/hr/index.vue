<template>
  <view class="yd-page-container">
    <!-- 顶部导航栏 -->
    <wd-navbar
      title="HR 工作台"
      left-arrow placeholder safe-area-inset-top fixed
      @click-left="handleBack"
    />

    <scroll-view class="min-h-0 flex-1" scroll-y scroll-with-animation>
      <view class="p-24rpx space-y-24rpx">
        <view class="overflow-hidden rounded-12rpx bg-white shadow-sm">
          <view class="flex items-center justify-between border-b border-b-[#f0f0f0] px-24rpx py-20rpx">
            <text class="yd-text-main text-30rpx font-semibold">
              HR 统计
            </text>
            <wd-button size="small" type="primary" :loading="loading" @click="getSummary">
              刷新
            </wd-button>
          </view>
        </view>

        <view v-if="loading && !summary" class="yd-text-hint rounded-12rpx bg-white py-64rpx text-center text-26rpx shadow-sm">
          <wd-loading size="32rpx" />
          <view class="mt-12rpx">
            正在加载工作台数据
          </view>
        </view>

        <view
          v-else-if="loadError"
          class="yd-text-hint rounded-12rpx bg-white py-64rpx text-center text-26rpx shadow-sm"
        >
          <view>数据加载失败</view>
          <view class="mt-12rpx text-[--wot-color-theme]" @click="getSummary">
            重新加载
          </view>
        </view>

        <template v-else>
          <EmployeeSurvey :survey="summary?.employeeSurvey" />
          <RecruitSurvey :survey="summary?.recruitSurvey" />
          <SalarySurvey :survey="summary?.salarySurvey" />
          <TodoSurvey :survey="summary?.todoSurvey" />
          <HomeCalendar
            :get-calendar-items="getHrHomeCalendar"
            :is-item-clickable="isCalendarItemClickable"
            @item-click="openCalendarItem"
          />
        </template>
      </view>
      <view class="h-40rpx" />
    </scroll-view>
  </view>
</template>

<script lang="ts" setup>
import type { HomeCalendarItem, HrHomeStatistics } from '@/api/hrm/home'
import { onMounted, ref } from 'vue'
import { getHrHomeCalendar, getHrHomeStatisticsSummary } from '@/api/hrm/home'
import { HrmHomeCalendarItemType } from '@/pages-hrm/utils/constants'
import { navigateBackPlus } from '@/utils'
import EmployeeSurvey from '../components/employee-survey.vue'
import HomeCalendar from '../components/home-calendar.vue'
import RecruitSurvey from '../components/recruit-survey.vue'
import SalarySurvey from '../components/salary-survey.vue'
import TodoSurvey from '../components/todo-survey.vue'

definePage({
  style: {
    navigationBarTitleText: '',
    navigationStyle: 'custom',
  },
})

const loading = ref(false) // 加载中
const summary = ref<HrHomeStatistics>() // 工作台汇总数据
const loadError = ref(false) // add by 棱信矩灵：加载失败标记，避免失败后整屏渲染成 0 被误认为「数据真的是 0」

/** 返回上一页 */
function handleBack() {
  navigateBackPlus()
}

/** 获得首页统计汇总 */
async function getSummary() {
  loading.value = true
  loadError.value = false
  try {
    summary.value = await getHrHomeStatisticsSummary()
  } catch {
    // add by 棱信矩灵：失败时置错误态并展示「重新加载」，此前无 catch，失败后各卡片用 || 0 兜底渲染成满屏 0
    loadError.value = true
  } finally {
    loading.value = false
  }
}

/** 日历事项是否支持跳转详情 */
function isCalendarItemClickable(item: HomeCalendarItem) {
  return item.type !== HrmHomeCalendarItemType.NOTE && !!item.typeId
}

/** 打开日历事项详情 */
function openCalendarItem(item: HomeCalendarItem) {
  if (!item.typeId) {
    return
  }
  if (item.type === HrmHomeCalendarItemType.RECRUIT) {
    uni.navigateTo({
      url: `/pages-hrm/recruit/candidate/detail/index?id=${item.typeId}`,
    })
    return
  }
  uni.navigateTo({
    url: `/pages-hrm/employee/detail/index?id=${item.typeId}`,
  })
}

/** 初始化 */
onMounted(() => {
  getSummary()
})
</script>
