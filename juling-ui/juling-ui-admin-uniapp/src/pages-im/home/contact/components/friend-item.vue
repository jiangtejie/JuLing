<template>
  <view class="flex items-center gap-20rpx px-24rpx active:bg-[var(--yd-surface-page)]" @click="emit('open', friend)">
    <view class="py-16rpx">
      <ImAvatar :src="friend.avatar" :name="friend.nickname" size="84rpx" :round="false" />
    </view>
    <view class="yd-border-light min-w-0 flex-1 border-b py-16rpx">
      <view class="yd-text-strong line-clamp-1 text-30rpx font-medium">
        {{ friend.displayName || friend.nickname }}
      </view>
      <view class="yd-text-hint line-clamp-1 mt-4rpx text-24rpx">
        昵称：{{ friend.nickname || '-' }}
      </view>
    </view>
  </view>
</template>

<script lang="ts" setup>
import type { FriendLite } from '../../types'
import ImAvatar from '../../components/im-avatar.vue'

defineProps<{
  friend: FriendLite // 好友数据
}>()

const emit = defineEmits<{
  open: [friend: FriendLite] // 打开好友资料
}>()
</script>
