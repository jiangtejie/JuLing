<template>
  <wd-popup
    v-model="visible"
    position="bottom"
    custom-style="border-radius: 24rpx 24rpx 0 0; height: 50%"
    safe-area-inset-bottom
    @close="visible = false"
  >
    <view class="h-full flex flex-col p-32rpx">
      <!-- 标题 -->
      <view class="mb-32rpx flex items-center justify-between">
        <view class="yd-text-main text-36rpx font-semibold">
          消息详情
        </view>
        <view class="p-8rpx" @click="visible = false">
          <wd-icon name="close" size="20px" color="#999" />
        </view>
      </view>

      <!-- 详情内容 -->
      <view v-if="formData" class="flex flex-1 flex-col overflow-hidden space-y-24rpx">
        <view class="flex items-start">
          <text class="yd-text-hint w-160rpx shrink-0 text-28rpx">发送人</text>
          <text class="yd-text-main text-28rpx">{{ formData.templateNickname }}</text>
        </view>
        <view class="flex items-start">
          <text class="yd-text-hint w-160rpx shrink-0 text-28rpx">发送时间</text>
          <text class="yd-text-main text-28rpx">{{ formatDateTime(formData.createTime) }}</text>
        </view>
        <view class="flex items-start">
          <text class="yd-text-hint w-160rpx shrink-0 text-28rpx">消息类型</text>
          <text class="yd-text-main text-28rpx">
            {{ getDictLabel(DICT_TYPE.SYSTEM_NOTIFY_TEMPLATE_TYPE, formData.templateType) }}
          </text>
        </view>
        <view class="flex items-start">
          <text class="yd-text-hint w-160rpx shrink-0 text-28rpx">是否已读</text>
          <wd-tag v-if="formData.readStatus" type="success" variant="plain">
            已读
          </wd-tag>
          <wd-tag v-else type="warning" variant="plain">
            未读
          </wd-tag>
        </view>
        <view v-if="formData.readStatus" class="flex items-start">
          <text class="yd-text-hint w-160rpx shrink-0 text-28rpx">阅读时间</text>
          <text class="yd-text-main text-28rpx">{{ formatDateTime(formData.readTime) || '-' }}</text>
        </view>
        <view class="flex flex-1 flex-col overflow-hidden">
          <text class="yd-text-hint mb-12rpx w-160rpx shrink-0 text-28rpx">消息内容</text>
          <view class="yd-bg-page flex-1 rounded-12rpx p-24rpx">
            <text class="yd-text-main text-28rpx">{{ formData.templateContent }}</text>
          </view>
        </view>
      </view>
    </view>
  </wd-popup>
</template>

<script lang="ts" setup>
import type { NotifyMessage } from '@/api/system/notify/message'
import { ref } from 'vue'
import { getDictLabel } from '@/hooks/useDict'
import { DICT_TYPE } from '@/utils/constants'
import { formatDateTime } from '@/utils/date'

const visible = ref(false) // 详情弹窗显示状态
const formData = ref<NotifyMessage>() // 详情数据

/** 打开弹窗 */
function open(data: NotifyMessage) {
  formData.value = data
  visible.value = true
}

/** 关闭弹窗 */
function close() {
  visible.value = false
}

defineExpose({ open, close })
</script>
