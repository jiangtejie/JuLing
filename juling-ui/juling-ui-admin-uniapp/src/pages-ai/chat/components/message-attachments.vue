<template>
  <view v-if="urls?.length" class="mt-20rpx flex flex-col gap-12rpx">
    <view
      v-for="url in urls"
      :key="url"
      class="yd-bg-page flex items-center gap-14rpx rounded-16rpx px-18rpx py-16rpx active:bg-[#eee]"
      @click="openAttachment(url)"
    >
      <view class="yd-bg-info-soft h-56rpx w-56rpx flex shrink-0 items-center justify-center rounded-12rpx">
        <wd-icon name="file" size="32rpx" color="#1677ff" />
      </view>
      <view class="min-w-0 flex-1">
        <view class="yd-text-main truncate text-25rpx font-medium">
          {{ getFileNameFromUrl(url) || '附件' }}
        </view>
        <view class="yd-text-hint mt-4rpx text-21rpx">
          点击预览
        </view>
      </view>
      <wd-icon name="arrow-right" size="28rpx" color="#bbb" />
    </view>
  </view>
</template>

<script lang="ts" setup>
import { getFileNameFromUrl, openAttachment } from '@/utils/download'

defineProps<{
  urls?: string[]
}>()
</script>
