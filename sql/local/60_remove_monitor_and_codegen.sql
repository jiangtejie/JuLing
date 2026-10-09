-- ============================================================================
-- 60 下线「监控中心」与「代码生成」
--
-- 背景：这两个功能本项目用不到（用户明确要求删除）。前端页面、后端代码与模板已随本次提交
--   一并删除；本脚本负责清数据库侧遗留 —— 菜单、角色授权、以及代码生成的两张表。
--
-- 删除范围：
--   监控中心（菜单 2740）子树 7 条：
--     2740 监控中心 · 111 MySQL 监控 · 112 Java 监控 · 113 Redis 监控 · 1077 链路追踪
--     · 1066 获得 Redis 监控信息 · 1067 获得 Redis Key 列表
--   代码生成 6 条：
--     115 代码生成 · 1056 生成修改 · 1057 生成删除 · 1058 导入代码 · 1059 预览代码 · 1060 生成代码
--   表：infra_codegen_table / infra_codegen_column（实测均 0 行）+ 两个序列
--
-- **不动**：114 表单构建、116 API 接口（Swagger）—— 它们是「基础设施」直属菜单，不在本次范围。
--
-- 注意：两张 codegen 表由 sql/postgresql/juling-baseline.sql 创建，本脚本在全新环境重建后
--   会再次把它们删掉 —— 与 45 号脚本删 277 张基线表是同一模式。
--
-- 安全：菜单与授权先备份到 bak_infra_codegen_monitor_20261007，可回退。
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

-- 1) 备份
CREATE SCHEMA IF NOT EXISTS bak_infra_codegen_monitor_20261007;
CREATE TABLE IF NOT EXISTS bak_infra_codegen_monitor_20261007.system_menu AS SELECT * FROM system_menu WHERE id IN (2740, 111, 112, 113, 1077, 1066, 1067, 115, 1056, 1057, 1058, 1059, 1060);
CREATE TABLE IF NOT EXISTS bak_infra_codegen_monitor_20261007.system_role_menu AS SELECT * FROM system_role_menu WHERE menu_id IN (2740, 111, 112, 113, 1077, 1066, 1067, 115, 1056, 1057, 1058, 1059, 1060);
-- 注意：**不备份** infra_codegen_table / infra_codegen_column 两张表。
--   理由：两者实测均 0 行；且它们的建表语句本来就在 sql/postgresql/juling-baseline.sql 里
--   （第 171-293 行），需要时从基线重建即可。若在此备份，脚本第二次执行会去 SELECT 一张
--   自己已经删掉的表而报错（不幂等）。

-- 2) 删菜单与角色授权（先删授权，无外键但保持语义顺序）
DELETE FROM system_role_menu WHERE menu_id IN (2740, 111, 112, 113, 1077, 1066, 1067, 115, 1056, 1057, 1058, 1059, 1060);
DELETE FROM system_menu WHERE id IN (2740, 111, 112, 113, 1077, 1066, 1067, 115, 1056, 1057, 1058, 1059, 1060);

-- 3) 删代码生成的表与序列
DROP TABLE IF EXISTS infra_codegen_column;
DROP TABLE IF EXISTS infra_codegen_table;
DROP SEQUENCE IF EXISTS infra_codegen_column_seq;
DROP SEQUENCE IF EXISTS infra_codegen_table_seq;

-- 4) 自检
SELECT '被删菜单残留（应为 0）' AS item, count(*)::text AS value FROM system_menu WHERE id IN (2740, 111, 112, 113, 1077, 1066, 1067, 115, 1056, 1057, 1058, 1059, 1060)
UNION ALL SELECT '被删菜单的角色授权残留（应为 0）', count(*)::text FROM system_role_menu WHERE menu_id IN (2740, 111, 112, 113, 1077, 1066, 1067, 115, 1056, 1057, 1058, 1059, 1060)
UNION ALL SELECT 'infra_codegen_* 表残留（应为 0）', count(*)::text FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE 'infra\_codegen\_%'
UNION ALL SELECT '仍保留的直属开发工具菜单', COALESCE((SELECT string_agg(id || ':' || name, ' | ' ORDER BY id) FROM system_menu WHERE deleted = 0 AND id IN (114, 116)), '无')
UNION ALL SELECT '菜单总数', (SELECT count(*)::text FROM system_menu WHERE deleted = 0);

COMMIT;