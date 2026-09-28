-- =============================================================================
-- 补全角色的「祖先菜单」授权（yudao 会剔除父菜单未授权的节点）
--
-- 背景（实测踩坑）：给角色授了某个深层菜单/按钮权限，若**没有同时授予它的祖先菜单**，
-- MenuServiceImpl.isMenuDisabled（MenuServiceImpl.java:177-181）会把"父菜单不在授权集合里"
-- 的节点判为禁用并整棵剔除，于是该权限**不会出现在 /system/auth/get-permission-info** 里：
-- 前端拿不到权限、菜单树里也没有入口（但后端 @PreAuthorize 走的是 DB 角色-菜单映射、不受影响，
-- 表现为"接口能调通、界面却看不到"——供应链/财务审批人看不到首页待办卡片就是这个原因）。
--
-- 本脚本为指定角色**递归补全所有祖先菜单**（幂等，可重复执行）。
-- 执行：psql -U root -d yate -f sql/local/34_role_menu_ancestors.sql
-- 执行后建议让相关用户重新登录或刷新权限（前端权限在登录时下发）。
-- =============================================================================

WITH RECURSIVE granted AS (
    SELECT rm.role_id, m.id, m.parent_id
    FROM system_role_menu rm JOIN system_menu m ON m.id = rm.menu_id
    WHERE rm.role_id IN (156, 157)   -- 156 财务 / 157 供应链（按需增删角色）
      AND rm.deleted = 0 AND m.deleted = 0
), ancestors AS (
    SELECT role_id, parent_id AS id FROM granted WHERE parent_id IS NOT NULL AND parent_id <> 0
    UNION
    SELECT a.role_id, m.parent_id FROM ancestors a JOIN system_menu m ON m.id = a.id
    WHERE m.parent_id IS NOT NULL AND m.parent_id <> 0
), missing AS (
    SELECT DISTINCT a.role_id, a.id FROM ancestors a
    WHERE a.id IS NOT NULL AND a.id <> 0
      AND EXISTS (SELECT 1 FROM system_menu m WHERE m.id = a.id AND m.deleted = 0)
      AND NOT EXISTS (SELECT 1 FROM system_role_menu x WHERE x.role_id = a.role_id AND x.menu_id = a.id AND x.deleted = 0)
)
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT (SELECT COALESCE(MAX(id),0) FROM system_role_menu) + row_number() OVER (), role_id, id, '1', now(), '1', now(), 0, 1
FROM missing;

-- 复核：两个角色的 bpm 权限与"工作流程"根菜单是否都在
SELECT rm.role_id || ' → 菜单数 ' || count(*)
FROM system_role_menu rm WHERE rm.role_id IN (156, 157) AND rm.deleted = 0 GROUP BY rm.role_id ORDER BY rm.role_id;
