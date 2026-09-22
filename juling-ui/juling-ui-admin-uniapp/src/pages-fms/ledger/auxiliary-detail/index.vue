<template>
  <view class="yd-page-container">
    <!-- 顶部导航栏 -->
    <wd-navbar
      title="辅助核算明细账"
      left-arrow placeholder safe-area-inset-top fixed
      @click-left="handleBack"
    />

    <template v-if="hasAccessByCodes(['fms:ledger:detail:query'])">
      <!-- 账套切换 -->
      <view class="p-24rpx pb-0">
        <AccountSetSwitch @change="handleAccountSetChange" />
      </view>
      <template v-if="fmsStore.accountSet">
        <!-- 搜索组件 -->
        <view class="px-24rpx">
          <SearchForm
            show-subject
            subject-all-option
            show-auxiliary
            search-placeholder="搜索辅助核算明细账"
            @search="handleQuery"
            @reset="handleQuery"
          />
        </view>

        <!-- 核算项目明细账列表 -->
        <scroll-view class="min-h-0 flex-1" scroll-y scroll-with-animation>
          <view class="p-24rpx">
            <!-- 加载状态 -->
            <view
              v-if="loading"
              class="yd-text-hint rounded-12rpx bg-white py-64rpx text-center text-26rpx shadow-sm"
            >
              <wd-loading size="32rpx" />
              <view class="mt-12rpx">
                正在加载账簿数据
              </view>
            </view>

            <view v-else-if="list.length" class="overflow-hidden rounded-12rpx bg-white shadow-sm">
              <!-- 辅助项目标题 -->
              <view class="yd-text-main yd-border-base border-0 border-b border-b-solid px-24rpx py-20rpx text-30rpx font-semibold">
                {{ queryParams.auxiliaryTypeName }}：{{ queryParams.auxiliaryItemCode }}_{{ queryParams.auxiliaryItemName }}
              </view>
              <view v-for="(row, index) in list" :key="index">
                <!-- 凭证分录行 -->
                <view v-if="row.rowType === FmsLedgerRowType.VOUCHER" class="yd-border-light border-0 border-b border-b-solid px-24rpx py-20rpx">
                  <view class="mb-8rpx flex items-center justify-between gap-16rpx">
                    <text class="yd-text-hint text-26rpx">{{ row.accountDate || '-' }}</text>
                    <text
                      v-if="row.voucherId && hasAccessByCodes(['fms:voucher:query'])"
                      class="yd-text-link text-26rpx"
                      @click="openVoucher(row)"
                    >
                      {{ row.voucherNumber }}
                    </text>
                    <text v-else class="yd-text-hint text-26rpx">{{ row.voucherNumber || '' }}</text>
                  </view>
                  <view class="yd-text-main mb-8rpx text-28rpx">
                    {{ row.digest || '-' }}
                  </view>
                  <view class="yd-text-sub flex flex-wrap items-center gap-x-24rpx gap-y-4rpx text-26rpx">
                    <text>借方 {{ formatFmsMoney(row.debitAmount) }}</text>
                    <text>贷方 {{ formatFmsMoney(row.creditAmount) }}</text>
                    <text>余额 {{ formatFmsSubjectBalance(row.balance, row.balanceDirection) }}</text>
                  </view>
                </view>
                <!-- 汇总行（期初、本期合计、本年累计） -->
                <view
                  v-else
                  class="yd-text-main yd-border-light yd-bg-subtle flex flex-wrap items-center gap-x-24rpx gap-y-4rpx border-0 border-b border-b-solid px-24rpx py-16rpx text-26rpx font-semibold"
                >
                  <text class="min-w-140rpx">{{ row.digest }}</text>
                  <text>借 {{ formatFmsMoney(row.debitAmount) }}</text>
                  <text>贷 {{ formatFmsMoney(row.creditAmount) }}</text>
                  <text>余 {{ formatFmsSubjectBalance(row.balance, row.balanceDirection) }}</text>
                </view>
              </view>
            </view>

            <!-- 空状态 -->
            <view v-else class="rounded-12rpx bg-white py-96rpx shadow-sm">
              <wd-empty
                icon="content"
                :tip="queryParams.auxiliaryItemId ? '暂无核算项目明细账数据' : '当前辅助类别下暂无核算项目'"
              />
            </view>
          </view>
          <view class="h-40rpx" />
        </scroll-view>
      </template>
    </template>
  </view>
</template>

<script lang="ts" setup>
import type { LedgerAuxiliaryDetail } from '@/api/fms/ledger'
import { FmsLedgerRowType, getLedgerAuxiliaryDetailList } from '@/api/fms/ledger'
import { useAccess } from '@/hooks/useAccess'
import AccountSetSwitch from '@/pages-fms/components/account-set/switch.vue'
import SearchForm from '@/pages-fms/ledger/components/search-form.vue'
import { useFmsStore } from '@/pages-fms/store/fms'
import { formatFmsMoney, formatFmsSubjectBalance } from '@/pages-fms/utils/format'
import { navigateBackPlus } from '@/utils'

definePage({
  style: {
    navigationBarTitleText: '',
    navigationStyle: 'custom',
  },
})

const { hasAccessByCodes } = useAccess()
const fmsStore = useFmsStore()
const loading = ref(false) // 账簿加载状态
const list = ref<LedgerAuxiliaryDetail[]>([]) // 核算项目明细账行列表
const queryParams = reactive({ // 查询参数
  startMonth: '',
  endMonth: '',
  auxiliaryTypeId: undefined as number | undefined,
  auxiliaryTypeName: '' as string | undefined,
  auxiliaryItemId: undefined as number | undefined,
  auxiliaryItemCode: '' as string | undefined,
  auxiliaryItemName: '' as string | undefined,
  subjectId: undefined as number | undefined,
})

/** 返回上一页 */
function handleBack() {
  navigateBackPlus()
}

/** 查询核算项目明细账 */
async function getList() {
  const accountSetId = fmsStore.accountSet?.id
  if (!accountSetId || !queryParams.auxiliaryTypeId || !queryParams.auxiliaryItemId
    || !queryParams.startMonth || !queryParams.endMonth) {
    list.value = []
    return
  }
  loading.value = true
  try {
    list.value = await getLedgerAuxiliaryDetailList({
      accountSetId,
      startMonth: queryParams.startMonth,
      endMonth: queryParams.endMonth,
      auxiliaryTypeId: queryParams.auxiliaryTypeId,
      auxiliaryItemId: queryParams.auxiliaryItemId,
      subjectId: queryParams.subjectId,
    })
  } finally {
    loading.value = false
  }
}

/** 搜索按钮操作 */
function handleQuery(data: Record<string, any>) {
  queryParams.startMonth = data.startMonth
  queryParams.endMonth = data.endMonth
  queryParams.auxiliaryTypeId = data.auxiliaryTypeId
  queryParams.auxiliaryTypeName = data.auxiliaryTypeName
  queryParams.auxiliaryItemId = data.auxiliaryItemId
  queryParams.auxiliaryItemCode = data.auxiliaryItemCode
  queryParams.auxiliaryItemName = data.auxiliaryItemName
  queryParams.subjectId = data.subjectId
  getList()
}

/** 账套切换后清空列表，等待搜索组件重新触发查询 */
function handleAccountSetChange() {
  list.value = []
}

/** 打开凭证详情 */
function openVoucher(row: LedgerAuxiliaryDetail) {
  uni.navigateTo({ url: `/pages-fms/voucher/detail/index?id=${row.voucherId}` })
}

/** 初始化 */
onMounted(async () => {
  await fmsStore.loadAccountSetList()
})
</script>
