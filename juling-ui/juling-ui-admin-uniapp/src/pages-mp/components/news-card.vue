<!-- 图文消息卡片：展示一组图文 articles（封面图 + 标题） -->
<template>
  <view class="yd-border-base overflow-hidden border rounded-12rpx bg-white">
    <view
      v-for="(article, index) in safeArticles"
      :key="index"
      class="yd-border-light border-b last:border-b-0 active:opacity-70"
      @click="emit('articleClick', article)"
    >
      <view v-if="index === 0" class="yd-bg-page relative h-260rpx">
        <wd-img
          v-if="getImageUrl(article)"
          :src="getImageUrl(article)"
          width="100%"
          height="260rpx"
          mode="aspectFill"
        />
        <view v-else class="yd-text-hint h-full flex items-center justify-center text-26rpx">
          暂无封面
        </view>
        <view class="absolute bottom-0 left-0 right-0 bg-[rgba(0,0,0,0.55)] px-20rpx py-12rpx text-28rpx text-white">
          {{ article.title || '未命名图文' }}
        </view>
      </view>
      <view v-else class="flex items-center gap-16rpx p-20rpx">
        <view class="yd-text-main min-w-0 flex-1 text-28rpx">
          {{ article.title || '未命名图文' }}
        </view>
        <wd-img
          v-if="getImageUrl(article)"
          :src="getImageUrl(article)"
          width="96rpx"
          height="96rpx"
          radius="8rpx"
          mode="aspectFill"
        />
      </view>
      <view v-if="article.digest" class="yd-text-hint px-20rpx pb-16rpx text-24rpx">
        {{ article.digest }}
      </view>
    </view>
  </view>
</template>

<script lang="ts" setup>
import type { MpArticle } from '@/api/mp/message'
import { computed } from 'vue'

const props = defineProps<{
  articles?: MpArticle[]
}>()

const emit = defineEmits<{
  (e: 'articleClick', article: MpArticle): void
}>()

const safeArticles = computed(() => props.articles || [])

/** 获取图文封面 */
function getImageUrl(article: MpArticle) {
  return article?.picUrl || article?.thumbUrl || article?.thumbMediaUrl || ''
}
</script>
