import type { VbenFormSchema } from '#/adapter/form';
import type { VxeTableGridOptions } from '#/adapter/vxe-table';

import { DICT_TYPE } from '@vben/constants';

import { getRangePickerDefaultProps } from '#/utils';

/** 订单工作台 - 列表的搜索表单 */
export function useGridFormSchema(): VbenFormSchema[] {
  return [
    {
      fieldName: 'no',
      label: '要货单号',
      component: 'Input',
      componentProps: {
        placeholder: '请输入要货单号',
        allowClear: true,
      },
    },
    {
      fieldName: 'customerId',
      label: '门店客户编号',
      component: 'Input',
      componentProps: {
        placeholder: '请输入门店客户编号',
        allowClear: true,
      },
    },
    {
      fieldName: 'createTime',
      label: '下单时间',
      component: 'RangePicker',
      componentProps: {
        ...getRangePickerDefaultProps(),
        allowClear: true,
      },
    },
  ];
}

/** 订单工作台 - 待处理要货单列表字段 */
export function useGridColumns(): VxeTableGridOptions['columns'] {
  return [
    { type: 'expand', width: 46, fixed: 'left', slots: { content: 'expand_content' } },
    {
      field: 'no',
      title: '要货单号',
      minWidth: 190,
    },
    {
      field: 'customerName',
      title: '门店',
      minWidth: 190,
    },
    {
      field: 'storeType',
      title: '店型',
      minWidth: 90,
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.ERP_STORE_TYPE },
      },
    },
    {
      field: 'createTime',
      title: '下单时间',
      minWidth: 170,
      formatter: 'formatDateTime',
    },
    {
      field: 'payPrice',
      title: '应付金额',
      minWidth: 110,
      formatter: 'formatAmount2',
    },
    {
      field: 'paidAmount',
      title: '已收款',
      minWidth: 110,
      formatter: 'formatAmount2',
    },
    {
      field: 'paymentProofStatus',
      title: '收款状态',
      minWidth: 110,
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.TRADE_PAYMENT_PROOF_STATUS },
      },
    },
    {
      field: 'auditStatus',
      title: '审核状态',
      minWidth: 110,
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.TRADE_ORDER_AUDIT_STATUS },
      },
    },
    {
      field: 'pendingItemCount',
      title: '未分料行',
      minWidth: 100,
    },
    {
      title: '操作',
      width: 110,
      fixed: 'right',
      slots: { default: 'actions' },
    },
  ];
}

/** 明细行的分料方式选项（按物料的 allowCentral / allowDirect 过滤） */
export function useAllocModeOptions(allowCentral?: boolean, allowDirect?: boolean) {
  const options: { label: string; value: string }[] = [];
  if (allowCentral) {
    options.push({ label: '统配（配送出库）', value: 'CENTRAL' });
  }
  if (allowDirect) {
    options.push({ label: '直拨（采购订单）', value: 'DIRECT' });
  }
  return options;
}

/** 明细行表格列 */
export function useItemColumns(): any[] {
  return [
    { title: '商品', dataIndex: 'spuName', key: 'spuName', width: 200 },
    { title: '要货数量', dataIndex: 'count', key: 'count', width: 90 },
    {
      title: '单价',
      dataIndex: 'price',
      key: 'price',
      width: 110,
      customRender: ({ text }: any) => (text === undefined || text === null ? '-' : fenToYuanText(text)),
    },
    {
      title: '合计',
      dataIndex: 'payPrice',
      key: 'payPrice',
      width: 110,
      customRender: ({ text }: any) => (text === undefined || text === null ? '-' : fenToYuanText(text)),
    },
    {
      title: '可下推提示',
      dataIndex: 'availableHint',
      key: 'availableHint',
      width: 220,
    },
    { title: '分料方式', key: 'allocMode', width: 210, slots: { default: 'allocMode' } },
    { title: '下推数量', key: 'pushCount', width: 140, slots: { default: 'pushCount' } },
    { title: '供应商（直拨）', key: 'supplierId', width: 200, slots: { default: 'supplierId' } },
  ];
}

function fenToYuanText(fen: number) {
  return (fen / 100).toFixed(2);
}

export { fenToYuanText };
