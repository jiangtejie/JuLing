import type { VbenFormSchema } from '#/adapter/form';
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { ErpPurchasePriceApi } from '#/api/erp/price-list';

import { CommonStatusEnum, DICT_TYPE } from '@vben/constants';
import { getDictOptions } from '@vben/hooks';
import { erpPriceInputFormatter } from '@vben/utils';

import { z } from '#/adapter/form';
import { getSupplierSimpleList } from '#/api/erp/purchase/supplier';
import { getCustomerSimpleList } from '#/api/erp/sale/customer';
import { getSimpleUserList } from '#/api/system/user';

/** 新增/修改的表单（表头字段；明细用 items 插槽渲染） */
export function useFormSchema(
  formType: 'create' | 'detail' | 'edit',
  priceType: 'DELIVERY' | 'PURCHASE' = 'PURCHASE',
): VbenFormSchema[] {
  const isDelivery = priceType === 'DELIVERY';
  return [
    {
      component: 'Input',
      fieldName: 'id',
      dependencies: { triggerFields: [''], show: () => false },
    },
    {
      fieldName: 'name',
      label: '价目表名称',
      component: 'Input',
      rules: 'required',
      componentProps: {
        placeholder: '如：2026 年度彩云西南食品报价',
        disabled: formType === 'detail',
      },
    },
    {
      // 适用范围：一张价目表可以指定适用哪些对象（采购=供应商 / 配送=门店）
      fieldName: 'scopePartnerIds',
      label: isDelivery ? '适用门店' : '适用供应商',
      component: 'ApiSelect',
      componentProps: {
        placeholder: isDelivery ? '留空表示通用（不限门店）' : '留空表示通用（不限供应商）',
        allowClear: true,
        showSearch: true,
        mode: 'multiple',
        api: isDelivery ? getCustomerSimpleList : getSupplierSimpleList,
        labelField: 'name',
        valueField: 'id',
        disabled: formType === 'detail',
      },
      help: isDelivery
        ? '可以多选：这张配送价目表对哪些门店生效；留空 = 通用（不限门店）'
        : '可以多选；留空 = 通用（不限供应商）',
    },
    {
      fieldName: 'scopeIsDefault',
      label: '默认价目表',
      component: 'Switch',
      componentProps: {
        class: '!w-auto', // 开关不该被表单的全局 w-full 拉满
        checkedChildren: '默认',
        unCheckedChildren: '普通',
      },
      defaultValue: false,
      help: '取价时优先取它。注：当前界面是整张表一个开关，数据库支持「只对部分门店默认」，后续可细化',
    },
    {
      fieldName: 'priceIncludesTax',
      label: '含税报价',
      component: 'Switch',
      componentProps: {
        class: '!w-auto', // 开关不该被表单的全局 w-full 拉满
        checkedChildren: '含税',
        unCheckedChildren: '不含税',
      },
      defaultValue: false,
      help: '供应商报价的口径；明细行两个单价列可互算，存的一直是不含税价',
    },
    {
      fieldName: 'pricerUserId',
      label: '定价员',
      component: 'ApiSelect',
      componentProps: {
        placeholder: '请选择定价员',
        allowClear: true,
        showSearch: true,
        api: getSimpleUserList,
        labelField: 'nickname',
        valueField: 'id',
        disabled: formType === 'detail',
      },
      help: '价格的制定人，与「录入人」区分',
    },
    {
      fieldName: 'status',
      label: '状态',
      component: 'RadioGroup',
      componentProps: {
        options: getDictOptions(DICT_TYPE.COMMON_STATUS, 'number'),
        buttonStyle: 'solid',
        optionType: 'button',
      },
      rules: z.number().default(CommonStatusEnum.ENABLE),
      help: '仅启用中的价目表参与取价',
    },
    {
      fieldName: 'effectiveDate',
      label: '生效日期',
      component: 'DatePicker',
      componentProps: {
        class: '!w-full',
        placeholder: '留空表示不限',
        valueFormat: 'YYYY-MM-DD',
        disabled: formType === 'detail',
      },
    },
    {
      fieldName: 'expiryDate',
      label: '失效日期',
      component: 'DatePicker',
      componentProps: {
        class: '!w-full',
        placeholder: '留空表示长期有效',
        valueFormat: 'YYYY-MM-DD',
        disabled: formType === 'detail',
      },
    },
    {
      fieldName: 'remark',
      label: '备注',
      component: 'Textarea',
      formItemClass: 'col-span-2',
      componentProps: {
        placeholder: '如：年度框架协议价',
        rows: 2,
        disabled: formType === 'detail',
      },
    },
    {
      // 明细用插槽渲染：form.vue 里 <template #items>，字段名必须与插槽名一致。
      // 标题由这里的 label 提供，item-form 里**不再重复写标题**（原先两处都有，界面上出现了两次）
      fieldName: 'items',
      label: '价目表明细',
      component: 'Input',
      formItemClass: 'col-span-2',
    },
  ];
}

/** 搜索表单 */
export function useGridFormSchema(): VbenFormSchema[] {
  return [
    {
      fieldName: 'code',
      label: '编码',
      component: 'Input',
      componentProps: { placeholder: '请输入编码', allowClear: true },
    },
    {
      fieldName: 'name',
      label: '名称',
      component: 'Input',
      componentProps: { placeholder: '请输入价目表名称', allowClear: true },
    },

    {
      fieldName: 'status',
      label: '状态',
      component: 'Select',
      componentProps: {
        placeholder: '请选择状态',
        allowClear: true,
        options: getDictOptions(DICT_TYPE.COMMON_STATUS, 'number'),
      },
    },
  ];
}

/** 列表的字段 */
export function useGridColumns(): VxeTableGridOptions<ErpPurchasePriceApi.Price>['columns'] {
  return [
    { type: 'checkbox', width: 40 },
    { field: 'code', title: '编码', width: 120, formatter: ({ cellValue }) => cellValue || '-' },
    { field: 'name', title: '名称', minWidth: 200 },
    {
      field: 'scopeSummary',
      title: '适用范围',
      minWidth: 180,
      formatter: ({ cellValue }) => cellValue || '通用（不限）',
    },
    {
      field: 'isDefault',
      title: '默认价目表',
      width: 110,
      formatter: ({ cellValue }) => (cellValue ? '是' : '否'),
    },
    {
      field: 'priceIncludesTax',
      title: '报价口径',
      width: 100,
      formatter: ({ cellValue }) => (cellValue ? '含税' : '不含税'),
    },
    { field: 'pricerUserName', title: '定价员', width: 100, formatter: ({ cellValue }) => cellValue || '-' },
    {
      field: 'status',
      title: '状态',
      width: 90,
      cellRender: { name: 'CellDict', props: { type: DICT_TYPE.COMMON_STATUS } },
    },
    {
      field: 'effectiveDate',
      title: '生效日期',
      width: 120,
      formatter: ({ cellValue }) => cellValue || '不限',
    },
    {
      field: 'expiryDate',
      title: '失效日期',
      width: 120,
      formatter: ({ cellValue }) => cellValue || '长期',
    },
    { field: 'itemCount', title: '明细行数', width: 100, formatter: ({ cellValue }) => cellValue ?? 0 },
    { field: 'remark', title: '备注', minWidth: 100, showOverflow: 'tooltip' },
    { title: '操作', width: 130, fixed: 'right', slots: { default: 'actions' } },
  ];
}

/** 明细行的字段 */
export function useItemColumns(): VxeTableGridOptions<ErpPurchasePriceApi.Item>['columns'] {
  return [
    {
      field: 'productId',
      title: '物料',
      minWidth: 160,
      slots: { default: 'productId' },
    },
    {
      field: 'spec',
      title: '规格型号',
      minWidth: 100,
      showOverflow: 'tooltip',
      formatter: ({ cellValue }) => cellValue || '-',
    },
    {
      field: 'unitName',
      title: '计价单位',
      minWidth: 80,
      formatter: ({ cellValue }) => cellValue || '-',
    },
    { field: 'price', title: '单价(不含税)', width: 110, slots: { default: 'price' } },
    { field: 'taxPercent', title: '税率%', width: 75, slots: { default: 'taxPercent' } },
    // 含税单价：与「单价(不含税)」互算 —— 改任一个，另一个自动跟着变
    // （后端只存不含税，见 sql/local/67 的设计说明）
    { field: 'taxPrice', title: '含税单价', width: 95, slots: { default: 'taxPrice' } },
    { field: 'remark', title: '备注', minWidth: 120, slots: { default: 'remark' } },
    { title: '操作', width: 70, fixed: 'right', slots: { default: 'actions' } },
  ];
}

export { erpPriceInputFormatter };
