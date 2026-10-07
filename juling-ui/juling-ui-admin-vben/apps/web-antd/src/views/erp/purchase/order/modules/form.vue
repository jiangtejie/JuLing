<script lang="ts" setup>
import type { FormType } from '../data';

import type { ErpPurchaseOrderApi } from '#/api/erp/purchase/order';

import { computed, ref } from 'vue';

import { useVbenModal } from '@vben/common-ui';

import { message } from 'ant-design-vue';

import { useVbenForm } from '#/adapter/form';
import { getAccountSimpleList } from '#/api/erp/finance/account';
import {
  getSupplierSimpleList,
  type ErpSupplierApi,
} from '#/api/erp/purchase/supplier';
import {
  createPurchaseOrder,
  getPurchaseOrder,
  updatePurchaseOrder,
} from '#/api/erp/purchase/order';
import { $t } from '#/locales';

import { useFormSchema } from '../data';
import PurchaseOrderItemForm from './item-form.vue';

const emit = defineEmits(['success']);
const formData = ref<ErpPurchaseOrderApi.PurchaseOrder>();
const formType = ref<FormType>('create'); // 表单类型：'create' | 'edit' | 'detail'
const itemFormRef = ref<InstanceType<typeof PurchaseOrderItemForm>>();
/** 当前选中供应商的开票税点：传给明细表作为新增行的税率默认值 */
const supplierTaxPercent = ref<number>();
/** 当前选中的供应商编号：传给明细表用于取价 */
const supplierId = ref<number>();
/** 供应商精简列表：选供应商时要按 id 反查它的结算方式 / 交期 / 税点 */
let supplierList: ErpSupplierApi.Supplier[] = [];

const getTitle = computed(() => {
  if (formType.value === 'create') {
    return $t('ui.actionTitle.create', ['采购订单']);
  } else if (formType.value === 'edit') {
    return $t('ui.actionTitle.edit', ['采购订单']);
  } else {
    return '采购订单详情';
  }
});

const [Form, formApi] = useVbenForm({
  commonConfig: {
    componentProps: {
      class: 'w-full',
    },
    labelWidth: 120,
  },
  wrapperClass: 'grid-cols-3',
  layout: 'vertical',
  schema: useFormSchema(formType.value),
  showDefaultActions: false,
  handleValuesChange: async (values, changedFields) => {
    // 目的：同步到 item-form 组件，触发整体的价格计算
    if (formData.value && changedFields.includes('discountPercent')) {
      formData.value.discountPercent = values.discountPercent;
    }
    // 切换供应商时带出结算方式 / 交期 / 开票税点。
    // **总是覆盖**：换供应商本身就是"换一套交易条件"，保留旧条件反而会误导。
    // 与后端一致（后端仅在单据上留空时兜底），这里覆盖是为了让用户立刻看到生效值。
    if (changedFields.includes('supplierId')) {
      const supplier = supplierList.find((s) => s.id === values.supplierId);
      supplierId.value = supplier?.id;
      supplierTaxPercent.value = supplier?.taxPercent ?? undefined;
      await formApi.setValues({
        settlementType: supplier?.settlementType ?? undefined,
        deliveryDays: supplier?.deliveryDays ?? undefined,
      });
    }
  },
});

/** 更新采购订单项 */
function handleUpdateItems(items: ErpPurchaseOrderApi.PurchaseOrderItem[]) {
  formData.value = modalApi.getData() as ErpPurchaseOrderApi.PurchaseOrder;
  formData.value.items = items;
  formApi.setValues({
    items,
  });
}

/** 更新优惠金额 */
function handleUpdateDiscountPrice(discountPrice: number) {
  formApi.setValues({
    discountPrice,
  });
}

/** 更新总金额 */
function handleUpdateTotalPrice(totalPrice: number) {
  formApi.setValues({
    totalPrice,
  });
}

/** 创建或更新采购订单 */
const [Modal, modalApi] = useVbenModal({
  async onConfirm() {
    const { valid } = await formApi.validate();
    if (!valid) {
      return;
    }
    const itemFormInstance = Array.isArray(itemFormRef.value)
      ? itemFormRef.value[0]
      : itemFormRef.value;
    try {
      itemFormInstance.validate();
    } catch (error: any) {
      message.error(error.message || '子表单验证失败');
      return;
    }

    modalApi.lock();
    // 提交表单
    const data =
      (await formApi.getValues()) as ErpPurchaseOrderApi.PurchaseOrder;
    data.items = formData.value?.items?.map((item) => ({
      ...item,
      // 解决新增采购订单报错
      id: undefined,
    }));
    // 将文件数组转换为字符串
    if (data.fileUrl && Array.isArray(data.fileUrl)) {
      data.fileUrl = data.fileUrl.length > 0 ? data.fileUrl[0] : '';
    }
    try {
      await (formType.value === 'create'
        ? createPurchaseOrder(data)
        : updatePurchaseOrder(data));
      // 关闭并提示
      await modalApi.close();
      emit('success');
      message.success($t('ui.actionMessage.operationSuccess'));
    } finally {
      modalApi.unlock();
    }
  },
  async onOpenChange(isOpen: boolean) {
    if (!isOpen) {
      formData.value = undefined;
      return;
    }
    // 加载数据
    const data = modalApi.getData() as { formType: FormType; id?: number };
    formType.value = data.formType;
    formApi.setDisabled(formType.value === 'detail');
    formApi.updateSchema(useFormSchema(formType.value));
    // 供应商列表：供「切换供应商带出交易条件」反查（列表很小，整个取回即可）
    supplierList = (await getSupplierSimpleList()) as ErpSupplierApi.Supplier[];
    if (!data || !data.id) {
      // 新增时，默认选中账户
      const accountList = await getAccountSimpleList();
      const defaultAccount = accountList.find((item) => item.defaultStatus);
      if (defaultAccount) {
        await formApi.setValues({ accountId: defaultAccount.id });
      }
      return;
    }
    modalApi.lock();
    try {
      formData.value = await getPurchaseOrder(data.id);
      // 设置到 values
      await formApi.setValues(formData.value);
      // 编辑态：明细表要跟着当前供应商的税点走
      supplierId.value = formData.value?.supplierId ?? undefined;
      supplierTaxPercent.value = supplierList.find(
        (s) => s.id === formData.value?.supplierId,
      )?.taxPercent;
    } finally {
      modalApi.unlock();
    }
  },
});
</script>

<template>
  <Modal
    :title="getTitle"
    class="w-3/4"
    :show-confirm-button="formType !== 'detail'"
  >
    <Form class="mx-3">
      <template #items>
        <PurchaseOrderItemForm
          ref="itemFormRef"
          :items="formData?.items ?? []"
          :disabled="formType === 'detail'"
          :discount-percent="formData?.discountPercent ?? 0"
          :supplier-tax-percent="supplierTaxPercent"
          :supplier-id="supplierId"
          @update:items="handleUpdateItems"
          @update:discount-price="handleUpdateDiscountPrice"
          @update:total-price="handleUpdateTotalPrice"
        />
      </template>
    </Form>
  </Modal>
</template>
