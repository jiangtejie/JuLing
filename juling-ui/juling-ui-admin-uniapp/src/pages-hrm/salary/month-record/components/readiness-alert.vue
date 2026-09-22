<template>
  <view v-if="readiness?.noSalaryGroupEmployeeCount" class="yd-bg-warning-soft mx-24rpx mt-16rpx rounded-8rpx px-16rpx py-16rpx">
    <view class="yd-text-warning text-26rpx">
      有 {{ readiness.noSalaryGroupEmployeeCount }} 名员工未加入任何薪资组，无法参与工资核算。
    </view>
    <view
      class="yd-text-link mt-8rpx text-26rpx"
      @click="openEmployeeList('noSalaryGroup')"
    >
      查看员工
    </view>
  </view>
  <view v-if="readiness?.noSalaryEmployeeCount" class="yd-bg-warning-soft mx-24rpx mt-16rpx rounded-8rpx px-16rpx py-16rpx">
    <view class="yd-text-warning text-26rpx">
      有 {{ readiness.noSalaryEmployeeCount }} 名员工没有生效薪资档案，将优先继承上月工资；无上月工资时按 0 核算。
    </view>
    <view
      class="yd-text-link mt-8rpx text-26rpx"
      @click="openEmployeeList('noSalary')"
    >
      查看员工
    </view>
  </view>

  <wd-popup v-model="listVisible" position="bottom" closable safe-area-inset-bottom>
    <view class="max-h-70vh p-24rpx">
      <view class="yd-text-main mb-24rpx text-32rpx font-semibold">
        {{ listTitle }}
      </view>
      <scroll-view scroll-y class="max-h-60vh">
        <view
          v-for="item in currentEmployees"
          :key="item.employeeId"
          class="yd-bg-subtle mb-16rpx rounded-12rpx p-20rpx"
        >
          <view class="yd-text-main mb-8rpx text-30rpx font-semibold">
            {{ item.employeeName || '-' }}
          </view>
          <view class="yd-text-sub mb-4rpx text-26rpx">
            工号：{{ item.jobNumber || '-' }}
          </view>
          <view class="yd-text-sub mb-4rpx text-26rpx">
            部门：{{ item.deptName || '-' }}
          </view>
          <view class="yd-text-sub mb-4rpx text-26rpx">
            岗位：{{ item.postName || '-' }}
          </view>
          <view class="yd-text-sub text-26rpx">
            入职：{{ formatHrmDate(item.entryTime) }}
          </view>
        </view>
        <view v-if="!currentEmployees.length" class="yd-text-hint py-48rpx text-center text-28rpx">
          暂无员工
        </view>
      </scroll-view>
    </view>
  </wd-popup>
</template>

<script lang="ts" setup>
import type { SalaryPayrollReadiness, SalaryPayrollReadinessEmployee } from '@/api/hrm/salary/month-record'
import { computed, ref, watch } from 'vue'
import { getSalaryPayrollReadiness } from '@/api/hrm/salary/month-record'
import { formatHrmDate } from '@/pages-hrm/utils/format'

const props = defineProps<{
  monthRecordId?: number
}>()

const readiness = ref<SalaryPayrollReadiness>() // 核算准备
const listVisible = ref(false) // 员工列表弹窗
const listType = ref<'noSalaryGroup' | 'noSalary'>('noSalaryGroup') // 当前查看类型

const listTitle = computed(() => { // 弹窗标题
  return listType.value === 'noSalaryGroup' ? '未加入薪资组的员工' : '未设置薪资档案的员工'
})

const currentEmployees = computed<SalaryPayrollReadinessEmployee[]>(() => { // 当前弹窗员工
  if (listType.value === 'noSalaryGroup') {
    return readiness.value?.noSalaryGroupEmployees || []
  }
  return readiness.value?.noSalaryEmployees || []
})

/** 刷新薪资核算准备状态 */
async function refresh() {
  if (!props.monthRecordId) {
    readiness.value = undefined
    return
  }
  readiness.value = await getSalaryPayrollReadiness(props.monthRecordId)
}
defineExpose({ refresh })

/** 打开员工列表 */
function openEmployeeList(type: 'noSalaryGroup' | 'noSalary') {
  listType.value = type
  listVisible.value = true
}

/** 月表切换时刷新 */
watch(
  () => props.monthRecordId,
  () => {
    refresh()
  },
)
</script>
