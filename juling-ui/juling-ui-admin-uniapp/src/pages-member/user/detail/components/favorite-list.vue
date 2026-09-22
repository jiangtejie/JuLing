<template>
  <!-- 收藏记录列表 -->
  <z-paging
    ref="pagingRef"
    v-model="list"
    :fixed="false"
    class="min-h-0 flex-1"
    :default-page-size="10"
    :refresher-enabled="true"
    :inside-more="true"
    :loading-more-default-as-loading="true"
    empty-view-text="暂无收藏记录"
    @query="queryList"
  >
    <view class="p-24rpx pb-160rpx">
      <view
        v-for="item in list"
        :key="item.id"
        class="mb-20rpx rounded-12rpx bg-white p-24rpx shadow-sm"
      >
        <view class="flex gap-16rpx">
          <wd-img
            v-if="item.picUrl"
            :src="item.picUrl"
            :width="56"
            :height="56"
            mode="aspectFill"
            radius="8rpx"
          />
          <view class="min-w-0 flex-1">
            <view class="mb-12rpx flex items-center justify-between gap-16rpx">
              <view class="yd-text-main min-w-0 flex-1 truncate text-30rpx font-semibold">
                {{ item.name || `商品 ${item.spuId || '-'}` }}
              </view>
              <dict-tag :type="DICT_TYPE.PRODUCT_SPU_STATUS" :value="item.status" />
            </view>
            <view class="yd-text-sub mb-12rpx flex items-center text-26rpx">
              <text class="yd-text-hint mr-8rpx">商品售价：</text>
              <text>{{ formatDisplayMoney(item.price) }}</text>
            </view>
            <view class="yd-text-sub mb-12rpx flex items-center text-26rpx">
              <text class="yd-text-hint mr-8rpx">销量：</text>
              <text>{{ item.salesCount ?? 0 }}</text>
            </view>
            <view class="yd-text-hint text-24rpx">
              {{ formatDateTime(item.createTime) || '-' }}
            </view>
          </view>
        </view>
      </view>
    </view>
  </z-paging>
</template>

<script lang="ts" setup>
import type { ProductFavorite } from '@/api/mall/product/favorite'
import { ref, watch } from 'vue'
import { getProductFavoritePage } from '@/api/mall/product/favorite'
import { DICT_TYPE } from '@/utils/constants'
import { formatDateTime } from '@/utils/date'
import { formatDisplayMoney } from '@/utils/format'

const props = defineProps<{
  userId?: number | any
}>()

const list = ref<ProductFavorite[]>([]) // 列表数据
const pagingRef = ref<ZPagingRef<ProductFavorite>>() // 分页组件引用

/** 查询收藏记录 */
async function queryList(pageNo: number, pageSize: number) {
  if (!props.userId) {
    pagingRef.value?.complete([])
    return
  }
  try {
    const data = await getProductFavoritePage({
      userId: Number(props.userId),
      pageNo,
      pageSize,
    })
    pagingRef.value?.completeByTotal(data.list, data.total)
  } catch {
    pagingRef.value?.complete(false)
  }
}

/** 重新加载 */
function reload() {
  pagingRef.value?.reload()
}

/** 监听会员变化，重新加载列表 */
watch(
  () => props.userId,
  () => reload(),
)
</script>
