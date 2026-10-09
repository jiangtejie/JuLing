-- ============================================================================
-- 54 订货账号授权：备份并删除四处冗余字段（**不可逆，执行前须确认**）
--
-- 前置：53 号脚本已建 member_user_store 并回填；代码已切换到授权表读取
--       （TradeOrderStoreServiceImpl 只经 MemberUserStoreApi 取门店）。
--
-- 本脚本删除：
--   · member_user.dept_id            —— 账号没有部门
--   · member_user.customer_id        —— 账号没有自己的经营主体，它有的是一组授权门店
--   · trade_order.agent_customer_id  —— 只写不读；「谁操作的」user_id 已记
--   · erp_customer.parent_customer_id —— 唯一用途是下单授权，已被授权表取代
--
-- 另外两件事：
--   1) 软删「代理客户」（有下级客户的客户档案）—— 代理概念在业务上不存在（只是帮忙下单）；
--      其中 erp_customer 144 被门店 16 与代理 19 共用，不清理会让「一店一档」约束建不起来；
--   2) 建 uk_erp_customer_dept_id —— 门店节点 ↔ 客户档案**一对一**（组织架构设计 §7 决策 4）。
--
-- 幂等：DDL 全用 IF EXISTS；依赖旧列的数据处理用 information_schema 存在性守卫，
--       因此重复执行（列已删）不会报错。
-- 备份：删列前把旧值存到 bak_ordering_account_20261007（对齐 27 号脚本的既有做法）。
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. 备份旧值（仅当旧列还在时）
-- ---------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS bak_ordering_account_20261007;

DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'member_user' AND column_name = 'dept_id') THEN CREATE TABLE IF NOT EXISTS bak_ordering_account_20261007.member_user AS SELECT id, username, nickname, dept_id, customer_id FROM member_user; END IF; END $$;

DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'erp_customer' AND column_name = 'parent_customer_id') THEN CREATE TABLE IF NOT EXISTS bak_ordering_account_20261007.erp_customer AS SELECT id, name, dept_id, parent_customer_id, store_type, deleted FROM erp_customer; END IF; END $$;

DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'trade_order' AND column_name = 'agent_customer_id') THEN CREATE TABLE IF NOT EXISTS bak_ordering_account_20261007.trade_order AS SELECT id, user_id, customer_id, dept_id, agent_customer_id, settlement_mode, store_type FROM trade_order; END IF; END $$;

-- ---------------------------------------------------------------------------
-- 2. 软删「代理客户」（有下级客户的客户档案）
--    业务口径：代理人只是帮忙下单，不承担账期与结算，不该是一份客户档案。
-- ---------------------------------------------------------------------------
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'erp_customer' AND column_name = 'parent_customer_id') THEN UPDATE erp_customer SET deleted = 1, updater = 'script54', update_time = now() WHERE deleted = 0 AND id IN (SELECT DISTINCT parent_customer_id FROM erp_customer WHERE deleted = 0 AND parent_customer_id IS NOT NULL); END IF; END $$;

-- ---------------------------------------------------------------------------
-- 3. 门店节点 ↔ 客户档案 一对一
-- ---------------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS uk_erp_customer_dept_id
    ON erp_customer (dept_id) WHERE deleted = 0 AND dept_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 4. 删索引与列
-- ---------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_member_user_customer_id;
DROP INDEX IF EXISTS idx_erp_customer_parent_id;

ALTER TABLE member_user  DROP COLUMN IF EXISTS dept_id;
ALTER TABLE member_user  DROP COLUMN IF EXISTS customer_id;
ALTER TABLE trade_order  DROP COLUMN IF EXISTS agent_customer_id;
ALTER TABLE erp_customer DROP COLUMN IF EXISTS parent_customer_id;

-- ---------------------------------------------------------------------------
-- 5. 自检
-- ---------------------------------------------------------------------------
SELECT 'member_user 是否还有 dept_id/customer_id' AS item,
       (SELECT count(*)::text FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = 'member_user'
           AND column_name IN ('dept_id', 'customer_id')) AS value
UNION ALL SELECT 'trade_order 是否还有 agent_customer_id',
       (SELECT count(*)::text FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = 'trade_order' AND column_name = 'agent_customer_id')
UNION ALL SELECT 'erp_customer 是否还有 parent_customer_id',
       (SELECT count(*)::text FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = 'erp_customer' AND column_name = 'parent_customer_id')
UNION ALL SELECT '在营客户数（未删）', (SELECT count(*)::text FROM erp_customer WHERE deleted = 0)
UNION ALL SELECT '在营门店数（dept_id 非空）', (SELECT count(*)::text FROM erp_customer WHERE deleted = 0 AND dept_id IS NOT NULL)
UNION ALL SELECT '授权行数', (SELECT count(*)::text FROM member_user_store WHERE deleted = 0)
UNION ALL SELECT '备份表数（bak_ordering_account_20261007）',
       (SELECT count(*)::text FROM information_schema.tables WHERE table_schema = 'bak_ordering_account_20261007');

COMMIT;
