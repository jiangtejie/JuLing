import type { VbenFormSchema } from '#/adapter/form';
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { ErpStockBatchApi } from '#/api/erp/stock/batch';

import { DICT_TYPE } from '@vben/constants';
import { erpCountInputFormatter, erpNumberFormatter } from '@vben/utils';

import { z } from '#/adapter/form';
import { getProductSimpleList } from '#/api/erp/product/product';
import {
  getStockBatchExpiryList,
  getStockBatchPage,
} from '#/api/erp/stock/batch';
import { getWarehouseSimpleList } from '#/api/erp/stock/warehouse';

/** 临期预警默认天数（与后端 DEFAULT_WARN_DAYS 一致） */
export const DEFAULT_WARN_DAYS = 30;

/** 效期筛选维度：ALL 全部 / WARNING 临期 N 天内 / EXPIRED 已过期 */
export const EXPIRY_FILTER_OPTIONS = [
  { label: '全部', value: 'ALL' },
  { label: '临期', value: 'WARNING' },
  { label: '已过期', value: 'EXPIRED' },
];

/**
 * 效期状态的展示口径（与后端 ErpStockBatchController 的取值一一对应）。
 * 颜色沿用页面既有的 antd Tag 预设色：红 = 已过期、黄（orange）= 临期。
 */
export const EXPIRY_STATUS_META: Record<
  string,
  { color: string; label: string }
> = {
  EXPIRED: { color: 'red', label: '已过期' },
  WARNING: { color: 'orange', label: '临期' },
  NORMAL: { color: 'green', label: '正常' },
  NONE: { color: 'default', label: '无有效期' },
};

/**
 * 批次日期格式化。
 *
 * 后端把 `java.time.LocalDate` 序列化成了数组（实测 `inDate: [2026,9,28]`），
 * 直接渲染会变成 "2026,9,28"；这里统一成 `yyyy-MM-dd`，
 * 已经是字符串时原样返回（兼容后端将来改成字符串）。
 */
export function formatBatchDate(value?: null | number[] | string): string {
  if (!value) {
    return '';
  }
  if (Array.isArray(value)) {
    const [year, month, day] = value;
    if (!year || !month || !day) {
      return '';
    }
    return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
  }
  return String(value);
}

/** 页面查询表单值 */
export interface StockBatchFormValues {
  batchNo?: string; // 批次号（模糊）
  expiryFilter?: string; // 效期筛选
  onlyStock?: boolean; // 只看有量（在仓 > 0）
  productId?: number; // 物料
  warehouseId?: number; // 仓库
  warnDays?: number; // 临期天数
}

/** 分页查询参数 = 表单值 + 分页 */
export interface StockBatchQueryParams extends StockBatchFormValues {
  pageNo: number;
  pageSize: number;
}

/** 搜索表单 */
export function useGridFormSchema(): VbenFormSchema[] {
  return [
    {
      fieldName: 'productId',
      label: '物料',
      component: 'ApiSelect',
      componentProps: {
        placeholder: '请选择物料',
        allowClear: true,
        showSearch: true,
        api: getProductSimpleList,
        labelField: 'name',
        valueField: 'id',
      },
    },
    {
      fieldName: 'warehouseId',
      label: '仓库',
      component: 'ApiSelect',
      componentProps: {
        placeholder: '请选择仓库',
        allowClear: true,
        showSearch: true,
        api: getWarehouseSimpleList,
        labelField: 'name',
        valueField: 'id',
      },
    },
    {
      fieldName: 'batchNo',
      label: '批次号',
      component: 'Input',
      componentProps: {
        placeholder: '请输入批次号（模糊）',
        allowClear: true,
      },
    },
    {
      fieldName: 'onlyStock',
      label: '只看有量',
      component: 'Switch',
      defaultValue: true,
      componentProps: {
        class: '!w-auto', // 开关不该被表单的全局 w-full 拉满
        checkedChildren: '只看有量',
        unCheckedChildren: '含零',
      },
    },
    {
      fieldName: 'expiryFilter',
      label: '效期筛选',
      component: 'Select',
      defaultValue: 'ALL',
      componentProps: {
        placeholder: '请选择效期筛选',
        options: EXPIRY_FILTER_OPTIONS,
      },
    },
    {
      fieldName: 'warnDays',
      label: '临期天数',
      component: 'InputNumber',
      defaultValue: DEFAULT_WARN_DAYS,
      componentProps: {
        class: 'w-full',
        min: 1,
        max: 3650,
        precision: 0,
        placeholder: '默认 30 天',
      },
      // 只在「临期」筛选下有意义
      dependencies: {
        triggerFields: ['expiryFilter'],
        show: (values) => values.expiryFilter === 'WARNING',
      },
    },
  ];
}

/** 列表的字段 */
export function useGridColumns(): VxeTableGridOptions<ErpStockBatchApi.StockBatch>['columns'] {
  return [
    {
      field: 'productName',
      title: '物料',
      minWidth: 140,
    },
    {
      field: 'warehouseName',
      title: '仓库',
      width: 110,
    },
    {
      field: 'batchNo',
      title: '批次号',
      minWidth: 160,
      showOverflow: 'tooltip',
    },
    {
      field: 'productionDate',
      title: '生产日期',
      width: 110,
      formatter: ({ cellValue }) => formatBatchDate(cellValue),
    },
    {
      field: 'expiryDate',
      title: '效期',
      width: 170,
      slots: { default: 'expiry' },
    },
    {
      field: 'count',
      title: '在仓',
      width: 110,
      align: 'right',
      formatter: 'formatAmount3',
    },
    {
      field: 'transitCount',
      title: '在途',
      width: 110,
      align: 'right',
      formatter: 'formatAmount3',
    },
    {
      field: 'occupiedCount',
      title: '占用',
      width: 110,
      align: 'right',
      formatter: 'formatAmount3',
    },
    {
      field: 'inspectingCount',
      title: '待检',
      width: 110,
      align: 'right',
      formatter: 'formatAmount3',
    },
    {
      field: 'availableCount',
      title: '可用量',
      width: 110,
      align: 'right',
      formatter: 'formatAmount3',
    },
    {
      field: 'unitCost',
      title: '单位成本',
      width: 110,
      align: 'right',
      formatter: 'formatAmount2',
    },
    {
      field: 'totalCost',
      title: '总成本',
      width: 120,
      align: 'right',
      formatter: 'formatAmount2',
    },
    {
      field: 'sourceBizNo',
      title: '来源单据号',
      minWidth: 180,
      showOverflow: 'tooltip',
    },
    {
      field: 'sourceBizType',
      title: '来源类型',
      width: 120,
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.ERP_STOCK_RECORD_BIZ_TYPE },
      },
    },
    {
      field: 'operation',
      title: '操作',
      width: 100,
      fixed: 'right',
      slots: { default: 'operation' },
    },
  ];
}

/**
 * 批次库存分页查询（页面唯一取数入口）。
 *
 * 1. 效期筛选 = 临期 / 已过期：走后端专用接口 `/erp/stock-batch/expiry-list`（在仓 > 0 且有到期日期，
 *    返回完整集合、无分页），因此批次号模糊与「只留临期」在前端完成，再按页切片；
 * 2. 效期筛选 = 全部：走 `/erp/stock-batch/page`，分页与排序沿用后端（vxe 远程分页规范）；
 * 3. 「只看有量」= 在仓 > 0（与后端 FIFO 的 onlyPositive 同口径）。后端 /page 暂无该参数，
 *    本切片不允许改后端，故对当前页做行过滤——跨页精确过滤需后端在 ErpStockBatchPageReqVO
 *    补 onlyPositive 并在 Mapper 加 `gt(count, 0)`（见 docs/stock-center.md「前端页面与菜单权限」）。
 */
export async function queryStockBatchPage(
  params: StockBatchQueryParams,
): Promise<{ list: ErpStockBatchApi.StockBatch[]; total: number }> {
  const {
    pageNo,
    pageSize,
    productId,
    warehouseId,
    batchNo,
    onlyStock = true,
    expiryFilter = 'ALL',
    warnDays = DEFAULT_WARN_DAYS,
  } = params;

  if (expiryFilter !== 'ALL') {
    const list =
      (await getStockBatchExpiryList({
        productId,
        warehouseId,
        warnDays,
        expiredOnly: expiryFilter === 'EXPIRED',
      })) ?? [];
    // expiredOnly = false 时后端返回「已过期 + 临期」，只留临期需要在前端再筛一次
    let rows =
      expiryFilter === 'WARNING'
        ? list.filter((row) => row.expiryStatus === 'WARNING')
        : list;
    if (batchNo) {
      rows = rows.filter((row) => (row.batchNo ?? '').includes(batchNo));
    }
    const start = (pageNo - 1) * pageSize;
    return { list: rows.slice(start, start + pageSize), total: rows.length };
  }

  const result = await getStockBatchPage({
    pageNo,
    pageSize,
    productId,
    warehouseId,
    batchNo,
  });
  const list = result?.list ?? [];
  if (onlyStock === false) {
    return { list, total: result?.total ?? list.length };
  }
  return {
    list: list.filter((row) => Number(row.count ?? 0) > 0),
    total: result?.total ?? list.length,
  };
}

/** 可登记的状态（在仓只能由出入库产生，不在此处登记） */
export const STOCK_STATE_OPTIONS = [
  { label: '在途', value: 'IN_TRANSIT' },
  { label: '占用', value: 'OCCUPIED' },
  { label: '待检', value: 'INSPECTING' },
];

/** 状态数量登记表单 */
export function useStateFormSchema(): VbenFormSchema[] {
  return [
    {
      fieldName: 'state',
      label: '状态',
      component: 'Select',
      componentProps: {
        placeholder: '请选择要登记的状态',
        options: STOCK_STATE_OPTIONS,
      },
      rules: 'selectRequired',
    },
    {
      fieldName: 'delta',
      label: '增量数量',
      component: 'InputNumber',
      componentProps: {
        class: 'w-full',
        precision: 3,
        placeholder: '正数增加、负数减少',
      },
      rules: z
        .number({ message: '请输入增量数量' })
        .refine((value) => value !== 0, { message: '增量数量不能为 0' }),
    },
    {
      fieldName: 'remark',
      label: '备注',
      component: 'Textarea',
      componentProps: {
        class: 'w-full',
        rows: 3,
        maxlength: 200,
        showCount: true,
        placeholder: '请输入备注',
      },
    },
  ];
}

/** 底部合计：数量（在仓/在途/占用/待检/可用量）与金额（总成本），单位成本不参与合计 */
export function buildFooterMethod() {
  const sumFields = new Set([
    'availableCount',
    'count',
    'inspectingCount',
    'occupiedCount',
    'totalCost',
    'transitCount',
  ]);
  return ({
    columns,
    data,
  }: {
    columns: Array<{ field?: string }>;
    data: ErpStockBatchApi.StockBatch[];
  }) => {
    const rows = data ?? [];
    return [
      columns.map((column, index) => {
        if (index === 0) {
          return '本页合计';
        }
        const field = column.field;
        if (!field || !sumFields.has(field)) {
          return '';
        }
        const total = rows.reduce(
          (sum, item) => sum + Number(item[field as 'count'] ?? 0),
          0,
        );
        return field === 'totalCost'
          ? erpNumberFormatter(total, 2)
          : erpCountInputFormatter(total);
      }),
    ];
  };
}
