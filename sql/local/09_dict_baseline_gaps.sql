-- 补齐"代码引用但基线 SQL 未提供"的字典（幂等，ON CONFLICT DO NOTHING）
--
-- 背景：以下字典在代码里被 @DictFormat / @ExcelColumnSelect 引用，但基线 sql 脚本
-- 均无种子数据，导致：HRM 员工导入模板下载 500（下拉区间变成 字典sheet!$F$1:$F$0）、
-- MES 编码规则相关下拉为空。取值以对应 Java 枚举为准（注释里标注枚举类）。
--
-- id 段：字典类型 11100+，字典数据 111000+（与本项目已有 9000/9500/11000、90000/95000 段不冲突）

-- 1. 证件类型（HrmEmployeeIdTypeEnum）
INSERT INTO system_dict_type (id, name, type, status, remark, creator, create_time, updater, update_time, deleted) VALUES
 (11100, '证件类型', 'hrm_employee_id_type', 0, 'HRM 员工证件类型', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

INSERT INTO system_dict_data (id, sort, label, value, dict_type, status, color_type, css_class, remark, creator, create_time, updater, update_time, deleted) VALUES
 (111000, 1, '身份证',     '1', 'hrm_employee_id_type', 0, 'default', '', '', '1', now(), '1', now(), 0),
 (111001, 2, '港澳通行证', '2', 'hrm_employee_id_type', 0, 'default', '', '', '1', now(), '1', now(), 0),
 (111002, 3, '台湾通行证', '3', 'hrm_employee_id_type', 0, 'default', '', '', '1', now(), '1', now(), 0),
 (111003, 4, '护照',       '4', 'hrm_employee_id_type', 0, 'default', '', '', '1', now(), '1', now(), 0),
 (111004, 5, '其他',       '5', 'hrm_employee_id_type', 0, 'default', '', '', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- 2. MES 编码规则 - 循环方式（MesMdAutoCodeCycleMethodEnum）
INSERT INTO system_dict_type (id, name, type, status, remark, creator, create_time, updater, update_time, deleted) VALUES
 (11110, 'MES 编码循环方式', 'mes_auto_code_cycle_method', 0, 'MES 编码规则循环方式', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

INSERT INTO system_dict_data (id, sort, label, value, dict_type, status, color_type, css_class, remark, creator, create_time, updater, update_time, deleted) VALUES
 (111010, 1, '按年',       '1',  'mes_auto_code_cycle_method', 0, 'default', '', '', '1', now(), '1', now(), 0),
 (111011, 2, '按月',       '2',  'mes_auto_code_cycle_method', 0, 'default', '', '', '1', now(), '1', now(), 0),
 (111012, 3, '按天',       '3',  'mes_auto_code_cycle_method', 0, 'default', '', '', '1', now(), '1', now(), 0),
 (111013, 4, '按小时',     '4',  'mes_auto_code_cycle_method', 0, 'default', '', '', '1', now(), '1', now(), 0),
 (111014, 5, '按分钟',     '5',  'mes_auto_code_cycle_method', 0, 'default', '', '', '1', now(), '1', now(), 0),
 (111015, 10, '按传入字符', '10', 'mes_auto_code_cycle_method', 0, 'default', '', '', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- 3. MES 编码规则 - 补位方式（MesMdAutoCodePaddedMethodEnum）
INSERT INTO system_dict_type (id, name, type, status, remark, creator, create_time, updater, update_time, deleted) VALUES
 (11120, 'MES 编码补位方式', 'mes_auto_code_padded_method', 0, 'MES 编码规则补位方式', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

INSERT INTO system_dict_data (id, sort, label, value, dict_type, status, color_type, css_class, remark, creator, create_time, updater, update_time, deleted) VALUES
 (111020, 1, '左补齐', '1', 'mes_auto_code_padded_method', 0, 'default', '', '', '1', now(), '1', now(), 0),
 (111021, 2, '右补齐', '2', 'mes_auto_code_padded_method', 0, 'default', '', '', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- 4. MES 编码规则 - 段类型（MesMdAutoCodePartTypeEnum）
INSERT INTO system_dict_type (id, name, type, status, remark, creator, create_time, updater, update_time, deleted) VALUES
 (11130, 'MES 编码段类型', 'mes_auto_code_part_type', 0, 'MES 编码规则段类型', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

INSERT INTO system_dict_data (id, sort, label, value, dict_type, status, color_type, css_class, remark, creator, create_time, updater, update_time, deleted) VALUES
 (111030, 1, '输入字符', '1', 'mes_auto_code_part_type', 0, 'default', '', '', '1', now(), '1', now(), 0),
 (111031, 2, '当前日期', '2', 'mes_auto_code_part_type', 0, 'default', '', '', '1', now(), '1', now(), 0),
 (111032, 3, '固定字符', '3', 'mes_auto_code_part_type', 0, 'default', '', '', '1', now(), '1', now(), 0),
 (111033, 4, '流水号',   '4', 'mes_auto_code_part_type', 0, 'default', '', '', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

\echo '--- 校验 ---'
SELECT t.type, t.name, count(d.id) AS data_rows
  FROM system_dict_type t
  LEFT JOIN system_dict_data d ON d.dict_type = t.type AND d.deleted = 0
 WHERE t.type IN ('hrm_employee_id_type', 'mes_auto_code_cycle_method',
                  'mes_auto_code_padded_method', 'mes_auto_code_part_type')
 GROUP BY t.type, t.name ORDER BY t.type;
