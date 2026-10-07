import type { VbenFormSchema } from '#/adapter/form';
import type { VxeTableGridOptions } from '#/adapter/vxe-table';
import type { SystemDeptApi } from '#/api/system/dept';
import type { SystemUserApi } from '#/api/system/user';

import { CommonStatusEnum, DICT_TYPE } from '@vben/constants';
import { getDictOptions } from '@vben/hooks';
import { handleTree } from '@vben/utils';

import { z } from '#/adapter/form';
import { getDeptList } from '#/api/system/dept';
import { getSimpleUserList } from '#/api/system/user';

/** 关联数据 */
let userList: SystemUserApi.User[] = [];
getSimpleUserList().then((data) => (userList = data));

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
      fieldName: 'parentId',
      label: '上级部门',
      component: 'ApiTreeSelect',
      componentProps: {
        allowClear: true,
        api: async () => {
          const data = await getDeptList();
          data.unshift({
            id: 0,
            name: '顶级部门',
          });
          return handleTree(data);
        },
        labelField: 'name',
        valueField: 'id',
        childrenField: 'children',
        placeholder: '请选择上级部门',
        treeDefaultExpandAll: true,
      },
      rules: 'selectRequired',
    },
    {
      fieldName: 'name',
      label: '部门名称',
      component: 'Input',
      componentProps: {
        placeholder: '请输入部门名称',
      },
      rules: 'required',
    },
    {
      fieldName: 'sort',
      label: '显示顺序',
      component: 'InputNumber',
      componentProps: {
        class: '!w-full',
        min: 0,
        placeholder: '请输入显示顺序',
      },
      rules: 'required',
    },
    {
      fieldName: 'leaderUserId',
      label: '负责人',
      component: 'ApiSelect',
      componentProps: {
        api: getSimpleUserList,
        labelField: 'nickname',
        valueField: 'id',
        placeholder: '请选择负责人',
        allowClear: true,
      },
      rules: z.number().optional(),
    },
    {
      fieldName: 'phone',
      label: '联系电话',
      component: 'Input',
      componentProps: {
        maxLength: 11,
        placeholder: '请输入联系电话',
      },
      rules: 'mobileRequired',
    },
    {
      fieldName: 'email',
      label: '邮箱',
      component: 'Input',
      componentProps: {
        placeholder: '请输入邮箱',
      },
      rules: z.string().email('邮箱格式不正确').or(z.literal('')).optional(),
    },
    {
      fieldName: 'deptType',
      label: '节点类型',
      component: 'RadioGroup',
      componentProps: {
        options: getDictOptions(DICT_TYPE.SYSTEM_DEPT_TYPE),
        buttonStyle: 'solid',
        optionType: 'button',
      },
      rules: z.string().default('ORG'),
      help: '门店才可被订货账号授权、可下单、可建门店仓；店型（直营/加盟）在客户档案上维护',
    },
    {
      fieldName: 'businessStatus',
      label: '营业状态',
      component: 'RadioGroup',
      componentProps: {
        options: getDictOptions(DICT_TYPE.SYSTEM_DEPT_BUSINESS_STATUS, 'number'),
        buttonStyle: 'solid',
        optionType: 'button',
      },
      rules: z.number().default(0),
      dependencies: {
        triggerFields: ['deptType'],
        show: (values) => values.deptType === 'STORE',
      },
    },
    {
      fieldName: 'closedReason',
      label: '闭店原因',
      component: 'Input',
      componentProps: {
        placeholder: '闭店时填写',
      },
      dependencies: {
        triggerFields: ['deptType', 'businessStatus'],
        show: (values) => values.deptType === 'STORE' && values.businessStatus === 1,
      },
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
    },
  ];
}

/** 列表的字段 */
export function useGridColumns(): VxeTableGridOptions<SystemDeptApi.Dept>['columns'] {
  return [
    {
      // ⚠️ 多选框必须也在左侧固定区。
      // 树列是 fixed:'left'，会先渲染进固定区；多选框若不固定就留在主区，
      // 结果被排到树列右侧（表头看起来像「节点名称 | 多选框 | 编码」）。
      // VXE 并不会因为 treeNode 就重排列序（见 vxe-table/es/table/src/table.js:1689），
      // 顺序完全由 fixed 分区 + 定义顺序决定。
      type: 'checkbox',
      width: 40,
      fixed: 'left',
    },
    {
      field: 'name',
      title: '节点名称',
      minWidth: 150,
      align: 'left',
      fixed: 'left',
      treeNode: true,
    },
    {
      field: 'code',
      title: '编码',
      width: 130,
      formatter: ({ cellValue }) => cellValue || '-',
    },
    {
      field: 'deptType',
      title: '节点类型',
      width: 100,
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.SYSTEM_DEPT_TYPE },
      },
    },
    {
      field: 'businessStatus',
      title: '营业状态',
      width: 100,
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.SYSTEM_DEPT_BUSINESS_STATUS },
      },
    },
    {
      field: 'leaderUserId',
      title: '负责人',
      minWidth: 150,
      formatter: ({ cellValue }) =>
        userList.find((user) => user.id === cellValue)?.nickname || '-',
    },
    {
      field: 'sort',
      title: '显示顺序',
      minWidth: 100,
    },
    {
      field: 'status',
      title: '节点状态',
      minWidth: 100,
      cellRender: {
        name: 'CellDict',
        props: { type: DICT_TYPE.COMMON_STATUS },
      },
    },
    {
      field: 'createTime',
      title: '创建时间',
      minWidth: 180,
      formatter: 'formatDateTime',
    },
    {
      title: '操作',
      width: 220,
      fixed: 'right',
      slots: { default: 'actions' },
    },
  ];
}
