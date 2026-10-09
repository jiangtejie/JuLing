import type { VbenFormApi, VbenFormSchema } from '#/adapter/form';
import type { VxeTableGridOptions } from '#/adapter/vxe-table';

import { markRaw } from 'vue';

import { CommonStatusEnum, DICT_TYPE } from '@vben/constants';
import { getDictOptions } from '@vben/hooks';

import { z } from '#/adapter/form';
import { getCustomerSimpleList } from '#/api/erp/sale/customer';
import { AreaCascader } from '#/components/area';
import { getRangePickerDefaultProps } from '#/utils';

/** 门店编号 → 门店（列表列展示「授权门店」用；simple-list 只透出 id/name/storeType） */
let customerList: OrderAccountCustomer[] = [];
getCustomerSimpleList().then((data) => (customerList = data as OrderAccountCustomer[]));

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
      fieldName: 'storeCustomerIds',
      label: '授权门店',
      component: 'ApiSelect',
      componentProps: {
        api: getCustomerSimpleList,
        labelFn: formatOrderSubjectLabel,
        labelField: 'name',
        valueField: 'id',
        mode: 'multiple',
        allowClear: true,
        placeholder: '请选择授权门店（可多选）',
      },
      help: '账号能给哪些门店下单：一家门店＝加盟店自己的账号；多家＝片区订货管理人',
      rules: z.array(z.number()).min(1, '至少授权一个门店'),
    },
    {
      fieldName: 'defaultStoreCustomerId',
      label: '默认门店',
      component: 'ApiSelect',
      componentProps: {
        api: getCustomerSimpleList,
        labelFn: formatOrderSubjectLabel,
        labelField: 'name',
        valueField: 'id',
        allowClear: true,
        placeholder: '不填则取授权门店的第一家',
      },
      help: '门店在 H5 首次进入时默认选中的门店',
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
      field: 'storeCustomerIds',
      title: '授权门店',
      minWidth: 200,
      formatter: ({ cellValue }) => {
        const ids = (cellValue ?? []) as number[];
        if (ids.length === 0) {
          return '-';
        }
        return ids
          .map((id) => customerList.find((item) => item.id === id)?.name ?? id)
          .join('、');
      },
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
  defaultStoreCustomerId?: number;
  email?: string;
  mark?: string;
  mobile?: string;
  nickname?: string;
  password?: string;
  status?: number;
  storeCustomerIds?: number[];
  username?: string;
}

/**
 * 授权门店下拉项。
 *
 * simple-list 透出 id/name/code/storeType；编码用于区分同名门店，店型用于标注「（直营）/（加盟）」。
 */
export interface OrderAccountCustomer {
  id?: number;
  name?: string;
  /** 业务编码（门店编码，如 KH000001）：同名门店靠它区分 */
  code?: string;
  /** 店型：DIRECT 直营 / FRANCHISE 加盟（字典 erp_store_type） */
  storeType?: string;
}

/** 授权门店下拉的显示名：编码 + 店型，避免选错门店（同名靠编码区分） */
export function formatOrderSubjectLabel(item: OrderAccountCustomer): string {
  const name = item.code ? `${item.code} ${item.name ?? ''}` : (item.name ?? '');
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
  /** 授权门店下拉数据源 */
  getCustomerList: () => Promise<OrderAccountCustomer[]>;
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
      fieldName: 'storeCustomerIds',
      label: '授权门店',
      component: 'ApiSelect',
      componentProps: {
        api: options.getCustomerList,
        labelFn: formatOrderSubjectLabel,
        labelField: 'name',
        valueField: 'id',
        mode: 'multiple',
        allowClear: true,
        placeholder: '请选择授权门店（可多选）',
      },
      help: '一家门店＝加盟店自己的订货账号；多家＝片区订货管理人（登录后可在 H5 切换下单门店）',
      rules: z.array(z.number()).min(1, '至少授权一个门店'),
    },
    {
      fieldName: 'defaultStoreCustomerId',
      label: '默认门店',
      component: 'ApiSelect',
      componentProps: {
        api: options.getCustomerList,
        labelFn: formatOrderSubjectLabel,
        labelField: 'name',
        valueField: 'id',
        allowClear: true,
        placeholder: '不填则取授权门店的第一家',
      },
      help: '门店在 H5 首次进入时默认选中的门店',
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
