<template>
  <view class="yd-page-container yd-page-container-paging">
    <!-- 顶部导航栏 -->
    <wd-navbar
      title="支付应用"
      left-arrow placeholder safe-area-inset-top fixed
      @click-left="handleBack"
    />

    <!-- 搜索组件 -->
    <SearchForm @search="handleQuery" @reset="handleReset" />

    <!-- 分页列表 -->
    <z-paging
      ref="pagingRef"
      v-model="list"
      :fixed="false"
      class="min-h-0 flex-1"
      :default-page-size="10"
      :refresher-enabled="true"
      :inside-more="true"
      :loading-more-default-as-loading="true"
      empty-view-text="暂无支付应用数据"
      @query="queryList"
    >
      <view class="p-24rpx">
        <view
          v-for="item in list"
          :key="item.id"
          class="mb-24rpx overflow-hidden rounded-12rpx bg-white p-24rpx shadow-sm"
          @click="handleDetail(item)"
        >
          <view class="mb-16rpx flex items-start justify-between gap-16rpx">
            <view class="min-w-0 flex-1">
              <view class="yd-text-main truncate text-32rpx font-semibold">
                {{ item.name || `应用 #${item.id}` }}
              </view>
              <view v-if="item.appKey" class="yd-text-hint mt-6rpx truncate text-24rpx">
                应用标识：{{ item.appKey }}
              </view>
            </view>
            <dict-tag v-if="item.status != null" :type="DICT_TYPE.COMMON_STATUS" :value="item.status" />
          </view>

          <view class="yd-text-sub mb-12rpx flex items-center text-28rpx">
            <text class="yd-text-hint mr-8rpx shrink-0">商户名称：</text>
            <text class="min-w-0 flex-1 truncate">{{ item.merchantName || '-' }}</text>
          </view>
          <view class="yd-text-sub mb-12rpx flex items-center text-28rpx">
            <text class="yd-text-hint mr-8rpx shrink-0">支付渠道：</text>
            <view class="min-w-0 flex-1">
              <dict-tag v-if="item.channelCodes?.length" :type="DICT_TYPE.PAY_CHANNEL_CODE" :value="item.channelCodes" />
              <text v-else>-</text>
            </view>
          </view>
          <view class="yd-text-sub flex items-center text-28rpx">
            <text class="yd-text-hint mr-8rpx shrink-0">创建时间：</text>
            <text>{{ formatDateTime(item.createTime) || '-' }}</text>
          </view>
        </view>
      </view>
    </z-paging>

    <!-- 新增按钮 -->
    <wd-fab
      v-if="hasAccessByCodes(['pay:app:create'])"
      position="right-bottom"
      type="primary"
      :expandable="false"
      @click="handleAdd"
    />
  </view>
</template>

<script lang="ts" setup>
import type { PayApp } from '@/api/pay/app'
import { onUnload } from '@dcloudio/uni-app'
import { onMounted, ref } from 'vue'
import { getPayAppPage } from '@/api/pay/app'
import { useAccess } from '@/hooks/useAccess'
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

const { hasAccessByCodes } = useAccess()
const list = ref<PayApp[]>([]) // 列表数据
const pagingRef = ref<any>() // 分页组件引用
const queryParams = ref<Record<string, any>>({}) // 查询参数

/** 返回上一页 */
function handleBack() {
  navigateBackPlus()
}

/** 查询支付应用列表 */
async function queryList(pageNo: number, pageSize: number) {
  try {
    const data = await getPayAppPage({ ...queryParams.value, pageNo, pageSize })
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

/** 新增支付应用 */
function handleAdd() {
  uni.navigateTo({ url: '/pages-pay/app/form/index' })
}

/** 查看详情 */
function handleDetail(item: PayApp) {
  uni.navigateTo({ url: `/pages-pay/app/detail/index?id=${item.id}` })
}

/** 初始化 */
onMounted(() => {
  uni.$on('pay:app:reload', reload)
})

/** 卸载 */
onUnload(() => {
  uni.$off('pay:app:reload', reload)
})
</script>
