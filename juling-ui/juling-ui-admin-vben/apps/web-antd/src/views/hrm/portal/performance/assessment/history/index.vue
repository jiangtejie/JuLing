<script lang="ts" setup>
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { HrmPortalPerformanceAssessmentApi } from '#/api/hrm/portal/performance/assessment';

import { nextTick, ref } from 'vue';
import { useRouter } from 'vue-router';

import { Page, useVbenDrawer } from '@vben/common-ui';

import { Tag } from 'ant-design-vue';

import { TableAction, useVbenVxeGrid } from '#/adapter/vxe-table';
import { getPerformanceAssessmentPage } from '#/api/hrm/portal/performance/assessment';
import { usePageActivateLoad } from '#/utils/usePageActivateLoad';
import { checkHrmPortalAccess } from '#/views/hrm/utils/employee';

import { useHistoryGridColumns, useHistoryGridFormSchema } from '../data';
import PerformanceAssessmentDetail from '../modules/detail-drawer.vue';

defineOptions({ name: 'HrmPortalPerformanceHistory' });

const router = useRouter();
const accessible = ref(false);

const [DetailDrawer, detailDrawerApi] = useVbenDrawer({
  connectedComponent: PerformanceAssessmentDetail,
});

const [Grid, gridApi] = useVbenVxeGrid({
  formOptions: {
    schema: useHistoryGridFormSchema(),
    submitOnEnter: true,
  },
  gridOptions: {
    columns: useHistoryGridColumns(),
    height: 'auto',
    proxyConfig: {
      autoLoad: false,
      ajax: {
        query: async ({ page }, formValues) =>
          getPerformanceAssessmentPage({
            ...formValues,
            archived: true,
            pageNo: page.currentPage,
            pageSize: page.pageSize,
          }),
      },
    },
    rowConfig: { keyField: 'id', isHover: true },
    toolbarConfig: { refresh: true, search: true },
  } as VxeTableGridOptions<HrmPortalPerformanceAssessmentApi.AssessmentSummary>,
});

function openDetail(row: HrmPortalPerformanceAssessmentApi.AssessmentSummary) {
  detailDrawerApi.setData({ row }).open();
}

/** 首屏加载 + 切回页签刷新，原因见 usePageActivateLoad 注释 */
usePageActivateLoad(async () => {
  accessible.value = await checkHrmPortalAccess(router);
  if (!accessible.value) return;
  // 首屏时表格还挂在 <Page v-if="accessible"> 之下：accessible 变 true 后要等下一次渲染表格才 mount，
  // 否则此处 gridApi.query() 会因为表格 api 尚未 mount 而静默失效（this.grid.commitProxy is not a function）
  await nextTick();
  await gridApi.query();
});
</script>

<template>
  <Page v-if="accessible" auto-content-height>
    <Grid table-title="绩效档案">
      <template #resultLevel="{ row }">
        <Tag v-if="row.resultLevel" color="success">
          {{ row.resultLevel }}
        </Tag>
        <span v-else>-</span>
      </template>
      <template #actions="{ row }">
        <TableAction
          :actions="[
            {
              label: '查看',
              type: 'link',
              onClick: () => openDetail(row),
            },
          ]"
        />
      </template>
    </Grid>
    <DetailDrawer />
  </Page>
</template>
