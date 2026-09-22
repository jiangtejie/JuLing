import { toTimestamp } from '@/utils/date'

/**
 * 计算并格式化通话时长（接通到结束）
 *
 * edit by 棱信矩灵：改用 @/utils/date 的 toTimestamp。原实现 new Date(字符串) 在 iOS/JSCore 上
 * 解析 LocalDateTime 会得到 NaN，导致通话时长恒显示 '-'
 */
export function formatCallDuration(acceptTime?: string, endTime?: string): string {
  if (!acceptTime || !endTime) {
    return '-'
  }
  const seconds = Math.floor((toTimestamp(endTime) - toTimestamp(acceptTime)) / 1000)
  if (Number.isNaN(seconds) || seconds < 0) {
    return '-'
  }
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  const s = seconds % 60
  const pad = (n: number) => String(n).padStart(2, '0')
  return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${pad(m)}:${pad(s)}`
}
