import dayjs from 'dayjs'
import { toTimestamp as parseTimestamp } from '@/utils/date'

const WEEKDAY_NAMES_FULL = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'] // 会话时间星期文案
const WEEKDAY_NAMES_SHORT = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'] // 消息时间星期文案

/**
 * 时间值转毫秒
 *
 * edit by 棱信矩灵：原实现用 new Date(time) 解析，而后端 sendTime 是 LocalDateTime 字符串
 * （'YYYY-MM-DD HH:mm:ss'），iOS/JSCore 上会返回 NaN → 0，导致消息时间分隔条消失、
 * 撤回按钮的 2 分钟判断恒 false 而永不出现。改用 @/utils/date 的 toTimestamp（已做 '-'→'/' 兼容）。
 */
export function toTimestamp(time?: number | string) {
  if (!time) {
    return 0
  }
  const timestamp = parseTimestamp(time)
  return Number.isNaN(timestamp) ? 0 : timestamp
}

/** 消息列表时间分隔条 */
export function formatTimeTip(timestamp: number) {
  if (!timestamp) {
    return ''
  }
  const target = dayjs(timestamp)
  const now = dayjs()
  const time = target.format('HH:mm')
  if (target.isSame(now, 'day')) {
    return time
  }
  if (target.isSame(now.subtract(1, 'day'), 'day')) {
    return `昨天 ${time}`
  }
  const diffDays = now.startOf('day').diff(target.startOf('day'), 'day')
  if (diffDays >= 2 && diffDays <= 6) {
    return `${WEEKDAY_NAMES_SHORT[target.day()]} ${time}`
  }
  return target.format('MM-DD HH:mm')
}

/** 会话列表时间 */
export function formatConversationTime(timestamp?: number) {
  if (!timestamp) {
    return ''
  }
  const target = dayjs(timestamp)
  const now = dayjs()
  if (target.isSame(now, 'day')) {
    return target.format('HH:mm')
  }
  if (target.isSame(now.subtract(1, 'day'), 'day')) {
    return `昨天 ${target.format('HH:mm')}`
  }
  const diffDays = now.startOf('day').diff(target.startOf('day'), 'day')
  if (diffDays >= 2 && diffDays <= 6) {
    return WEEKDAY_NAMES_FULL[target.day()]
  }
  return target.year() === now.year() ? target.format('MM/DD') : target.format('YYYY/MM/DD')
}

/** 历史消息搜索时间 */
export function formatHistoryTime(timestamp: number) {
  if (!timestamp) {
    return ''
  }
  const target = dayjs(timestamp)
  return target.year() === dayjs().year()
    ? target.format('M月D日 HH:mm')
    : target.format('YYYY年M月D日 HH:mm')
}

/** 合并消息详情时间 */
export function formatMergeItemTime(timestamp: number) {
  return timestamp ? dayjs(timestamp).format('MM-DD HH:mm') : ''
}

/** 格式化 RTC 通话时长 */
export function formatCallDuration(seconds?: number) {
  const total = Math.max(0, Math.floor(seconds || 0))
  const hours = Math.floor(total / 3600)
  const minutes = Math.floor((total % 3600) / 60)
  const remainSeconds = total % 60
  const pad = (value: number) => String(value).padStart(2, '0')
  return hours > 0
    ? `${hours}:${pad(minutes)}:${pad(remainSeconds)}`
    : `${pad(minutes)}:${pad(remainSeconds)}`
}
