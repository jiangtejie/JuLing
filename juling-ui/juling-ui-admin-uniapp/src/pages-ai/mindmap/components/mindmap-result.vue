<template>
  <scroll-view scroll-y class="min-h-0 flex-1">
    <view v-if="content || generating" class="p-28rpx">
      <view class="mb-20rpx flex items-center justify-between">
        <view class="flex items-center gap-12rpx">
          <view class="yd-bg-success h-48rpx w-48rpx flex items-center justify-center rounded-14rpx">
            <wd-icon name="share-alt" size="28rpx" color="#fff" />
          </view>
          <text class="yd-text-main text-28rpx font-medium">当前思维导图</text>
        </view>
        <wd-loading v-if="generating" size="30rpx" />
      </view>
      <YdMarkdown v-if="generating" :content="content" />
      <YdMindMap v-else :content="content" />
    </view>
    <view v-else class="h-full flex flex-col items-center justify-center px-64rpx text-center">
      <view class="h-112rpx w-112rpx flex items-center justify-center rounded-32rpx bg-[#f0f9eb]">
        <wd-icon name="share-alt" size="54rpx" color="#52c41a" />
      </view>
      <view class="yd-text-main mt-28rpx text-32rpx font-semibold">
        生成一张思维导图
      </view>
      <view class="yd-text-hint mt-14rpx text-25rpx leading-40rpx">
        输入一个主题，AI 将帮你梳理结构
      </view>
    </view>
  </scroll-view>
</template>

<script lang="ts" setup>
import YdMarkdown from '@/pages-ai/components/yd-markdown/yd-markdown.vue'
import YdMindMap from '@/pages-ai/components/yd-mind-map/yd-mind-map.vue'

defineProps<{
  content: string
  generating: boolean
}>()
</script>
