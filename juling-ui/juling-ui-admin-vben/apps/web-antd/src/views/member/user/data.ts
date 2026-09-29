import type { VbenFormApi, VbenFormSchema } from '#/adapter/form';
import type { VxeTableGridOptions } from '#/adapter/vxe-table';

import { markRaw } from 'vue';

import { CommonStatusEnum, DICT_TYPE } from '@vben/constants';
import { getDictOptions } from '@vben/hooks';
import { handleTree } from '@vben/utils';

import { z } from '#/adapter/form';
import { getCustomerSimpleList } from '#/api/erp/sale/customer';
import { getSimpleDeptList } from '#/api/system/dept';
import { AreaCascader } from '#/components/area';
import { getRangePickerDefaultProps } from '#/utils';

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
      fieldName: 'username',
      label: '订货账号',
      component: 'Input',
      componentProps: {
        allowClear: true,
        maxlength: 64,
        placeholder: '请输入订货账号（订货人名字，登录用）',
      },
      help: '订货人登录用的账号名，填订货人名字（如「张三」），2-64 位且不能与其它账号重复；清空表示不修改',
      rules: z
        .string()
        .min(2, '订货账号长度为 2-64 位')
        .max(64, '订货账号长度不能超过 64 位')
        .or(z.literal(''))
        .optional(),
    },
    {
      fieldName: 'mobile',
      label: '手机号',
      component: 'Input',
      componentProps: {
        allowClear: true,
        maxlength: 20,
        placeholder: '选填，不填则只能用订货账号登录',
      },
      help: '选填。不填则只能用账号名登录，填了就必须唯一',
      rules: 'mobile',
    },
    {
      fieldName: 'email',
      label: '邮箱',
      component: 'Input',
      componentProps: {
        allowClear: true,
        maxlength: 50,
        placeholder: '请输入邮箱',
      },
      rules: z.string().email('邮箱格式不正确').or(z.literal('')).optional(),
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
      rules: z.number().default(CommonStatusEnum.ENABLE).optional(),
    },
    {
      fieldName: 'nickname',
      label: '联系人',
      component: 'Input',
      componentProps: {
        allowClear: true,
        placeholder: '请输入联系人',
      },
      help: '订货账号的展示名；开账号时为空则取订货账号',
    },
    {
      fieldName: 'avatar',
      label: '头像',
      component: 'ImageUpload',
    },
    {
      fieldName: 'name',
      label: '真实名字',
      component: 'Input',
      componentProps: {
        placeholder: '请输入真实名字',
      },
    },
    {
      fieldName: 'sex',
      label: '用户性别',
      component: 'RadioGroup',
      componentProps: {
        options: getDictOptions(DICT_TYPE.SYSTEM_USER_SEX, 'number'),
        buttonStyle: 'solid',
        optionType: 'button',
      },
    },
    {
      fieldName: 'birthday',
      label: '出生日期',
      component: 'DatePicker',
      componentProps: {
        format: 'YYYY-MM-DD',
        valueFormat: 'x',
        placeholder: '请选择出生日期',
      },
    },
    {
      fieldName: 'areaId',
      label: '所在地',
      component: markRaw(AreaCascader),
      componentProps: {
        allowClear: true,
        changeOnSelect: true,
        class: '!w-full',
        placeholder: '请选择所在地',
        showSearch: true,
      },
    },
    {
      fieldName: 'deptId',
      label: '所属部门',
      component: 'ApiTreeSelect',
      componentProps: {
        allowClear: true,
        api: async () => handleTree(await getSimpleDeptList()),
        labelField: 'name',
        valueField: 'id',
        childrenField: 'children',
        placeholder: '请选择所属部门',
        treeDefaultExpandAll: true,
      },
    },
    {
      fieldName: 'customerId',
      label: '所属客户',
      component: 'ApiSelect',
      componentProps: {
        api: getCustomerSimpleList,
        labelField: 'name',
        valueField: 'id',
        allowClear: true,
        placeholder: '请选择所属客户',
      },
    },
    {
      fieldName: 'mark',
      label: '备注',
      component: 'Textarea',
      componentProps: {
        placeholder: '请输入备注',
      },
    },
  ];
}

/** 列表的搜索表单 */
export function useGridFormSchema(): VbenFormSchema[] {
  return [
    {
      fieldName: 'username',
      label: '订货账号',
      component: 'Input',
      componentProps: {
        placeholder: '请输入订货账号',
        allowClear: true,
      },
    },
    {
      fieldName: 'nickname',
      label: '联系人',
      component: 'Input',
      componentProps: {
        placeholder: '请输入联系人',
        allowClear: true,
      },
    },
    {
      fieldName: 'mobile',
      label: '手机号',
      component: 'Input',
      componentProps: {
        placeholder: '请输入手机号',
        allowClear: true,
      },
    },
    {
      fieldName: 'email',
      label: '邮箱',
      component: 'Input',
      componentProps: {
        placeholder: '请输入邮箱',
        allowClear: true,
      },
    },
    {
      fieldName: 'loginDate',
      label: '最后登录时间',
      component: 'RangePicker',
      componentProps: {
        ...getRangePickerDefaultProps(),
        allowClear: true,
      },
    },
    {
      fieldName: 'createTime',
      label: '注册时间',
      component: 'RangePicker',
      componentProps: {
        ...getRangePickerDefaultProps(),
        allowClear: true,
      },
    },
  ];
}

/** 列表的字段 */
export function useGridColumns(): VxeTableGridOptions['columns'] {
  return [
    {
      type: 'checkbox',
      width: 50,
    },
    {
      field: 'username',
      title: '订货账号',
      minWidth: 140,
      formatter: ({ cellValue }) => cellValue || '-',
    },
    {
      field: 'nickname',
      title: '联系人',
      minWidth: 120,
      formatter: ({ cellValue }) => cellValue || '-',
    },
    {
      field: 'mobile',
      title: '手机号',
      minWidth: 120,
      // 私域订货场景手机号可选，历史会员也可能没有手机号
      formatter: ({ cellValue }) => cellValue || '-',
    },
    {
      field: 'customerId',
      title: '所属客户',
      minWidth: 100,
    },
    {
      field: 'deptId',
      title: '所属部门',
      minWidth: 100,
    },
    {
      field: 'status',
      title: '状态',
      minWidth: 80,
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.COMMON_STATUS },
      },
    },
    {
      field: 'loginDate',
      title: '最后登录时间',
      minWidth: 160,
      formatter: 'formatDateTime',
    },
    {
      field: 'createTime',
      title: '注册时间',
      minWidth: 160,
      formatter: 'formatDateTime',
    },
    {
      title: '操作',
      width: 200,
      fixed: 'right',
      slots: { default: 'actions' },
    },
  ];
}

/** 开订货账号表单值 */
export interface OrderAccountFormValues {
  customerId?: number;
  deptId?: number;
  email?: string;
  mark?: string;
  mobile?: string;
  nickname?: string;
  password?: string;
  status?: number;
  username?: string;
}

/**
 * 订货主体（门店 / 代理客户）下拉项。
 *
 * simple-list 目前透出 id/name/deptId/storeType；parentCustomerId 与 isAgent 是前端补充的：
 * 被别的客户挂成「上级代理」的客户＝代理客户（名下有门店，H5 可切换名下门店下单）。
 */
export interface OrderAccountCustomer {
  deptId?: number;
  id?: number;
  /** 是否代理客户（名下有门店）：由开账号弹窗拉列表时标注 */
  isAgent?: boolean;
  name?: string;
  /** 上级代理客户编号：simple-list 若已透出，可直接本地判定谁是代理 */
  parentCustomerId?: number;
  /** 店型：DIRECT 直营 / FRANCHISE 加盟（字典 erp_store_type） */
  storeType?: string;
}

/** 订货主体下拉的显示名：代理客户最需要标出来，其次标店型，避免门店账号 / 代理人账号选错 */
export function formatOrderSubjectLabel(item: OrderAccountCustomer): string {
  const name = item.name ?? '';
  if (item.isAgent) {
    return `${name}（代理）`;
  }
  if (item.storeType === 'DIRECT') {
    return `${name}（直营）`;
  }
  if (item.storeType === 'FRANCHISE') {
    return `${name}（加盟）`;
  }
  return name;
}

/**
 * 订货账号默认建议密码：`yt@` + 手机号后 6 位；没填手机号时用账号名后 6 位
 * （账号名不足 6 位就用账号名本身），长度与后端 6-32 位的校验对齐。
 */
export function suggestOrderPassword(
  mobile?: string,
  username?: string,
): string {
  const mobileText = (mobile ?? '').trim();
  let password: string;
  if (mobileText) {
    const digits = mobileText.replace(/\D/g, '');
    password = `yt@${(digits || mobileText).slice(-6)}`;
  } else {
    const usernameText = (username ?? '').trim();
    if (!usernameText) {
      return '';
    }
    password = `yt@${usernameText.slice(-6)}`;
  }
  // 账号名只有 2-3 位时拼出来不足 6 位会被后端拒绝，这里补足到最小长度
  return password.padEnd(6, '0');
}

/** 开订货账号表单（工具栏「开订货账号」弹窗） */
export function useOrderAccountFormSchema(options: {
  /** 订货主体（门店 / 代理客户）下拉数据源 */
  getCustomerList: () => Promise<OrderAccountCustomer[]>;
  /** 选中订货主体后的联动：能拿到 deptId 就自动带出所属部门 */
  onCustomerChange?: (
    values: Partial<OrderAccountFormValues>,
    form: VbenFormApi,
  ) => Promise<void> | void;
  /** 账号名 / 手机号变化后刷新默认建议密码 */
  onPasswordSourceChange?: (
    values: Partial<OrderAccountFormValues>,
    form: VbenFormApi,
  ) => void;
}): VbenFormSchema[] {
  return [
    {
      fieldName: 'username',
      label: '订货账号',
      component: 'Input',
      componentProps: {
        allowClear: true,
        maxlength: 64,
        placeholder: '请输入订货账号（订货人名字，如「张三」）',
      },
      help: '订货人登录用的账号名，填订货人名字，2-64 位且必须唯一',
      rules: z
        .string()
        .min(2, '订货账号长度为 2-64 位')
        .max(64, '订货账号长度不能超过 64 位'),
    },
    {
      fieldName: 'password',
      label: '初始密码',
      component: 'InputPassword',
      componentProps: {
        allowClear: true,
        maxlength: 32,
        placeholder: '请输入 6-32 位初始密码',
      },
      help: '默认「yt@ + 手机号后 6 位」；没填手机号时取账号名后 6 位，可自行修改',
      rules: z
        .string()
        .min(6, '密码长度为 6-32 位')
        .max(32, '密码长度为 6-32 位'),
      dependencies: {
        triggerFields: ['mobile', 'username'],
        trigger(values, _actions, controller) {
          options.onPasswordSourceChange?.(
            values as Partial<OrderAccountFormValues>,
            controller,
          );
        },
      },
    },
    {
      fieldName: 'customerId',
      label: '订货主体',
      component: 'ApiSelect',
      componentProps: {
        api: options.getCustomerList,
        labelFn: formatOrderSubjectLabel,
        labelField: 'name',
        valueField: 'id',
        allowClear: true,
        placeholder: '请选择订货主体（门店 / 代理客户）',
      },
      help: '选门店＝该账号只管这一家门店；选代理客户＝代理人账号，登录后可在 H5 切换名下门店下单',
      rules: 'selectRequired',
      dependencies: {
        triggerFields: ['customerId'],
        trigger(values, _actions, controller) {
          options.onCustomerChange?.(
            values as Partial<OrderAccountFormValues>,
            controller,
          );
        },
      },
    },
    {
      fieldName: 'deptId',
      label: '所属部门',
      component: 'ApiTreeSelect',
      componentProps: {
        allowClear: true,
        api: async () => handleTree(await getSimpleDeptList()),
        labelField: 'name',
        valueField: 'id',
        childrenField: 'children',
        placeholder: '请选择所属部门（门店 / 代理部门）',
        treeDefaultExpandAll: true,
      },
      help: '门店账号填门店部门；代理人账号填代理部门（仅门店自身没有部门时兜底）。选中订货主体后自动带出，可手动调整',
    },
    {
      fieldName: 'nickname',
      label: '联系人',
      component: 'Input',
      componentProps: {
        allowClear: true,
        maxlength: 30,
        placeholder: '请输入联系人（不填则取订货账号）',
      },
    },
    {
      fieldName: 'mobile',
      label: '手机号',
      component: 'Input',
      componentProps: {
        allowClear: true,
        maxlength: 20,
        placeholder: '选填，不填则只能用订货账号登录',
      },
      help: '选填；填了会校验格式且必须唯一',
      rules: 'mobile',
    },
    {
      fieldName: 'email',
      label: '邮箱',
      component: 'Input',
      componentProps: {
        allowClear: true,
        maxlength: 50,
        placeholder: '请输入邮箱',
      },
      rules: z.string().email('邮箱格式不正确').or(z.literal('')).optional(),
    },
    {
      fieldName: 'mark',
      label: '备注',
      component: 'Textarea',
      componentProps: {
        placeholder: '请输入备注',
      },
      formItemClass: 'col-span-2',
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
      rules: z.number().default(CommonStatusEnum.ENABLE).optional(),
    },
  ];
}

/** 重置订货账号密码表单（行操作「重置密码」弹窗） */
export function useResetPasswordFormSchema(): VbenFormSchema[] {
  return [
    {
      fieldName: 'id',
      label: '账号编号',
      component: 'Input',
      componentProps: {
        disabled: true,
      },
    },
    {
      fieldName: 'username',
      label: '订货账号',
      component: 'Input',
      componentProps: {
        disabled: true,
        placeholder: '（暂无订货账号）',
      },
      help: '重置后该账号会被强制下线，订货人需要用新密码重新登录',
    },
    {
      fieldName: 'nickname',
      label: '联系人',
      component: 'Input',
      componentProps: {
        disabled: true,
      },
    },
    {
      fieldName: 'password',
      label: '新密码',
      component: 'InputPassword',
      componentProps: {
        allowClear: true,
        maxlength: 32,
        placeholder: '请输入 6-32 位新密码',
      },
      help: '默认「yt@ + 手机号后 6 位」（无手机号取账号名后 6 位），可自行修改',
      rules: z
        .string()
        .min(6, '密码长度为 6-32 位')
        .max(32, '密码长度为 6-32 位'),
    },
  ];
}
