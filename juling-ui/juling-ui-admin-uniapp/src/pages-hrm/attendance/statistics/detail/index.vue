<template>
  <view class="yd-page-container">
    <!-- 顶部导航栏 -->
    <wd-navbar
      title="月度汇总详情"
      left-arrow placeholder safe-area-inset-top fixed
      @click-left="handleBack"
    />

    <!-- 头部摘要 -->
    <view v-if="summary.employeeId" class="bg-white px-24rpx py-24rpx">
      <view class="mb-16rpx flex items-start justify-between gap-16rpx">
        <view class="yd-text-main min-w-0 flex-1 truncate text-36rpx font-semibold">
          {{ summary.employeeName || '-' }}
        </view>
        <view
          class="shrink-0 rounded-8rpx px-12rpx py-4rpx text-22rpx"
          :class="summary.fullAttendance ? 'yd-bg-success-soft yd-text-success' : 'yd-bg-warning-soft yd-text-warning'"
        >
          {{ summary.fullAttendance ? '全勤' : '非全勤' }}
        </view>
      </view>
      <view class="yd-text-sub text-26rpx">
        {{ summary.jobNumber || '-' }} · {{ summary.deptName || '-' }} · {{ summary.postName || '-' }}
      </view>
      <view class="yd-text-sub mt-8rpx text-26rpx">
        {{ yearMonthText }} · 应出勤 {{ summary.attendDays ?? 0 }} 天 · 实出勤 {{ formatHrmDays(summary.actualDays) }} 天
      </view>
    </view>

    <!-- 详情分类 -->
    <view class="bg-white">
      <wd-tabs v-model="tabIndex" slidable="always">
        <wd-tab v-for="tab in tabs" :key="tab.key" :title="tab.title" />
      </wd-tabs>
    </view>

    <!-- 汇总信息 -->
    <view v-if="activeTab === 'summary'" class="pb-48rpx">
      <wd-cell-group border>
        <wd-cell title="员工" :value="summary.employeeName || '-'" />
        <wd-cell title="工号" :value="summary.jobNumber || '-'" />
        <wd-cell title="部门" :value="summary.deptName || '-'" />
        <wd-cell title="岗位" :value="summary.postName || '-'" />
        <wd-cell title="考勤组" :value="summary.attendanceGroupName || '-'" />
        <wd-cell title="入职时间" :value="formatDateTime(summary.entryTime) || '-'" />
        <wd-cell title="员工状态">
          <dict-tag
            v-if="summary.employeeStatus != null"
            :type="DICT_TYPE.HRM_EMPLOYEE_STATUS"
            :value="summary.employeeStatus"
          />
          <text v-else>-</text>
        </wd-cell>
        <wd-cell title="工作城市" :value="summary.workCity || '-'" />
        <wd-cell title="月份" :value="yearMonthText" />
        <wd-cell title="应出勤" :value="`${summary.attendDays ?? 0} 天`" />
        <wd-cell title="实际出勤" :value="`${formatHrmDays(summary.actualDays)} 天`" />
        <wd-cell title="是否全勤" :value="summary.fullAttendance ? '是' : '否'" />
        <wd-cell title="迟到" :value="`${summary.lateCount ?? 0} 次 / ${summary.lateMinute ?? 0} 分钟`" />
        <wd-cell title="早退" :value="`${summary.earlyCount ?? 0} 次 / ${summary.earlyMinute ?? 0} 分钟`" />
        <wd-cell title="缺卡" :value="`${summary.misscardCount ?? 0} 次`" />
        <wd-cell title="旷工" :value="`${formatHrmDays(summary.absenteeismDays)} 天`" />
        <wd-cell title="请假" :value="`${formatHrmDays(summary.leaveDays)} 天`" />
        <wd-cell title="考勤扣款" :value="`${formatHrmMoney(summary.attendanceDeductAmount)} 元`" />
      </wd-cell-group>
    </view>

    <!-- 每日明细 -->
    <view v-else-if="activeTab === 'daily'" class="pb-48rpx">
      <view class="bg-white px-24rpx py-16rpx">
        <scroll-view scroll-x class="whitespace-nowrap">
          <view
            v-for="item in dailyStatusOptions"
            :key="item.value"
            class="mr-16rpx inline-flex rounded-full px-24rpx py-10rpx text-24rpx"
            :class="dailyStatusFilter === item.value
              ? 'yd-bg-primary text-white'
              : 'yd-bg-page yd-text-sub'"
            @click="dailyStatusFilter = item.value"
          >
            {{ item.label }}
          </view>
        </scroll-view>
      </view>
      <view v-if="filteredDailyDetails.length === 0" class="yd-text-hint py-80rpx text-center text-28rpx">
        暂无每日明细
      </view>
      <view v-else class="p-24rpx">
        <view
          v-for="item in filteredDailyDetails"
          :key="String(item.attendanceTime)"
          class="mb-24rpx rounded-12rpx bg-white p-24rpx shadow-sm"
        >
          <view class="mb-16rpx flex items-start justify-between gap-16rpx">
            <view class="yd-text-main min-w-0 flex-1 text-30rpx font-semibold">
              {{ formatDate(item.attendanceTime) || '-' }}
            </view>
            <view
              v-if="item.attendanceResult"
              class="shrink-0 rounded-8rpx px-12rpx py-4rpx text-22rpx"
              :class="getAttendanceResultClass(item.attendanceResult)"
            >
              {{ item.attendanceResult }}
            </view>
          </view>
          <view class="yd-text-sub mb-12rpx text-26rpx">
            <text class="yd-text-hint mr-8rpx">班次：</text>{{ item.shiftName || '未排班' }}
          </view>
          <view
            v-for="clock in item.clockList || []"
            :key="clock.id || String(clock.clockTime)"
            class="yd-text-sub mb-8rpx flex items-center gap-12rpx text-26rpx"
          >
            <dict-tag
              v-if="clock.type != null"
              :type="DICT_TYPE.HRM_ATTENDANCE_CLOCK_TYPE"
              :value="clock.type"
            />
            <text class="flex-1 text-right">
              {{ formatDate(clock.clockTime, 'HH:mm') || '-' }}
            </text>
            <dict-tag
              v-if="clock.status != null"
              :type="DICT_TYPE.HRM_ATTENDANCE_CLOCK_STATUS"
              :value="clock.status"
            />
          </view>
          <view v-if="item.leaveMinutes" class="yd-text-link mt-8rpx text-26rpx">
            请假 {{ formatHrmDays(item.leaveDays) }} 天
          </view>
        </view>
      </view>
    </view>

    <!-- 请假记录 -->
    <view v-else-if="activeTab === 'leave'" class="pb-48rpx">
      <view class="bg-white px-24rpx py-16rpx">
        <scroll-view scroll-x class="whitespace-nowrap">
          <view
            v-for="item in leaveTypeOptions"
            :key="item.value"
            class="mr-16rpx inline-flex rounded-full px-24rpx py-10rpx text-24rpx"
            :class="leaveTypeFilter === item.value
              ? 'yd-bg-primary text-white'
              : 'yd-bg-page yd-text-sub'"
            @click="leaveTypeFilter = item.value"
          >
            {{ item.label }}
          </view>
        </scroll-view>
      </view>
      <view v-if="filteredLeaveList.length === 0" class="yd-text-hint py-80rpx text-center text-28rpx">
        暂无请假记录
      </view>
      <view v-else class="p-24rpx">
        <view
          v-for="item in filteredLeaveList"
          :key="item.id || `${item.type}-${item.startTime}`"
          class="mb-24rpx rounded-12rpx bg-white p-24rpx shadow-sm"
        >
          <view class="mb-12rpx flex items-center gap-12rpx">
            <dict-tag
              v-if="item.type"
              :type="DICT_TYPE.HRM_ATTENDANCE_LEAVE_TYPE"
              :value="item.type"
            />
            <text v-else class="yd-text-main text-28rpx">-</text>
          </view>
          <view class="yd-text-sub mb-8rpx text-26rpx">
            <text class="yd-text-hint mr-8rpx">开始：</text>{{ formatDateTime(item.startTime) || '-' }}
          </view>
          <view class="yd-text-sub mb-8rpx text-26rpx">
            <text class="yd-text-hint mr-8rpx">结束：</text>{{ formatDateTime(item.endTime) || '-' }}
          </view>
          <view class="yd-text-sub mb-8rpx text-26rpx">
            <text class="yd-text-hint mr-8rpx">时长：</text>{{ formatHrmDays(item.day) }} 天
          </view>
          <view v-if="item.reason" class="yd-text-sub text-26rpx">
            <text class="yd-text-hint mr-8rpx">事由：</text>{{ item.reason }}
          </view>
        </view>
      </view>
    </view>
  </view>
</template>

<script lang="ts" setup>
import type { AttendanceDailyDetail, AttendanceMonthDetail, AttendanceMonthRecord } from '@/api/hrm/attendance/statistics'
import type { AttendanceLeave } from '@/api/hrm/attendance/leave'
import { onShow } from '@dcloudio/uni-app'
import { computed, ref } from 'vue'
import { getAttendanceMonthDetail } from '@/api/hrm/attendance/statistics'
import { getStrDictOptions } from '@/hooks/useDict'
import { formatHrmDays, formatHrmMoney } from '@/pages-hrm/utils/format'
import { navigateBackPlus } from '@/utils'
import { DICT_TYPE } from '@/utils/constants'
import { formatDate, formatDateTime } from '@/utils/date'

const props = defineProps<{
  employeeId?: number | any
  year?: number | any
  month?: number | any
}>()

definePage({
  style: {
    navigationBarTitleText: '',
    navigationStyle: 'custom',
  },
})

const detail = ref<AttendanceMonthDetail>() // 月度考勤详情
const tabIndex = ref(0) // 当前 tab
const dailyStatusFilter = ref('all') // 每日考勤状态筛选
const leaveTypeFilter = ref('all') // 请假类型筛选
const tabs = [ // tab 配置
  { key: 'summary', title: '汇总信息' },
  { key: 'daily', title: '每日明细' },
  { key: 'leave', title: '请假记录' },
]
const dailyStatusOptions = [ // 每日状态筛选
  { label: '全部', value: 'all' },
  { label: '实际出勤', value: 'attendance' },
  { label: '迟到', value: 'late' },
  { label: '早退', value: 'early' },
  { label: '旷工', value: 'absenteeism' },
  { label: '缺卡', value: 'misscard' },
] as const
const leaveTypeOptions = computed(() => [ // 请假类型筛选
  { label: '全部', value: 'all' },
  ...getStrDictOptions(DICT_TYPE.HRM_ATTENDANCE_LEAVE_TYPE).map(item => ({
    label: item.label,
    value: item.value,
  })),
])

const activeTab = computed(() => tabs[tabIndex.value]?.key || 'summary')
const summary = computed<Partial<AttendanceMonthRecord>>(() => detail.value?.summary || {})
const yearMonthText = computed(() => {
  const year = Number(props.year)
  const month = Number(props.month)
  if (!year || !month) {
    return '-'
  }
  return `${year}-${String(month).padStart(2, '0')}`
})
const filteredDailyDetails = computed(() =>
  (detail.value?.dailyDetails || []).filter(item => isDailyDetailVisible(item)),
)
const filteredLeaveList = computed(() =>
  (detail.value?.leaves || []).filter(
    (item: AttendanceLeave) => leaveTypeFilter.value === 'all' || item.type === leaveTypeFilter.value,
  ),
)

/** 返回上一页 */
function handleBack() {
  navigateBackPlus('/pages-hrm/attendance/statistics/index')
}

/** 判断每日考勤明细是否符合筛选条件 */
function isDailyDetailVisible(item: AttendanceDailyDetail) {
  switch (dailyStatusFilter.value) {
    case 'attendance':
      return (item.clockList?.length || 0) > 0
    case 'late':
      return item.lateCount > 0
    case 'early':
      return item.earlyCount > 0
    case 'absenteeism':
      return item.absenteeism === true
    case 'misscard':
      return (item.misscardCount || 0) > 0
    default:
      return true
  }
}

/** 获得考勤结果样式 */
function getAttendanceResultClass(result?: string) {
  if (result === '正常') {
    return 'yd-bg-success-soft yd-text-success'
  }
  if (result?.includes('旷工')) {
    return 'yd-bg-danger-soft yd-text-danger'
  }
  if (result?.includes('缺卡') || result?.includes('迟到') || result?.includes('早退')) {
    return 'yd-bg-warning-soft yd-text-warning'
  }
  return 'yd-bg-page yd-text-sub'
}

/** 加载月度考勤详情 */
async function getDetail() {
  if (!props.employeeId || !props.year || !props.month) {
    return
  }
  detail.value = await getAttendanceMonthDetail({
    employeeId: Number(props.employeeId),
    year: Number(props.year),
    month: Number(props.month),
  })
}

/** 初始化 */
onShow(() => {
  getDetail()
})
</script>
