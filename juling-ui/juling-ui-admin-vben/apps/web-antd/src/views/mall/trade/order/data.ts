import type { VbenFormSchema } from '#/adapter/form';
import type { VxeGridPropTypes } from '#/adapter/vxe-table';
import type { MallDeliveryPickUpStoreApi } from '#/api/mall/trade/delivery/pickUpStore';

import { markRaw } from 'vue';

import { DeliveryTypeEnum, DICT_TYPE } from '@vben/constants';
import { getDictOptions } from '@vben/hooks';
import { convertToInteger, formatToFraction } from '@vben/utils';

import { getSimpleDeliveryExpressList } from '#/api/mall/trade/delivery/express';
import { getSimpleDeliveryPickUpStoreList } from '#/api/mall/trade/delivery/pickUpStore';
import { AreaCascader } from '#/components/area';
import { getRangePickerDefaultProps } from '#/utils';

/** 关联数据 */
let pickUpStoreList: MallDeliveryPickUpStoreApi.DeliveryPickUpStore[] = [];
getSimpleDeliveryPickUpStoreList().then((data) => {
  pickUpStoreList = data;
});

/** 列表的搜索表单 */
export function useGridFormSchema(): VbenFormSchema[] {
  return [
    {
      fieldName: 'status',
      label: '订单状态',
      component: 'Select',
      componentProps: {
        options: getDictOptions(DICT_TYPE.TRADE_ORDER_STATUS, 'number'),
        placeholder: '请选择订单状态',
        allowClear: true,
      },
    },
    {
      fieldName: 'payChannelCode',
      label: '支付方式',
      component: 'Select',
      componentProps: {
        options: getDictOptions(DICT_TYPE.PAY_CHANNEL_CODE, 'number'),
        placeholder: '请选择支付方式',
        allowClear: true,
      },
    },
    {
      fieldName: 'paymentProofStatus',
      label: '收款状态',
      component: 'Select',
      componentProps: {
        options: getDictOptions(DICT_TYPE.TRADE_PAYMENT_PROOF_STATUS, 'number'),
        placeholder: '请选择收款状态',
        allowClear: true,
      },
    },
    {
      fieldName: 'createTime',
      label: '创建时间',
      component: 'RangePicker',
      componentProps: {
        ...getRangePickerDefaultProps(),
        allowClear: true,
      },
    },
    {
      fieldName: 'terminal',
      label: '订单来源',
      component: 'Select',
      componentProps: {
        options: getDictOptions(DICT_TYPE.TERMINAL, 'number'),
        placeholder: '请选择订单来源',
        allowClear: true,
      },
    },
    {
      fieldName: 'deliveryType',
      label: '配送方式',
      component: 'Select',
      componentProps: {
        options: getDictOptions(DICT_TYPE.TRADE_DELIVERY_TYPE, 'number'),
        placeholder: '请选择配送方式',
        allowClear: true,
      },
    },
    {
      fieldName: 'logisticsId',
      label: '快递公司',
      component: 'ApiSelect',
      componentProps: {
        api: getSimpleDeliveryExpressList,
        labelField: 'name',
        valueField: 'id',
        placeholder: '请选择快递公司',
        allowClear: true,
      },
      dependencies: {
        triggerFields: ['deliveryType'],
        show: (values) => values.deliveryType === DeliveryTypeEnum.EXPRESS.type,
      },
    },
    {
      fieldName: 'pickUpStoreId',
      label: '自提门店',
      component: 'ApiSelect',
      componentProps: {
        api: getSimpleDeliveryPickUpStoreList,
        labelField: 'name',
        valueField: 'id',
        placeholder: '请选择自提门店',
        allowClear: true,
      },
      dependencies: {
        triggerFields: ['deliveryType'],
        show: (values) => values.deliveryType === DeliveryTypeEnum.PICK_UP.type,
      },
    },
    {
      fieldName: 'pickUpVerifyCode',
      label: '核销码',
      component: 'Input',
      componentProps: {
        placeholder: '请输入核销码',
        allowClear: true,
      },
      dependencies: {
        triggerFields: ['deliveryType'],
        show: (values) => values.deliveryType === DeliveryTypeEnum.PICK_UP.type,
      },
    },
    {
      fieldName: 'no',
      label: '订单号',
      component: 'Input',
      componentProps: {
        placeholder: '请输入订单号',
        allowClear: true,
      },
    },
    {
      fieldName: 'userId',
      label: '用户 UID',
      component: 'Input',
      componentProps: {
        placeholder: '请输入用户 UID',
        allowClear: true,
      },
    },
    {
      fieldName: 'userNickname',
      label: '用户昵称',
      component: 'Input',
      componentProps: {
        placeholder: '请输入用户昵称',
        allowClear: true,
      },
    },
    {
      fieldName: 'userMobile',
      label: '用户电话',
      component: 'Input',
      componentProps: {
        placeholder: '请输入用户电话',
        allowClear: true,
      },
    },
  ];
}

/** 表格列配置 */
export function useGridColumns(): VxeGridPropTypes.Columns {
  return [
    {
      // 展开列：content 插槽是展开后的明细区域，default 插槽放自定义展开按钮。
      // vxe 自带的展开按钮在本版本默认隐藏且点击无效，这里显式提供入口。
      type: 'expand',
      title: '明细',
      width: 90,
      slots: { default: 'expand_toggle', content: 'expand_content' },
      fixed: 'left',
    },
    {
      field: 'no',
      title: '订单号',
      fixed: 'left',
      minWidth: 180,
    },
    {
      field: 'createTime',
      title: '下单时间',
      formatter: 'formatDateTime',
      minWidth: 160,
    },
    {
      field: 'terminal',
      title: '订单来源',
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.TERMINAL },
      },
      minWidth: 120,
    },
    {
      field: 'payChannelCode',
      title: '支付方式',
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.PAY_CHANNEL_CODE },
      },
      minWidth: 120,
    },
    {
      field: 'payTime',
      title: '支付时间',
      formatter: 'formatDateTime',
      minWidth: 160,
    },
    {
      field: 'type',
      title: '订单类型',
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.TRADE_ORDER_TYPE },
      },
      minWidth: 80,
    },
    {
      field: 'payPrice',
      title: '实际支付',
      formatter: 'formatFenToYuanAmount',
      minWidth: 180,
    },
    {
      field: 'paymentProofStatus',
      title: '收款状态',
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.TRADE_PAYMENT_PROOF_STATUS },
      },
      minWidth: 110,
    },
    {
      field: 'paidAmount',
      title: '已确认收款',
      formatter: 'formatFenToYuanAmount',
      minWidth: 120,
    },
    {
      field: 'user',
      title: '买家/收货人',
      formatter: ({ row }) => {
        if (row.deliveryType === DeliveryTypeEnum.EXPRESS.type) {
          // 地区名可能为空（App 端下单未选地区），必须过滤，否则会拼出 'null'；
          // 各段之间也要有分隔，避免手机号与地址粘在一起
          const receiver = [
            row.receiverName,
            row.receiverMobile,
            row.receiverAreaName,
            row.receiverDetailAddress,
          ]
            .filter(Boolean)
            .join(' ');
          return `买家：${row.user?.nickname ?? '-'} / 收货人：${receiver || '-'}`;
        }
        if (row.deliveryType === DeliveryTypeEnum.PICK_UP.type) {
          const store = pickUpStoreList.find(
            (item) => item.id === row.pickUpStoreId,
          );
          const parts = [
            store?.name && `门店名称：${store.name}`,
            store?.phone && `门店手机：${store.phone}`,
            store?.detailAddress && `自提门店：${store.detailAddress}`,
          ].filter(Boolean);
          return parts.join(' / ') || '-';
        }
        return '-';
      },
      minWidth: 180,
    },
    {
      field: 'deliveryType',
      title: '配送方式',
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.TRADE_DELIVERY_TYPE },
      },
      minWidth: 80,
    },
    {
      field: 'status',
      title: '订单状态',
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.TRADE_ORDER_STATUS },
      },
      minWidth: 80,
    },
    {
      title: '操作',
      width: 180,
      fixed: 'right',
      slots: { default: 'actions' },
    },
  ];
}

/** 订单备注表单配置 */
export function useRemarkFormSchema(): VbenFormSchema[] {
  return [
    {
      component: 'Input',
      fieldName: 'id',
      dependencies: {
        triggerFields: [''],
        show: () => false,
      },
    },
    {
      fieldName: 'remark',
      label: '备注',
      component: 'Input',
      componentProps: {
        type: 'textarea',
        rows: 3,
      },
    },
  ];
}

/** 订单调价表单配置 */
export function usePriceFormSchema(): VbenFormSchema[] {
  return [
    {
      component: 'Input',
      fieldName: 'id',
      dependencies: {
        triggerFields: [''],
        show: () => false,
      },
    },
    {
      fieldName: 'payPrice',
      label: '应付金额(总)',
      component: 'Input',
      componentProps: {
        placeholder: '请输入应付金额(总)',
        disabled: true,
        formatter: (value: string) => `${value}元`,
      },
    },
    {
      fieldName: 'adjustPrice',
      label: '订单调价',
      component: 'InputNumber',
      componentProps: {
        class: '!w-full',
        placeholder: '请输入订单调价',
        step: 0.1,
        precision: 2,
      },
      help: '订单调价。 正数，加价；负数，减价',
      rules: 'required',
    },
    {
      fieldName: 'newPayPrice',
      label: '调价后',
      component: 'Input',
      componentProps: {
        placeholder: '',
        formatter: (value: string) => `${value}元`,
      },
      dependencies: {
        triggerFields: ['payPrice', 'adjustPrice'],
        disabled: true,
        trigger(values, form) {
          const originalPrice = convertToInteger(values.payPrice);
          const adjustPrice = convertToInteger(values.adjustPrice);
          const newPrice = originalPrice + adjustPrice;
          form.setFieldValue('newPayPrice', formatToFraction(newPrice));
        },
      },
    },
  ];
}

/** 订单修改地址表单配置 */
export function useAddressFormSchema(): VbenFormSchema[] {
  return [
    {
      component: 'Input',
      fieldName: 'id',
      dependencies: {
        triggerFields: [''],
        show: () => false,
      },
    },
    {
      fieldName: 'receiverName',
      label: '收件人',
      component: 'Input',
      componentProps: {
        placeholder: '请输入收件人名称',
      },
      rules: 'required',
    },
    {
      fieldName: 'receiverMobile',
      label: '手机号',
      component: 'Input',
      componentProps: {
        placeholder: '请输入收件人手机号',
      },
      rules: 'required',
    },
    {
      fieldName: 'receiverAreaId',
      label: '所在地',
      component: markRaw(AreaCascader),
      componentProps: {
        allowClear: true,
        changeOnSelect: true,
        class: '!w-full',
        placeholder: '请选择收件人所在地',
        showSearch: true,
      },
      rules: 'required',
    },
    {
      fieldName: 'receiverDetailAddress',
      label: '详细地址',
      component: 'Input',
      componentProps: {
        placeholder: '请输入收件人详细地址',
        type: 'textarea',
        rows: 3,
      },
      rules: 'required',
    },
  ];
}

/** 订单发货表单配置 */
export function useDeliveryFormSchema(): VbenFormSchema[] {
  return [
    {
      component: 'Input',
      fieldName: 'id',
      dependencies: {
        triggerFields: [''],
        show: () => false,
      },
    },
    {
      fieldName: 'expressType',
      label: '发货方式',
      component: 'RadioGroup',
      componentProps: {
        options: [
          { label: '快递', value: 'express' },
          { label: '无需发货', value: 'none' },
        ],
        buttonStyle: 'solid',
        optionType: 'button',
      },
      defaultValue: 'express',
    },
    {
      fieldName: 'logisticsId',
      label: '物流公司',
      component: 'ApiSelect',
      componentProps: {
        api: getSimpleDeliveryExpressList,
        labelField: 'name',
        valueField: 'id',
        placeholder: '请选择物流公司',
      },
      dependencies: {
        triggerFields: ['expressType'],
        show: (values) => values.expressType === 'express',
      },
      rules: 'required',
    },
    {
      fieldName: 'logisticsNo',
      label: '物流单号',
      component: 'Input',
      componentProps: {
        placeholder: '请输入物流单号',
      },
      dependencies: {
        triggerFields: ['expressType'],
        show: (values) => values.expressType === 'express',
      },
      rules: 'required',
    },
  ];
}
