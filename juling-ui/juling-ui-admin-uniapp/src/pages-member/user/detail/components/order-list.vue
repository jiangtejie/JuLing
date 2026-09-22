<template>
  <view class="min-h-0 flex flex-1 flex-col">
    <!-- 搜索组件 -->
    <OrderSearchForm @search="handleQuery" @reset="handleReset" />

    <!-- 订单记录列表 -->
    <z-paging
      ref="pagingRef"
      v-model="list"
      :fixed="false"
      class="min-h-0 flex-1"
      :default-page-size="10"
      :refresher-enabled="true"
      :inside-more="true"
      :loading-more-default-as-loading="true"
      empty-view-text="暂无订单记录"
      @query="queryList"
    >
      <view class="p-24rpx pb-160rpx">
        <view
          v-for="item in list"
          :key="item.id"
          class="mb-20rpx rounded-12rpx bg-white p-24rpx shadow-sm"
          @click="handleDetail(item)"
        >
          <view class="mb-16rpx flex items-center justify-between gap-16rpx">
            <view class="yd-text-main min-w-0 flex-1 truncate text-30rpx font-semibold">
              {{ item.no || `订单 ${item.id}` }}
            </view>
            <dict-tag :type="DICT_TYPE.TRADE_ORDER_STATUS" :value="item.status" />
          </view>
          <view class="yd-text-sub mb-12rpx flex items-center text-26rpx">
            <text class="yd-text-hint mr-8rpx">支付金额：</text>
            <text>{{ formatDisplayMoney(item.payPrice) }}</text>
          </view>
          <view class="yd-text-sub mb-12rpx flex items-center text-26rpx">
            <text class="yd-text-hint mr-8rpx">商品数量：</text>
            <text>{{ item.productCount ?? '-' }}</text>
          </view>
          <view class="yd-text-sub mb-12rpx flex items-center text-26rpx">
            <text class="yd-text-hint mr-8rpx">配送方式：</text>
            <dict-tag :type="DICT_TYPE.TRADE_DELIVERY_TYPE" :value="item.deliveryType" />
          </view>
          <view v-if="item.items?.length" class="yd-text-sub mb-12rpx text-26rpx">
            {{ item.items.map(goods => goods.spuName).filter(Boolean).join('、') }}
          </view>
          <view class="yd-text-hint text-24rpx">
            {{ formatDateTime(item.createTime) || '-' }}
          </view>
          <view class="yd-text-link mt-16rpx text-right text-24rpx">
            查看详情
          </view>
        </view>
      </view>
    </z-paging>
  </view>
</template>

<script lang="ts" setup>
import type { TradeOrder } from '@/api/mall/trade/order'
import { ref, watch } from 'vue'
import { getTradeOrderPage } from '@/api/mall/trade/order'
import { DICT_TYPE } from '@/utils/constants'
import { formatDateTime } from '@/utils/date'
import { formatDisplayMoney } from '@/utils/format'
import OrderSearchForm from './order-search-form.vue'

const props = defineProps<{
  userId?: number | any
}>()

const list = ref<TradeOrder[]>([]) // 列表数据
const pagingRef = ref<ZPagingRef<TradeOrder>>() // 分页组件引用
const queryParams = ref<Record<string, any>>({}) // 查询参数

/** 查询订单记录 */
async function queryList(pageNo: number, pageSize: number) {
  if (!props.userId) {
    pagingRef.value?.complete([])
    return
  }
  try {
    const data = await getTradeOrderPage({
      ...queryParams.value,
      userId: Number(props.userId),
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

/** 查看订单详情 */
function handleDetail(item: TradeOrder) {
  if (!item.id) {
    return
  }
  uni.navigateTo({
    url: `/pages-mall/trade/order/detail/index?id=${item.id}`,
  })
}

/** 监听会员变化，重新加载列表 */
watch(
  () => props.userId,
  () => reload(),
)
</script>
