import { requestClient } from '#/api/request';

/** 建门店：一个事务里同时建组织节点与客户档案 */
export interface ErpStoreApi {
  name: string; // 门店名称
  parentId: number; // 父组织节点（品牌或公司，不能是门店）
  storeType: string; // 店型：DIRECT 直营 / FRANCHISE 加盟
  settlementMode?: string; // 结算方式
  creditDays?: number; // 账期天数
  creditLimit?: number; // 授信额度
  contact?: string; // 联系人
  mobile?: string; // 联系手机
}

/** 建门店 */
export function createStore(data: ErpStoreApi) {
  return requestClient.post<number>('/erp/store/create', data);
}
