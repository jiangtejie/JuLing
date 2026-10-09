<template>
  <!-- 搜索框入口 -->
  <view @click="visible = true">
    <wd-search :placeholder="placeholder" hide-cancel disabled />
  </view>

  <!-- 搜索弹窗 -->
  <wd-popup
    v-model="visible"
    position="top"
    :custom-style="getTopPopupStyle()"
    :modal-style="getTopPopupModalStyle()"
    @close="visible = false"
  >
    <view class="yd-search-form-container">
      <view class="yd-search-form-item">
        <view class="yd-search-form-label">
          用户昵称
        </view>
        <wd-input
          v-model="formData.nickname"
          placeholder="请输入用户昵称"
          clearable
        />
      </view>
      <view class="yd-search-form-item">
        <view class="yd-search-form-label">
          手机号
        </view>
        <wd-input
          v-model="formData.mobile"
          placeholder="请输入手机号"
          clearable
        />
      </view>
      <view class="yd-search-form-item">
        <view class="yd-search-form-label">
          邮箱
        </view>
        <wd-input
          v-model="formData.email"
          placeholder="请输入邮箱"
          clearable
        />
      </view>
      <yd-search-date-range v-model="formData.createTime" label="注册时间" />
      <yd-search-date-range v-model="formData.loginDate" label="登录时间" />
      <view class="yd-search-form-actions">
        <wd-button class="flex-1" variant="plain" @click="handleReset">
          重置
        </wd-button>
        <wd-button class="flex-1" type="primary" @click="handleSearch">
          搜索
        </wd-button>
      </view>
    </view>
  </wd-popup>
</template>

<script lang="ts" setup>
import { computed, reactive, ref } from 'vue'
import { getTopPopupModalStyle, getTopPopupStyle } from '@/utils'
import { formatDate, formatDateRange } from '@/utils/date'

const emit = defineEmits<{
  search: [data: Record<string, any>]
  reset: []
}>()

const visible = ref(false) // 搜索弹窗显示状态
const formData = reactive({
  nickname: undefined as string | undefined,
  mobile: undefined as string | undefined,
  email: undefined as string | undefined,
  createTime: [undefined, undefined] as [number | undefined, number | undefined],
  loginDate: [undefined, undefined] as [number | undefined, number | undefined],
}) // 搜索表单数据

/** 搜索条件 placeholder 拼接 */
const placeholder = computed(() => {
  const conditions: string[] = []
  if (formData.nickname) {
    conditions.push(`昵称:${formData.nickname}`)
  }
  if (formData.mobile) {
    conditions.push(`手机号:${formData.mobile}`)
  }
  if (formData.email) {
    conditions.push(`邮箱:${formData.email}`)
  }
  if (formData.createTime[0] && formData.createTime[1]) {
    conditions.push(`注册:${formatDate(formData.createTime[0])}~${formatDate(formData.createTime[1])}`)
  }
  if (formData.loginDate[0] && formData.loginDate[1]) {
    conditions.push(`登录:${formatDate(formData.loginDate[0])}~${formatDate(formData.loginDate[1])}`)
  }
  return conditions.length > 0 ? conditions.join(' | ') : '搜索订货账号'
})

/** 搜索按钮操作 */
function handleSearch() {
  visible.value = false
  emit('search', {
    ...formData,
    createTime: formatDateRange(formData.createTime),
    loginDate: formatDateRange(formData.loginDate),
  })
}

/** 重置按钮操作 */
function handleReset() {
  formData.nickname = undefined
  formData.mobile = undefined
  formData.email = undefined
  formData.createTime = [undefined, undefined]
  formData.loginDate = [undefined, undefined]
  visible.value = false
  emit('reset')
}
</script>
