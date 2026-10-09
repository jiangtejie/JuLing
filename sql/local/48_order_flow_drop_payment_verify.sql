-- ============================================================================
-- 48 门店订货链：去掉「收款核验」，提交付款凭证即进入两级审批
--
-- 背景（2026-09 产品决定）：门店在 H5 提交付款凭证后不再需要后台人工「核验收款」，
--   直接按凭证申报金额把订单置为「已收款、待发货」，加盟门店随即自动提交 BPM 两级审批
--   （trade-order-store-audit：供应链 → 财务出纳），核收款的职责由财务审批节点承接。
--   后端已同步改造（TradeOrderPaymentProofServiceImpl 不再有 auditPaymentProof）。
--
-- 本脚本做四件事：
--   1) 停用「订单收款核验」按钮权限（菜单 11320 / trade:order:payment-proof:audit）及其角色授权；
--   2) 停用字典 trade_payment_proof_status 里不再产生的「待核验」(value=1) 取值；
--   3) 给「订单提交审核」(11530 / trade:order:audit:submit) 补授权——此前 0 授权，只有超管能用，
--      而它现在是门店被驳回后的人工兜底入口，财务/供应链都该有；
--   4) 把唯一一张卡在「待核验」的历史测试单（trade_order.id=63 + 凭证 id=46）按新流程归一。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

-- 1) 下线「收款核验」按钮权限（软删菜单 + 软删授权，保留历史可追溯）
UPDATE system_menu SET deleted = 1, updater = 'script48', update_time = now()
WHERE id = 11320 AND deleted = 0;
UPDATE system_role_menu SET deleted = 1, updater = 'script48', update_time = now()
WHERE menu_id = 11320 AND deleted = 0;

-- 2) 字典：「待核验」不再产生（保留行、置为停用，避免历史行渲染空白）
UPDATE system_dict_data SET status = 1, updater = 'script48', update_time = now()
WHERE id = 113001 AND dict_type = 'trade_payment_proof_status' AND status = 0;

-- 3) 人工「提交审核」补授权给财务(156) 与供应链(157)
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT nextval('system_role_menu_seq'), r.id, 11530, 'script48', now(), 'script48', now(), 0, 1
FROM system_role r
WHERE r.deleted = 0 AND r.id IN (156, 157)
  AND EXISTS (SELECT 1 FROM system_menu m WHERE m.id = 11530 AND m.deleted = 0)
  AND NOT EXISTS (SELECT 1 FROM system_role_menu x WHERE x.deleted = 0 AND x.role_id = r.id AND x.menu_id = 11530);

-- 4) 历史「待核验」单按新流程归一：视同门店已提交凭证 → 已收款待发货（等审批）
--    仅命中那一张测试单；其它环境若无此行则不动。
UPDATE trade_order
SET pay_status = TRUE,
    status = 10,
    pay_time = COALESCE(pay_time, now()),
    paid_amount = COALESCE((SELECT sum(p.amount) FROM trade_order_payment_proof p
                            WHERE p.order_id = trade_order.id AND p.deleted = 0 AND p.status <> 2), 0),
    payment_proof_status = 4,
    audit_status = 0,
    updater = '1', update_time = now()
WHERE id = 63 AND deleted = 0 AND payment_proof_status = 1;

-- 自检
SELECT '核验按钮菜单是否已下线' AS item,
       COALESCE((SELECT 'yes(deleted=1)' FROM system_menu WHERE id = 11320 AND deleted = 1), 'no') AS value
UNION ALL
SELECT '11320 的授权行（应 0）',
       (SELECT count(*)::text FROM system_role_menu WHERE menu_id = 11320 AND deleted = 0)
UNION ALL
SELECT '字典「待核验」是否停用',
       COALESCE((SELECT 'status=' || status FROM system_dict_data WHERE id = 113001), '缺失')
UNION ALL
SELECT '提交审核(11530)已授权角色',
       COALESCE((SELECT string_agg(r.name, ', ' ORDER BY r.id) FROM system_role_menu rm JOIN system_role r ON r.id = rm.role_id
                 WHERE rm.deleted = 0 AND rm.menu_id = 11530), '无')
UNION ALL
SELECT '仍处于「待核验」(payment_proof_status=1) 的订单数（应 0）',
       (SELECT count(*)::text FROM trade_order WHERE deleted = 0 AND payment_proof_status = 1);

COMMIT;
