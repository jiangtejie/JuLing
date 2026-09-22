<template>
  <view class="yd-page-container yd-page-container-paging">
    <!-- 顶部导航栏 -->
    <wd-navbar
      title="产品管理"
      left-arrow placeholder safe-area-inset-top fixed
      @click-left="handleBack"
    />

    <!-- 搜索组件 -->
    <SearchForm @search="handleQuery" @reset="handleReset" />

    <!-- 产品列表 -->
    <z-paging
      ref="pagingRef"
      v-model="list"
      :fixed="false"
      class="min-h-0 flex-1"
      :default-page-size="10"
      :refresher-enabled="true"
      :inside-more="true"
      :loading-more-default-as-loading="true"
      empty-view-text="暂无产品数据"
      @query="queryList"
    >
      <view class="p-24rpx">
        <view
          v-for="item in list"
          :key="item.id"
          class="erp-list-card relative mb-24rpx overflow-hidden rounded-12rpx bg-white shadow-sm"
          @click="handleDetail(item)"
        >
          <view class="p-24rpx">
            <view class="mb-16rpx flex items-start justify-between gap-16rpx">
              <view class="yd-text-main min-w-0 flex-1 truncate text-32rpx font-semibold">
                {{ item.name || '-' }}
              </view>
              <dict-tag :type="DICT_TYPE.COMMON_STATUS" :value="item.status" />
            </view>
            <view v-if="item.barCode" class="yd-text-sub mb-12rpx text-28rpx">
              <text class="yd-text-hint mr-8rpx">条码：</text>{{ item.barCode }}
            </view>
            <view v-if="item.standard" class="yd-text-sub mb-12rpx text-28rpx">
              <text class="yd-text-hint mr-8rpx">规格：</text>{{ item.standard }}
            </view>
            <view class="yd-text-sub grid grid-cols-2 mb-12rpx gap-12rpx text-28rpx">
              <view>
                <text class="yd-text-hint">分类：</text>{{ item.categoryName || '-' }}
              </view>
              <view>
                <text class="yd-text-hint">单位：</text>{{ item.unitName || '-' }}
              </view>
            </view>
            <view class="yd-bg-subtle grid grid-cols-3 gap-12rpx rounded-12rpx p-16rpx text-center">
              <view>
                <view class="yd-text-hint text-22rpx">
                  采购价
                </view>
                <view class="yd-text-main mt-4rpx text-26rpx">
                  {{ formatMoney(item.purchasePrice) }}
                </view>
              </view>
              <view>
                <view class="yd-text-hint text-22rpx">
                  销售价
                </view>
                <view class="yd-text-main mt-4rpx text-26rpx">
                  {{ formatMoney(item.salePrice) }}
                </view>
              </view>
              <view>
                <view class="yd-text-hint text-22rpx">
                  最低价
                </view>
                <view class="yd-text-main mt-4rpx text-26rpx">
                  {{ formatMoney(item.minPrice) }}
                </view>
              </view>
            </view>
          </view>
        </view>
      </view>
    </z-paging>

    <!-- 新增按钮 -->
    <wd-fab
      v-if="hasAccessByCodes(['erp:product:create'])"
      position="right-bottom"
      type="primary"
      :expandable="false"
      @click="handleAdd"
    />
  </view>
</template>

<script lang="ts" setup>
import type { Product } from '@/api/erp/product/product'
import { onUnload } from '@dcloudio/uni-app'
import { onMounted, ref } from 'vue'
import { getProductPage } from '@/api/erp/product/product'
import { useAccess } from '@/hooks/useAccess'
import { navigateBackPlus } from '@/utils'
import { DICT_TYPE } from '@/utils/constants'
import SearchForm from './components/search-form.vue'
import { formatMoney } from '@/utils/format'

definePage({
  style: {
    navigationBarTitleText: '',
    navigationStyle: 'custom',
  },
})

const { hasAccessByCodes } = useAccess()
const list = ref<Product[]>([]) // 列表数据
const pagingRef = ref<any>() // 分页组件引用
const queryParams = ref<Record<string, any>>({}) // 查询参数

/** 返回上一页 */
function handleBack() {
  navigateBackPlus()
}

/** 查询产品列表 */
async function queryList(pageNo: number, pageSize: number) {
  try {
    const data = await getProductPage({ ...queryParams.value, pageNo, pageSize })
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

/** 新增产品 */
function handleAdd() {
  uni.navigateTo({
    url: '/pages-erp/product/product/form/index',
  })
}

/** 查看详情 */
function handleDetail(item: Product) {
  uni.navigateTo({
    url: `/pages-erp/product/product/detail/index?id=${item.id}`,
  })
}

/** 初始化 */
onMounted(() => {
  uni.$on('erp:product:reload', reload)
})

/** 卸载 */
onUnload(() => {
  uni.$off('erp:product:reload', reload)
})
</script>
