<script setup lang="ts">
import type { TagType } from '@wot-ui/ui/components/wd-tag/types'
import { computed } from 'vue'

import { getDictOptions } from '@/hooks/useDict'

interface DictTagProps {
  type: string // 字典类型
  value: any // 字典值（支持单值，或数组 / 分隔符拼接的多值）
  plain?: boolean // 是否镂空，默认为 true
  separator?: string // 字符串多值的分隔符（仅 value 为字符串时生效）
  gutter?: string // 多个标签之间的间距
  /**
   * 未命中字典项时的兜底文案，默认 '-'
   *
   * add by 棱信矩灵：此前未命中（值不存在 / 值为空 / 字典未定义该项）时整个组件不渲染任何内容，
   * 详情页会显示成「状态：」这样标签后空白，与项目其它字段用 - 占位的约定不一致。
   * 传入空字符串可关闭兜底（回到只渲染标签的行为）。
   */
  placeholder?: string
}

const props = withDefaults(defineProps<DictTagProps>(), {
  plain: true,
  separator: ',',
  gutter: '8rpx',
  placeholder: '-',
})

/**
 * 后端颜色类型 => wd-tag 的 type 映射
 *
 * 后端可配置：default、primary、success、info、warning、danger
 * wd-tag 支持：default、primary、success、warning、danger
 * 匹配不上时默认用 default
 */
const COLOR_TYPE_MAP: Record<string, TagType> = {
  default: 'default',
  primary: 'primary',
  success: 'success',
  info: 'default', // wd-tag 无 info，映射为 default
  warning: 'warning',
  danger: 'danger',
}

/** 字典值列表：数字/布尔包一层，字符串按分隔符拆，数组逐项转字符串 */
const valueArr = computed<string[]>(() => {
  const { value } = props
  if (value === undefined || value === null || value === '') {
    return []
  }
  if (Array.isArray(value)) {
    return value.map(String)
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    return [String(value)]
  }
  return String(value).split(props.separator)
})

/** 命中的字典标签（遍历字典项保持定义顺序、天然去重） */
const dictTags = computed(() => {
  if (!props.type) {
    return []
  }
  return getDictOptions(props.type)
    .filter(dict => valueArr.value.includes(String(dict.value)))
    .map(dict => ({
      label: dict.label || '',
      tagType: COLOR_TYPE_MAP[dict.colorType || ''] || 'default',
      cssClass: dict.cssClass,
    }))
})
</script>

<template>
  <view
    v-if="dictTags.length"
    :style="{ display: 'inline-flex', flexWrap: 'wrap', alignItems: 'center', gap: gutter }"
  >
    <wd-tag
      v-for="(tag, index) in dictTags"
      :key="index"
      :type="tag.tagType"
      :variant="plain ? 'plain' : undefined"
      :custom-class="tag.cssClass"
    >
      {{ tag.label }}
    </wd-tag>
  </view>
  <!-- 未命中字典项时的兜底展示（与项目其它字段的 '-' 约定保持一致） -->
  <text v-else-if="placeholder !== ''" class="yd-text-hint">{{ placeholder }}</text>
</template>
