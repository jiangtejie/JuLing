-- ============================================================================
-- 61 下线「表单构建」「API 接口」「数据源配置」
--
-- 承接 60 号脚本：这三个是「基础设施」直属的开发期工具，本项目用不到（用户明确要求一并删除）。
--   前端页面与后端代码已随本次提交删除；本脚本清数据库侧遗留。
--
-- 删除范围：
--   114 表单构建（infra/build）
--   116 API 接口（infra/swagger）
--   1255 数据源配置 + 按钮 1256-1260
--   表 infra_data_source_config（实测 0 行）+ 序列
--
-- 连带说明：DatabaseTableService 在 60 号脚本删掉 CodegenService 后即成孤儿（它唯一的消费者），
--   本次一并删除。DataSourceConfigService 经核查**没有框架层引用**（framework/datasource 不碰它，
--   运行时的动态数据源由 application.yaml 的 spring.datasource.dynamic 配置），故可安全删除。
--
-- **保留**：components/form-create 组件库 —— 它被 BPM 的流程表单设计器与实例渲染共用
--   （18 个文件引用），表单构建页面只是它的消费者之一。
--
-- 安全：菜单与授权备份到 bak_infra_devtools_20261007，可回退。
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

-- 1) 备份（连带任何挂在这三个菜单下的未知子菜单）
CREATE SCHEMA IF NOT EXISTS bak_infra_devtools_20261007;
CREATE TABLE IF NOT EXISTS bak_infra_devtools_20261007.system_menu AS SELECT * FROM system_menu WHERE id IN (114, 116, 1255, 1256, 1257, 1258, 1259, 1260) OR parent_id IN (114, 116, 1255, 1256, 1257, 1258, 1259, 1260);
CREATE TABLE IF NOT EXISTS bak_infra_devtools_20261007.system_role_menu AS SELECT * FROM system_role_menu WHERE menu_id IN (SELECT id FROM system_menu WHERE id IN (114, 116, 1255, 1256, 1257, 1258, 1259, 1260) OR parent_id IN (114, 116, 1255, 1256, 1257, 1258, 1259, 1260));

-- 2) 删菜单与角色授权
DELETE FROM system_role_menu WHERE menu_id IN (SELECT id FROM system_menu WHERE id IN (114, 116, 1255, 1256, 1257, 1258, 1259, 1260) OR parent_id IN (114, 116, 1255, 1256, 1257, 1258, 1259, 1260));
DELETE FROM system_menu WHERE id IN (114, 116, 1255, 1256, 1257, 1258, 1259, 1260) OR parent_id IN (114, 116, 1255, 1256, 1257, 1258, 1259, 1260);

-- 3) 删数据源配置表与序列
DROP TABLE IF EXISTS infra_data_source_config;
DROP SEQUENCE IF EXISTS infra_data_source_config_seq;

-- 4) 自检
SELECT '被删菜单残留（应为 0）' AS item, count(*)::text AS value FROM system_menu WHERE id IN (114, 116, 1255, 1256, 1257, 1258, 1259, 1260) OR parent_id IN (114, 116, 1255, 1256, 1257, 1258, 1259, 1260)
UNION ALL SELECT 'infra_data_source_config 残留（应为 0）', count(*)::text FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'infra_data_source_config'
UNION ALL SELECT '基础设施菜单现状', COALESCE((SELECT string_agg(m.name, ' | ' ORDER BY m.sort, m.id) FROM system_menu m WHERE m.deleted = 0 AND m.parent_id = 2), '无')
UNION ALL SELECT '菜单总数（deleted = 0）', (SELECT count(*)::text FROM system_menu WHERE deleted = 0);

COMMIT;