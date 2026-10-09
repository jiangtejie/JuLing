<script setup lang="ts">
import type { MemberUserApi } from '#/api/member/user';

import { onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';

import { Page, useVbenModal } from '@vben/common-ui';
import { useTabs } from '@vben/hooks';

import { Button, Card, message, TabPane, Tabs } from 'antdv-next';

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

/** 获取会员详情 */
async function getUserDetail() {
  if (!userId) {
    message.error('参数错误，会员编号不能为空！');
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
          <Button type="primary" @click="handleEdit">
            {{ $t('common.edit') }}
          </Button>
        </template>
      </BasicInfo>
      <AccountInfo v-if="user" class="ml-4 w-2/5" :user="user">
        <template #title> 账户信息 </template>
      </AccountInfo>
    </div>
    <div class="mt-4">
      <Card title="订单与售后">
        <Tabs>
          <TabPane tab="订单管理" key="OrderList">
            <OrderList class="h-full" :user-id="userId" />
          </TabPane>
          <TabPane tab="售后管理" key="AfterSaleList">
            <AfterSaleList class="h-full" :user-id="userId" />
          </TabPane>
        </Tabs>
      </Card>
    </div>
  </Page>
</template>
