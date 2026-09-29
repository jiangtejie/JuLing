import type { VbenFormSchema } from '#/adapter/form';
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { TradeWorkbenchApi } from '#/api/mall/trade/workbench';

import { DICT_TYPE } from '@vben/constants';

import { getRangePickerDefaultProps } from '#/utils';

/**
 * 要货单明细行（前端态）
 *
 * 在接口类型之上补 ERP 库存中心（S2 切片一）暴露的真实可用量字段：
 * 可用量 = 在仓 − 占用 + 在途，由后端 ErpStockQtyApi 计算（默认发货仓 = 中心库）。
 */
export interface WorkbenchItem extends TradeWorkbenchApi.Item {
  erpWarehouseId?: number;
  erpWarehouseName?: string;
  erpOnHandCount?: number;
  erpOccupiedCount?: number;
  erpInTransitCount?: number;
  erpAvailableCount?: number;
}

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
      title: 'ERP 可用量（在仓 − 占用 + 在途）',
      dataIndex: 'availableHint',
      key: 'availableHint',
      width: 340,
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
