-- ============================================================================
-- 70 价目表适用范围：补唯一约束
--
-- 背景：ErpPriceListServiceImpl#validateScopes 已经在**代码层**拦了「同一张价目表里同一对象只能有一行」，
--   但数据库层没有约束 —— 并发写入、脚本直接改库、以后别的代码路径都可能绕过它。
--   重复的范围行会让「是不是默认价目表」变得没有意义，属于"配置错了但表现随机"的一类问题。
--
-- 注意：partner_id 可为空（= 通用范围），而 PostgreSQL 的唯一索引把 NULL 视为互不相同，
--   所以对 partner_id 做 COALESCE 后再建索引，否则可以插入多行通用范围。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

CREATE UNIQUE INDEX IF NOT EXISTS uk_price_list_scope_partner
    ON erp_price_list_scope (price_id, COALESCE(partner_id, 0))
    WHERE deleted = 0;

SELECT '唯一索引是否就位（应为 1）' AS item,
       (SELECT count(*)::text FROM pg_indexes WHERE indexname = 'uk_price_list_scope_partner') AS value
UNION ALL SELECT '索引定义',
       COALESCE((SELECT indexdef FROM pg_indexes WHERE indexname = 'uk_price_list_scope_partner'), '无');

COMMIT;
