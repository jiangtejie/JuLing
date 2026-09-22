<template>
  <view class="yd-page-container yd-page-container-paging">
    <!-- 顶部导航栏 -->
    <wd-navbar
      title="会员资料"
      left-arrow placeholder safe-area-inset-top fixed
      @click-left="handleBack"
    />

    <!-- 分组 tab -->
    <view class="bg-white">
      <wd-tabs v-model="activeTab">
        <wd-tab title="会员信息" />
        <wd-tab title="最近浏览" />
        <wd-tab title="交易订单" />
      </wd-tabs>
    </view>

    <!-- 会员信息 -->
    <scroll-view v-if="activeTab === 0" class="min-h-0 flex-1" scroll-y>
      <view class="p-24rpx">
        <view class="mb-24rpx flex items-center gap-20rpx rounded-12rpx bg-white p-24rpx shadow-sm">
          <wd-img v-if="member.avatar" :src="member.avatar" width="112rpx" height="112rpx" radius="56rpx" mode="aspectFill" />
          <view v-else class="yd-bg-info-soft h-112rpx w-112rpx flex items-center justify-center rounded-full">
            <wd-icon name="user" size="56rpx" color="#1677ff" />
          </view>
          <view class="min-w-0 flex-1">
            <view class="yd-text-main truncate text-32rpx font-semibold">
              {{ member.nickname || '-' }}
            </view>
            <view class="yd-text-hint mt-8rpx text-24rpx">
              编号：{{ member.id ?? '-' }}
            </view>
          </view>
        </view>

        <view class="mb-24rpx overflow-hidden rounded-12rpx bg-white shadow-sm">
          <wd-cell-group border>
            <wd-cell title="用户名" :value="member.name || '-'" />
            <wd-cell title="手机号" :value="member.mobile || '-'" />
            <wd-cell title="邮箱" :value="member.email || '-'" />
            <wd-cell title="性别">
              <dict-tag v-if="member.sex != null" :type="DICT_TYPE.SYSTEM_USER_SEX" :value="member.sex" />
              <text v-else>-</text>
            </wd-cell>
            <wd-cell title="所在地" :value="member.areaName || '-'" />
            <wd-cell title="注册 IP" :value="member.registerIp || '-'" />
            <wd-cell title="生日" :value="formatDate(member.birthday, 'YYYY-MM-DD HH:mm') || '-'" />
            <wd-cell title="注册时间" :value="formatDate(member.createTime, 'YYYY-MM-DD HH:mm') || '-'" />
            <wd-cell title="最后登录" :value="formatDate(member.loginDate, 'YYYY-MM-DD HH:mm') || '-'" />
            <wd-cell title="等级" :value="member.levelName || '-'" />
            <wd-cell title="成长值" :value="member.experience != null ? String(member.experience) : '-'" />
          </wd-cell-group>
        </view>

        <view class="overflow-hidden rounded-12rpx bg-white shadow-sm">
          <view class="yd-border-light yd-text-main border-b px-24rpx py-18rpx text-30rpx font-semibold">
            账户信息
          </view>
          <wd-cell-group border>
            <wd-cell title="当前余额" :value="`￥${fenToYuan(wallet.balance).toFixed(2)}`" />
            <wd-cell title="充值金额" :value="`￥${fenToYuan(wallet.totalRecharge).toFixed(2)}`" />
            <wd-cell title="支出金额" :value="`￥${fenToYuan(wallet.totalExpense).toFixed(2)}`" />
            <wd-cell title="当前积分" :value="member.point != null ? String(member.point) : '-'" />
            <wd-cell title="总积分" :value="member.totalPoint != null ? String(member.totalPoint) : '-'" />
          </wd-cell-group>
        </view>
      </view>
    </scroll-view>

    <!-- 最近浏览 -->
    <z-paging
      v-else-if="activeTab === 1"
      ref="browsePaging"
      v-model="browseList"
      :fixed="false"
      class="min-h-0 flex-1"
      :default-page-size="10"
      empty-view-text="暂无浏览记录"
      @query="queryBrowse"
    >
      <view class="p-24rpx">
        <view
          v-for="row in browseList"
          :key="row.id"
          class="mb-20rpx flex items-center gap-16rpx rounded-12rpx bg-white p-20rpx shadow-sm"
        >
          <wd-img v-if="row.picUrl" :src="row.picUrl" width="120rpx" height="120rpx" radius="8rpx" mode="aspectFill" />
          <view v-else class="yd-bg-page h-120rpx w-120rpx rounded-8rpx" />
          <view class="min-w-0 flex-1">
            <view class="yd-text-main line-clamp-2 text-28rpx">
              {{ row.spuName || `商品 #${row.spuId}` }}
            </view>
            <view class="mt-8rpx text-26rpx text-[#ff3000]">
              ￥{{ row.price }}
            </view>
            <view class="yd-text-hint mt-8rpx text-22rpx">
              浏览时间：{{ formatDate(row.createTime, 'YYYY-MM-DD HH:mm') }}
            </view>
          </view>
        </view>
      </view>
    </z-paging>

    <!-- 交易订单 -->
    <z-paging
      v-else
      ref="orderPaging"
      v-model="orderList"
      :fixed="false"
      class="min-h-0 flex-1"
      :default-page-size="10"
      empty-view-text="暂无交易订单"
      @query="queryOrder"
    >
      <view class="p-24rpx">
        <view
          v-for="order in orderList"
          :key="order.id"
          class="mb-20rpx overflow-hidden rounded-12rpx bg-white p-24rpx shadow-sm"
        >
          <view class="mb-12rpx flex items-center justify-between gap-16rpx">
            <text class="yd-text-main min-w-0 flex-1 truncate text-28rpx font-semibold">
              {{ order.no || '-' }}
            </text>
            <dict-tag v-if="order.status != null" :type="DICT_TYPE.TRADE_ORDER_STATUS" :value="order.status" />
          </view>
          <view
            v-for="orderItem in order.items || []"
            :key="orderItem.id"
            class="mb-12rpx flex items-center gap-16rpx last:mb-0"
          >
            <wd-img v-if="orderItem.picUrl" :src="orderItem.picUrl" width="88rpx" height="88rpx" radius="8rpx" mode="aspectFill" />
            <view class="min-w-0 flex-1">
              <view class="yd-text-main line-clamp-1 text-26rpx">
                {{ orderItem.spuName || '-' }}
              </view>
              <view class="yd-text-hint mt-4rpx text-22rpx">
                x{{ orderItem.count || 0 }}
              </view>
            </view>
          </view>
          <view class="yd-text-hint yd-border-light mt-12rpx flex items-center justify-between border-t pt-12rpx text-24rpx">
            <text>{{ formatDate(order.createTime, 'YYYY-MM-DD HH:mm') }}</text>
            <text>共 {{ order.productCount || 0 }} 件 实付 <text class="text-[#ff3000]">￥{{ fenToYuan(order.payPrice).toFixed(2) }}</text></text>
          </view>
        </view>
      </view>
    </z-paging>
  </view>
</template>

<script lang="ts" setup>
import type { PageParam } from '@/http/types'
import type { MemberUser } from '@/api/member/user'
import type { PayWallet } from '@/api/pay/wallet/balance'
import type { TradeOrder } from '@/api/mall/trade/order'
import { computed, ref } from 'vue'
import { getMemberUser } from '@/api/member/user'
import { getPayWallet } from '@/api/pay/wallet/balance'
import { getProductBrowseHistoryPage } from '@/api/mall/product/browse-history'
import { getProductSpuDetailList } from '@/api/mall/product/spu'
import { getTradeOrderPage } from '@/api/mall/trade/order'
import { navigateBackPlus } from '@/utils'
import { DICT_TYPE } from '@/utils/constants'
import { fenToYuan } from '@/utils/format'
import { formatDate } from '@/utils/date'

const props = defineProps<{ userId?: number | any }>()

definePage({
  style: {
    navigationBarTitleText: '',
    navigationStyle: 'custom',
  },
})

const userId = computed(() => props.userId != null && props.userId !== '' ? Number(props.userId) : undefined) // 会员编号
const activeTab = ref(0) // 当前 tab

const member = ref<MemberUser>({}) // 会员信息
const wallet = ref<PayWallet>({}) // 钱包信息

interface BrowseRow { id?: number, spuId?: number, spuName?: string, picUrl?: string, price: string, createTime?: string }
const browseList = ref<BrowseRow[]>([]) // 最近浏览
const browsePaging = ref<any>() // 最近浏览分页引用
const orderList = ref<TradeOrder[]>([]) // 交易订单
const orderPaging = ref<any>() // 交易订单分页引用

/** 返回上一页 */
function handleBack() {
  navigateBackPlus()
}

/** 加载会员信息 + 钱包 */
async function loadMember() {
  if (!userId.value) {
    return
  }
  const [memberRes, walletRes] = await Promise.allSettled([
    getMemberUser(userId.value),
    getPayWallet({ userId: userId.value }),
  ])
  if (memberRes.status === 'fulfilled') {
    member.value = memberRes.value || {}
  }
  if (walletRes.status === 'fulfilled') {
    wallet.value = walletRes.value || {}
  }
}

/** 最近浏览分页查询（浏览记录仅含 spuId，按 ids 批量取商品详情补全图/名/价） */
async function queryBrowse(pageNo: number, pageSize: number) {
  if (!userId.value) {
    browsePaging.value?.completeByTotal([], 0)
    return
  }
  try {
    const data = await getProductBrowseHistoryPage({ pageNo, pageSize, userId: userId.value, userDeleted: false })
    const records = data.list || []
    const spuIds = Array.from(new Set(records.map(item => item.spuId).filter(Boolean))) as number[]
    const spus = spuIds.length ? await getProductSpuDetailList(spuIds) : []
    const spuMap = new Map(spus.map(spu => [spu.id, spu]))
    const rows: BrowseRow[] = records.map((record) => {
      const spu = spuMap.get(record.spuId)
      return {
        id: record.id,
        spuId: record.spuId,
        spuName: spu?.name,
        picUrl: spu?.picUrl,
        price: fenToYuan(spu?.price).toFixed(2),
        createTime: record.createTime,
      }
    })
    browsePaging.value?.completeByTotal(rows, data.total)
  } catch {
    browsePaging.value?.complete(false)
  }
}

/** 交易订单分页查询 */
async function queryOrder(pageNo: number, pageSize: number) {
  if (!userId.value) {
    orderPaging.value?.completeByTotal([], 0)
    return
  }
  try {
    const query: Record<string, any> = { userId: userId.value }
    const data = await getTradeOrderPage({ ...query, pageNo, pageSize } as PageParam)
    orderPaging.value?.completeByTotal(data.list, data.total)
  } catch {
    orderPaging.value?.complete(false)
  }
}

loadMember()
</script>
