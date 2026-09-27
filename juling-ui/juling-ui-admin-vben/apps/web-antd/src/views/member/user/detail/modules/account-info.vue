<script setup lang="ts">
import type { MemberUserApi } from '#/api/member/user';

import { Card } from 'ant-design-vue';

import { useDescription } from '#/components/description';

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
      field: 'levelName',
      label: '等级',
      render: (val) => val || '-',
    },
    {
      field: 'experience',
      label: '成长值',
      render: (val) => val || 0,
    },
    {
      field: 'point',
      label: '当前积分',
      render: (val) => val || 0,
    },
    {
      field: 'totalPoint',
      label: '总积分',
      render: (val) => val || 0,
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
