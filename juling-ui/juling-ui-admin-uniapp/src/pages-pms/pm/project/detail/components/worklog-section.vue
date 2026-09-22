<template>
  <view class="h-full flex flex-col">
    <!-- 搜索区域 -->
    <view class="bg-white p-24rpx">
      <view class="mb-16rpx flex items-center gap-16rpx">
        <wd-input
          v-model="queryParams.iterationName"
          class="flex-1"
          placeholder="搜索迭代名称"
          clearable
          @confirm="getReport"
        />
        <wd-button size="small" type="primary" @click="getReport">
          查询
        </wd-button>
        <wd-button size="small" variant="plain" @click="handleReset">
          重置
        </wd-button>
      </view>
      <yd-search-date-range v-model="dateRange" label="日期范围" @change="getReport" />
    </view>

    <!-- 工时汇总 -->
    <view class="yd-text-link yd-bg-info-soft mx-24rpx mt-24rpx rounded-12rpx p-20rpx text-28rpx">
      当前范围累计登记 {{ report.totalHours }} 小时
    </view>

    <!-- 工时报表 -->
    <scroll-view scroll-y class="min-h-0 flex-1">
      <view class="p-24rpx pb-200rpx">
        <view v-if="!report.groups.length" class="yd-text-hint py-80rpx text-center text-28rpx">
          当前范围暂无工时记录
        </view>
        <view
          v-for="group in report.groups"
          :key="group.iterationId || 0"
          class="mb-24rpx rounded-12rpx bg-white p-24rpx shadow-sm"
        >
          <view class="mb-16rpx flex items-center justify-between">
            <text class="yd-text-main text-30rpx font-semibold">{{ group.iterationName }}</text>
            <text class="yd-text-link text-28rpx">共 {{ group.totalHours }} 小时</text>
          </view>
          <view
            v-for="item in group.items"
            :key="item.workItemId"
            class="yd-border-light border-t py-16rpx first:border-t-0"
          >
            <view class="flex items-center justify-between gap-16rpx" @click="toggleItem(item.workItemId)">
              <text class="yd-text-link min-w-0 flex-1 truncate text-28rpx" @click.stop="handleWorkItemDetail(item.workItemId)">
                #{{ item.serialNumber }} {{ item.name }}
              </text>
              <text class="yd-text-sub shrink-0 text-26rpx">{{ item.totalHours }} 小时</text>
            </view>
            <!-- 每日工时明细 -->
            <view v-if="expandedIds.has(item.workItemId)" class="yd-bg-subtle mt-12rpx rounded-8rpx p-16rpx">
              <view
                v-for="date in report.dates"
                :key="date"
                class="yd-text-sub flex justify-between py-6rpx text-24rpx"
              >
                <text>{{ formatDateWithWeekday(date) }}</text>
                <text>{{ item.dailyHours[date] || '-' }}</text>
              </view>
            </view>
          </view>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script lang="ts" setup>
import type { ProjectWorkLogReport } from '@/api/pms/pm/workitem/worklog'
import { reactive, ref } from 'vue'
import { getProjectWorkItemWorkLogReport } from '@/api/pms/pm/workitem/worklog'
import { formatDateWithWeekday } from '@/pages-pms/pm/utils/format'
import { formatDateRange } from '@/utils/date'
import dayjs from 'dayjs'

const props = defineProps<{
  projectId: number
  projectType: number
  editable: boolean
}>()

const dateRange = ref<[number | undefined, number | undefined]>([
  dayjs().startOf('month').valueOf(),
  dayjs().endOf('day').valueOf(),
]) // 日期范围，默认本月初至今天
const queryParams = reactive({
  iterationName: '',
}) // 查询参数
const report = ref<ProjectWorkLogReport>({ dates: [], totalHours: 0, groups: [] }) // 工时统计报表
const expandedIds = ref<Set<number>>(new Set()) // 展开每日明细的工作项编号

/** 查询工时统计报表 */
async function getReport() {
  const createTime = formatDateRange(dateRange.value) as [string, string] | undefined
  if (!createTime) {
    return
  }
  report.value = await getProjectWorkItemWorkLogReport({
    projectId: props.projectId,
    createTime,
    iterationName: queryParams.iterationName || undefined,
  })
}

/** 重置按钮操作 */
function handleReset() {
  queryParams.iterationName = ''
  dateRange.value = [dayjs().startOf('month').valueOf(), dayjs().endOf('day').valueOf()]
  getReport()
}

/** 展开或收起工作项的每日工时 */
function toggleItem(workItemId: number) {
  if (expandedIds.value.has(workItemId)) {
    expandedIds.value.delete(workItemId)
  } else {
    expandedIds.value.add(workItemId)
  }
  expandedIds.value = new Set(expandedIds.value)
}

/** 查看工作项详情 */
function handleWorkItemDetail(workItemId: number) {
  uni.navigateTo({ url: `/pages-pms/pm/workitem/detail/index?id=${workItemId}` })
}

/** 初始化 */
onMounted(() => {
  getReport()
})
</script>
