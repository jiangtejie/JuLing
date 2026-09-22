<template>
  <view class="yd-page-container yd-page-with-footer">
    <!-- 顶部导航栏 -->
    <wd-navbar
      :title="getTitle"
      left-arrow placeholder safe-area-inset-top fixed
      @click-left="handleBack"
    />

    <!-- 表单区域 -->
    <view>
      <wd-form ref="formRef" :model="formData" :schema="formSchema">
        <wd-cell-group border>
          <wd-form-item title="标签名称" title-width="180rpx" prop="name">
            <wd-input v-model="formData.name" clearable placeholder="请输入标签名称" />
          </wd-form-item>
        </wd-cell-group>
      </wd-form>
    </view>

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
import type { MemberTag } from '@/api/member/tag'
import { useToast } from '@wot-ui/ui/components/wd-toast'
import { computed, onMounted, ref } from 'vue'
import { createMemberTag, getMemberTag, updateMemberTag } from '@/api/member/tag'
import { delay, navigateBackPlus } from '@/utils'
import { createFormSchema } from '@/utils/wot'

const props = defineProps<{
  id?: number | any
}>()

definePage({
  style: {
    navigationBarTitleText: '',
    navigationStyle: 'custom',
  },
})

const toast = useToast()
const getTitle = computed(() => props.id ? '编辑会员标签' : '新增会员标签')
const formLoading = ref(false) // 表单提交状态
const formData = ref<MemberTag>({
  id: undefined,
  name: '',
}) // 表单数据
const formSchema = createFormSchema({
  name: [{ required: true, message: '标签名称不能为空' }],
})
const formRef = ref<FormInstance>() // 表单组件引用

/** 返回上一页 */
function handleBack() {
  navigateBackPlus('/pages-member/tag/index')
}

/** 加载标签详情 */
async function getDetail() {
  if (!props.id) {
    return
  }
  formData.value = await getMemberTag(Number(props.id))
}

/** 提交表单 */
async function handleSubmit() {
  const { valid } = await formRef.value.validate()
  if (!valid) {
    return
  }

  formLoading.value = true
  try {
    if (props.id) {
      await updateMemberTag(formData.value)
      toast.success('修改成功')
    } else {
      await createMemberTag(formData.value)
      toast.success('新增成功')
    }
    uni.$emit('member:tag:reload')
    delay(handleBack)
  } catch { // add by 棱信矩灵：成功分支不复位 loading（页面即将返回），仅失败时复位，避免 delay(handleBack) 的 500ms 窗口内重复提交
    formLoading.value = false
  }
}

/** 初始化 */
onMounted(() => {
  getDetail()
})
</script>
