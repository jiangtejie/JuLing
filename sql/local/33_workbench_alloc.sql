-- =============================================================================
-- 门店订货链 S2（切片一）：订单工作台 + 分料（统配 / 直拨）
--
-- 背景（《重庆亚特餐饮业务蓝图V3.0》CY-001 / CY-002 / CY-006）：
--   门店要货单（= 商城交易订单 trade_order）审核通过后**不直接**变成出库单，而是先进入
--   「订单工作台」（中心库操作中枢），逐行判定分料方式：
--     · 统配（CENTRAL）：中心库配送出库（ERP 销售出库，配送出库单 XSCK…）；
--     · 直拨（DIRECT） ：中心库向供应商下采购订单（CGDD…），供应商直送门店（不入中心库）。
--   物料（erp_product）带两个开关式属性「允许统配 / 允许直拨」，可同时允许，由工作台选择。
--
-- 本脚本做结构准备（**只加列/加表/加菜单，不改既有列**）：
--   1) erp_product         增加 allow_central / allow_direct（默认都允许）；
--   2) trade_order_item    增加 alloc_mode（CENTRAL / DIRECT，可空＝未分料）；
--   3) trade_order         增加 store_type 快照（工作台判定"直营免审"用，避免跨模块 join erp_customer）；
--   4) 回填：新增列的历史值 + demo 物料的分料属性（有意留出"只统配"与"只直拨"两类样本）；
--   5) 字典：trade_order_item_alloc_mode；
--   6) 菜单：「订单工作台」+ 查询/下推按钮权限，并授权给「供应链」角色（157）。
--
-- 幂等：ADD COLUMN IF NOT EXISTS / ON CONFLICT DO NOTHING / WHERE 条件回填，可重复执行。
-- 执行：psql -U root -d yate -f sql/local/33_workbench_alloc.sql
-- =============================================================================

-- ---------- 1) 物料分料属性 ----------
ALTER TABLE erp_product ADD COLUMN IF NOT EXISTS allow_central boolean NOT NULL DEFAULT TRUE;
ALTER TABLE erp_product ADD COLUMN IF NOT EXISTS allow_direct  boolean NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN erp_product.allow_central IS '允许统配：中心库配送出库（工作台可选统配）';
COMMENT ON COLUMN erp_product.allow_direct  IS '允许直拨：中心库下采购订单、供应商直送门店（工作台可选直拨）';

-- ---------- 2) 订单行分料方式 ----------
ALTER TABLE trade_order_item ADD COLUMN IF NOT EXISTS alloc_mode varchar(16);
ALTER TABLE trade_order_item ADD COLUMN IF NOT EXISTS alloc_count numeric(24, 6);

COMMENT ON COLUMN trade_order_item.alloc_mode  IS '分料方式：CENTRAL 统配 / DIRECT 直拨；NULL = 未分料（字典 trade_order_item_alloc_mode）';
COMMENT ON COLUMN trade_order_item.alloc_count IS '本次分料下推数量；为空表示按整行数量下推（≤ 原数量）';

CREATE INDEX IF NOT EXISTS idx_trade_order_item_alloc_mode ON trade_order_item (alloc_mode);

-- ---------- 3) 订单店型快照（工作台"待处理"口径判定） ----------
ALTER TABLE trade_order ADD COLUMN IF NOT EXISTS store_type varchar(20);
COMMENT ON COLUMN trade_order.store_type IS '下单门店店型快照：DIRECT 直营（免审）/ FRANCHISE 加盟（需审核）';

-- 回填：从门店客户主数据取店型（历史订单；取不到时留空，按直营免审处理，与发货闸门口径一致）
UPDATE trade_order o
   SET store_type = c.store_type
  FROM erp_customer c
 WHERE o.customer_id = c.id
   AND o.store_type IS NULL
   AND c.store_type IS NOT NULL;

-- ---------- 4) 回填：物料分料属性（demo 物料留出三类样本） ----------
-- 4.1 新增列的历史值兜底（列已带 DEFAULT，此处只兜 NULL，防手工造数）
UPDATE erp_product SET allow_central = TRUE WHERE allow_central IS NULL;
UPDATE erp_product SET allow_direct  = TRUE WHERE allow_direct  IS NULL;

-- 4.2 demo-seed 物料：一份"有意义的"取值
--     · 一次性用品（打包盒/餐巾纸）→ 只统配（体积大、中心库统一配送）
--     · 鲜货（鲜毛肚/鸭肠/鲜牛肉）  → 只直拨（供应商直送门店，不入中心库）
--     · 其余                        → 统配 + 直拨都允许
UPDATE erp_product SET allow_direct = FALSE, allow_central = TRUE
 WHERE remark = 'demo-seed' AND name IN ('打包盒', '餐巾纸');
UPDATE erp_product SET allow_central = FALSE, allow_direct = TRUE
 WHERE remark = 'demo-seed' AND name IN ('鲜毛肚', '鸭肠', '鲜牛肉');
UPDATE erp_product SET allow_central = TRUE, allow_direct = TRUE
 WHERE remark = 'demo-seed' AND name NOT IN ('打包盒', '餐巾纸', '鲜毛肚', '鸭肠', '鲜牛肉');

-- ---------- 5) 字典 ----------
INSERT INTO system_dict_type (id, name, type, status, remark, creator, create_time, updater, update_time, deleted)
VALUES (11560, '订单分料方式', 'trade_order_item_alloc_mode', 0, '订单工作台分料：统配 / 直拨', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

INSERT INTO system_dict_data (id, sort, label, value, dict_type, status, color_type, css_class, remark, creator, create_time, updater, update_time, deleted)
VALUES
    (115600, 0, '统配', 'CENTRAL', 'trade_order_item_alloc_mode', 0, 'primary', '', '中心库配送出库 → 门店收货', '1', now(), '1', now(), 0),
    (115601, 1, '直拨', 'DIRECT',  'trade_order_item_alloc_mode', 0, 'warning', '', '中心库下采购订单 → 供应商直送门店', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- ---------- 6) 菜单与权限（挂在「订单中心」2072 下） ----------
INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name, status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
VALUES (11550, '订单工作台', '', 2, 2, 2072, 'workbench', 'ep:operation', 'mall/trade/workbench/index', 'TradeWorkbench', 0, TRUE, TRUE, TRUE, '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name, status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
VALUES
    (11551, '工作台查询', 'trade:workbench:query', 3, 1, 11550, '', '', '', '', 0, TRUE, TRUE, FALSE, '1', now(), '1', now(), 0),
    (11552, '工作台下推', 'trade:workbench:push',  3, 2, 11550, '', '', '', '', 0, TRUE, TRUE, FALSE, '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- 授权给「供应链」(157) / 「财务」(156) 角色（与订单列表/审核同一批角色）；
-- system_role_menu.id 无默认值，且 system_role_menu_seq 常落后于 max(id)（见 28_fix_all_sequences.sql），
-- 因此这里用 max(id) + row_number() 取号，避免撞主键
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT (SELECT COALESCE(MAX(id), 0) FROM system_role_menu) + row_number() OVER (), r.role_id, m.menu_id, '1', now(), '1', now(), 0, 1
  FROM (VALUES (157), (156)) AS r(role_id)
  CROSS JOIN (VALUES (11550), (11551), (11552)) AS m(menu_id)
 WHERE NOT EXISTS (SELECT 1 FROM system_role_menu rm
                    WHERE rm.role_id = r.role_id AND rm.menu_id = m.menu_id AND rm.deleted = 0);

-- ---------- 7) 核对查询 ----------
-- select id, name, allow_central, allow_direct from erp_product where remark = 'demo-seed' order by id;
-- select alloc_mode, count(*) from trade_order_item where deleted = 0 group by alloc_mode;
-- select id, name, component from system_menu where id in (11550, 11551, 11552);
