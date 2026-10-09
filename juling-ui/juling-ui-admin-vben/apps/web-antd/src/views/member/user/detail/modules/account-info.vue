<script setup lang="ts">
import type { MemberUserApi } from '#/api/member/user';

import { h } from 'vue';

import { DICT_TYPE } from '@vben/constants';
import { formatDate } from '@vben/utils';

import { Card } from 'ant-design-vue';

import { useDescription } from '#/components/description';
import { DictTag } from '#/components/dict-tag';

const props = withDefaults(
  defineProps<{
    mode?: 'kefu' | 'member';
    user: MemberUserApi.User;
  }>(),
  {
    mode: 'member',
  },
);

const [Descriptions] = useDescription({
  bordered: false,
  column: props.mode === 'member' ? 2 : 1,
  schema: [
    {
      field: 'username',
      label: '订货账号',
      render: (val) => val || '-',
    },
    {
      field: 'status',
      label: '状态',
      render: (val) =>
        h(DictTag, { type: DICT_TYPE.COMMON_STATUS, value: val }),
    },
    // 授权门店：账号能给哪些门店下单。后端只下发门店编号，这里直接展示编号
    {
      field: 'storeCustomerIds',
      label: '授权门店',
      render: (val: number[] | undefined) =>
        val && val.length > 0 ? val.join('、') : '-',
    },
    {
      field: 'defaultStoreCustomerId',
      label: '默认门店',
      render: (val) => val ?? '-',
    },
    {
      field: 'registerIp',
      label: '注册 IP',
      render: (val) => val || '-',
    },
    {
      field: 'createTime',
      label: '注册时间',
      render: (val) => formatDate(val)?.toString() || '-',
    },
    {
      field: 'loginDate',
      label: '最后登录时间',
      render: (val) => formatDate(val)?.toString() || '-',
    },
  ],
});
</script>

<template>
  <Card>
    <template #title>
      <slot name="title"></slot>
    </template>
    <template #extra>
      <slot name="extra"></slot>
    </template>
    <Descriptions :column="mode === 'member' ? 2 : 1" :data="{ ...user }" />
  </Card>
</template>
