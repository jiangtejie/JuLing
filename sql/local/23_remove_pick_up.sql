-- ============================================================================
-- 门店自提（自提门店 / 订单核销）整体下线
--
-- 背景：亚特的订单全部走快递发货，不做门店自提。后端（自提门店 Service/Controller/DO/Mapper、
--       订单核销接口与实现、下单时的自提分支、运费计算的自提分支、商品级「配送方式」字段、
--       交易配置的自提开关、统计的「待核销」计数、DeliveryTypeEnum.PICK_UP 与相关错误码）
--       与前端（vben 三个模板、admin-uniapp 的自提门店/核销页面与配置项）均已删除。
--       本脚本把数据库层残留**物理删除**。
--
-- 说明：
--   1. 订单的 delivery_type 字段与 trade_delivery_type 字典类型**保留**：订单列表/详情仍要展示
--      「快递发货」，发货判断也用它；只删除字典里的「用户自提」数据行。
--   2. 执行前已确认无数据可丢：trade_order 中 0 条自提订单（pick_up_store_id / pick_up_verify_code
--      全空）；trade_delivery_pick_up_store 仅 1 行演示门店，删除前已导出备份。
--   3. 幂等（IF EXISTS / LIKE 条件），可重复执行。
--   4. 回滚：代码侧 git revert 对应提交；数据库侧需重建表与列（本脚本不含），演示门店数据需从备份恢复。
-- ============================================================================

-- 1) 自提菜单与角色关联（门店自提 / 门店管理 / 核销订单 / 自提门店增删改查导出 / 订单核销）
DELETE FROM system_role_menu
WHERE menu_id IN (SELECT id FROM system_menu
                  WHERE permission LIKE 'trade:delivery:pick-up-store%'
                     OR permission = 'trade:order:pick-up'
                     OR component LIKE '%pickUpStore%'
                     OR component LIKE '%pickUpOrder%'
                     OR name IN ('门店自提', '门店管理', '核销订单'));
DELETE FROM system_menu
WHERE permission LIKE 'trade:delivery:pick-up-store%'
   OR permission = 'trade:order:pick-up'
   OR component LIKE '%pickUpStore%'
   OR component LIKE '%pickUpOrder%'
   OR name IN ('门店自提', '门店管理', '核销订单');

-- 2) 配送方式字典里的「用户自提」（保留字典类型与「快递发货」）
DELETE FROM system_dict_data WHERE dict_type = 'trade_delivery_type' AND value = '2';

-- 3) 自提门店表物理删除（含核销员绑定 verify_user_ids）
DROP TABLE IF EXISTS trade_delivery_pick_up_store;

-- 4) 自提相关列物理删除
ALTER TABLE trade_config DROP COLUMN IF EXISTS delivery_pick_up_enabled;
ALTER TABLE trade_order  DROP COLUMN IF EXISTS pick_up_store_id;
ALTER TABLE trade_order  DROP COLUMN IF EXISTS pick_up_verify_code;
ALTER TABLE product_spu  DROP COLUMN IF EXISTS delivery_types;

-- 5) 校验：以下查询应全部返回 0 行
-- SELECT count(*) FROM system_menu WHERE permission LIKE 'trade:delivery:pick-up-store%' OR permission = 'trade:order:pick-up';
-- SELECT count(*) FROM system_dict_data WHERE dict_type = 'trade_delivery_type' AND value = '2';
-- SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name LIKE '%pick%';
-- SELECT table_name, column_name FROM information_schema.columns WHERE table_schema='public' AND (column_name LIKE '%pick%' OR column_name = 'delivery_types');
