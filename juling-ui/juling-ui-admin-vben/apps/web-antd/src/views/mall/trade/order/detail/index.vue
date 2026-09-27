<script lang="ts" setup>
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { MallDeliveryExpressApi } from '#/api/mall/trade/delivery/express';
import type { MallDeliveryPickUpStoreApi } from '#/api/mall/trade/delivery/pickUpStore';
import type { MallOrderApi } from '#/api/mall/trade/order';

import { onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';

import { confirm, Page, useVbenModal } from '@vben/common-ui';
import {
  DeliveryTypeEnum,
  DICT_TYPE,
  TradeOrderStatusEnum,
} from '@vben/constants';
import { useTabs } from '@vben/hooks';
import { fenToYuan, formatDateTime } from '@vben/utils';

import { Image, message, Space, Tag } from 'ant-design-vue';

import { useVbenVxeGrid } from '#/adapter/vxe-table';
import { getSimpleDeliveryExpressList } from '#/api/mall/trade/delivery/express';
import { getDeliveryPickUpStore } from '#/api/mall/trade/delivery/pickUpStore';
import {
  getExpressTrackList,
  getOrder,
  getPaymentProofList,
  pickUpOrder,
} from '#/api/mall/trade/order';
import { useDescription } from '#/components/description';
import { DictTag } from '#/components/dict-tag';
import { TableAction } from '#/components/table-action';

import AddressForm from '../modules/address-form.vue';
import DeliveryForm from '../modules/delivery-form.vue';
import PaymentProofForm from '../modules/payment-proof-form.vue';
import PriceForm from '../modules/price-form.vue';
import RemarkForm from '../modules/remark-form.vue';
import {
  useDeliveryInfoSchema,
  useExpressTrackColumns,
  useOperateLogColumns,
  useOrderInfoSchema,
  useOrderPriceSchema,
  useOrderStatusSchema,
  usePaymentInfoSchema,
  useProductColumns,
} from './data';

defineOptions({ name: 'TradeOrderDetail' });

const route = useRoute();
const router = useRouter();
const tabs = useTabs();

const loading = ref(false);
const orderId = ref(0);
const order = ref<MallOrderApi.Order>({
  logs: [],
});
/** 付款凭证（线下收款，含历史与驳回记录） */
const proofs = ref<MallOrderApi.PaymentProof[]>([]);

/**
 * 单条凭证状态（后端 TradeOrderPaymentProofStatusEnum）。
 * 这里用本地映射而非字典：订单维度已有字典 trade_payment_proof_status，
 * 凭证维度只有 3 个值且仅本页展示，避免为一个纯展示字段新增一套字典数据。
 */
const PROOF_STATUS_MAP: Record<number, { color: string; text: string }> = {
  0: { color: 'warning', text: '待核验' },
  1: { color: 'success', text: '已确认' },
  2: { color: 'error', text: '已驳回' },
};

const deliveryExpressList = ref<MallDeliveryExpressApi.DeliveryExpress[]>([]);
const expressTrackList = ref<any[]>([]);
const pickUpStore = ref<
  MallDeliveryPickUpStoreApi.DeliveryPickUpStore | undefined
>();

const [OrderInfoDescriptions] = useDescription({
  title: '订单信息',
  bordered: false,
  column: 3,
  class: 'mx-4',
  schema: useOrderInfoSchema(),
});

const [OrderStatusDescriptions] = useDescription({
  title: '订单状态',
  bordered: false,
  column: 1,
  class: 'mx-4',
  schema: useOrderStatusSchema(),
});

const [OrderPriceDescriptions] = useDescription({
  title: '费用信息',
  bordered: false,
  column: 4,
  class: 'mx-4',
  schema: useOrderPriceSchema(),
});

const [PaymentInfoDescriptions] = useDescription({
  title: '收款信息（线下收款）',
  bordered: false,
  column: 4,
  class: 'mx-4',
  schema: usePaymentInfoSchema(),
});

const [DeliveryInfoDescriptions] = useDescription({
  title: '收货信息',
  bordered: false,
  column: 3,
  class: 'mx-4',
  schema: useDeliveryInfoSchema(),
});

const [ProductGrid, productGridApi] = useVbenVxeGrid({
  gridOptions: {
    cellConfig: {
      height: 60,
    },
    columns: useProductColumns(),
    data: [],
    height: 'auto',
    border: true,
    pagerConfig: {
      enabled: false,
    },
    toolbarConfig: {
      refresh: true,
      search: true,
    },
  } as VxeTableGridOptions<MallOrderApi.OrderItem>,
});

const [ExpressTrackGrid, expressTrackGridApi] = useVbenVxeGrid({
  gridOptions: {
    columns: useExpressTrackColumns(),
    data: [],
    border: true,
    pagerConfig: {
      enabled: false,
    },
    toolbarConfig: {
      refresh: true,
      search: true,
    },
  } as VxeTableGridOptions,
});

const [OperateLogGrid, operateLogGridApi] = useVbenVxeGrid({
  gridOptions: {
    columns: useOperateLogColumns(),
    data: [],
    border: true,
    pagerConfig: {
      enabled: false,
    },
    toolbarConfig: {
      refresh: true,
      search: true,
    },
  } as VxeTableGridOptions,
});

const [DeliveryFormModal, deliveryFormModalApi] = useVbenModal({
  connectedComponent: DeliveryForm,
  destroyOnClose: true,
});

const [RemarkFormModal, remarkFormModalApi] = useVbenModal({
  connectedComponent: RemarkForm,
  destroyOnClose: true,
});

const [AddressFormModal, addressFormModalApi] = useVbenModal({
  connectedComponent: AddressForm,
  destroyOnClose: true,
});

const [PriceFormModal, priceFormModalApi] = useVbenModal({
  connectedComponent: PriceForm,
  destroyOnClose: true,
});

const [PaymentProofFormModal, paymentProofFormModalApi] = useVbenModal({
  connectedComponent: PaymentProofForm,
  destroyOnClose: true,
});

/** 获得详情 */
async function getDetail() {
  loading.value = true;
  try {
    const res = await getOrder(orderId.value);
    if (res === null) {
      message.error('交易订单不存在');
      handleBack();
      return;
    }
    order.value = res;
    productGridApi.setGridOptions({ data: res.items || [] });
    operateLogGridApi.setGridOptions({ data: res.logs || [] });
    // 线下收款：付款凭证（核验进度与驳回原因）
    proofs.value = await getPaymentProofList(orderId.value);

    // 如果配送方式为快递，则查询物流公司
    if (res.deliveryType === DeliveryTypeEnum.EXPRESS.type) {
      deliveryExpressList.value = await getSimpleDeliveryExpressList();
      if (res.logisticsId) {
        expressTrackList.value = await getExpressTrackList(res.id!);
        expressTrackGridApi.setGridOptions({
          data: expressTrackList.value || [],
        });
      }
    } else if (
      res.deliveryType === DeliveryTypeEnum.PICK_UP.type &&
      res.pickUpStoreId
    ) {
      pickUpStore.value = await getDeliveryPickUpStore(res.pickUpStoreId);
    }
  } finally {
    loading.value = false;
  }
}

/** 各种操作 */
const handleRemark = () => {
  remarkFormModalApi.setData(order.value).open();
};

const handleDelivery = () => {
  deliveryFormModalApi.setData(order.value).open();
};

const handleUpdateAddress = () => {
  addressFormModalApi.setData(order.value).open();
};

const handleUpdatePrice = () => {
  priceFormModalApi.setData(order.value).open();
};

/** 线下收款：核验付款凭证 */
const handleAuditPaymentProof = () => {
  paymentProofFormModalApi.setData(order.value).open();
};

/** 核销 */
const handlePickUp = async () => {
  await confirm('确认核销订单吗？');
  const hideLoading = message.loading({
    content: '正在处理中...',
    duration: 0,
  });
  try {
    await pickUpOrder(order.value.id!);
    message.success('核销成功');
    await getDetail();
  } finally {
    hideLoading();
  }
};

/** 返回列表页 */
function handleBack() {
  tabs.closeCurrentTab();
  router.push({ name: 'TradeOrder' });
}

/** 初始化 */
onMounted(async () => {
  orderId.value = Number(route.params.id);
  await getDetail();
});
</script>

<template>
  <Page auto-content-height :title="order.no" :loading="loading">
    <template #extra>
      <TableAction
        :actions="[
          {
            label: '返回',
            type: 'default',
            icon: 'lucide:arrow-left',
            onClick: handleBack,
          },
          {
            label: '调整价格',
            type: 'primary',
            onClick: handleUpdatePrice,
            ifShow: order.status === TradeOrderStatusEnum.UNPAID.status,
          },
          {
            label: '核验收款',
            type: 'primary',
            onClick: handleAuditPaymentProof,
            ifShow: order.paymentProofStatus === 1,
          },
          {
            label: '备注',
            type: 'primary',
            onClick: handleRemark,
          },
          {
            label: '发货',
            type: 'primary',
            onClick: handleDelivery,
            ifShow:
              order.status === TradeOrderStatusEnum.UNDELIVERED.status &&
              order.deliveryType === DeliveryTypeEnum.EXPRESS.type,
          },
          {
            label: '修改地址',
            type: 'primary',
            onClick: handleUpdateAddress,
            ifShow:
              order.status === TradeOrderStatusEnum.UNDELIVERED.status &&
              order.deliveryType === DeliveryTypeEnum.EXPRESS.type,
          },
          {
            label: '核销',
            type: 'primary',
            onClick: handlePickUp,
            ifShow:
              order.status === TradeOrderStatusEnum.UNDELIVERED.status &&
              order.deliveryType === DeliveryTypeEnum.PICK_UP.type,
          },
        ]"
      />
    </template>

    <!-- 各种操作的弹窗 -->
    <DeliveryFormModal @success="getDetail" />
    <RemarkFormModal @success="getDetail" />
    <AddressFormModal @success="getDetail" />
    <PriceFormModal @success="getDetail" />
    <PaymentProofFormModal @success="getDetail" />

    <!-- 订单信息 -->
    <div class="mb-4">
      <OrderInfoDescriptions :data="order" />
    </div>
    <!-- 订单状态 -->
    <div class="mb-4">
      <OrderStatusDescriptions :data="order" />
    </div>
    <!-- 商品信息 -->
    <div class="mb-4">
      <ProductGrid table-title="商品信息">
        <template #spuName="{ row }">
          <div class="flex flex-1 flex-col items-start gap-1 text-left">
            <span class="text-sm">{{ row.spuName }}</span>
            <div class="flex flex-wrap gap-1">
              <Tag
                v-for="property in row.properties"
                :key="property.propertyId!"
                size="small"
              >
                {{ property.propertyName }}: {{ property.valueName }}
              </Tag>
            </div>
          </div>
        </template>
      </ProductGrid>
    </div>
    <!-- 费用信息 -->
    <div class="mb-4">
      <OrderPriceDescriptions :data="order" />
    </div>
    <!-- 收款信息（线下收款） -->
    <div class="mb-4">
      <PaymentInfoDescriptions :data="order" />
    </div>
    <!-- 付款凭证：客户上传的转账截图与核验进度 -->
    <div v-if="proofs.length > 0" class="mx-4 mb-4">
      <div class="mb-2 font-medium">付款凭证（线下收款）</div>
      <div
        v-for="proof in proofs"
        :key="proof.id"
        class="mb-3 rounded border border-gray-200 p-3"
      >
        <div class="mb-2 flex flex-wrap items-center gap-3">
          <Tag :color="PROOF_STATUS_MAP[proof.status ?? 0]?.color">
            {{ PROOF_STATUS_MAP[proof.status ?? 0]?.text }}
          </Tag>
          <span>申报 {{ fenToYuan(proof.amount ?? 0) }} 元</span>
          <span v-if="proof.confirmedAmount !== null && proof.confirmedAmount !== undefined">
            核定 {{ fenToYuan(proof.confirmedAmount) }} 元
          </span>
          <span class="text-gray-400">
            提交 {{ formatDateTime(proof.createTime) }}
          </span>
          <span v-if="proof.payerName" class="text-gray-400">
            付款人：{{ proof.payerName }}
          </span>
          <DictTag
            v-if="proof.payChannelCode"
            :type="DICT_TYPE.PAY_CHANNEL_CODE"
            :value="proof.payChannelCode"
          />
        </div>
        <Image.PreviewGroup>
          <Space :size="12" wrap>
            <Image
              v-for="(url, index) in proof.urls"
              :key="index"
              :src="url"
              :width="120"
              class="rounded border border-gray-200"
            />
          </Space>
        </Image.PreviewGroup>
        <div v-if="proof.auditRemark" class="mt-2 text-xs text-red-500">
          核验意见：{{ proof.auditRemark }}
        </div>
      </div>
    </div>
    <!-- 收货信息 -->
    <div class="mb-4">
      <DeliveryInfoDescriptions :data="order" />
    </div>
    <!-- 物流详情 -->
    <div v-if="expressTrackList.length > 0" class="mb-4">
      <ExpressTrackGrid table-title="物流详情" />
    </div>
    <!-- 操作日志 -->
    <div>
      <OperateLogGrid table-title="操作日志">
        <template #userType="{ row }">
          <Tag v-if="row.userType === 0" color="default"> 系统 </Tag>
          <DictTag v-else :type="DICT_TYPE.USER_TYPE" :value="row.userType" />
        </template>
      </OperateLogGrid>
    </div>
  </Page>
</template>
