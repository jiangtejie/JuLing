<script setup lang="ts">
defineOptions({
  name: 'DocLink',
});

const PROJECT_URL = 'https://github.com/jiangtejie/JuLing';
</script>

<template>
  <div class="w-full sm:mx-auto md:max-w-md">
    <div class="mt-4 flex items-center justify-between">
      <span class="border-input w-[35%] border-b dark:border-gray-600"></span>
      <span class="text-muted-foreground text-center text-xs uppercase">
        萌新必读
      </span>
      <span class="border-input w-[35%] border-b dark:border-gray-600"></span>
    </div>

    <div class="mt-4 flex w-full justify-around">
      <a
        :href="`${PROJECT_URL}#readme`"
        target="_blank"
        class="text-primary hover:text-primary/80 text-sm"
      >
        📚 项目说明
      </a>
      <a
        :href="`${PROJECT_URL}/issues`"
        target="_blank"
        class="text-primary hover:text-primary/80 text-sm"
      >
        🐞 问题反馈
      </a>
    </div>
  </div>
</template>
