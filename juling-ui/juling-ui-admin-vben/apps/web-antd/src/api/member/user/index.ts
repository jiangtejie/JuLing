import type { PageParam, PageResult } from '@vben/request';

import { requestClient } from '#/api/request';

export namespace MemberUserApi {
  /** 会员用户信息 */
  export interface User {
    id?: number;
    /** 订货账号（登录名 = 订货人名字；C 端历史会员可能为空） */
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
    tagIds?: number[];
    groupId?: number;
    levelId?: number;
    levelName?: null | string;
    point?: null | number;
    totalPoint?: null | number;
    experience?: null | number;
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

  /** 重置订货账号密码请求信息（重置后后端会强制该会员下线） */
  export interface UserResetPasswordReqVO {
    id: number;
    /** 新密码：6-32 位 */
    password: string;
  }

  /** 会员用户等级更新信息 */
  export interface UserUpdateLevelReqVO {
    id: number;
    levelId: number;
    reason: string;
  }

  /** 会员用户积分更新信息 */
  export interface UserPointUpdateReqVO {
    id: number;
    point: number;
  }
}

/** 查询会员用户列表 */
export function getUserPage(params: PageParam) {
  return requestClient.get<PageResult<MemberUserApi.User>>(
    '/member/user/page',
    {
      params,
    },
  );
}

/** 查询会员用户详情 */
export function getUser(id: number) {
  return requestClient.get<MemberUserApi.User>(`/member/user/get?id=${id}`);
}

/**
 * 开订货账号（私域加盟客户：订货人账号名 + 初始密码 + 绑定门店）
 *
 * 返回新会员编号
 */
export function createUser(data: MemberUserApi.UserCreateReqVO) {
  return requestClient.post<number>('/member/user/create', data);
}

/** 重置订货账号密码（无需短信验证码，重置后后端会强制该会员下线） */
export function resetUserPassword(data: MemberUserApi.UserResetPasswordReqVO) {
  return requestClient.put<boolean>('/member/user/reset-password', data);
}

/** 修改会员用户 */
export function updateUser(data: MemberUserApi.User) {
  return requestClient.put('/member/user/update', data);
}

/** 修改会员用户等级 */
export function updateUserLevel(data: MemberUserApi.UserUpdateLevelReqVO) {
  return requestClient.put('/member/user/update-level', data);
}

/** 修改会员用户积分 */
export function updateUserPoint(data: MemberUserApi.UserPointUpdateReqVO) {
  return requestClient.put('/member/user/update-point', data);
}
