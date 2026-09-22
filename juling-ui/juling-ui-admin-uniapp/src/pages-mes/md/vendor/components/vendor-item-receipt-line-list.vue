<template>
  <view class="min-h-0 flex flex-1 flex-col bg-white">
    <view class="flex items-center border-b border-b-[#f0f0f0] px-24rpx py-20rpx" :class="showTitle ? 'justify-between' : 'justify-end'">
      <view v-if="showTitle" class="yd-text-main text-30rpx font-semibold">
        物料清单
      </view>
      <view class="yd-text-hint text-24rpx">
        共 {{ total }} 条
      </view>
    </view>

    <z-paging
      ref="pagingRef"
      v-model="list"
      :fixed="false"
      class="min-h-0 flex-1"
      :default-page-size="5"
      :refresher-enabled="false"
      :inside-more="true"
      :loading-more-default-as-loading="true"
      empty-view-text="暂无物料清单"
      @query="queryList"
    >
      <view class="px-24rpx py-8rpx pb-160rpx">
        <view
          v-for="item in list"
          :key="item.id"
          class="border-b border-b-[#f5f5f5] py-20rpx last:border-b-0"
          @click="handleViewItem(item)"
        >
          <view class="mb-12rpx flex items-start justify-between gap-16rpx">
            <view class="min-w-0 flex-1">
              <view class="yd-text-main truncate text-28rpx font-medium">
                {{ item.itemCode || `物料 #${item.itemId}` }}
              </view>
              <view class="yd-text-sub mt-4rpx truncate text-26rpx">
                {{ item.itemName || '-' }}
              </view>
            </view>
            <view class="yd-text-hint shrink-0 text-24rpx">
              {{ item.unitMeasureName || '-' }}
            </view>
          </view>
          <view class="yd-text-sub mb-8rpx flex text-26rpx">
            <text class="yd-text-hint mr-8rpx shrink-0">规格型号：</text>
            <text class="min-w-0 flex-1 truncate">{{ item.specification || '-' }}</text>
          </view>
          <view class="yd-text-sub mb-8rpx flex text-26rpx">
            <text class="yd-text-hint mr-8rpx shrink-0">入库数量：</text>
            <text class="min-w-0 flex-1 truncate">{{ item.receivedQuantity ?? '-' }}</text>
          </view>
          <view class="yd-text-sub flex text-26rpx">
            <text class="yd-text-hint mr-8rpx shrink-0">批次号：</text>
            <text class="min-w-0 flex-1 truncate">{{ item.batchCode || '-' }}</text>
          </view>
        </view>
      </view>
    </z-paging>
  </view>
</template>

<script lang="ts" setup>
import type { WmItemReceiptLine } from '@/api/mes/wm/itemreceipt/line'
import { nextTick, ref, watch } from 'vue'
import { getItemReceiptLinePage } from '@/api/mes/wm/itemreceipt/line'

const props = withDefaults(defineProps<{
  vendorId?: number
  showTitle?: boolean
}>(), {
  showTitle: true,
})

const list = ref<WmItemReceiptLine[]>([]) // 物料清单
const total = ref(0) // 总条数
const pagingRef = ref<ZPagingRef<WmItemReceiptLine>>() // 分页组件引用

/** 查询物料清单 */
async function queryList(currentPageNo: number, currentPageSize: number) {
  if (!props.vendorId) {
    total.value = 0
    pagingRef.value?.completeByTotal([], 0)
    return
  }
  try {
    const data = await getItemReceiptLinePage({
      pageNo: currentPageNo,
      pageSize: currentPageSize,
      vendorId: props.vendorId,
    })
    total.value = data.total
    pagingRef.value?.completeByTotal(data.list, data.total)
  } catch {
    pagingRef.value?.complete(false)
  }
}

/** 查看物料详情 */
function handleViewItem(item: WmItemReceiptLine) {
  if (!item.itemId) {
    return
  }
  uni.navigateTo({ url: `/pages-mes/md/item/detail/index?id=${item.itemId}` })
}

/** 监听供应商编号变化 */
watch(
  () => props.vendorId,
  async () => {
    total.value = 0
    list.value = []
    await nextTick()
    pagingRef.value?.reload()
  },
  { immediate: true },
)
</script>
