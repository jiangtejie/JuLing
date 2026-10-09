import type { VbenFormSchema } from '#/adapter/form';
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { SystemCodeRuleApi } from '#/api/system/code-rule';

import { z } from '#/adapter/form';

/** 搜索表单 */
export function useGridFormSchema(): VbenFormSchema[] {
  return [
    {
      fieldName: 'ruleKey',
      label: '规则标识',
      component: 'Input',
      componentProps: { allowClear: true, placeholder: '请输入规则标识' },
    },
    {
      fieldName: 'name',
      label: '规则名称',
      component: 'Input',
      componentProps: { allowClear: true, placeholder: '请输入规则名称' },
    },
  ];
}

/** 列表字段 */
export function useGridColumns(): VxeTableGridOptions<SystemCodeRuleApi.CodeRule>['columns'] {
  return [
    { field: 'ruleKey', title: '规则标识', minWidth: 160 },
    { field: 'name', title: '规则名称', minWidth: 160 },
    { field: 'prefix', title: '前缀', width: 90 },
    { field: 'seqLength', title: '流水位数', width: 100 },
    { field: 'currentValue', title: '当前流水', width: 100 },
    { field: 'nextCode', title: '下一个编码', width: 140 },
    {
      field: 'remark',
      title: '备注',
      minWidth: 160,
      formatter: ({ cellValue }) => cellValue || '-',
    },
    { title: '操作', width: 160, fixed: 'right', slots: { default: 'actions' } },
  ];
}

/** 新增/修改的表单 */
export function useFormSchema(): VbenFormSchema[] {
  return [
    {
      fieldName: 'id',
      component: 'Input',
      dependencies: {
        triggerFields: [''],
        show: () => false,
      },
    },
    {
      fieldName: 'ruleKey',
      label: '规则标识',
      component: 'Input',
      componentProps: {
        maxlength: 64,
        placeholder: '与主数据对象一一对应，如 erp_customer',
      },
      rules: 'required',
      help: '代码里按这个标识取号；创建后不建议修改',
    },
    {
      fieldName: 'name',
      label: '规则名称',
      component: 'Input',
      componentProps: { maxlength: 64, placeholder: '如：客户（门店）编码' },
      rules: 'required',
    },
    {
      fieldName: 'prefix',
      label: '编码前缀',
      component: 'Input',
      componentProps: { maxlength: 16, placeholder: '如：KH' },
      rules: 'required',
    },
    {
      fieldName: 'seqLength',
      label: '流水位数',
      component: 'InputNumber',
      componentProps: {
        class: '!w-full',
        max: 12,
        min: 1,
        placeholder: '如：6 → KH000001',
      },
      rules: z.number().min(1).max(12),
      help: '编码 = 前缀 + 流水左补零，如 KH + 000001',
    },
    {
      fieldName: 'remark',
      label: '备注',
      component: 'Textarea',
      componentProps: { placeholder: '请输入备注' },
    },
  ];
}
