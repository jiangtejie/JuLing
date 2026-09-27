<script lang="ts" setup>
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { MallDeliveryExpressApi } from '#/api/mall/trade/delivery/express';
import type { MallDeliveryPickUpStoreApi } from '#/api/mall/trade/delivery/pickUpStore';
import type { MallOrderApi } from '#/api/mall/trade/order';

import { computed, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';

import { confirm, Page, useVbenModal } from '@vben/common-ui';
import {
  DeliveryTypeEnum,
  DICT_TYPE,
  TradeOrderStatusEnum,
} from '@vben/constants';
import { useTabs } from '@vben/hooks';
import { fenToYuan, formatDateTime } from '@vben/utils';

import {
  Badge,
  Button,
  Card,
  Divider,
  Image,
  message,
  Space,
  TabPane,
  Tabs,
  Tag,
} from 'ant-design-vue';

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

/** 当前页签：默认展示订单信息 */
const activeTab = ref('order');
/** 是否存在待核验的付款凭证：给「收款信息」页签加红点 */
const paymentPending = computed(() => order.value.paymentProofStatus === 1);

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

/** 待收货款（应付 - 已确认收款，负数归零） */
const remainAmount = computed(() =>
  Math.max(0, (order.value.payPrice ?? 0) - (order.value.paidAmount ?? 0)),
);

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

    <!-- 概览条：订单状态与收款进度是本页最常看的信息，固定展示在页签上方 -->
    <Card class="mb-4" size="small">
      <div class="flex flex-wrap items-center gap-x-10 gap-y-3">
        <div class="flex items-center gap-2">
          <span class="text-gray-400">订单状态</span>
          <DictTag :type="DICT_TYPE.TRADE_ORDER_STATUS" :value="order.status" />
        </div>
        <div class="flex items-center gap-2">
          <span class="text-gray-400">收款状态</span>
          <DictTag
            :type="DICT_TYPE.TRADE_PAYMENT_PROOF_STATUS"
            :value="order.paymentProofStatus ?? 0"
          />
        </div>
        <div>
          <span class="text-gray-400">已收货款</span>
          <span class="ml-2 font-semibold">
            ¥{{ fenToYuan(order.paidAmount ?? 0) }}
          </span>
        </div>
        <div>
          <span class="text-gray-400">待收货款</span>
          <span
            class="ml-2 font-semibold"
            :class="remainAmount > 0 ? 'text-red-500' : 'text-green-600'"
          >
            ¥{{ fenToYuan(remainAmount) }}
          </span>
        </div>
        <div>
          <span class="text-gray-400">应收金额</span>
          <span class="ml-2">¥{{ fenToYuan(order.payPrice ?? 0) }}</span>
        </div>
      </div>
    </Card>

    <Tabs v-model:activeKey="activeTab">
      <!-- 订单信息：基础信息 + 状态与操作提示 -->
      <TabPane key="order" tab="订单信息">
        <div class="grid grid-cols-1 gap-4 xl:grid-cols-3">
          <div class="xl:col-span-2">
            <OrderInfoDescriptions :data="order" />
          </div>
          <div>
            <OrderStatusDescriptions :data="order" />
          </div>
        </div>
      </TabPane>

      <!-- 线下收款：待核验时页签带红点，避免财务漏看 -->
      <TabPane key="payment">
        <template #tab>
          <Badge :dot="paymentPending" :offset="[6, -2]">收款信息</Badge>
        </template>

        <Card size="small">
          <div class="flex flex-wrap items-baseline gap-x-12 gap-y-3">
            <div>
              <span class="text-gray-400">已确认收款</span>
              <span class="ml-2 text-base font-semibold">
                ¥{{ fenToYuan(order.paidAmount ?? 0) }}
              </span>
            </div>
            <div>
              <span class="text-gray-400">待收货款</span>
              <span
                class="ml-2 text-base font-semibold"
                :class="remainAmount > 0 ? 'text-red-500' : 'text-green-600'"
              >
                ¥{{ fenToYuan(remainAmount) }}
              </span>
            </div>
            <div>
              <span class="text-gray-400">应收金额</span>
              <span class="ml-2">¥{{ fenToYuan(order.payPrice ?? 0) }}</span>
            </div>
            <div v-if="order.payChannelCode">
              <span class="text-gray-400">收款渠道</span>
              <span class="ml-2">
                <DictTag
                  :type="DICT_TYPE.PAY_CHANNEL_CODE"
                  :value="order.payChannelCode"
                />
              </span>
            </div>
            <div class="ml-auto">
              <Button
                type="primary"
                :disabled="!paymentPending"
                @click="handleAuditPaymentProof"
              >
                核验收款
              </Button>
            </div>
          </div>

          <Divider class="!my-3" />

          <div v-if="proofs.length === 0" class="py-2 text-gray-400">
            客户尚未上传付款凭证
          </div>
          <div v-else class="flex flex-col gap-3">
            <div
              v-for="proof in proofs"
              :key="proof.id"
              class="rounded-md border border-border p-3"
            >
              <div class="flex flex-wrap items-center gap-x-4 gap-y-2">
                <Tag :color="PROOF_STATUS_MAP[proof.status ?? 0]?.color">
                  {{ PROOF_STATUS_MAP[proof.status ?? 0]?.text }}
                </Tag>
                <span>
                  申报
                  <span class="font-medium">
                    ¥{{ fenToYuan(proof.amount ?? 0) }}
                  </span>
                </span>
                <span
                  v-if="
                    proof.confirmedAmount !== null &&
                    proof.confirmedAmount !== undefined
                  "
                >
                  核定
                  <span class="font-medium">
                    ¥{{ fenToYuan(proof.confirmedAmount) }}
                  </span>
                </span>
                <span v-if="proof.payerName" class="text-gray-400">
                  付款人：{{ proof.payerName }}
                </span>
                <DictTag
                  v-if="proof.payChannelCode"
                  :type="DICT_TYPE.PAY_CHANNEL_CODE"
                  :value="proof.payChannelCode"
                />
                <span class="text-xs text-gray-400">
                  {{ formatDateTime(proof.createTime) }}
                </span>
              </div>
              <Image.PreviewGroup>
                <Space :size="12" wrap class="mt-3">
                  <Image
                    v-for="(url, index) in proof.urls"
                    :key="index"
                    :src="url"
                    :width="128"
                    class="rounded-md border border-border"
                  />
                </Space>
              </Image.PreviewGroup>
              <div v-if="proof.auditRemark" class="mt-2 text-xs text-red-500">
                核验意见：{{ proof.auditRemark }}
              </div>
            </div>
          </div>
        </Card>
      </TabPane>

      <!-- 商品与费用 -->
      <TabPane key="goods" tab="商品与费用">
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
        <div class="mt-4">
          <OrderPriceDescriptions :data="order" />
        </div>
      </TabPane>

      <!-- 收货与物流 -->
      <TabPane key="delivery" tab="收货与物流">
        <DeliveryInfoDescriptions :data="order" />
        <div v-if="expressTrackList.length > 0" class="mt-4">
          <ExpressTrackGrid table-title="物流详情" />
        </div>
        <div v-else class="mt-4 text-gray-400">
          暂无物流轨迹（尚未发货或无需物流）
        </div>
      </TabPane>

      <!-- 操作日志：页签上带条数 -->
      <TabPane key="logs">
        <template #tab>
          操作日志
          <span v-if="order.logs?.length" class="text-gray-400">
            ({{ order.logs.length }})
          </span>
        </template>
        <OperateLogGrid table-title="操作日志">
          <template #userType="{ row }">
            <Tag v-if="row.userType === 0" color="default"> 系统 </Tag>
            <DictTag v-else :type="DICT_TYPE.USER_TYPE" :value="row.userType" />
          </template>
        </OperateLogGrid>
      </TabPane>
    </Tabs>

  </Page>
</template>
