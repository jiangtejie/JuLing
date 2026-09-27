<template>
  <view class="yd-page-container">
    <!-- 顶部导航栏 -->
    <wd-navbar
      title="交易配置"
      left-arrow placeholder safe-area-inset-top fixed
      @click-left="handleBack"
    />

    <!-- 分组 tab -->
    <view class="bg-white">
      <wd-tabs v-model="activeTab" slidable="always">
        <wd-tab v-for="(tab, index) in CONFIG_TABS" :key="index" :title="tab" />
      </wd-tabs>
    </view>

    <!-- 表单区域 -->
    <scroll-view class="min-h-0 flex-1" scroll-y scroll-with-animation>
      <wd-form ref="formRef" :model="formData" :schema="formSchema">
        <view class="p-24rpx">
          <!-- 售后配置 -->
          <view v-show="activeTab === 0" class="mb-160rpx overflow-hidden rounded-12rpx bg-white shadow-sm">
            <wd-cell-group border>
              <wd-form-item title="退款理由" title-width="200rpx">
                <view class="w-full py-8rpx">
                  <view v-for="(_, i) in formData.afterSaleRefundReasons" :key="i" class="mb-12rpx flex items-center gap-16rpx">
                    <wd-input v-model="formData.afterSaleRefundReasons[i]" class="flex-1" placeholder="请输入退款理由" />
                    <text class="yd-text-danger shrink-0 text-26rpx" @click="formData.afterSaleRefundReasons.splice(i, 1)">删除</text>
                  </view>
                  <wd-button size="small" variant="plain" @click="formData.afterSaleRefundReasons.push('')">
                    + 添加退款理由
                  </wd-button>
                </view>
              </wd-form-item>
              <wd-form-item title="退货理由" title-width="200rpx">
                <view class="w-full py-8rpx">
                  <view v-for="(_, i) in formData.afterSaleReturnReasons" :key="i" class="mb-12rpx flex items-center gap-16rpx">
                    <wd-input v-model="formData.afterSaleReturnReasons[i]" class="flex-1" placeholder="请输入退货理由" />
                    <text class="yd-text-danger shrink-0 text-26rpx" @click="formData.afterSaleReturnReasons.splice(i, 1)">删除</text>
                  </view>
                  <wd-button size="small" variant="plain" @click="formData.afterSaleReturnReasons.push('')">
                    + 添加退货理由
                  </wd-button>
                </view>
              </wd-form-item>
            </wd-cell-group>
          </view>

          <!-- 配送配置 -->
          <view v-show="activeTab === 1" class="mb-160rpx overflow-hidden rounded-12rpx bg-white shadow-sm">
            <wd-cell-group border>
              <wd-form-item title="启用包邮" title-width="200rpx" prop="deliveryExpressFreeEnabled" center>
                <wd-switch v-model="formData.deliveryExpressFreeEnabled" />
              </wd-form-item>
              <wd-form-item title="满额包邮(元)" title-width="200rpx" prop="deliveryExpressFreePrice" center>
                <wd-input-number v-model="formData.deliveryExpressFreePrice" :min="0" :step="0.01" :precision="2" />
              </wd-form-item>
            </wd-cell-group>
          </view>
        </view>
      </wd-form>
    </scroll-view>

    <!-- 底部保存按钮 -->
    <view class="yd-detail-footer">
      <wd-button type="primary" block :loading="formLoading" @click="handleSubmit">
        保存
      </wd-button>
    </view>
  </view>
</template>

<script lang="ts" setup>
import type { FormInstance } from '@wot-ui/ui/components/wd-form/types'
import { useToast } from '@wot-ui/ui/components/wd-toast'
import { onMounted, ref } from 'vue'
import { getTradeConfig, saveTradeConfig } from '@/api/mall/trade/config'
import { fenToYuan, yuanToFen } from '@/utils/format'
import { navigateBackPlus, trimArray } from '@/utils'
import { createFormSchema } from '@/utils/wot'

interface TradeConfigForm {
  afterSaleRefundReasons: string[]
  afterSaleReturnReasons: string[]
  deliveryExpressFreeEnabled: boolean
  deliveryExpressFreePrice: number
}

const CONFIG_TABS = ['售后', '配送'] // 分组 tab

definePage({
  style: {
    navigationBarTitleText: '',
    navigationStyle: 'custom',
  },
})

const toast = useToast()
const formRef = ref<FormInstance>() // 表单组件引用
const formLoading = ref(false) // 表单提交状态
const activeTab = ref(0) // 当前分组 tab 下标
const formData = ref<TradeConfigForm>({
  afterSaleRefundReasons: [],
  afterSaleReturnReasons: [],
  deliveryExpressFreeEnabled: false,
  deliveryExpressFreePrice: 0,
}) // 表单数据
const formSchema = createFormSchema({
  deliveryExpressFreePrice: [{ required: true, message: '满额包邮不能为空' }],
})

/** 字段 → tab 映射（校验失败时切到对应 tab） */
const PROP_TAB: Record<string, number> = {
  deliveryExpressFreePrice: 1,
}

/** 返回上一页 */
function handleBack() {
  navigateBackPlus('/pages-statistics/mall/home/index')
}

/** 加载配置 */
async function loadConfig() {
  const data = await getTradeConfig()
  if (!data) {
    return
  }
  formData.value = {
    ...data,
    afterSaleRefundReasons: data.afterSaleRefundReasons || [],
    afterSaleReturnReasons: data.afterSaleReturnReasons || [],
    deliveryExpressFreeEnabled: !!data.deliveryExpressFreeEnabled,
    deliveryExpressFreePrice: fenToYuan(data.deliveryExpressFreePrice),
  }
}

/** 提交表单 */
async function handleSubmit() {
  const result = await formRef.value.validate()
  if (!result?.valid) {
    // 校验失败时切到首个错误字段所在的 tab
    const prop = result?.errors?.[0]?.prop
    if (prop != null && PROP_TAB[prop] != null) {
      activeTab.value = PROP_TAB[prop]
    }
    return
  }
  formLoading.value = true
  try {
    await saveTradeConfig({
      afterSaleRefundReasons: trimArray(formData.value.afterSaleRefundReasons),
      afterSaleReturnReasons: trimArray(formData.value.afterSaleReturnReasons),
      deliveryExpressFreeEnabled: formData.value.deliveryExpressFreeEnabled,
      deliveryExpressFreePrice: yuanToFen(formData.value.deliveryExpressFreePrice),
    })
    toast.success('保存成功')
  } finally {
    formLoading.value = false
  }
}

/** 初始化 */
onMounted(() => {
  loadConfig()
})
</script>
