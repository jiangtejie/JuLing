<script lang="ts" setup>
import type { VbenFormApi } from '#/adapter/form';
import type { MemberUserApi } from '#/api/member/user';

import type { OrderAccountCustomer, OrderAccountFormValues } from '../data';

import { ref } from 'vue';

import { useAccess } from '@vben/access';
import { useVbenModal } from '@vben/common-ui';

import { message } from 'ant-design-vue';

import { useVbenForm } from '#/adapter/form';
import {
  getCustomer,
  getCustomerPage,
  getCustomerSimpleList,
} from '#/api/erp/sale/customer';
import { createUser } from '#/api/member/user';

import { suggestOrderPassword, useOrderAccountFormSchema } from '../data';

defineOptions({ name: 'MemberOrderAccountForm' });

const emit = defineEmits(['success']);

const { hasAccessByCodes } = useAccess();

/** 订货主体（门店 / 代理客户）下拉数据：既喂给 ApiSelect，也用于「选中后带出部门」 */
const customerList = ref<OrderAccountCustomer[]>([]);
/** 上一次自动生成的建议密码：管理员手动改过密码后就不再覆盖 */
const lastSuggestedPassword = ref('');

/** 从「上级代理」反推代理客户编号：被挂成上级的客户就是代理（名下有门店） */
function collectAgentIds(source: OrderAccountCustomer[]) {
  return new Set(
    source
      .map((item) => item.parentCustomerId)
      .filter((id): id is number => typeof id === 'number'),
  );
}

/**
 * 标出代理客户，供下拉显示「（代理）」。
 *
 * simple-list 若已透出 parentCustomerId 就本地判定；否则有 erp:customer:query 权限时补一次全量查询，
 * 没权限 / 查失败就静默跳过（下拉照常可用，只是不带「（代理）」后缀）。
 */
async function markAgentCustomers(list: OrderAccountCustomer[]) {
  let agentIds = collectAgentIds(list);
  if (agentIds.size === 0) {
    if (!hasAccessByCodes(['erp:customer:query'])) {
      return;
    }
    try {
      const page = await getCustomerPage({ pageNo: 1, pageSize: -1 });
      agentIds = collectAgentIds((page?.list ?? []) as OrderAccountCustomer[]);
    } catch {
      return;
    }
  }
  list.forEach((item) => {
    if (item.id !== undefined && agentIds.has(item.id)) {
      item.isAgent = true;
    }
  });
}

/** 订货主体精简列表（含 deptId / storeType，并尽量标出代理客户） */
async function fetchCustomerList() {
  const list = ((await getCustomerSimpleList()) ?? []) as OrderAccountCustomer[];
  await markAgentCustomers(list);
  customerList.value = list;
  return list;
}

/**
 * 选中订货主体后带出所属部门。
 *
 * 精简列表已返回 deptId，拿不到时（老接口/空数据）再查一次客户详情；
 * 没有 erp:customer:query 权限就安静跳过（部门本来就能手选），避免无权限时弹错误提示。
 */
async function handleCustomerChange(
  values: Partial<OrderAccountFormValues>,
  form: VbenFormApi,
) {
  const customerId = values.customerId;
  if (customerId === undefined || customerId === null) {
    return;
  }
  let deptId = customerList.value.find(
    (item) => item.id === customerId,
  )?.deptId;
  if (deptId === undefined || deptId === null) {
    if (!hasAccessByCodes(['erp:customer:query'])) {
      return;
    }
    try {
      const detail = (await getCustomer(customerId)) as OrderAccountCustomer;
      deptId = detail?.deptId;
    } catch {
      return;
    }
  }
  if (deptId !== undefined && deptId !== null) {
    await form.setFieldValue('deptId', deptId);
  }
}

/** 账号名 / 手机号变化后刷新默认建议密码（管理员自己改过就不覆盖） */
function handlePasswordSourceChange(
  values: Partial<OrderAccountFormValues>,
  form: VbenFormApi,
) {
  const suggested = suggestOrderPassword(values.mobile, values.username);
  const current = values.password ?? '';
  if (current && current !== lastSuggestedPassword.value) {
    return;
  }
  lastSuggestedPassword.value = suggested;
  void form.setFieldValue('password', suggested);
}

const [Form, formApi] = useVbenForm({
  commonConfig: {
    componentProps: {
      class: 'w-full',
    },
    labelWidth: 90,
  },
  layout: 'horizontal',
  schema: useOrderAccountFormSchema({
    getCustomerList: fetchCustomerList,
    onCustomerChange: handleCustomerChange,
    onPasswordSourceChange: handlePasswordSourceChange,
  }),
  showDefaultActions: false,
  wrapperClass: 'grid-cols-2',
});

/** 过滤空值：后端按「不传」取默认（status 默认开启、nickname 默认取账号名） */
function buildPayload(
  values: OrderAccountFormValues,
): MemberUserApi.UserCreateReqVO {
  const payload: Record<string, any> = {};
  Object.entries(values).forEach(([key, value]) => {
    if (value === undefined || value === null || value === '') {
      return;
    }
    payload[key] = value;
  });
  return payload as MemberUserApi.UserCreateReqVO;
}

const [Modal, modalApi] = useVbenModal({
  async onConfirm() {
    const { valid } = await formApi.validate();
    if (!valid) {
      return;
    }
    modalApi.lock();
    try {
      const values = (await formApi.getValues()) as OrderAccountFormValues;
      await createUser(buildPayload(values));
      await modalApi.close();
      emit('success');
      // 密码只在这里出现一次，提示管理员转告订货人
      message.success('账号已创建，请把账号和密码告知订货人');
    } finally {
      modalApi.unlock();
    }
  },
  onOpenChange(isOpen: boolean) {
    if (!isOpen) {
      customerList.value = [];
      lastSuggestedPassword.value = '';
      return;
    }
    lastSuggestedPassword.value = '';
  },
});
</script>

<template>
  <Modal title="开订货账号" class="w-1/2">
    <Form class="mx-4" />
    <div class="text-muted-foreground mx-4 mt-2 text-[13px]">
      订货账号就是订货人登录用的账号名（填订货人名字，如「张三」）；订货主体选「门店」＝该账号只管这一家，
      选「代理」＝代理人账号，登录后可在 H5 切换名下门店下单；创建后请把「账号 +
      初始密码」告知订货人，订货人用账号名 + 密码登录订货端。
    </div>
  </Modal>
</template>
