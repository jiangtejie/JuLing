-- ============================================================================
-- 52 组织架构：system_dept 区分「组织 / 门店」+ 门店开店闭店 + 菜单改名
--
-- 背景（2026-10）：system_dept 此前只是一棵「无类型的部门树」——仅 name/parentId/sort/
--   leaderUserId/phone/email/status，没有任何字段说明「这个节点是部门还是门店」。
--   而库里早已把门店当部门节点用（134-146 共 13 家门店、121 中心库、119-122 品牌）。
--   设计见 docs/organization-architecture-design.md。
--
-- 本脚本做五件事：
--   1) system_dept 加 dept_type（ORG 组织 / STORE 门店）+ 营业状态与闭店留痕；
--      **店型（直营/加盟）刻意不落在本表** —— 以 erp_customer.store_type 为唯一权威，
--      避免同一件事两处维护必然漂移（见设计文档 §7 第 1 项）。
--   2) 按客户档案回填 dept_type：门店节点 = 被「非代理」客户引用的部门（实测 13 个：134-146）。
--   3) 字典 system_dept_type / system_dept_business_status。
--   4) 菜单「部门管理」(103) 更名「组织架构管理」，并补「门店开店/闭店」按钮权限。
--   5) 组织节点类型的索引。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

-- ---------- 1) system_dept 加列 ----------
ALTER TABLE system_dept ADD COLUMN IF NOT EXISTS dept_type       varchar(20) NOT NULL DEFAULT 'ORG';
ALTER TABLE system_dept ADD COLUMN IF NOT EXISTS business_status smallint    NOT NULL DEFAULT 0;
ALTER TABLE system_dept ADD COLUMN IF NOT EXISTS closed_time     timestamp;
ALTER TABLE system_dept ADD COLUMN IF NOT EXISTS closed_reason   varchar(255);

COMMENT ON COLUMN system_dept.dept_type       IS '节点类型：ORG 组织 / STORE 门店（字典 system_dept_type）';
COMMENT ON COLUMN system_dept.business_status IS '营业状态（仅门店有意义）：0 营业 / 1 已闭店（字典 system_dept_business_status）';
COMMENT ON COLUMN system_dept.closed_time     IS '闭店时间（复开时清空）';
COMMENT ON COLUMN system_dept.closed_reason   IS '闭店原因';

-- ---------- 2) 回填 dept_type ----------
-- 门店判定：该部门被「非代理」客户档案引用（代理客户有下级子客户，不算门店）
UPDATE system_dept d
SET dept_type = 'STORE', updater = 'script52', update_time = now()
WHERE d.deleted = 0
  AND d.dept_type <> 'STORE'
  AND EXISTS (SELECT 1 FROM erp_customer c
              WHERE c.deleted = 0 AND c.dept_id = d.id
                AND NOT EXISTS (SELECT 1 FROM erp_customer s
                                WHERE s.deleted = 0 AND s.parent_customer_id = c.id));

-- 反向复位：与客户档案保持一致（保证反复执行结果稳定）
UPDATE system_dept d
SET dept_type = 'ORG', updater = 'script52', update_time = now()
WHERE d.deleted = 0
  AND d.dept_type <> 'ORG'
  AND NOT EXISTS (SELECT 1 FROM erp_customer c
                  WHERE c.deleted = 0 AND c.dept_id = d.id
                    AND NOT EXISTS (SELECT 1 FROM erp_customer s
                                    WHERE s.deleted = 0 AND s.parent_customer_id = c.id));

-- 复开的门店：清掉闭店留痕（营业状态与留痕必须一致，避免出现「营业但有闭店时间」）
UPDATE system_dept SET closed_time = NULL, closed_reason = NULL, updater = 'script52', update_time = now()
WHERE deleted = 0 AND business_status = 0 AND (closed_time IS NOT NULL OR closed_reason IS NOT NULL);

CREATE INDEX IF NOT EXISTS idx_system_dept_dept_type ON system_dept (dept_type) WHERE deleted = 0;

-- ---------- 3) 字典 ----------
INSERT INTO system_dict_type (id, name, type, status, remark, creator, create_time, updater, update_time, deleted)
VALUES (11570, '组织节点类型', 'system_dept_type', 0, '组织架构节点：组织 / 门店', '1', now(), '1', now(), 0),
       (11571, '门店营业状态', 'system_dept_business_status', 0, '门店开店 / 闭店', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

INSERT INTO system_dict_data (id, sort, label, value, dict_type, status, color_type, css_class, remark, creator, create_time, updater, update_time, deleted)
VALUES
    (115700, 0, '组织', 'ORG',   'system_dept_type', 0, 'default', '', '部门 / 公司 / 品牌 / 仓库等非门店节点', '1', now(), '1', now(), 0),
    (115701, 1, '门店', 'STORE', 'system_dept_type', 0, 'primary', '', '门店：可被订货账号授权、可下单、可建门店仓', '1', now(), '1', now(), 0),
    (115710, 0, '营业',   '0', 'system_dept_business_status', 0, 'success', '', '', '1', now(), '1', now(), 0),
    (115711, 1, '已闭店', '1', 'system_dept_business_status', 0, 'danger',  '', '已闭店门店不可被授权、不可下单', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- ---------- 4) 菜单：改名 + 开店/闭店按钮 ----------
UPDATE system_menu SET name = '组织架构管理', updater = 'script52', update_time = now()
WHERE id = 103 AND deleted = 0 AND name <> '组织架构管理';

INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT v.id, v.name, v.perm, 3, v.sort, 103, '', '', NULL, NULL,
       0, true, true, true, 'script52', now(), 'script52', now(), 0
FROM (VALUES (12170, '门店开店/闭店', 'system:dept:update-business-status', 5)) AS v(id, name, perm, sort)
WHERE EXISTS (SELECT 1 FROM system_menu WHERE id = 103 AND deleted = 0)
  AND NOT EXISTS (SELECT 1 FROM system_menu WHERE id = v.id);

-- 授给已有「组织架构管理」的角色，并补祖先链（yudao 会剔除父菜单未授权的节点）
WITH RECURSIVE need AS (
    SELECT id, parent_id FROM system_menu WHERE id = 103 AND deleted = 0
    UNION ALL
    SELECT m.id, m.parent_id FROM system_menu m JOIN need n ON m.id = n.parent_id WHERE m.deleted = 0
), target_role AS (
    SELECT DISTINCT rm.role_id, rm.tenant_id FROM system_role_menu rm
    WHERE rm.deleted = 0 AND rm.menu_id = 103
), want AS (
    SELECT id FROM need UNION ALL SELECT 12170
)
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT nextval('system_role_menu_seq'), t.role_id, w.id, 'script52', now(), 'script52', now(), 0, t.tenant_id
FROM target_role t CROSS JOIN want w
WHERE NOT EXISTS (SELECT 1 FROM system_role_menu x
                   WHERE x.deleted = 0 AND x.role_id = t.role_id AND x.menu_id = w.id);

-- ---------- 5) 序列与自检 ----------
SELECT setval('system_menu_seq',      (SELECT COALESCE(MAX(id), 1) FROM system_menu), true);
SELECT setval('system_dict_type_seq', (SELECT COALESCE(MAX(id), 1) FROM system_dict_type), true);
SELECT setval('system_dict_data_seq', (SELECT COALESCE(MAX(id), 1) FROM system_dict_data), true);

SELECT '门店节点数' AS item, (SELECT count(*)::text FROM system_dept WHERE deleted = 0 AND dept_type = 'STORE') AS value
UNION ALL SELECT '组织节点数', (SELECT count(*)::text FROM system_dept WHERE deleted = 0 AND dept_type = 'ORG')
UNION ALL SELECT '菜单名', (SELECT name FROM system_menu WHERE id = 103)
UNION ALL SELECT '新增按钮权限',
       COALESCE((SELECT string_agg(id || ':' || permission, ', ') FROM system_menu WHERE id = 12170), '无')
UNION ALL SELECT '已授角色数',
       (SELECT count(DISTINCT role_id)::text FROM system_role_menu WHERE deleted = 0 AND menu_id = 12170)
UNION ALL SELECT '菜单序列下一个值（须 > max(id)）',
       (SELECT CASE WHEN (SELECT last_value FROM system_menu_seq) >= (SELECT MAX(id) FROM system_menu)
                    THEN 'OK' ELSE '异常' END);

COMMIT;
