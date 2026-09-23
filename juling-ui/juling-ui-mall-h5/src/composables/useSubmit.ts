/**
 * 防重复提交包装。
 *
 * const { loading, run } = useSubmit(async () => { await createOrder(...) })
 * <van-button :loading="loading" @click="run">提交订单</van-button>
 *
 * 说明：失败提示由请求层（`utils/request`）统一处理，此处只负责 loading 与解锁节奏。
 */
export function useSubmit<A extends unknown[], R>(
  handler: (...args: A) => Promise<R>,
  options: {
    /** 解锁延迟，避免连点 */ delay?: number;
  } = {},
) {
  const { delay = 300 } = options;
  const loading = ref(false);

  async function run(...args: A): Promise<R | undefined> {
    if (loading.value) return undefined;
    loading.value = true;
    try {
      return await handler(...args);
    } finally {
      setTimeout(() => {
        loading.value = false;
      }, delay);
    }
  }

  return { loading, run };
}
