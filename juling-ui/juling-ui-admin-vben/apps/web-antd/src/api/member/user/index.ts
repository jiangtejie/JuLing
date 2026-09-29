import type { PageParam, PageResult } from '@vben/request';

import { requestClient } from '#/api/request';

export namespace MemberUserApi {
  /** 订货账号信息（原 C 端会员用户） */
  export interface User {
    id?: number;
    /** 订货账号（登录名 = 订货人名字；历史数据可能为空） */
    username?: string;
    avatar?: string;
    birthday?: number;
    createTime?: number;
    loginDate?: number;
    loginIp?: string;
    mark?: string;
    mobile?: string;
    email?: string;
    name?: string;
    nickname?: string;
    registerIp?: string;
    sex?: number;
    status?: number;
    areaId?: number;
    areaName?: string;
    /** 所属部门（门店节点）编号 */
    deptId?: number;
    /** 所属客户（门店 / 代理）编号 */
    customerId?: number;
  }

  /** 开订货账号请求信息（后台给加盟客户开「账号名 + 初始密码 + 绑定门店」） */
  export interface UserCreateReqVO {
    /** 订货账号（登录名 = 订货人名字）：2-64 位，必填 */
    username: string;
    /** 初始密码：6-32 位，必填 */
    password: string;
    /** 所属客户（门店）编号，必填 */
    customerId: number;
    deptId?: number;
    nickname?: string;
    mobile?: string;
    email?: string;
    /** 状态：0 开启 / 1 关闭，不传默认开启 */
    status?: number;
    mark?: string;
  }

  /** 重置订货账号密码请求信息（重置后后端会强制该账号下线） */
  export interface UserResetPasswordReqVO {
    id: number;
    /** 新密码：6-32 位 */
    password: string;
  }
}

/** 查询订货账号列表 */
export function getUserPage(params: PageParam) {
  return requestClient.get<PageResult<MemberUserApi.User>>(
    '/member/user/page',
    {
      params,
    },
  );
}

/** 查询订货账号详情 */
export function getUser(id: number) {
  return requestClient.get<MemberUserApi.User>(`/member/user/get?id=${id}`);
}

/**
 * 开订货账号（私域加盟客户：订货人账号名 + 初始密码 + 绑定门店）
 *
 * 返回新账号编号
 */
export function createUser(data: MemberUserApi.UserCreateReqVO) {
  return requestClient.post<number>('/member/user/create', data);
}

/** 重置订货账号密码（无需短信验证码，重置后后端会强制该账号下线） */
export function resetUserPassword(data: MemberUserApi.UserResetPasswordReqVO) {
  return requestClient.put<boolean>('/member/user/reset-password', data);
}

/** 修改订货账号 */
export function updateUser(data: MemberUserApi.User) {
  return requestClient.put('/member/user/update', data);
}

/** 停用 / 启用订货账号（status：0 开启、1 停用；停用后无法登录，历史订单与台账仍可追溯） */
export function updateUserStatus(id: number, status: number) {
  return requestClient.put<boolean>(
    `/member/user/update-status?id=${id}&status=${status}`,
  );
}

/** 删除订货账号（已绑定门店/部门的账号后端会拒绝，引导改用停用） */
export function deleteUser(id: number) {
  return requestClient.delete<boolean>(`/member/user/delete?id=${id}`);
}
