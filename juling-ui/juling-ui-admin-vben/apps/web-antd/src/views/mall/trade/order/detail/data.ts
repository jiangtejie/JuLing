import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { DescriptionItemSchema } from '#/components/description';

import { h } from 'vue';

import { DICT_TYPE } from '@vben/constants';
import { fenToYuan, formatDateTime } from '@vben/utils';

import { DictTag } from '#/components/dict-tag';

/** 订单基础信息 schema */
export function useOrderInfoSchema(): DescriptionItemSchema[] {
  return [
    {
      field: 'no',
      label: '订单号',
    },
    {
      field: 'user.nickname',
      label: '买家',
    },
    {
      field: 'type',
      label: '订单类型',
      render: (val) =>
        h(DictTag, {
          type: DICT_TYPE.TRADE_ORDER_TYPE,
          value: val,
        }),
    },
    {
      field: 'terminal',
      label: '订单来源',
      render: (val) =>
        h(DictTag, {
          type: DICT_TYPE.TERMINAL,
          value: val,
        }),
    },
    {
      field: 'userRemark',
      label: '买家留言',
      render: (val) => val || '-',
    },
    {
      field: 'remark',
      label: '商家备注',
      render: (val) => val || '-',
    },
    // 线下收款：不再展示「支付单号」（线上支付已切除，该字段恒空）
    {
      field: 'payChannelCode',
      label: '收款渠道',
      render: (val) =>
        h(DictTag, {
          type: DICT_TYPE.PAY_CHANNEL_CODE,
          value: val,
        }),
    },
    // 门店要货：结算模式与审核进度
    {
      field: 'settlementMode',
      label: '结算模式',
      render: (val) =>
        h(DictTag, {
          type: DICT_TYPE.TRADE_SETTLEMENT_MODE,
          value: val,
        }),
    },
    {
      field: 'auditStatus',
      label: '审核状态',
      render: (val) =>
        h(DictTag, {
          type: DICT_TYPE.TRADE_ORDER_AUDIT_STATUS,
          value: val,
        }),
    },
    {
      field: 'auditRemark',
      label: '审核意见',
      render: (val) => val || '-',
    },
    {
      field: 'auditTime',
      label: '审核时间',
      render: (val) => (val ? (formatDateTime(val) as string) : '-'),
    },
  ];
}

/**
 * 收款状态 → 下一步操作提示。
 *
 * 门店订货链已去掉「收款核验」：门店在 H5 提交付款凭证后订单直接变成「待发货」，
 * 并自动进入「供应链 → 财务」两级审批；审批通过才算认定收款（认定金额 = 门店申报金额）。
 * 因此这里的金额口径是「门店申报金额」（order.paidAmount），不再是后台核定的收款额。
 */
const RECEIVE_PROMPT: Record<number, string> = {
  0: '等待门店上传付款凭证：门店转账后在 H5 提交凭证，订单会自动进入待发货并提交两级审批',
  1: '「待核验」已随收款核验下线，不再产生；历史数据请以「审核状态」为准',
  2: '凭证已被审批驳回，等待门店重新上传；门店重传后会自动再次提交审批，无需人工操作',
  3: '门店申报金额不足应收，财务审批时需确认：通过则差额挂门店往来，驳回则要求门店补传凭证',
  4: '门店申报金额已收齐，等待审批通过后即可安排发货',
};

/** 订单状态信息 schema */
export function useOrderStatusSchema(): DescriptionItemSchema[] {
  return [
    {
      field: 'status',
      label: '订单状态',
      render: (val) =>
        h(DictTag, {
          type: DICT_TYPE.TRADE_ORDER_STATUS,
          value: val,
        }),
    },
    {
      field: 'reminder',
      label: '提醒',
      render: (_val, data) => {
        const receiveStatus: number = data?.paymentProofStatus ?? 0;
        const remain = Math.max(
          0,
          (data?.payPrice ?? 0) - (data?.paidAmount ?? 0),
        );
        return h(
          'div',
          { class: 'space-y-1 leading-6' },
          [
            h('div', RECEIVE_PROMPT[receiveStatus] ?? RECEIVE_PROMPT[0]),
            receiveStatus !== 4 &&
              h(
                'div',
                { class: 'text-red-500' },
                `待收货款（应收 - 门店申报）：${fenToYuan(remain)} 元`,
              ),
            h(
              'div',
              { class: 'text-gray-400' },
              '发货后请关注物流状态，确保可配送至客户手中',
            ),
          ].filter(Boolean),
        );
      },
    },
  ];
}

/** 订单金额信息 schema */
export function useOrderPriceSchema(): DescriptionItemSchema[] {
  return [
    {
      field: 'totalPrice',
      label: '商品总额',
      render: (val) => `${fenToYuan(val ?? 0)} 元`,
    },
    {
      field: 'deliveryPrice',
      label: '运费金额',
      render: (val) => `${fenToYuan(val ?? 0)} 元`,
    },
    {
      field: 'adjustPrice',
      label: '订单调价',
      render: (val) => `${fenToYuan(val ?? 0)} 元`,
    },
    {
      field: 'couponPrice',
      label: '优惠劵优惠',
      render: (val) =>
        h('span', { class: 'text-red-500' }, `${fenToYuan(val ?? 0)} 元`),
    },
    {
      field: 'vipPrice',
      label: 'VIP 优惠',
      render: (val) =>
        h('span', { class: 'text-red-500' }, `${fenToYuan(val ?? 0)} 元`),
    },
    {
      field: 'discountPrice',
      label: '活动优惠',
      render: (val) =>
        h('span', { class: 'text-red-500' }, `${fenToYuan(val ?? 0)} 元`),
    },
    {
      field: 'pointPrice',
      label: '积分抵扣',
      render: (val) =>
        h('span', { class: 'text-red-500' }, `${fenToYuan(val ?? 0)} 元`),
    },
    {
      field: 'payPrice',
      label: '应付金额',
      render: (val) => `${fenToYuan(val ?? 0)} 元`,
    },
  ];
}

/** 收货信息 schema */
export function useDeliveryInfoSchema(): DescriptionItemSchema[] {
  return [
    {
      field: 'deliveryType',
      label: '配送方式',
      render: (val) =>
        h(DictTag, {
          type: DICT_TYPE.TRADE_DELIVERY_TYPE,
          value: val,
        }),
    },
    {
      field: 'receiverName',
      label: '收货人',
    },
    {
      field: 'receiverMobile',
      label: '联系电话',
    },
    {
      // 注意：后端字段是 receiverDetailAddress，没有 receiverAddress；
      // 另外地区名可能为 null（App 端下单未选地区），必须过滤，否则会渲染出 "null undefined"
      field: 'receiverDetailAddress',
      label: '收货地址',
      span: 2,
      render: (val, data) =>
        [data?.receiverAreaName, val].filter(Boolean).join(' ') || '-',
    },
    {
      field: 'deliveryTime',
      label: '发货时间',
      render: (val) => formatDateTime(val) as string,
    },
  ];
}

/** 商品信息 columns */
export function useProductColumns(): VxeTableGridOptions['columns'] {
  return [
    {
      field: 'picUrl',
      title: '图片',
      width: 84,
      slots: { default: 'spuPic' },
    },
    {
      field: 'spuName',
      title: '商品',
      minWidth: 220,
      slots: { default: 'spuName' },
    },
    {
      field: 'price',
      title: '商品原价',
      width: 150,
      formatter: 'formatFenToYuanAmount',
    },
    {
      field: 'count',
      title: '数量',
      width: 100,
    },
    {
      field: 'payPrice',
      title: '合计',
      width: 150,
      formatter: 'formatFenToYuanAmount',
    },
    {
      field: 'afterSaleStatus',
      title: '售后状态',
      width: 120,
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.TRADE_ORDER_ITEM_AFTER_SALE_STATUS },
      },
    },
  ];
}

/** 物流详情 columns */
export function useExpressTrackColumns(): VxeTableGridOptions['columns'] {
  return [
    {
      field: 'time',
      title: '时间',
      width: 180,
      formatter: 'formatDateTime',
    },
    {
      field: 'content',
      title: '物流状态',
      minWidth: 300,
    },
  ];
}

/** 操作日志 columns */
export function useOperateLogColumns(): VxeTableGridOptions['columns'] {
  return [
    {
      field: 'createTime',
      title: '操作时间',
      width: 180,
      formatter: 'formatDateTime',
    },
    {
      field: 'userType',
      title: '操作人',
      width: 100,
      slots: { default: 'userType' },
    },
    {
      field: 'content',
      title: '操作内容',
      minWidth: 200,
    },
  ];
}
