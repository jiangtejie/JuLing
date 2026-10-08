-- ============================================================================
-- 76 菜单归口重构的收尾清理
--
-- 【背景】把菜单收拢到「主数据」「基础资料」等分组时，只做了「搬新的」，
--   没做「清旧的」，也没做搬完之后的核对。本脚本清掉遗留。
--
-- 【现象与修复】
--   ① 两个旧位置的空壳菜单（已由脚本 75 补成可用页面，但仍是重复入口）
--        12140 订货账号（商城系统）  ← 重复；正确位置是 2317（主数据）
--        2564  物料管理（ERP 系统）  ← 重复；正确位置是 2565（主数据）
--      处理：**软删**（deleted=1）。不物理删除 —— 留着可追溯，也给回退余地。
--
--   ② 孤儿按钮 1150 秘钥解析：父节点 1129 在 system_menu 里**根本不存在**
--      （连已删除的都查不到），且它自身的 permission 为空 ——
--      既到不了、也不授权任何东西。处理：软删。
--
--   ③ 6 条菜单的 type 标错：它们**都有子菜单**（实测 2~5 个），本就是目录，
--      却被标成 type=2（菜单）。目前无可见症状（前端对「无 component」一律按
--      layout 处理），但哪天前端改了判断逻辑，这 6 条就会变成空白页 ——
--      和「订货账号点开是空白」是同一个成因。处理：type 改回 1（目录）。
--        1083 API 日志   1200 审批中心   1224 租户管理
--        1243 文件管理   1261 OAuth 2.0  2130 邮箱管理
--
-- 【特意**没有**改的一条，记录原因以免以后有人再动】
--   12150「会员统计查询」(permission=statistics:member:query, parent=2358 统计中心)
--   表面上「按钮挂在目录下」像是不规范，但：
--     · 该权限**被 7 个后端接口使用**（@PreAuthorize），不是悬空权限
--     · 脚本 46_member_statistics_permission.sql 是**显式**把它建在 2358 下的
--       （40 脚本按产品决策删掉会员统计页面时误删了该权限，46 专门补回来）
--     · 会员统计页面已按产品决策删除，所以它**本来就没有页面可挂**
--   结论：有意为之，保持不动。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

-- ① 旧位置的重复菜单
UPDATE system_menu SET deleted = 1, update_time = now()
 WHERE id IN (12140, 2564) AND deleted = 0;

-- ② 孤儿按钮（父节点不存在）
UPDATE system_menu SET deleted = 1, update_time = now()
 WHERE id = 1150 AND deleted = 0
   AND parent_id NOT IN (SELECT id FROM system_menu);

-- ③ 目录的 type 修正（仅当确实有子菜单时才改，避免误伤真正没子节点的页面）
UPDATE system_menu m SET type = 1, update_time = now()
 WHERE m.id IN (1083, 1200, 1224, 1243, 1261, 2130)
   AND m.deleted = 0 AND m.type = 2
   AND EXISTS (SELECT 1 FROM system_menu c WHERE c.parent_id = m.id AND c.deleted = 0);

-- ④ 自检
SELECT '重复 component（应为 0）' AS 项, count(*)::text AS 值 FROM (
  SELECT component FROM system_menu
   WHERE deleted = 0 AND component IS NOT NULL AND component <> ''
   GROUP BY component HAVING count(*) > 1) t
UNION ALL SELECT '孤儿菜单（应为 0）', count(*)::text FROM system_menu m
   WHERE m.deleted = 0 AND m.parent_id <> 0
     AND m.parent_id NOT IN (SELECT id FROM system_menu WHERE deleted = 0)
UNION ALL SELECT '应为目录却标成菜单（应为 0）', count(*)::text FROM system_menu m
   WHERE m.deleted = 0 AND m.type = 2 AND (m.component IS NULL OR m.component = '')
     AND EXISTS (SELECT 1 FROM system_menu c WHERE c.parent_id = m.id AND c.deleted = 0)
UNION ALL SELECT '订货账号(12140) deleted', deleted::text FROM system_menu WHERE id = 12140
UNION ALL SELECT '物料管理(2564) deleted',  deleted::text FROM system_menu WHERE id = 2564
UNION ALL SELECT '秘钥解析(1150) deleted',  deleted::text FROM system_menu WHERE id = 1150;

COMMIT;
