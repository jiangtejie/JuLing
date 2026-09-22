<template>
  <view class="mt-16rpx bg-white px-24rpx py-20rpx">
    <view class="mb-12rpx flex items-center justify-between">
      <view>
        <view class="yd-text-main text-28rpx font-semibold">
          附加条件组
        </view>
        <view class="yd-text-hint mt-4rpx text-24rpx">
          组间为或，组内为且
        </view>
      </view>
      <wd-button size="small" type="primary" variant="plain" :disabled="groups.length >= MAX_GROUPS" @click="addGroup">
        + 添加组
      </wd-button>
    </view>

    <view v-if="groups.length === 0" class="yd-text-hint yd-bg-subtle rounded-8rpx px-20rpx py-24rpx text-center text-26rpx">
      暂无附加条件
    </view>

    <view v-for="(group, groupIndex) in groups" :key="groupIndex" class="mb-16rpx">
      <view class="yd-border-light border rounded-8rpx bg-white">
        <view class="yd-border-light flex items-center justify-between border-b px-20rpx py-14rpx">
          <view>
            <text class="yd-text-main text-27rpx font-medium">子条件组 {{ groupIndex + 1 }}</text>
            <text class="yd-text-hint ml-12rpx text-24rpx">组内条件为且</text>
          </view>
          <text class="yd-text-danger text-26rpx" @click="removeGroup(groupIndex)">删除组</text>
        </view>
        <view class="p-16rpx">
          <ConditionItem
            v-for="(condition, conditionIndex) in group"
            :key="conditionIndex"
            :condition="condition"
            :product-options="productOptions"
            :index="conditionIndex"
            @update:condition="updateCondition(groupIndex, conditionIndex, $event)"
            @remove="removeCondition(groupIndex, conditionIndex)"
          />
          <wd-button
            v-if="group.length < MAX_CONDITIONS"
            size="small"
            type="primary"
            variant="plain"
            @click="addCondition(groupIndex)"
          >
            + 添加条件
          </wd-button>
        </view>
      </view>
      <view v-if="groupIndex < groups.length - 1" class="yd-text-hint py-12rpx text-center text-24rpx">
        或
      </view>
    </view>
  </view>
</template>

<script lang="ts" setup>
import type { Product } from '@/api/iot/product/product'
import type { TriggerCondition } from '@/api/iot/rule/scene'
import { ref, watch } from 'vue'
import {
  IotRuleSceneTriggerConditionParameterOperatorEnum,
  IotRuleSceneTriggerConditionTypeEnum,
} from '@/utils/constants'
import ConditionItem from './condition-item.vue'

const props = defineProps<{ modelValue?: TriggerCondition[][], productOptions: Product[] }>()
const emit = defineEmits<{ (e: 'update:modelValue', value: TriggerCondition[][]): void }>()

const MAX_GROUPS = 3 // 最大条件组数
const MAX_CONDITIONS = 3 // 每组最大条件数
const groups = ref<TriggerCondition[][]>(cloneGroups(props.modelValue || [])) // 本地条件组

/** 创建默认条件 */
function createCondition(): TriggerCondition {
  return {
    type: IotRuleSceneTriggerConditionTypeEnum.DEVICE_PROPERTY,
    productId: undefined,
    deviceId: undefined,
    identifier: undefined,
    operator: IotRuleSceneTriggerConditionParameterOperatorEnum.EQUALS.value,
    param: '',
  }
}

/** 克隆条件组 */
function cloneGroups(value: TriggerCondition[][]) {
  return value.map(group => group.map(condition => ({ ...condition })))
}

/** 判断条件组是否一致 */
function isSameGroups(left?: TriggerCondition[][], right?: TriggerCondition[][]) {
  return JSON.stringify(left || []) === JSON.stringify(right || [])
}

watch(
  () => props.modelValue,
  (value) => {
    const nextGroups = cloneGroups(value || [])
    if (!isSameGroups(nextGroups, groups.value)) {
      groups.value = nextGroups
    }
  },
  { deep: true },
)

watch(
  groups,
  (value) => {
    const nextGroups = cloneGroups(value)
    if (!isSameGroups(nextGroups, props.modelValue)) {
      emit('update:modelValue', nextGroups)
    }
  },
  { deep: true },
)

/** 添加条件组 */
function addGroup() {
  if (groups.value.length >= MAX_GROUPS) {
    return
  }
  groups.value.push([createCondition()])
}

/** 删除条件组 */
function removeGroup(groupIndex: number) {
  groups.value.splice(groupIndex, 1)
}

/** 添加条件 */
function addCondition(groupIndex: number) {
  const group = groups.value[groupIndex]
  if (group.length >= MAX_CONDITIONS) {
    return
  }
  group.push(createCondition())
}

/** 删除条件 */
function removeCondition(groupIndex: number, conditionIndex: number) {
  groups.value[groupIndex].splice(conditionIndex, 1)
}

/** 更新条件 */
function updateCondition(groupIndex: number, conditionIndex: number, condition: TriggerCondition) {
  groups.value[groupIndex][conditionIndex] = condition
}
</script>
