import type { VbenFormSchema } from '#/adapter/form';
import type { VxeTableGridOptions } from '#/adapter/vxe-table';

import { CommonStatusEnum, DICT_TYPE } from '@vben/constants';
import { getDictOptions } from '@vben/hooks';

import { z } from '#/adapter/form';

/** 证照类上传的接受类型（营业执照 / 生产许可证） */
const LICENSE_ACCEPT = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];

/** 表单分组标题（对齐 docs/supplier-master-data-design.md 的分组建议） */
function divider(fieldName: string, title: string): VbenFormSchema {
  return {
    fieldName,
    component: 'Divider',
    label: '',
    formItemClass: 'col-span-2', // 分组标题占满两列，否则只占半行
    renderComponentContent: () => ({ default: () => [title] }),
  };
}

/** 新增/修改的表单 */
export function useFormSchema(): VbenFormSchema[] {
  return [
    {
      component: 'Input',
      fieldName: 'id',
      dependencies: {
        triggerFields: [''],
        show: () => false,
      },
    },

    // ==================== 基础信息 ====================
    divider('baseDivider', '基础信息'),
    {
      fieldName: 'name',
      label: '供应商名称',
      component: 'Input',
      rules: 'required',
      componentProps: { placeholder: '请输入供应商名称' },
    },
    {
      fieldName: 'contact',
      label: '联系人',
      component: 'Input',
      componentProps: { placeholder: '请输入联系人' },
    },
    {
      fieldName: 'mobile',
      label: '手机号码',
      component: 'Input',
      componentProps: { placeholder: '请输入手机号码' },
    },
    {
      fieldName: 'telephone',
      label: '联系电话',
      component: 'Input',
      componentProps: { placeholder: '请输入联系电话' },
    },
    {
      fieldName: 'email',
      label: '电子邮箱',
      component: 'Input',
      componentProps: { placeholder: '请输入电子邮箱' },
    },
    {
      fieldName: 'fax',
      label: '传真',
      component: 'Input',
      componentProps: { placeholder: '请输入传真' },
    },
    {
      fieldName: 'status',
      label: '开启状态',
      component: 'RadioGroup',
      componentProps: {
        options: getDictOptions(DICT_TYPE.COMMON_STATUS, 'number'),
        buttonStyle: 'solid',
        optionType: 'button',
      },
      rules: z.number().default(CommonStatusEnum.ENABLE),
    },
    {
      fieldName: 'sort',
      label: '排序',
      component: 'InputNumber',
      componentProps: { class: '!w-full', placeholder: '请输入排序' },
      rules: 'required',
    },

    // ==================== 账户与税务 ====================
    divider('accountDivider', '账户与税务'),
    {
      fieldName: 'accountName',
      label: '户名',
      component: 'Input',
      componentProps: { placeholder: '银行账户的开户名称，通常同公司全称' },
    },
    {
      fieldName: 'taxNo',
      label: '税号',
      component: 'Input',
      componentProps: { placeholder: '请输入纳税人识别号' },
    },
    {
      fieldName: 'registeredAddress',
      label: '注册地址',
      component: 'Input',
      componentProps: { placeholder: '营业执照上的营业地址（开专票需要）' },
    },
    {
      fieldName: 'bankName',
      label: '开户银行',
      component: 'Input',
      componentProps: { placeholder: '请输入开户银行' },
    },
    {
      fieldName: 'bankAccount',
      label: '银行账号',
      component: 'Input',
      componentProps: { placeholder: '请输入银行账号' },
    },
    {
      fieldName: 'bankAddress',
      label: '开户地址',
      component: 'Input',
      componentProps: { placeholder: '银行侧的地址（与注册地址不同）' },
    },
    {
      fieldName: 'taxPercent',
      label: '开票税点(%)',
      component: 'InputNumber',
      componentProps: {
        class: '!w-full',
        placeholder: '免税填 0，其余 1~13',
        min: 0,
        max: 13,
        precision: 2,
      },
      help: '免税填 0；一般纳税人 6 / 9 / 13，小规模 1 / 3',
    },

    // ==================== 开票 ====================
    divider('invoiceDivider', '开票'),
    {
      fieldName: 'invoiceMode',
      label: '开票情况',
      component: 'Select',
      componentProps: {
        placeholder: '请选择开票情况',
        allowClear: true,
        options: getDictOptions(DICT_TYPE.ERP_SUPPLIER_INVOICE_MODE),
      },
    },
    {
      fieldName: 'invoiceRatio',
      label: '开票比例(%)',
      component: 'InputNumber',
      dependencies: {
        triggerFields: ['invoiceMode'],
        show: (values) => values.invoiceMode === 'RATIO',
      },
      componentProps: {
        class: '!w-full',
        placeholder: '如 15~25',
        min: 0,
        max: 100,
        precision: 2,
      },
      help: '仅「按销售额比例开票」时填写',
    },
    {
      fieldName: 'invoiceType',
      label: '开票类型',
      component: 'Select',
      componentProps: {
        placeholder: '请选择开票类型',
        allowClear: true,
        options: getDictOptions(DICT_TYPE.ERP_SUPPLIER_INVOICE_TYPE),
      },
    },

    // ==================== 结算与交期 ====================
    divider('settleDivider', '结算与交期'),
    {
      fieldName: 'settlementType',
      label: '结账方式',
      component: 'Select',
      componentProps: {
        placeholder: '请选择结账方式',
        allowClear: true,
        options: getDictOptions(DICT_TYPE.ERP_SUPPLIER_SETTLEMENT_TYPE),
      },
    },
    {
      fieldName: 'creditDays',
      label: '账期天数(天)',
      component: 'InputNumber',
      dependencies: {
        triggerFields: ['settlementType'],
        show: (values) =>
          values.settlementType === 'MONTHLY' ||
          values.settlementType === 'HALF_MONTH',
      },
      componentProps: {
        class: '!w-full',
        placeholder: '如月结 30 天、半月结 15 天',
        min: 0,
        precision: 0,
      },
    },
    {
      fieldName: 'deliveryDays',
      label: '交期时间(天)',
      component: 'InputNumber',
      componentProps: {
        class: '!w-full',
        placeholder: '下单到到货的承诺天数，如 7',
        min: 0,
        precision: 0,
      },
    },

    // ==================== 合同与证照 ====================
    divider('contractDivider', '合同与证照'),
    {
      fieldName: 'contractSigned',
      label: '是否签订合同',
      component: 'Switch',
      componentProps: {
        class: '!w-auto', // 开关不该被表单的全局 w-full 拉满
        checkedChildren: '已签订',
        unCheckedChildren: '未签订',
      },
      defaultValue: false,
    },
    {
      fieldName: 'contractEntity',
      label: '签订主体',
      component: 'Input',
      dependencies: {
        triggerFields: ['contractSigned'],
        show: (values) => !!values.contractSigned,
      },
      componentProps: {
        placeholder: '由亚特哪个公司/主体签订，如 亚特萍姐商贸公司',
      },
    },
    {
      fieldName: 'businessLicenseUrls',
      label: '营业执照',
      component: 'FileUpload',
      componentProps: {
        maxNumber: 5,
        maxSize: 10,
        accept: LICENSE_ACCEPT,
      },
      help: '支持 pdf / 图片，单个不超过 10MB，最多 5 个',
      formItemClass: 'col-span-2',
    },
    {
      fieldName: 'productionLicenseUrls',
      label: '生产许可证',
      component: 'FileUpload',
      componentProps: {
        maxNumber: 5,
        maxSize: 10,
        accept: LICENSE_ACCEPT,
      },
      help: '支持 pdf / 图片，单个不超过 10MB，最多 5 个',
      formItemClass: 'col-span-2',
    },

    // ==================== 备注 ====================
    {
      fieldName: 'remark',
      label: '备注',
      component: 'Textarea',
      componentProps: { placeholder: '请输入备注', rows: 3 },
      formItemClass: 'col-span-2',
    },
  ];
}

/** 搜索表单 */
export function useGridFormSchema(): VbenFormSchema[] {
  return [
    {
      fieldName: 'name',
      label: '供应商名称',
      component: 'Input',
      componentProps: { placeholder: '请输入供应商名称', allowClear: true },
    },
    {
      fieldName: 'settlementType',
      label: '结账方式',
      component: 'Select',
      componentProps: {
        placeholder: '请选择结账方式',
        allowClear: true,
        options: getDictOptions(DICT_TYPE.ERP_SUPPLIER_SETTLEMENT_TYPE),
      },
    },
    {
      fieldName: 'invoiceMode',
      label: '开票情况',
      component: 'Select',
      componentProps: {
        placeholder: '请选择开票情况',
        allowClear: true,
        options: getDictOptions(DICT_TYPE.ERP_SUPPLIER_INVOICE_MODE),
      },
    },
    {
      fieldName: 'contractSigned',
      label: '是否签订合同',
      component: 'Select',
      componentProps: {
        placeholder: '请选择',
        allowClear: true,
        options: [
          { label: '已签订', value: true },
          { label: '未签订', value: false },
        ],
      },
    },
    {
      fieldName: 'mobile',
      label: '手机号码',
      component: 'Input',
      componentProps: { placeholder: '请输入手机号码', allowClear: true },
    },
    {
      fieldName: 'telephone',
      label: '联系电话',
      component: 'Input',
      componentProps: { placeholder: '请输入联系电话', allowClear: true },
    },
  ];
}

/** 列表的字段 */
export function useGridColumns(): VxeTableGridOptions['columns'] {
  return [
    {
      field: 'code',
      title: '编码',
      width: 130,
      formatter: ({ cellValue }) => cellValue || '-',
    },
    {
      field: 'name',
      title: '供应商名称',
      minWidth: 180,
    },
    {
      field: 'settlementType',
      title: '结账方式',
      width: 130,
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.ERP_SUPPLIER_SETTLEMENT_TYPE },
      },
    },
    {
      field: 'creditDays',
      title: '账期(天)',
      width: 90,
      formatter: ({ cellValue }) => cellValue ?? '-',
    },
    {
      field: 'invoiceMode',
      title: '开票情况',
      width: 140,
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.ERP_SUPPLIER_INVOICE_MODE },
      },
    },
    {
      field: 'invoiceType',
      title: '开票类型',
      width: 140,
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.ERP_SUPPLIER_INVOICE_TYPE },
      },
    },
    {
      field: 'taxPercent',
      title: '税点(%)',
      width: 90,
      formatter: ({ cellValue }) =>
        cellValue === null || cellValue === undefined
          ? '-'
          : Number(cellValue) === 0
            ? '免税'
            : cellValue,
    },
    {
      field: 'deliveryDays',
      title: '交期(天)',
      width: 90,
      formatter: ({ cellValue }) => cellValue ?? '-',
    },
    {
      field: 'contractSigned',
      title: '合同',
      width: 90,
      formatter: ({ cellValue }) =>
        cellValue ? '已签订' : cellValue === false ? '未签订' : '-',
    },
    {
      field: 'contractEntity',
      title: '签订主体',
      minWidth: 140,
      formatter: ({ cellValue }) => cellValue || '-',
    },
    {
      field: 'contact',
      title: '联系人',
      minWidth: 110,
    },
    {
      field: 'mobile',
      title: '手机号码',
      minWidth: 130,
    },
    {
      field: 'status',
      title: '状态',
      width: 90,
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.COMMON_STATUS },
      },
    },
    {
      field: 'sort',
      title: '排序',
      width: 80,
    },
    {
      field: 'remark',
      title: '备注',
      minWidth: 150,
      showOverflow: 'tooltip',
    },
    {
      title: '操作',
      width: 130,
      fixed: 'right',
      slots: { default: 'actions' },
    },
  ];
}
