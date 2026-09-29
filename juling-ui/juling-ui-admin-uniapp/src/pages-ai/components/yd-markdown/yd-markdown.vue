<template>
  <view class="yd-markdown">
    <rich-text :nodes="htmlContent" selectable />
  </view>
</template>

<script lang="ts" setup>
import MarkdownIt from 'markdown-it'

const props = withDefaults(defineProps<{
  content?: string
}>(), {
  content: '',
})

const markdown = new MarkdownIt({
  breaks: true,
  html: false,
  linkify: true,
  typographer: true,
})
markdown.renderer.rules.paragraph_open = (tokens, index, options, env, renderer) => {
  tokens[index].attrJoin('class', 'yd-markdown-paragraph')
  return renderer.renderToken(tokens, index, options)
}

const htmlContent = computed(() => markdown.render(props.content))
</script>

<style lang="scss" scoped>
.yd-markdown {
  color: var(--yd-text-main);
  font-size: 28rpx;
  line-height: 1.75;
  word-break: break-word;

  :deep(h1),
  :deep(h2),
  :deep(h3),
  :deep(h4) {
    margin: 28rpx 0 16rpx;
    color: var(--yd-text-strong);
    font-weight: 600;
    line-height: 1.4;
  }

  :deep(h1) {
    font-size: 40rpx;
  }

  :deep(h2) {
    font-size: 34rpx;
  }

  :deep(h3),
  :deep(h4) {
    font-size: 30rpx;
  }

  :deep(.yd-markdown-paragraph),
  :deep(blockquote),
  :deep(pre),
  :deep(ul),
  :deep(ol),
  :deep(table) {
    margin: 16rpx 0;
  }

  :deep(ul),
  :deep(ol) {
    padding-left: 42rpx;
  }

  :deep(blockquote) {
    padding: 12rpx 20rpx;
    border-left: 6rpx solid var(--yd-text-link);
    background: var(--yd-surface-subtle);
    color: var(--yd-text-sub);
  }

  :deep(code) {
    border-radius: 6rpx;
    background: var(--yd-surface-page);
    padding: 2rpx 8rpx;
    font-family: monospace;
  }

  :deep(pre) {
    overflow-x: auto;
    border-radius: 12rpx;
    background: var(--yd-surface-dark);
    padding: 20rpx;
    color: var(--yd-text-inverse);
  }

  :deep(pre code) {
    background: transparent;
    padding: 0;
    color: inherit;
  }

  :deep(table) {
    width: 100%;
    border-collapse: collapse;
  }

  :deep(th),
  :deep(td) {
    border: 1px solid var(--yd-border-base);
    padding: 10rpx 12rpx;
    text-align: left;
  }

  :deep(a) {
    color: var(--yd-text-link);
  }
}
</style>
