/**
 * 错误提示去重器。
 *
 * 语义：**每条消息各自**在 `windowMs` 窗口内只放行一次；不同消息互不影响。
 *
 * 抽成独立纯函数是为了可单测——原先的实现用单一时间戳做全局限流，
 * 导致「1 秒内不同接口的不同错误互相吞没」（如「库存不足」把「网络超时」挡掉）。
 */
export function createToastDeduper(windowMs = 1000): (message: string, now?: number) => boolean {
  /** 每条消息各自记录「上次放行时间」——按消息独立去重，而非只记最后一条 */
  const lastAtByMessage = new Map<string, number>();

  return function shouldSuppress(message: string, now: number = Date.now()): boolean {
    // 控制 Map 规模：条目过多时清理已过期项
    if (lastAtByMessage.size > 50) {
      for (const [key, ts] of lastAtByMessage) {
        if (now - ts >= windowMs) lastAtByMessage.delete(key);
      }
    }

    const lastAt = lastAtByMessage.get(message);
    if (lastAt !== undefined && now - lastAt < windowMs) return true;

    lastAtByMessage.set(message, now);
    return false;
  };
}
