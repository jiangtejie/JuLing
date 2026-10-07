-- ============================================================================
-- 69 价目表统一重构：采购价目表 / 配送价目表 合并为一套「价目表 + 类型」
--
-- 背景：用户提出要「配送价目表」（门店配送的内部结算价），并要求统一重构干净。
--
-- 为什么统一（评估结论）：
--   两个对象除了「适用对象是谁」之外 90% 同构 —— 头字段相同、行字段相同、
--   **取价算法完全相同**（专项 > 通用 → 默认 > 普通 → 生效日期新 > 旧）。
--   分成两张表 = 一份永远要同步维护的重复逻辑；而且「销售价目表」迟早会来。
--   此刻是最便宜的迁移时机：采购价目表刚落库、**零生产数据**。
--
-- 门店维度（用户明确要求）：一个配送价目表**可以指定适用哪些门店**（金蝶的「适用范围」页签
--   就是一行一个组织）。因此适用范围独立成表，支持一张价目表适用 N 个对象。
--   `partner_id` 为空 = **通用范围**（金蝶也有独立的「通用范围」页签），优先级最低。
--
-- 表结构：
--   erp_price_list        头   —— price_type(PURCHASE/DELIVERY) + 编码/名称/状态/有效期/含税/定价员
--   erp_price_list_scope  范围 —— 一张价目表适用 N 个对象；is_default 在**范围行**上
--   erp_price_list_item   行   —— 物料 + 单价(不含税) + 税率
--
-- 「默认价目表」为什么放在范围行而不是头上（对齐金蝶）：同一张价目表适用多个门店时，
--   可以只对其中某些门店是默认，粒度更准；放头上只能整张表一刀切。
--
-- 编码规则：采购 CJJM、配送 PSJM（金蝶配送价目表也是 PSJM 前缀），各自独立发号。
-- 权限：统一为 erp:price-list:*（两个菜单共用同一个页面实现）。
--
-- 幂等：表/列的重命名与新增都用存在性守卫，可重复执行。
--
-- ⚠️ 脚本约定（踩过的坑）：本地用 DbTool 执行时，它按 ";" + 换行切分语句，
--   因此 **DO $ ... $ 块必须写成一行**（内部的 ";" 后面不能跟换行），否则块会被切碎。
--   54 号脚本能跑通正是因为它把 DO 块写成了一行。
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1) 头表：erp_purchase_price → erp_price_list，加 price_type
-- ---------------------------------------------------------------------------
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='erp_purchase_price') AND NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='erp_price_list') THEN ALTER TABLE erp_purchase_price RENAME TO erp_price_list; END IF; END $$;
ALTER TABLE erp_price_list ADD COLUMN IF NOT EXISTS price_type varchar(16);
UPDATE erp_price_list SET price_type = 'PURCHASE' WHERE price_type IS NULL;
ALTER TABLE erp_price_list ALTER COLUMN price_type SET NOT NULL;

-- ---------------------------------------------------------------------------
-- 2) 明细表改名
-- ---------------------------------------------------------------------------
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='erp_purchase_price_item') AND NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='erp_price_list_item') THEN ALTER TABLE erp_purchase_price_item RENAME TO erp_price_list_item; END IF; END $$;

-- ---------------------------------------------------------------------------
-- 3) 适用范围表（新）
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS erp_price_list_scope (
    id          bigint      NOT NULL,
    price_id    bigint      NOT NULL,
    partner_id  bigint,
    is_default  boolean     NOT NULL DEFAULT false,
    remark      varchar(255),
    tenant_id   bigint      NOT NULL DEFAULT 0,
    creator     varchar(64) DEFAULT '',
    create_time timestamp   NOT NULL DEFAULT now(),
    updater     varchar(64) DEFAULT '',
    update_time timestamp   NOT NULL DEFAULT now(),
    deleted     int2        NOT NULL DEFAULT 0,
    CONSTRAINT pk_erp_price_list_scope PRIMARY KEY (id)
);
CREATE SEQUENCE IF NOT EXISTS erp_price_list_scope_seq;
CREATE INDEX IF NOT EXISTS idx_erp_price_list_scope_price   ON erp_price_list_scope (price_id);
CREATE INDEX IF NOT EXISTS idx_erp_price_list_scope_partner ON erp_price_list_scope (partner_id);

-- ---------------------------------------------------------------------------
-- 4) 把旧的 supplier_id / is_default 迁进适用范围表（每张表一行；supplier_id 可空=通用）
--    迁移是幂等的：已迁过的（scope 表里已有该 price_id 的行）不再重复插
-- ---------------------------------------------------------------------------
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='erp_price_list' AND column_name='supplier_id') THEN INSERT INTO erp_price_list_scope (id, price_id, partner_id, is_default, remark, tenant_id, creator, create_time, updater, update_time, deleted) SELECT nextval('erp_price_list_scope_seq'), p.id, p.supplier_id, COALESCE(p.is_default, false), 'script69 由 supplier_id/is_default 迁入', p.tenant_id, 'script69', now(), 'script69', now(), 0 FROM erp_price_list p WHERE NOT EXISTS (SELECT 1 FROM erp_price_list_scope s WHERE s.price_id = p.id AND s.deleted = 0); END IF; END $$;
ALTER TABLE erp_price_list DROP COLUMN IF EXISTS supplier_id;
ALTER TABLE erp_price_list DROP COLUMN IF EXISTS is_default;

-- ---------------------------------------------------------------------------
-- 5) 序列改名
-- ---------------------------------------------------------------------------
DO $$ BEGIN IF EXISTS (SELECT 1 FROM pg_class WHERE relkind='S' AND relname='erp_purchase_price_seq') AND NOT EXISTS (SELECT 1 FROM pg_class WHERE relkind='S' AND relname='erp_price_list_seq') THEN ALTER SEQUENCE erp_purchase_price_seq RENAME TO erp_price_list_seq; END IF; IF EXISTS (SELECT 1 FROM pg_class WHERE relkind='S' AND relname='erp_purchase_price_item_seq') AND NOT EXISTS (SELECT 1 FROM pg_class WHERE relkind='S' AND relname='erp_price_list_item_seq') THEN ALTER SEQUENCE erp_purchase_price_item_seq RENAME TO erp_price_list_item_seq; END IF; END $$;

-- ---------------------------------------------------------------------------
-- 6) 注释
-- ---------------------------------------------------------------------------
COMMENT ON TABLE  erp_price_list             IS '价目表（头）：按 price_type 区分采购 / 配送等；适用对象见 erp_price_list_scope';
COMMENT ON COLUMN erp_price_list.price_type  IS '价目表类型：PURCHASE 采购 / DELIVERY 配送；决定适用范围里的对象是供应商还是门店';
COMMENT ON TABLE  erp_price_list_scope       IS '价目表适用范围：一张价目表可适用 N 个对象（配送=门店）；partner_id 为空=通用范围';
COMMENT ON COLUMN erp_price_list_scope.partner_id IS '适用对象编号：PURCHASE=供应商 erp_supplier.id；DELIVERY=门店 erp_customer.id；**为空=通用范围**（不限对象，优先级最低）';
COMMENT ON COLUMN erp_price_list_scope.is_default IS '该对象下的默认价目表（取价时优先）；放在范围行上是为了支持「同一张表只对部分门店默认」';
COMMENT ON TABLE  erp_price_list_item        IS '价目表明细（行）：物料 + 单价(不含税) + 税率；同一价目表里同一物料只能有一行';

-- ---------------------------------------------------------------------------
-- 7) 编码规则：采购改名 + 新增配送
-- ---------------------------------------------------------------------------
UPDATE system_code_rule SET rule_key = 'erp_price_list_purchase', name = '采购价目表编码',
       updater = 'script69', update_time = now()
 WHERE deleted = 0 AND rule_key = 'erp_purchase_price';
INSERT INTO system_code_rule (id, rule_key, name, prefix, seq_length, current_value, remark, tenant_id, creator, create_time, updater, update_time, deleted)
VALUES (9, 'erp_price_list_delivery', '配送价目表编码', 'PSJM', 4, 0, '中心库 → 门店的内部结算价', 1, 'script69', now(), 'script69', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 8) 菜单：采购价目表权限统一为 erp:price-list:*；新增配送价目表
-- ---------------------------------------------------------------------------
UPDATE system_menu SET permission = replace(permission, 'erp:purchase-price:', 'erp:price-list:'),
       updater = 'script69', update_time = now()
 WHERE deleted = 0 AND permission LIKE 'erp:purchase-price:%';

INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT 12210, '配送价目表', '', 2, 6, 12182, 'delivery-price', 'lucide:truck', 'erp/purchase/delivery-price/index', 'ErpDeliveryPrice',
       0, true, true, true, 'script69', now(), 'script69', now(), 0
WHERE EXISTS (SELECT 1 FROM system_menu WHERE id = 12182 AND deleted = 0)
  AND NOT EXISTS (SELECT 1 FROM system_menu WHERE id = 12210);

INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT v.id, v.name, 'erp:price-list:' || v.act, 3, v.sort, 12210, '', '', NULL, NULL,
       0, true, true, true, 'script69', now(), 'script69', now(), 0
FROM (VALUES (12211, '配送价目表查询', 'query', 1), (12212, '配送价目表创建', 'create', 2),
             (12213, '配送价目表更新', 'update', 3), (12214, '配送价目表删除', 'delete', 4),
             (12215, '配送价目表导出', 'export', 5)) AS v(id, name, act, sort)
WHERE EXISTS (SELECT 1 FROM system_menu WHERE id = 12210 AND deleted = 0)
  AND NOT EXISTS (SELECT 1 FROM system_menu WHERE id = v.id);

-- 授权：给已有「基础资料」的角色补上配送价目表（含祖先链）
WITH RECURSIVE need AS (
    SELECT id, parent_id FROM system_menu WHERE id = 12210 AND deleted = 0
    UNION ALL SELECT m.id, m.parent_id FROM system_menu m JOIN need n ON m.id = n.parent_id WHERE m.deleted = 0
), target_role AS (
    SELECT DISTINCT rm.role_id, rm.tenant_id FROM system_role_menu rm WHERE rm.deleted = 0 AND rm.menu_id = 12180
), want AS (
    SELECT id FROM need UNION ALL SELECT 12211 UNION ALL SELECT 12212 UNION ALL SELECT 12213
    UNION ALL SELECT 12214 UNION ALL SELECT 12215
)
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT nextval('system_role_menu_seq'), t.role_id, w.id, 'script69', now(), 'script69', now(), 0, t.tenant_id
FROM target_role t CROSS JOIN want w
WHERE NOT EXISTS (SELECT 1 FROM system_role_menu x WHERE x.deleted = 0 AND x.role_id = t.role_id AND x.menu_id = w.id);

SELECT setval('system_menu_seq', (SELECT COALESCE(MAX(id), 1) FROM system_menu), true);
SELECT setval('system_code_rule_seq', (SELECT COALESCE(MAX(id), 1) FROM system_code_rule), true);

-- ---------------------------------------------------------------------------
-- 9) 自检
-- ---------------------------------------------------------------------------
SELECT '价目表三张表' AS item, COALESCE((SELECT string_agg(table_name, ', ' ORDER BY table_name)
    FROM information_schema.tables WHERE table_schema='public' AND table_name LIKE 'erp_price_list%'), '无') AS value
UNION ALL SELECT 'erp_price_list 的列',
    COALESCE((SELECT string_agg(column_name, ', ' ORDER BY ordinal_position) FROM information_schema.columns
               WHERE table_schema='public' AND table_name='erp_price_list'), '无')
UNION ALL SELECT '编码规则',
    COALESCE((SELECT string_agg(rule_key || '=' || prefix, ' | ' ORDER BY id) FROM system_code_rule
               WHERE deleted = 0 AND rule_key LIKE 'erp_price_list%'), '无')
UNION ALL SELECT '价目表菜单与按钮',
    COALESCE((SELECT string_agg(id || ':' || name, ' | ' ORDER BY id) FROM system_menu
               WHERE deleted = 0 AND (id IN (12200, 12210) OR parent_id IN (12200, 12210))), '无')
UNION ALL SELECT '旧权限码残留（应为 0）',
    (SELECT count(*)::text FROM system_menu WHERE deleted = 0 AND permission LIKE 'erp:purchase-price:%')
UNION ALL SELECT '旧的 erp_purchase_price 表（应为 0）',
    (SELECT count(*)::text FROM information_schema.tables WHERE table_schema='public' AND table_name='erp_purchase_price');

COMMIT;