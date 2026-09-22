<template>
  <scroll-view scroll-y class="min-h-0 flex-1">
    <view v-if="props.imageData" class="p-24rpx">
      <view class="overflow-hidden rounded-24rpx bg-white shadow-[0_12rpx_44rpx_rgba(0,0,0,0.06)]">
        <image
          v-if="props.imageData.picUrl"
          class="yd-bg-subtle h-640rpx w-full"
          :src="props.imageData.picUrl"
          mode="aspectFit"
          @click="handlePreview(props.imageData.picUrl)"
        />
        <view
          v-else
          class="yd-text-hint yd-bg-subtle flex flex-col items-center justify-center gap-18rpx px-32rpx text-26rpx"
          :class="props.imageData.errorMessage ? 'min-h-200rpx py-32rpx' : 'h-540rpx'"
        >
          <wd-loading v-if="!props.imageData.errorMessage" />
          <text class="line-clamp-3 text-center leading-40rpx">{{ props.imageData.errorMessage || '正在创作，请稍候' }}</text>
        </view>
        <view class="p-24rpx">
          <view class="mb-16rpx flex items-center justify-between">
            <dict-tag :type="DICT_TYPE.AI_IMAGE_STATUS" :value="props.imageData.status" />
            <text class="yd-text-hint text-22rpx">{{ formatDateTime(props.imageData.createTime) }}</text>
          </view>
          <view class="yd-text-main text-28rpx">
            {{ props.imageData.prompt || '-' }}
          </view>
          <view class="yd-text-hint mt-16rpx text-24rpx">
            {{ props.imageData.platform || '-' }} / {{ props.imageData.model || '-' }}
          </view>
          <view v-if="props.imageData.buttons?.length" class="mt-18rpx flex flex-wrap gap-12rpx">
            <wd-button
              v-for="button in props.imageData.buttons"
              :key="button.customId"
              size="small"
              variant="plain"
              :loading="props.actionLoadingId === `${props.imageData.id}-${button.customId}`"
              @click="emit('action', props.imageData, button.customId)"
            >
              {{ button.emoji || '' }}{{ button.label || '操作' }}
            </wd-button>
          </view>
        </view>
      </view>
    </view>
    <view v-else class="h-full flex flex-col items-center justify-center px-64rpx text-center">
      <view class="h-112rpx w-112rpx flex items-center justify-center rounded-32rpx bg-[#eeedff]">
        <wd-icon name="image" size="54rpx" color="#615ced" />
      </view>
      <view class="yd-text-main mt-28rpx text-32rpx font-semibold">
        生成一张图片
      </view>
      <view class="yd-text-hint mt-14rpx text-25rpx leading-40rpx">
        输入画面描述，本次生成结果将显示在这里
      </view>
    </view>
  </scroll-view>
</template>

<script lang="ts" setup>
import type { AiImage } from '@/api/ai/image'
import { DICT_TYPE } from '@/utils/constants'
import { formatDateTime } from '@/utils/date'

const props = defineProps<{
  imageData?: AiImage
  actionLoadingId: string
}>()
const emit = defineEmits<{
  action: [item: AiImage, customId: string]
}>()

/** 预览图片 */
function handlePreview(url?: string) {
  if (url) {
    uni.previewImage({ urls: [url] })
  }
}
</script>
