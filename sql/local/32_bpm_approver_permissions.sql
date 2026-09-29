-- =============================================================================
-- 门店要货审批：两级流程（供应链 → 财务出纳）配套数据
--
-- 背景（2026-09-28 决策）：加盟店要货申请审批 = **先供应链审批，后财务出纳审批**。
-- BPM 流程定义 trade-order-store-audit 已相应重建（v4，见 docs/store-ordering-flow-design.md）：
--   发起人 → 供应链审批（角色：供应链）→ 财务出纳审批（角色：财务）→ 结束
--   两个节点均为「多人或签」（组内任一人通过即可），审批人为空时「转交流程管理员」。
--
-- 本脚本解决"任务分给了人、人却点不动"的权限缺口：
--   实测「供应链(157)」「财务(156)」两个角色**没有任何 bpm 权限**，成员调用审批接口直接 403。
--   这里把 BPM 相关菜单与按钮权限（含 bpm:task:query / bpm:task:update）授给这两个角色。
--
-- 幂等：可重复执行（NOT EXISTS 去重）。
-- 执行：psql -U root -d yate -f sql/local/32_bpm_approver_permissions.sql
-- 注意：直接改 SQL 不会刷新应用侧的权限缓存；线上请改用
--       后台【角色管理 → 分配菜单】或 POST /system/permission/assign-role-menu（本脚本执行后建议重启或走一次该接口）。
-- =============================================================================

WITH bpm_menus AS (
    SELECT id FROM system_menu
    WHERE deleted = 0
      AND (permission LIKE 'bpm:%'
           OR name IN ('待办任务', '已办任务', '抄送我的', '我的流程', '发起流程', '流程详情', '审批中心'))
)
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT (SELECT COALESCE(MAX(id),0) FROM system_role_menu) + row_number() OVER (), r.role_id, m.id, '1', now(), '1', now(), 0, 1
FROM bpm_menus m
CROSS JOIN (VALUES (156), (157)) AS r(role_id)   -- 156 财务、157 供应链
WHERE NOT EXISTS (SELECT 1 FROM system_role_menu x WHERE x.role_id = r.role_id AND x.menu_id = m.id);

-- 复核：两个角色各应有多少 bpm 相关授权
SELECT rm.role_id || ' → ' || count(*) || ' 条 bpm 授权'
FROM system_role_menu rm JOIN system_menu m ON m.id = rm.menu_id
WHERE rm.role_id IN (156, 157) AND (m.permission LIKE 'bpm:%' OR m.name IN ('待办任务','已办任务','抄送我的','我的流程','发起流程','流程详情','审批中心'))
GROUP BY rm.role_id ORDER BY rm.role_id;

-- 待办：财务角色目前无人，第二级会按"转交流程管理员"兜底落到管理员。
-- 请把「财务」(156) 角色分配给实际出纳账号，第二级审批才会落到出纳的待办里：
--   UPDATE 走后台【用户管理 → 分配角色】，或
--   INSERT INTO system_user_role (id, user_id, role_id, creator, create_time, updater, update_time, deleted, tenant_id)
--   VALUES ((SELECT COALESCE(MAX(id),0)+1 FROM system_user_role), <出纳用户id>, 156, '1', now(), '1', now(), 0, 1);
