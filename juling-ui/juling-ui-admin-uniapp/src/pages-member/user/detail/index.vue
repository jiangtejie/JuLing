<template>
  <view
    class="yd-page-container"
    :class="{
      'yd-page-container-paging': isPagingTab,
      'pb-[140rpx]': !isPagingTab,
    }"
  >
    <!-- 顶部导航栏 -->
    <wd-navbar
      title="订货账号详情"
      left-arrow placeholder safe-area-inset-top fixed
      @click-left="handleBack"
    />

    <!-- 详情分类 -->
    <view class="bg-white">
      <wd-tabs v-model="tabIndex" slidable="always">
        <wd-tab v-for="tab in tabs" :key="tab.key" :title="tab.title" />
      </wd-tabs>
    </view>

    <!-- 基本信息 -->
    <template v-if="activeTab === 'basic'">
      <!-- 账号概览 -->
      <view class="bg-white p-24rpx">
        <view class="mb-24rpx flex items-center gap-20rpx">
          <wd-img
            v-if="formData?.avatar"
            :src="formData.avatar"
            :width="56"
            :height="56"
            mode="aspectFill"
            round
          />
          <view
            v-else
            class="yd-bg-primary h-112rpx w-112rpx flex items-center justify-center rounded-full text-40rpx text-white"
          >
            {{ (formData?.nickname || formData?.mobile || '订').charAt(0) }}
          </view>
          <view class="min-w-0 flex-1">
            <view class="yd-text-main truncate text-36rpx font-semibold">
              {{ formData?.nickname || formData?.name || '-' }}
            </view>
            <view class="yd-text-hint mt-8rpx text-26rpx">
              {{ formData?.mobile || '未绑定手机号' }}
            </view>
          </view>
          <dict-tag v-if="formData?.status != null" :type="DICT_TYPE.COMMON_STATUS" :value="formData?.status" />
          <text v-else class="yd-text-hint text-26rpx">-</text>
        </view>
      </view>

      <!-- 基础字段 -->
      <wd-cell-group border>
        <wd-cell title="真实姓名" :value="formData?.name || '-'" />
        <wd-cell title="邮箱" :value="formData?.email || '-'" />
        <wd-cell title="性别">
          <dict-tag v-if="formData?.sex != null" :type="DICT_TYPE.SYSTEM_USER_SEX" :value="formData?.sex" />
          <text v-else>-</text>
        </wd-cell>
        <wd-cell title="所在地" :value="formData?.areaName || '-'" />
        <wd-cell title="注册 IP" :value="formData?.registerIp || '-'" />
        <wd-cell title="最后登录 IP" :value="formData?.loginIp || '-'" />
        <wd-cell title="生日" :value="formatDate(formData?.birthday) || '-'" />
        <wd-cell title="注册时间" :value="formatDateTime(formData?.createTime) || '-'" />
        <wd-cell title="最后登录时间" :value="formatDateTime(formData?.loginDate) || '-'" />
        <wd-cell title="备注" :value="formData?.mark || '-'" />
      </wd-cell-group>
    </template>

    <!-- 明细列表 -->
    <OrderList v-if="loadedTabs.has('order')" v-show="activeTab === 'order'" class="min-h-0 flex-1" :user-id="props.id" />
    <AfterSaleList v-if="loadedTabs.has('after-sale')" v-show="activeTab === 'after-sale'" class="min-h-0 flex-1" :user-id="props.id" />
    <FavoriteList v-if="loadedTabs.has('favorite')" v-show="activeTab === 'favorite'" class="min-h-0 flex-1" :user-id="props.id" />

    <!-- 底部操作按钮 -->
    <view class="yd-detail-footer">
      <view class="yd-detail-footer-actions">
        <wd-button
          v-if="hasAccessByCodes(['member:user:update'])"
          class="flex-1" type="warning" @click="handleEdit"
        >
          编辑
        </wd-button>
      </view>
    </view>
  </view>
</template>

<script lang="ts" setup>
import type { MemberUser } from '@/api/member/user'
import { onUnload } from '@dcloudio/uni-app'
import { useToast } from '@wot-ui/ui/components/wd-toast'
import { computed, onMounted, ref, watch } from 'vue'
import { getMemberUser } from '@/api/member/user'
import { useAccess } from '@/hooks/useAccess'
import { navigateBackPlus } from '@/utils'
import { DICT_TYPE } from '@/utils/constants'
import { formatDate, formatDateTime } from '@/utils/date'
import AfterSaleList from './components/after-sale-list.vue'
import FavoriteList from './components/favorite-list.vue'
import OrderList from './components/order-list.vue'

const props = defineProps<{
  id?: number | any
}>()

definePage({
  style: {
    navigationBarTitleText: '',
    navigationStyle: 'custom',
  },
})

// 详情分类：只保留后端仍在的功能。
// 积分 / 签到 / 成长值 / 收货地址 / 优惠券 / 会员等级 随会员中心一并下线（后端菜单与接口均已删除），
// 对应的 tab、组件与「更多操作」里的修改入口同步移除。
const tabs: { key: string, title: string }[] = [
  { key: 'basic', title: '基本信息' },
  { key: 'order', title: '订单管理' },
  { key: 'after-sale', title: '售后管理' },
  { key: 'favorite', title: '收藏记录' },
]
const { hasAccessByCodes } = useAccess()
const toast = useToast()
const formData = ref<MemberUser>() // 详情数据
const tabIndex = ref(0) // 当前详情分类下标
const loadedTabs = ref(new Set<string>(['basic'])) // 已加载过的分类；懒加载，避免打开详情即并发全部列表请求
const activeTab = computed(() => tabs[tabIndex.value]?.key || 'basic') // 当前详情分类
const isPagingTab = computed(() => activeTab.value !== 'basic') // 分页详情分类使用固定高布局

/** 切换详情分类时记录已加载分类，实现懒加载 */
watch(activeTab, value => loadedTabs.value.add(value))

/** 返回上一页 */
function handleBack() {
  navigateBackPlus('/pages-member/user/index')
}

/** 加载账号详情 */
async function getDetail() {
  if (!props.id) {
    return
  }
  try {
    toast.loading('加载中...')
    formData.value = await getMemberUser(Number(props.id))
  } finally {
    toast.close()
  }
}

/** 编辑账号 */
function handleEdit() {
  uni.navigateTo({
    url: `/pages-member/user/form/index?id=${props.id}`,
  })
}

/** 初始化 */
onMounted(() => {
  uni.$on('member:user:reload', getDetail)
  getDetail()
})

/** 卸载 */
onUnload(() => {
  uni.$off('member:user:reload', getDetail)
})
</script>
