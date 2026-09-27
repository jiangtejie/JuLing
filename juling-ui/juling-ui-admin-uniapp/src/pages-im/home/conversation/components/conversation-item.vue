<template>
  <view
    class="conversation-row"
    :class="conversation.top ? 'is-top' : ''"
    @click="openChat"
    @longpress="emit('longpress', conversation)"
  >
    <view class="relative py-22rpx">
      <GroupAvatar
        v-if="isGroup"
        :group-id="conversation.targetId"
        :src="conversation.avatar"
        :name="conversation.name"
        size="96rpx"
      />
      <ImAvatar v-else :src="conversation.avatar" :name="conversation.name" :round="false" size="96rpx" />
      <view
        v-if="conversation.unreadCount > 0"
        class="unread-badge"
        :class="conversation.silent ? 'is-dot' : ''"
      >
        {{ conversation.silent ? '' : conversation.unreadCount > 99 ? '99+' : conversation.unreadCount }}
      </view>
    </view>
    <view class="conversation-content">
      <view class="min-w-0 flex items-center justify-between">
        <view class="min-w-0 flex flex-1 items-center gap-8rpx">
          <text class="conversation-name">{{ conversation.name || '未命名' }}</text>
          <text v-if="isGroup" class="group-tag">群</text>
        </view>
        <text class="conversation-time">{{ formatConversationTime(conversation.lastSendTime) }}</text>
      </view>
      <view class="mt-7rpx flex items-center gap-8rpx">
        <view class="yd-text-hint line-clamp-1 min-w-0 flex-1 text-27rpx">
          <text v-if="groupRequestText" class="yd-text-danger">{{ groupRequestText }} </text>
          <text v-if="hasDraft" class="yd-text-danger">[草稿] </text>
          <template v-else>
            <text v-if="conversation.atMe" class="yd-text-danger">[有人@我] </text>
            <text v-else-if="conversation.atAll" class="yd-text-danger">[@全体成员] </text>
            <text v-if="mutedUnreadText">{{ mutedUnreadText }} </text>
            <text v-if="lastSenderText">{{ lastSenderText }}: </text>
          </template>
          <text v-if="hasDraft && mutedUnreadText">{{ mutedUnreadText }} </text>{{ contentText || ' ' }}
        </view>
        <wd-icon v-if="conversation.silent" name="notification-close" size="27rpx" color="#b2b2b2" />
      </view>
    </view>
  </view>
</template>

<script lang="ts" setup>
import type { ConversationDO } from '@/pages-im/utils/db'
import { computed } from 'vue'
import { buildConversationMessageUrl } from '@/pages-im/utils/conversation'
import { ImConversationType, ImMessageType, isNormalMessage } from '@/pages-im/utils/constants'
import { formatConversationTime } from '@/pages-im/utils/time'
import { getFriendDisplayName, getMemberDisplayName } from '@/pages-im/utils/user'
import { useUserStore } from '@/store/user'
import { useFriendStore } from '../../store/friendStore'
import { useGroupRequestStore } from '../../store/groupRequestStore'
import { useGroupStore } from '../../store/groupStore'
import ImAvatar from '../../components/im-avatar.vue'
import GroupAvatar from '../../components/group-avatar.vue'

const props = defineProps<{
  conversation: ConversationDO // 当前会话
}>()

const emit = defineEmits<{
  longpress: [conversation: ConversationDO] // 长按当前会话
}>()

const friendStore = useFriendStore()
const groupStore = useGroupStore()
const groupRequestStore = useGroupRequestStore()
const userStore = useUserStore()
const hasDraft = computed(() => !!props.conversation.draft
  && (!!props.conversation.draft.plain.trim() || !!props.conversation.draft.reply)) // 是否存在会话草稿
const isGroup = computed(() => props.conversation.type === ImConversationType.GROUP) // 是否群聊
const mutedUnreadText = computed(() => { // 免打扰会话未读条数
  if (!props.conversation.silent || props.conversation.unreadCount <= 0) {
    return ''
  }
  const count = props.conversation.unreadCount > 99 ? '99+' : props.conversation.unreadCount
  return `[${count}条]`
})

/** 获取会话发送人名称 */
function getSenderName() {
  const senderId = props.conversation.lastSenderId
  if (!senderId) {
    return ''
  }
  if (senderId === userStore.userInfo.userId) {
    return '我'
  }
  const member = (groupStore.getGroup(props.conversation.targetId)?.members || [])
    .find(candidate => candidate.userId === senderId)
  if (member) {
    return getMemberDisplayName(member, friendStore.getFriend(senderId))
  }
  const friend = friendStore.getFriend(senderId)
  return friend
    ? getFriendDisplayName(friend)
    : props.conversation.lastSenderDisplayName || `用户 ${senderId}`
}

const groupRequestText = computed(() => { // 群聊未处理申请提示
  if (props.conversation.type !== ImConversationType.GROUP) {
    return ''
  }
  const count = groupRequestStore.getUnhandledGroupRequestCount(props.conversation.targetId)
  return count > 0 ? `[${count}条进群申请]` : ''
})
const lastSenderText = computed(() => { // 群聊最后发送人前缀
  if (props.conversation.type !== ImConversationType.GROUP
    || !props.conversation.lastSenderId
    || props.conversation.lastMessageType == null
    || !isNormalMessage(props.conversation.lastMessageType)) {
    return ''
  }
  return getSenderName()
})
const contentText = computed(() => { // 会话摘要文案
  if (hasDraft.value) {
    return props.conversation.draft?.plain
  }
  if (props.conversation.lastMessageType === ImMessageType.RECALL) {
    return props.conversation.lastSelfSend
      ? '你撤回了一条消息'
      : `${getSenderName() || '对方'} 撤回了一条消息`
  }
  return props.conversation.lastContent
})

/** 打开会话 */
function openChat() {
  uni.navigateTo({
    url: buildConversationMessageUrl({
      type: props.conversation.type,
      targetId: props.conversation.targetId,
      mentionMessageId: props.conversation.atMessageId || props.conversation.atAllMessageId,
    }),
  })
}
</script>

<style lang="scss" scoped>
.conversation-row {
  display: flex;
  align-items: center;
  gap: 22rpx;
  padding-left: 28rpx;
  background: var(--yd-surface-card);

  &:active {
    background: var(--yd-surface-page);
  }

  &.is-top {
    background: var(--yd-surface-page);
  }
}

.conversation-content {
  min-width: 0;
  flex: 1;
  padding: 22rpx 28rpx 22rpx 0;
  border-bottom: 1rpx solid var(--yd-border-light);
}

.conversation-name {
  min-width: 0;
  flex: 1;
  overflow: hidden;
  color: var(--yd-text-strong);
  font-size: 34rpx;
  font-weight: 400;
  line-height: 44rpx;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.group-tag {
  flex-shrink: 0;
  padding: 0 7rpx;
  border: 1rpx solid var(--yd-text-link);
  border-radius: 5rpx;
  color: var(--yd-text-link);
  font-size: 20rpx;
  line-height: 28rpx;
}

.conversation-time {
  flex-shrink: 0;
  margin-left: 16rpx;
  color: var(--yd-text-muted);
  font-size: 23rpx;
  line-height: 34rpx;
}

.unread-badge {
  position: absolute;
  top: 13rpx;
  right: -8rpx;
  min-width: 34rpx;
  height: 34rpx;
  padding: 0 7rpx;
  border: 2rpx solid var(--yd-surface-card);
  border-radius: 18rpx;
  background: var(--yd-danger-bright);
  color: var(--yd-text-inverse);
  font-size: 20rpx;
  line-height: 30rpx;
  text-align: center;
  box-sizing: border-box;

  &.is-dot {
    top: 16rpx;
    right: -2rpx;
    min-width: 18rpx;
    width: 18rpx;
    height: 18rpx;
    padding: 0;
    border-radius: 50%;
  }
}
</style>
