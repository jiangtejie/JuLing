<template>
  <view class="yd-bg-subtle shrink-0 px-20rpx pb-[calc(18rpx+env(safe-area-inset-bottom))] pt-12rpx">
    <view class="yd-border-base border rounded-28rpx bg-white px-22rpx pb-16rpx pt-18rpx shadow-[0_12rpx_48rpx_rgba(0,0,0,0.08)]">
      <wd-form ref="formRef" :model="formData" :schema="formSchema">
        <wd-textarea
          v-model="formData.prompt"
          placeholder="输入思维导图主题"
          :maxlength="1024"
          auto-height
          compact
          custom-style="--wot-textarea-inner-min-height: 54rpx; --wot-textarea-inner-max-height: 180rpx; --wot-textarea-inner-font-size: 28rpx; --wot-textarea-inner-line-height: 42rpx;"
        />
      </wd-form>
      <view class="mt-14rpx flex items-center justify-between">
        <view class="flex items-center gap-12rpx">
          <view class="yd-bg-page yd-text-sub rounded-full px-18rpx py-10rpx text-22rpx" @click="formData.prompt = '移动端 AI 能力'">
            使用示例
          </view>
          <view v-if="hasResult" class="yd-bg-page yd-text-sub rounded-full px-18rpx py-10rpx text-22rpx" @click="emit('reset')">
            新建
          </view>
        </view>
        <view
          class="h-64rpx w-64rpx flex items-center justify-center rounded-full"
          :class="formData.prompt.trim() && !generating ? 'yd-bg-success' : 'bg-[#d9d9d9]'"
          @click="generating ? emit('stop') : emit('submit')"
        >
          <wd-icon :name="generating ? 'stop' : 'arrow-up'" size="32rpx" color="#fff" />
        </view>
      </view>
    </view>
    <view class="yd-text-muted pt-10rpx text-center text-20rpx">
      内容由 AI 生成，请注意甄别
    </view>
  </view>
</template>

<script lang="ts" setup>
import type { FormInstance } from '@wot-ui/ui/components/wd-form/types'
import type { AiMindMapGenerateReq } from '@/api/ai/mindmap'
import { ref } from 'vue'
import { createFormSchema } from '@/utils/wot'

defineProps<{
  generating: boolean
  hasResult: boolean
}>()
const emit = defineEmits<{
  reset: []
  stop: []
  submit: []
}>()
const formData = defineModel<AiMindMapGenerateReq>({ required: true })
const formRef = ref<FormInstance>() // 表单组件引用
const formSchema = createFormSchema({
  prompt: [{ required: true, message: '请输入思维导图主题' }],
})

/** 校验思维导图主题 */
function validate() {
  return formRef.value?.validate()
}

defineExpose({ validate })
</script>
