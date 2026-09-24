import { showConfirmDialog } from 'vant';

/**
 * 确认弹窗：用户点「确认」返回 true，点「取消」/ 关闭返回 false。
 *
 * 为什么不直接用 `await showConfirmDialog()`：Vant 在「取消」时会让 Promise **reject**
 * （dialog/function-call.mjs 里的 `(action === "confirm" ? resolve : reject)(action)`），
 * 而 Vue 3 会把事件处理器返回的 Promise 的 rejection 交给 `app.config.errorHandler` ——
 * 用户明明只是想放弃操作，却会看到兜底的「页面出现异常」提示，控制台还会多一条未捕获异常。
 *
 * 用法：
 * ```ts
 * if (!(await confirmDialog('确认取消该订单？'))) return;
 * ```
 */
export async function confirmDialog(message: string, title = '提示'): Promise<boolean> {
  try {
    await showConfirmDialog({ title, message });
    return true;
  } catch {
    return false;
  }
}
