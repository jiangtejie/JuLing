<template>
  <view class="yd-page-container yd-page-container-paging">
    <!-- 顶部导航栏 -->
    <wd-navbar title="库存明细" left-arrow placeholder safe-area-inset-top fixed @click-left="handleBack" />

    <!-- 搜索组件 -->
    <SearchForm @search="handleQuery" @reset="handleReset" />

    <!-- 库存明细列表 -->
    <z-paging ref="pagingRef" v-model="list" :fixed="false" class="min-h-0 flex-1" :default-page-size="10" :refresher-enabled="true" :inside-more="true" :loading-more-default-as-loading="true" empty-view-text="暂无库存明细数据" @query="queryList">
      <view class="p-24rpx">
        <view v-for="item in list" :key="item.id" class="mb-24rpx overflow-hidden rounded-12rpx bg-white shadow-sm" @click="handleDetail(item)">
          <view class="p-24rpx">
            <view class="mb-16rpx flex items-start justify-between gap-16rpx">
              <view class="yd-text-main min-w-0 flex-1 truncate text-32rpx font-semibold">
                {{ item.productName || '-' }}
              </view>
              <dict-tag :type="DICT_TYPE.ERP_STOCK_RECORD_BIZ_TYPE" :value="item.bizType" />
            </view>
            <view class="yd-text-sub grid grid-cols-2 mb-12rpx gap-12rpx text-28rpx">
              <view>
                <text class="yd-text-hint">分类：</text>{{ item.categoryName || '-' }}
              </view>
              <view>
                <text class="yd-text-hint">单位：</text>{{ item.unitName || '-' }}
              </view>
            </view>
            <view class="yd-text-sub mb-12rpx text-28rpx">
              <text class="yd-text-hint mr-8rpx">仓库：</text>{{ item.warehouseName || '-' }}
            </view>
            <view class="yd-text-sub mb-12rpx text-28rpx">
              <text class="yd-text-hint mr-8rpx">业务单号：</text>{{ item.bizNo || '-' }}
            </view>
            <view class="yd-bg-subtle grid grid-cols-2 mb-16rpx gap-12rpx rounded-12rpx p-16rpx text-center">
              <view>
                <view class="yd-text-hint text-22rpx">
                  出入库数量
                </view>
                <view class="mt-4rpx text-30rpx font-semibold" :class="getCountClass(item.count)">
                  {{ formatCount(item.count) }}
                </view>
              </view>
              <view>
                <view class="yd-text-hint text-22rpx">
                  库存量
                </view>
                <view class="yd-text-main mt-4rpx text-30rpx font-semibold">
                  {{ formatCount(item.totalCount) }}
                </view>
              </view>
            </view>
            <view class="yd-text-hint flex items-center justify-between text-24rpx">
              <text>{{ formatDateTime(item.createTime) || '-' }}</text>
              <text>操作人：{{ item.creatorName || '-' }}</text>
            </view>
          </view>
        </view>
      </view>
    </z-paging>
  </view>
</template>

<script lang="ts" setup>
import type { StockRecord } from '@/api/erp/stock/record'
import { ref } from 'vue'
import { getStockRecordPage } from '@/api/erp/stock/record'
import { navigateBackPlus } from '@/utils'
import { DICT_TYPE } from '@/utils/constants'
import { formatDateTime } from '@/utils/date'
import SearchForm from './components/search-form.vue'
import { formatCount } from '@/pages-erp/utils/format'

definePage({
  style: {
    navigationBarTitleText: '',
    navigationStyle: 'custom',
  },
})

const list = ref<StockRecord[]>([]) // 列表数据
const pagingRef = ref<any>() // 分页组件引用
const queryParams = ref<Record<string, any>>({}) // 查询参数

/** 返回上一页 */
function handleBack() {
  navigateBackPlus()
}

/** 获取数量颜色 */
function getCountClass(value?: any) {
  const count = Number(value || 0)
  if (count > 0) {
    return 'text-[#16a34a]'
  }
  if (count < 0) {
    return 'text-[#dc2626]'
  }
  return 'yd-text-main'
}

/** 查询库存明细列表 */
async function queryList(pageNo: number, pageSize: number) {
  try {
    const data = await getStockRecordPage({ ...queryParams.value, pageNo, pageSize })
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
function handleDetail(item: StockRecord) {
  uni.navigateTo({ url: `/pages-erp/stock/record/detail/index?id=${item.id}` })
}
</script>
