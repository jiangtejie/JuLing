import type { PageParam, PageResult } from '@vben/request';

import { requestClient } from '#/api/request';

export namespace ErpSupplierApi {
  /** 供应商信息 */
  export interface Supplier {
    id?: number; // 供应商编号
    name: string; // 供应商名称
    contact: string; // 联系人
    mobile: string; // 手机号码
    telephone: string; // 联系电话
    email: string; // 电子邮箱
    fax: string; // 传真
    remark: string; // 备注
    status: number; // 开启状态
    sort: number; // 排序
    taxNo: string; // 纳税人识别号
    taxPercent: number; // 税率
    bankName: string; // 开户行
    bankAccount: string; // 开户账号
    bankAddress: string; // 开户地址（银行侧地址，与注册地址不同）
    // ========== 采购部门需求扩展（见 sql/local/62_supplier_profile.sql） ==========
    accountName: string; // 账户户名
    registeredAddress: string; // 注册地址（开专票用）
    settlementType: string; // 结账方式：MONTHLY 月结 / HALF_MONTH 半月结 / CASH_FIRST 次结(先款后货) / GOODS_FIRST 次结(先货后款)
    creditDays: number; // 账期天数
    invoiceMode: string; // 开票情况：FULL 全额 / RATIO 按比例 / PLUS_TAX 需加税点 / NONE 不开
    invoiceRatio: number; // 开票比例(%)
    invoiceType: string; // 开票类型：VAT_NORMAL 普票 / VAT_SPECIAL 专票
    deliveryDays: number; // 交期时间（天）
    contractSigned: boolean; // 是否已签订合同
    contractEntity: string; // 合同签订主体
    businessLicenseUrls: string; // 营业执照（逗号分隔）
    productionLicenseUrls: string; // 生产许可证（逗号分隔）
  }
}

/** 查询供应商分页 */
export function getSupplierPage(params: PageParam) {
  return requestClient.get<PageResult<ErpSupplierApi.Supplier>>(
    '/erp/supplier/page',
    { params },
  );
}

/** 获得供应商精简列表 */
export function getSupplierSimpleList() {
  return requestClient.get<ErpSupplierApi.Supplier[]>(
    '/erp/supplier/simple-list',
  );
}

/** 查询供应商详情 */
export function getSupplier(id: number) {
  return requestClient.get<ErpSupplierApi.Supplier>(
    `/erp/supplier/get?id=${id}`,
  );
}

/** 新增供应商 */
export function createSupplier(data: ErpSupplierApi.Supplier) {
  return requestClient.post('/erp/supplier/create', data);
}

/** 修改供应商 */
export function updateSupplier(data: ErpSupplierApi.Supplier) {
  return requestClient.put('/erp/supplier/update', data);
}

/** 删除供应商 */
export function deleteSupplier(id: number) {
  return requestClient.delete(`/erp/supplier/delete?id=${id}`);
}

/** 导出供应商 Excel */
export function exportSupplier(params: any) {
  return requestClient.download('/erp/supplier/export-excel', { params });
}
