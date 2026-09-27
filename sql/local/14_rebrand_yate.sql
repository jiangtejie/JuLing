-- =============================================================================
-- 品牌标识同步：把运行库中残留的 棱信矩灵 统一为 亚特
-- 背景：代码侧品牌已由「棱信矩灵」改为「亚特」，但数据库里有两处展示性字段
--       直接存了旧品牌名，界面仍会显示旧名，需要同步。
-- 影响：仅改展示名称，不动任何业务数据、外键或结构。
-- 可重复执行（幂等）。
--
-- 执行方式（PowerShell 管道会破坏中文编码，故先 cp 再 -f）：
--   docker cp sql/local/14_rebrand_yate.sql postgres:/tmp/14_rebrand_yate.sql
--   docker exec postgres psql -U root -d juling -f /tmp/14_rebrand_yate.sql
-- =============================================================================

\echo '=== 执行前 ==='
SELECT id, name, contact_name FROM system_tenant WHERE name = '棱信矩灵';
SELECT id, client_id, name FROM system_oauth2_client WHERE name = '棱信矩灵';

BEGIN;

-- 1. 租户名称（登录后界面顶部/租户标识）
UPDATE system_tenant
SET name = '亚特', update_time = now()
WHERE name = '棱信矩灵';

-- 2. OAuth2 客户端名称（管理后台「应用管理」列表展示）
UPDATE system_oauth2_client
SET name = '亚特', update_time = now()
WHERE name = '棱信矩灵';

COMMIT;

\echo '=== 执行后（应各返回 0 行旧品牌）==='
SELECT id, name, contact_name FROM system_tenant WHERE name LIKE '%矩灵%';
SELECT id, client_id, name FROM system_oauth2_client WHERE name LIKE '%矩灵%';
\echo '=== 当前品牌 ==='
SELECT id, name FROM system_tenant WHERE id = 1;
