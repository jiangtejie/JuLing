import { requestClient } from '#/api/request';

export namespace SystemDeptApi {
  /** 部门信息 */
  export interface Dept {
    id?: number;
    name: string;
    parentId?: number;
    status: number;
    sort: number;
    leaderUserId: number;
    phone: string;
    email: string;
    /** 节点类型：ORG 组织 / STORE 门店 */
    deptType?: string;
    /** 营业状态：0 营业 / 1 已闭店（仅门店有意义） */
    businessStatus?: number;
    /** 闭店时间 */
    closedTime?: Date;
    /** 闭店原因 */
    closedReason?: string;
    createTime: Date;
    children?: Dept[];
  }
}

/** 查询部门（精简)列表 */
export async function getSimpleDeptList() {
  return requestClient.get<SystemDeptApi.Dept[]>('/system/dept/simple-list');
}

/** 查询部门列表 */
export async function getDeptList() {
  return requestClient.get('/system/dept/list');
}

/** 查询部门详情 */
export async function getDept(id: number) {
  return requestClient.get<SystemDeptApi.Dept>(`/system/dept/get?id=${id}`);
}

/** 新增部门 */
export async function createDept(data: SystemDeptApi.Dept) {
  return requestClient.post('/system/dept/create', data);
}

/** 修改部门 */
export async function updateDept(data: SystemDeptApi.Dept) {
  return requestClient.put('/system/dept/update', data);
}

/** 门店开店 / 闭店（只对门店节点有效） */
export async function updateDeptBusinessStatus(data: {
  id: number;
  businessStatus: number;
  closedReason?: string;
}) {
  return requestClient.put('/system/dept/update-business-status', data);
}

/** 删除部门 */
export async function deleteDept(id: number) {
  return requestClient.delete(`/system/dept/delete?id=${id}`);
}

/** 批量删除部门 */
export async function deleteDeptList(ids: number[]) {
  return requestClient.delete(`/system/dept/delete-list?ids=${ids.join(',')}`);
}
