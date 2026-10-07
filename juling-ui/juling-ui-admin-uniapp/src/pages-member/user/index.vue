<template>
  <view class="yd-page-container yd-page-container-paging">
    <!-- 顶部导航栏 -->
    <wd-navbar
      title="订货账号"
      left-arrow placeholder safe-area-inset-top fixed
      @click-left="handleBack"
    />

    <!-- 搜索组件 -->
    <SearchForm @search="handleQuery" @reset="handleReset" />

    <!-- 账号列表 -->
    <z-paging
      ref="pagingRef"
      v-model="list"
      :fixed="false"
      class="min-h-0 flex-1"
      :default-page-size="10"
      :refresher-enabled="true"
      :inside-more="true"
      :loading-more-default-as-loading="true"
      empty-view-text="暂无订货账号数据"
      @query="queryList"
    >
      <view class="p-24rpx">
        <view
          v-for="item in list"
          :key="item.id"
          class="mb-24rpx overflow-hidden rounded-12rpx bg-white shadow-sm"
          @click="handleCardClick(item)"
        >
          <view class="p-24rpx">
            <view class="mb-20rpx flex items-start justify-between gap-16rpx">
              <view class="min-w-0 flex flex-1 items-center gap-16rpx">
                <wd-img
                  v-if="item.avatar"
                  :src="item.avatar"
                  :width="44"
                  :height="44"
                  mode="aspectFill"
                  round
                />
                <view
                  v-else
                  class="yd-bg-primary h-88rpx w-88rpx flex shrink-0 items-center justify-center rounded-full text-34rpx text-white"
                >
                  {{ (item.nickname || item.mobile || '订').charAt(0) }}
                </view>
                <view class="min-w-0 flex-1">
                  <view class="yd-text-main truncate text-32rpx font-semibold">
                    {{ item.nickname || item.name || item.mobile || '-' }}
                  </view>
                  <view class="yd-text-hint mt-4rpx text-24rpx">
                    {{ item.mobile || '未绑定手机号' }}
                  </view>
                </view>
              </view>
              <dict-tag :type="DICT_TYPE.COMMON_STATUS" :value="item.status" />
            </view>
            <view class="yd-text-hint flex items-center justify-between text-24rpx">
              <text>注册：{{ formatDateTime(item.createTime) || '-' }}</text>
              <text>登录：{{ formatDateTime(item.loginDate) || '-' }}</text>
            </view>
          </view>
        </view>
      </view>
    </z-paging>
  </view>
</template>

<script lang="ts" setup>
import type { MemberUser } from '@/api/member/user'
import { onUnload } from '@dcloudio/uni-app'
import { useToast } from '@wot-ui/ui/components/wd-toast'
import { onMounted, ref } from 'vue'
import { getMemberUserPage } from '@/api/member/user'
import { navigateBackPlus } from '@/utils'
import { DICT_TYPE } from '@/utils/constants'
import { formatDateTime } from '@/utils/date'
import SearchForm from './components/search-form.vue'

definePage({
  style: {
    navigationBarTitleText: '',
    navigationStyle: 'custom',
  },
})

const toast = useToast()
const list = ref<MemberUser[]>([]) // 列表数据
const pagingRef = ref<any>() // 分页组件引用
const queryParams = ref<Record<string, any>>({}) // 查询参数

/** 返回上一页 */
function handleBack() {
  navigateBackPlus()
}

/** 查询订货账号列表 */
async function queryList(pageNo: number, pageSize: number) {
  try {
    const data = await getMemberUserPage({
      ...queryParams.value,
      pageNo,
      pageSize,
    })
    pagingRef.value?.completeByTotal(data.list, data.total)
  } catch {
    pagingRef.value?.complete(false)
  }
}

/** 搜索按钮操作 */
function handleQuery(data?: Record<string, any>) {
  queryParams.value = { ...data }
  reload()
}

/** 重置按钮操作 */
function handleReset() {
  handleQuery()
}

/** 重新加载 */
function reload() {
  pagingRef.value?.reload()
}

/** 查看详情 */
function handleDetail(item: MemberUser) {
  uni.navigateTo({
    url: `/pages-member/user/detail/index?id=${item.id}`,
  })
}

/** 点击账号卡片 */
function handleCardClick(item: MemberUser) {
  handleDetail(item)
}

/** 初始化 */
onMounted(() => {
  uni.$on('member:user:reload', reload)
})

/** 卸载 */
onUnload(() => {
  uni.$off('member:user:reload', reload)
})
</script>
