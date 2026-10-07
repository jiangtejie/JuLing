<template>
  <yd-form-picker
    :model-value="modelValue"
    :label="label"
    :label-width="labelWidth"
    :prop="prop"
    :disabled="disabled"
    :clearable="clearable"
    :columns="options"
    label-key="name"
    value-key="id"
    :placeholder="placeholder"
    :before-open="ensureOptions"
    @update:model-value="handleUpdate"
    @confirm="handleConfirm"
    @clear="handleClear"
  />
</template>

<script lang="ts" setup>
import type { Product } from '@/api/erp/product/product'
import { onMounted, ref, watch } from 'vue'
import { getProductSimpleList } from '@/api/erp/product/product'

const props = withDefaults(defineProps<{
  modelValue?: number
  label?: string
  labelWidth?: string
  placeholder?: string
  prop?: string
  disabled?: boolean
  clearable?: boolean
}>(), {
  label: '物料',
  labelWidth: '220rpx',
  placeholder: '请选择物料',
  prop: '',
  disabled: false,
  clearable: false,
})

const emit = defineEmits<{
  'update:modelValue': [value: number | undefined]
  'change': [item: Product | undefined]
}>()

const options = ref<Product[]>([]) // 物料选项
let loadingPromise: Promise<void> | undefined // 加载中的物料请求

/** 加载物料选项 */
async function loadOptions() {
  if (options.value.length > 0) {
    return
  }
  if (!loadingPromise) {
    loadingPromise = getProductSimpleList()
      .then((data) => {
        options.value = data
      })
      .finally(() => {
        loadingPromise = undefined
      })
  }
  try {
    await loadingPromise
  } catch {
    // 请求层负责提示；保留空选项以便下次打开重试。
  }
}

/** 打开前确保物料选项 */
function ensureOptions() {
  loadOptions()
}

/** 更新物料编号 */
function handleUpdate(value?: number) {
  emit('update:modelValue', value)
}

/** 选择物料 */
function handleConfirm(value?: number) {
  emit('change', options.value.find(item => item.id === value))
}

/** 清空物料 */
function handleClear() {
  emit('change', undefined)
}

/** 同步外部绑定值 */
watch(
  () => props.modelValue,
  (value) => {
    if (value != null) {
      loadOptions()
    }
  },
  { immediate: true },
)

/** 初始化 */
onMounted(() => {
  loadOptions()
})
</script>
