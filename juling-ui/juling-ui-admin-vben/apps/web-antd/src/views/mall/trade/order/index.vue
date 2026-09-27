<script lang="ts" setup>
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { MallOrderApi } from '#/api/mall/trade/order';

import { onActivated, ref } from 'vue';
import { useRouter } from 'vue-router';

import { DocAlert, Page, useVbenModal } from '@vben/common-ui';
import {
  DeliveryTypeEnum,
  DICT_TYPE,
  TradeOrderStatusEnum,
} from '@vben/constants';
import { fenToYuan } from '@vben/utils';

import { Button, Image, List, Tag } from 'ant-design-vue';

import { ACTION_ICON, TableAction, useVbenVxeGrid } from '#/adapter/vxe-table';
import { getOrderPage } from '#/api/mall/trade/order';
import { DictTag } from '#/components/dict-tag';
import { $t } from '#/locales';

import { useGridColumns, useGridFormSchema } from './data';
import DeliveryForm from './modules/delivery-form.vue';
import PaymentProofForm from './modules/payment-proof-form.vue';
import RemarkForm from './modules/remark-form.vue';

const { push } = useRouter();

const [DeliveryFormModal, deliveryFormModalApi] = useVbenModal({
  connectedComponent: DeliveryForm,
  destroyOnClose: true,
});

const [RemarkFormModal, remarkFormModalApi] = useVbenModal({
  connectedComponent: RemarkForm,
  destroyOnClose: true,
});

const [PaymentProofFormModal, paymentProofFormModalApi] = useVbenModal({
  connectedComponent: PaymentProofForm,
  destroyOnClose: true,
});

/** 已展开明细的订单编号（用于按钮文案：明细 / 收起） */
const expandedOrderIds = ref<number[]>([]);

/** 刷新表格：刷新后展开态会被重置，这里同步清空 */
function handleRefresh() {
  expandedOrderIds.value = [];
  gridApi.query();
}

/**
 * 回到本页时表格会自动刷新（见 adapter/vxe-table.ts），刷新后所有行都会收起，
 * 因此同步清空本地的展开态，避免按钮文案还停留在「收起」。
 */
onActivated(() => {
  expandedOrderIds.value = [];
});

/** 该行明细是否已展开 */
function isExpanded(row: MallOrderApi.Order): boolean {
  return row.id !== undefined && expandedOrderIds.value.includes(row.id);
}

/**
 * 展开 / 收起某行的商品明细。
 *
 * vxe 内置的展开按钮在本版本默认隐藏且点击无效，因此自己渲染按钮，
 * 通过 vben 暴露的 vxe 表格实例（gridApi.grid）调用 setRowExpand。
 */
function toggleExpand(row: MallOrderApi.Order) {
  const id = row.id;
  if (id === undefined) return;
  const expanded = isExpanded(row);
  const grid = gridApi.grid as unknown as {
    setRowExpand?: (rows: MallOrderApi.Order[], expanded: boolean) => void;
    toggleRowExpand?: (row: MallOrderApi.Order) => void;
  };
  if (grid?.setRowExpand) {
    grid.setRowExpand([row], !expanded);
  } else {
    grid?.toggleRowExpand?.(row);
  }
  expandedOrderIds.value = expanded
    ? expandedOrderIds.value.filter((item) => item !== id)
    : [...expandedOrderIds.value, id];
}

/** 详情 */
function handleDetail(row: MallOrderApi.Order) {
  push({ name: 'TradeOrderDetail', params: { id: row.id } });
}

/** 发货 */
function handleDelivery(row: MallOrderApi.Order) {
  deliveryFormModalApi.setData(row).open();
}

/** 备注 */
function handleRemark(row: MallOrderApi.Order) {
  remarkFormModalApi.setData(row).open();
}

/** 线下收款：核验客户上传的付款凭证（确认收款 / 驳回） */
function handleAuditPaymentProof(row: MallOrderApi.Order) {
  paymentProofFormModalApi.setData(row).open();
}

const [Grid, gridApi] = useVbenVxeGrid({
  formOptions: {
    schema: useGridFormSchema(),
  },
  gridOptions: {
    // 默认收起：订单多时每行都摊开商品明细会让列表无法快速扫读，需要时点左侧箭头展开。
    // 这里不配 trigger/expandAll，用 vxe 默认行为（与 wms 明细列表一致）——
    // 之前配的 trigger:'row' 会让展开列的图标不再渲染，收起后反而没有展开入口。
    expandConfig: {
      padding: true,
    },
    columns: useGridColumns(),
    height: 'auto',
    keepSource: true,
    proxyConfig: {
      ajax: {
        query: async ({ page }, formValues) => {
          return await getOrderPage({
            pageNo: page.currentPage,
            pageSize: page.pageSize,
            ...formValues,
          });
        },
      },
    },
    rowConfig: {
      keyField: 'id',
      isHover: true,
    },
    toolbarConfig: {
      refresh: true,
      search: true,
    },
  } as VxeTableGridOptions<MallOrderApi.Order>,
});
</script>

<template>
  <Page auto-content-height>
    <template #doc>
      <DocAlert
        title="【交易】交易订单"
        url="https://github.com/jiangtejie/JuLing#readme"
      />
      <DocAlert
        title="【交易】购物车"
        url="https://github.com/jiangtejie/JuLing#readme"
      />
    </template>

    <DeliveryFormModal @success="handleRefresh" />
    <RemarkFormModal @success="handleRefresh" />
    <PaymentProofFormModal @success="handleRefresh" />
    <Grid table-title="订单列表">
      <template #expand_toggle="{ row }">
        <Button type="link" size="small" @click.stop="toggleExpand(row)">
          {{ isExpanded(row) ? '收起' : '明细' }}
        </Button>
      </template>
      <template #expand_content="{ row }">
        <List item-layout="vertical" :data-source="row.items">
          <template #renderItem="{ item }">
            <List.Item>
              <List.Item.Meta>
                <template #title>
                  {{ item.spuName }}
                  <Tag
                    color="blue"
                    v-for="property in item.properties"
                    :key="property.propertyId"
                  >
                    {{ property.propertyName }} : {{ property.valueName }}
                  </Tag>
                </template>
                <template #avatar>
                  <Image :src="item.picUrl" :width="40" :height="40" />
                </template>
                <template #description>
                  {{
                    `原价：${fenToYuan(item.price)} 元 / 数量：${item.count} 个`
                  }}
                  |
                  <DictTag
                    :type="DICT_TYPE.TRADE_ORDER_ITEM_AFTER_SALE_STATUS"
                    :value="item.afterSaleStatus"
                  />
                </template>
              </List.Item.Meta>
            </List.Item>
          </template>
        </List>
      </template>
      <template #actions="{ row }">
        <TableAction
          :actions="[
            {
              label: $t('common.detail'),
              type: 'link',
              icon: ACTION_ICON.VIEW,
              auth: ['trade:order:query'],
              onClick: handleDetail.bind(null, row),
            },
          ]"
          :drop-down-actions="[
            {
              label: '核验收款',
              type: 'link',
              auth: ['trade:order:payment-proof:audit'],
              ifShow: () => row.paymentProofStatus === 1,
              onClick: handleAuditPaymentProof.bind(null, row),
            },
            {
              label: '发货',
              type: 'link',
              ifShow: () =>
                row.deliveryType === DeliveryTypeEnum.EXPRESS.type &&
                (row.status === TradeOrderStatusEnum.UNDELIVERED.status ||
                  row.status === TradeOrderStatusEnum.DELIVERED.status),
              onClick: handleDelivery.bind(null, row),
            },
            {
              label: '备注',
              type: 'link',
              onClick: handleRemark.bind(null, row),
            },
          ]"
        />
      </template>
    </Grid>
  </Page>
</template>
