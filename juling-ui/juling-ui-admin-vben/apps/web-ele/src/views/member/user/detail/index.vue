<script setup lang="ts">
import type { MemberUserApi } from '#/api/member/user';

import { onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';

import { Page, useVbenModal } from '@vben/common-ui';
import { useTabs } from '@vben/hooks';

import { ElButton, ElCard, ElMessage, ElTabPane, ElTabs } from 'element-plus';

import { getUser } from '#/api/member/user';
import { $t } from '#/locales';

import Form from '../modules/form.vue';
import AccountInfo from './modules/account-info.vue';
import AfterSaleList from './modules/after-sale-list.vue';
import BasicInfo from './modules/basic-info.vue';
import OrderList from './modules/order-list.vue';

const route = useRoute();
const { closeCurrentTab, refreshTab } = useTabs();

const [FormModal, formModalApi] = useVbenModal({
  connectedComponent: Form,
  destroyOnClose: true,
});

const userId = Number(route.query.id);
const user = ref<MemberUserApi.User>();
const activeName = ref('OrderList');

/** 获取会员详情 */
async function getUserDetail() {
  if (!userId) {
    ElMessage.error('参数错误，会员编号不能为空！');
    await closeCurrentTab();
    return;
  }
  user.value = await getUser(userId);
}

/** 编辑会员 */
function handleEdit() {
  formModalApi.setData(user.value).open();
}

/** 初始化 */
onMounted(async () => {
  await getUserDetail();
});
</script>
<template>
  <Page auto-content-height>
    <FormModal @success="refreshTab" />
    <div class="flex">
      <BasicInfo v-if="user" class="w-3/5" :user="user" mode="member">
        <template #title> 基本信息 </template>
        <template #extra>
          <ElButton type="primary" @click="handleEdit">
            {{ $t('common.edit') }}
          </ElButton>
        </template>
      </BasicInfo>
      <AccountInfo v-if="user" class="ml-4 w-2/5" :user="user">
        <template #title> 账户信息 </template>
      </AccountInfo>
    </div>
    <div class="mt-4">
      <ElCard title="订单与售后">
        <ElTabs v-model="activeName">
          <ElTabPane label="订单管理" name="OrderList">
            <OrderList class="h-full" :user-id="userId" />
          </ElTabPane>
          <ElTabPane label="售后管理" name="AfterSaleList">
            <AfterSaleList class="h-full" :user-id="userId" />
          </ElTabPane>
        </ElTabs>
      </ElCard>
    </div>
  </Page>
</template>
