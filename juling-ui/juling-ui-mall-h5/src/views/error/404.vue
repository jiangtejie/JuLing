<script setup lang="ts">
  defineOptions({ name: 'NotFound' });

  const router = useRouter();
</script>

<template>
  <div class="app-page not-found">
    <AppNavBar title="页面不存在" />
    <div class="not-found__body">
      <van-empty image="error" description="抱歉，你访问的页面不存在或已被移除">
        <div class="not-found__actions">
          <van-button round type="primary" size="small" @click="router.replace('/home')">
            返回首页
          </van-button>
          <van-button round size="small" @click="router.back()">返回上一页</van-button>
        </div>
      </van-empty>
    </div>
  </div>
</template>

<style scoped lang="scss">
  .not-found {
    &__body {
      display: flex;
      flex: 1;
      align-items: center;
      justify-content: center;
    }

    &__actions {
      display: flex;
      justify-content: center;
      gap: 10px;
    }
  }
</style>
