-- 补齐「线上库有、基线 sql/postgresql 与 sql/local 没有」的字典（幂等，ON CONFLICT DO NOTHING）
--
-- 背景：以下字典被代码引用或界面需要，但基线脚本未提供，导致全新环境缺字典：
--   system_menu_type     菜单类型（目录/菜单/按钮）
--   system_data_scope    数据范围，RoleRespVO 的数据范围下拉依赖它
--   mes_wm_issue_status  MES 领料单状态
-- 校验方式：python script/tools/check-dict-coverage.py（应输出「缺失 0 个 / 无数据行 0 个」）
--
-- id 段：字典类型 11200+，字典数据 112000+（与 9000/9500/11000/11100、90000/95000/111000 段不冲突）

-- 菜单类型（目录/菜单/按钮）
INSERT INTO system_dict_type (id, name, type, status, remark, creator, create_time, updater, update_time, deleted) VALUES
 (11200, '菜单类型', 'system_menu_type', 0, '菜单类型（基线脚本仅含数据、缺类型行，此处补齐）', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

INSERT INTO system_dict_data (id, sort, label, value, dict_type, status, color_type, css_class, remark, creator, create_time, updater, update_time, deleted) VALUES
 (112000, 1, '目录', '1', 'system_menu_type', 0, '', '', '目录', '1', now(), '1', now(), 0),
 (112001, 2, '菜单', '2', 'system_menu_type', 0, '', '', '菜单', '1', now(), '1', now(), 0),
 (112002, 3, '按钮', '3', 'system_menu_type', 0, '', '', '按钮', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- 数据范围（RoleRespVO 的数据范围下拉）
INSERT INTO system_dict_type (id, name, type, status, remark, creator, create_time, updater, update_time, deleted) VALUES
 (11210, '数据范围', 'system_data_scope', 0, '角色数据范围（基线脚本仅含数据、缺类型行，此处补齐）', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

INSERT INTO system_dict_data (id, sort, label, value, dict_type, status, color_type, css_class, remark, creator, create_time, updater, update_time, deleted) VALUES
 (112010, 1, '全部数据权限', '1', 'system_data_scope', 0, '', '', '全部数据权限', '1', now(), '1', now(), 0),
 (112011, 2, '指定部门数据权限', '2', 'system_data_scope', 0, '', '', '指定部门数据权限', '1', now(), '1', now(), 0),
 (112012, 3, '本部门数据权限', '3', 'system_data_scope', 0, '', '', '本部门数据权限', '1', now(), '1', now(), 0),
 (112013, 4, '本部门及以下数据权限', '4', 'system_data_scope', 0, '', '', '本部门及以下数据权限', '1', now(), '1', now(), 0),
 (112014, 5, '仅本人数据权限', '5', 'system_data_scope', 0, '', '', '仅本人数据权限', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- MES 领料单状态
INSERT INTO system_dict_type (id, name, type, status, remark, creator, create_time, updater, update_time, deleted) VALUES
 (11220, 'MES 发料状态', 'mes_wm_issue_status', 0, 'MES 发料单状态（基线脚本仅含数据、缺类型行，此处补齐）', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

INSERT INTO system_dict_data (id, sort, label, value, dict_type, status, color_type, css_class, remark, creator, create_time, updater, update_time, deleted) VALUES
 (112020, 1, '草稿', '0', 'mes_wm_issue_status', 0, 'info', '', '草稿状态，未完成', '1', now(), '1', now(), 0),
 (112021, 2, '已完成', '4', 'mes_wm_issue_status', 0, 'success', '', '已完成出库', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;
