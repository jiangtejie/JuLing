import type { VbenFormSchema } from '#/adapter/form';

export const schema: VbenFormSchema[] = [
  {
    component: 'Input',
    fieldName: 'id',
    dependencies: {
      triggerFields: [''],
      show: () => false,
    },
  },
  {
    component: 'Input',
    fieldName: 'type',
    dependencies: {
      triggerFields: [''],
      show: () => false,
    },
  },
  {
    fieldName: 'afterSaleRefundReasons',
    label: '退款理由',
    component: 'Select',
    componentProps: {
      placeholder: '请直接输入退款理由',
      multiple: true,
      options: [],
      class: 'w-full',
      allowCreate: true,
      filterable: true,
      reserveKeyword: false,
    },
    dependencies: {
      triggerFields: ['type'],
      show: (values) => values.type === 'afterSale',
    },
  },
  {
    fieldName: 'afterSaleReturnReasons',
    label: '退货理由',
    component: 'Select',
    componentProps: {
      placeholder: '请直接输入退货理由',
      multiple: true,
      options: [],
      class: 'w-full',
      allowCreate: true,
      filterable: true,
      reserveKeyword: false,
    },
    dependencies: {
      triggerFields: ['type'],
      show: (values) => values.type === 'afterSale',
    },
  },
  {
    fieldName: 'deliveryExpressFreeEnabled',
    label: '启用包邮',
    component: 'Switch',
    rules: 'required',
    dependencies: {
      triggerFields: ['type'],
      show: (values) => values.type === 'delivery',
    },
    help: '商城是否启用全场包邮',
  },
  {
    fieldName: 'deliveryExpressFreePrice',
    label: '满额包邮',
    component: 'InputNumber',
    componentProps: {
      min: 0,
      precision: 2,
      placeholder: '请输入满额包邮金额',
      controlsPosition: 'right',
      class: '!w-full',
    },
    rules: 'required',
    dependencies: {
      triggerFields: ['type'],
      show: (values) => values.type === 'delivery',
    },
    help: '商城商品满多少金额即可包邮，单位：元',
  },
];
