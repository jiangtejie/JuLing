import type { PageParam, PageResult } from '@/http/types'
import { http } from '@/http/http'

/**
 * 订货账号（member_user）
 *
 * 注：会员等级 / 积分 / 成长值 / 标签 / 分组 随会员中心一并下线，
 * 对应的字段与 update-level、update-point 接口已从后端删除，这里同步移除。
 */
export interface MemberUser {
  id?: number
  avatar?: string
  birthday?: string | number | Date
  createTime?: string
  loginDate?: string | number | Date
  loginIp?: string
  mark?: string
  mobile?: string
  email?: string
  name?: string
  nickname?: string
  registerIp?: string
  sex?: number
  status?: number
  areaId?: number
  areaName?: string
}

/** 获取订货账号分页列表 */
export function getMemberUserPage(params: PageParam) {
  return http.get<PageResult<MemberUser>>('/member/user/page', params)
}

/** 获取订货账号详情 */
export function getMemberUser(id: number) {
  return http.get<MemberUser>(`/member/user/get?id=${id}`)
}

/** 更新订货账号 */
export function updateMemberUser(data: MemberUser) {
  return http.put<boolean>('/member/user/update', data)
}
