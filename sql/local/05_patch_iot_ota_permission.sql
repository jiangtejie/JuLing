-- 补丁:IoT「OTA 任务进度查询」按钮权限
-- 背景:基线脚本把该按钮的 permission 误写成 iot:ota-task:create(与"创建"重复),
--       缺少 iot:ota-task:query,导致拥有查询权限的角色在 IoT OTA 页面点击查询会 403。
-- 幂等:重复执行不会造成冲突

INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name, status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
VALUES (12000, 'OTA 任务进度查询', 'iot:ota-task:query', 3, 6, 5032, '', '', '', '', 0, TRUE, TRUE, FALSE, '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;
