-- =============================================================================
-- P0 模拟测试数据（可重复执行，全部带 'demo-seed' 标记，便于清理）
--
-- 内容：
--   A) 组织树对齐组织架构图：恢复根节点「重庆亚特餐饮发展有限公司」(id 100) 并把
--      萍姐/直营门店/中心库/卤校长 四个品牌分支(119-122) 挂到它下面
--   B) 主数据：计量单位、商品分类、16 个餐饮食材商品（含规格/保质期/进价/售价/最低价）
--   C) 供应商 3 家（含税号/税率/开户行）
--   D) 门店客户 13 家（按组织树 134-146，直营/加盟混合）+ 1 个代理客户（挂 3 家门店）
--   E) 订货账号 4 个（3 个门店账号 + 1 个代理账号，手机号 190000001xx）
--   F) 仓库：中心库 + 门店虚拟仓样本；中心库期初库存
--   G) 商城商品：为前 10 个商品建 SPU/SKU（价格由元转分），使 H5 订货可下单
--   H) 核对查询
--
-- 说明：批次/效期与门店仓库存属于 S2（库存中心）范围，本脚本只造当前结构支持的数据。
-- 执行：psql -U root -d yate -f sql/local/29_seed_demo_data.sql
-- 清理：脚本开头会先删除带 demo-seed 标记的旧数据（幂等）
-- =============================================================================

-- ---------- A) 组织树对齐 ----------
UPDATE system_dept SET deleted = 0, updater = '1', update_time = now() WHERE tenant_id = 1 AND id = 100;
UPDATE system_dept SET parent_id = 100, deleted = 0, updater = '1', update_time = now()
 WHERE tenant_id = 1 AND id IN (119, 120, 121, 122);

-- ---------- 幂等清理 ----------
DELETE FROM product_sku WHERE spu_id IN (SELECT id FROM product_spu WHERE keyword = 'demo-seed');
DELETE FROM product_spu WHERE keyword = 'demo-seed';
DELETE FROM erp_stock   WHERE product_id IN (SELECT id FROM erp_product WHERE remark = 'demo-seed');
DELETE FROM erp_stock   WHERE warehouse_id IN (SELECT id FROM erp_warehouse WHERE remark = 'demo-seed');
DELETE FROM erp_product WHERE remark = 'demo-seed';
DELETE FROM erp_customer WHERE remark = 'demo-seed';
DELETE FROM erp_supplier WHERE remark = 'demo-seed';
DELETE FROM erp_warehouse WHERE remark = 'demo-seed';
DELETE FROM member_user WHERE mobile LIKE '190000001%';
DELETE FROM system_oauth2_access_token WHERE user_id IN (SELECT id FROM member_user WHERE mobile LIKE '190000001%');

-- ---------- B) 单位与分类 ----------
INSERT INTO erp_product_unit (id, name, status, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT (SELECT COALESCE(MAX(id),0) FROM erp_product_unit) + row_number() OVER (), u.name, 0, '1', now(), '1', now(), 0, 1
FROM (VALUES ('斤'), ('公斤'), ('箱'), ('袋'), ('瓶'), ('桶')) AS u(name)
WHERE NOT EXISTS (SELECT 1 FROM erp_product_unit p WHERE p.name = u.name AND p.tenant_id = 1 AND p.deleted = 0);

INSERT INTO erp_product_category (id, name, parent_id, sort, status, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT (SELECT COALESCE(MAX(id),0) FROM erp_product_category) + row_number() OVER (), c.name, 0, 10, 0, '1', now(), '1', now(), 0, 1
FROM (VALUES ('素菜类'), ('冻品类'), ('调味品类'), ('酒水饮料'), ('一次性用品')) AS c(name)
WHERE NOT EXISTS (SELECT 1 FROM erp_product_category p WHERE p.name = c.name AND p.tenant_id = 1 AND p.deleted = 0);
-- ---------- B2) 餐饮食材商品（18 个，含规格/保质期/进价/售价/最低价）----------
INSERT INTO erp_product (id, name, bar_code, category_id, unit_id, status, standard, remark, expiry_day, weight,
                         purchase_price, sale_price, min_price, tenant_id, creator, create_time, updater, update_time, deleted)
SELECT (SELECT COALESCE(MAX(id),0) FROM erp_product) + row_number() OVER (ORDER BY v.name),
       v.name, 'DS' || lpad((row_number() OVER (ORDER BY v.name))::text, 4, '0'),
       (SELECT c.id FROM erp_product_category c WHERE c.name = v.cat AND c.tenant_id = 1 AND c.deleted = 0 LIMIT 1),
       (SELECT u.id FROM erp_product_unit u WHERE u.name = v.unit AND u.tenant_id = 1 AND u.deleted = 0 LIMIT 1),
       0, v.standard, 'demo-seed', v.expiry, 0, v.purchase, v.sale, v.min_price, 1, '1', now(), '1', now(), 0
FROM (VALUES
    ('鲜毛肚',     '荤菜类',   '斤', '净重 500g/份', 3,   38.00, 52.00, 45.00),
    ('鸭肠',       '荤菜类',   '斤', '净重 500g/份', 3,   22.00, 30.00, 28.00),
    ('肥牛卷',     '冻品类',   '斤', '2.5kg/袋',     180, 35.00, 48.00, 45.00),
    ('鲜牛肉',     '荤菜类',   '斤', '冷鲜',         3,   42.00, 55.00, 50.00),
    ('猪黄喉',     '荤菜类',   '斤', '净重 500g/份', 3,   28.00, 38.00, 35.00),
    ('午餐肉',     '冻品类',   '箱', '24 罐/箱',     365, 85.00, 110.00, 100.00),
    ('藕片',       '素菜类',   '斤', '净菜',         7,    4.00,  6.00,  5.50),
    ('青笋',       '素菜类',   '斤', '净菜',         5,    3.00,  4.50,  4.00),
    ('豆皮',       '素菜类',   '斤', '干制',         10,   5.00,  7.00,  6.50),
    ('金针菇',     '素菜类',   '袋', '200g/袋',      15,   3.50,  5.00,  4.50),
    ('虾滑',       '冻品类',   '袋', '500g/袋',      180, 18.00, 26.00, 24.00),
    ('蟹柳',       '冻品类',   '袋', '500g/袋',      180,  9.00, 14.00, 12.00),
    ('速冻丸子',   '冻品类',   '袋', '500g/袋',      180, 12.00, 18.00, 16.00),
    ('牛油火锅底料', '调味品类', '袋', '500g/袋',    365, 28.00, 38.00, 35.00),
    ('香油',       '调味品类', '瓶', '5L/瓶',        540, 15.00, 22.00, 20.00),
    ('豆瓣酱',     '调味品类', '桶', '5kg/桶',       365, 45.00, 60.00, 55.00),
    ('山城啤酒',   '酒水饮料', '箱', '24 瓶/箱',     270, 48.00, 68.00, 65.00),
    ('唯怡豆奶',   '酒水饮料', '箱', '12 瓶/箱',     180, 52.00, 72.00, 68.00),
    ('打包盒',     '一次性用品', '箱', '300 个/箱',  0,   35.00, 45.00, 42.00),
    ('餐巾纸',     '一次性用品', '箱', '20 提/箱',   0,   60.00, 80.00, 75.00)
) AS v(name, cat, unit, standard, expiry, purchase, sale, min_price);

-- ---------- C) 供应商 ----------
INSERT INTO erp_supplier (id, name, contact, mobile, telephone, email, fax, remark, status, sort, tax_no, tax_percent, bank_name, bank_account, bank_address, tenant_id, creator, create_time, updater, update_time, deleted)
SELECT (SELECT COALESCE(MAX(id),0) FROM erp_supplier) + row_number() OVER (),
       v.name, v.contact, v.mobile, v.mobile, '', '', 'demo-seed', 0, 10, v.tax_no, v.tax, v.bank, v.acct, v.addr, 1, '1', now(), '1', now(), 0
FROM (VALUES
    ('重庆鲜丰蔬菜配送有限公司', '王菜农', '13800000001', '91500101MA5U00001X', 9,  '中国农业银行重庆分行', '310001010000001', '重庆市江北区'),
    ('成都蜀香调味品有限公司',   '李调味', '13800000002', '91510101MA5U00002Y', 13, '中国银行成都分行',     '310001010000002', '成都市武侯区'),
    ('重庆冻品汇供应链有限公司', '张冻品', '13800000003', '91500101MA5U00003Z', 9,  '招商银行重庆分行',     '310001010000003', '重庆市渝北区')
) AS v(name, contact, mobile, tax_no, tax, bank, acct, addr);

-- ---------- D) 门店客户（13 家，直营/加盟混合）+ 1 个代理 ----------
INSERT INTO erp_customer (id, name, contact, mobile, telephone, email, fax, remark, status, sort, tax_no, tax_percent, bank_name, bank_account, bank_address, dept_id, parent_customer_id, store_type, settlement_mode, credit_days, credit_limit, tenant_id, creator, create_time, updater, update_time, deleted)
SELECT (SELECT COALESCE(MAX(id),0) FROM erp_customer) + row_number() OVER (),
       d.name || '（门店）', d.name || '店长', '1390000' || lpad((1000 + row_number() OVER ())::text, 4, '0'), '', '', '', 'demo-seed', 0, 10,
       '', 0, '', '', '', d.id, NULL, v.store_type, 'PREPAID', NULL, NULL, 1, '1', now(), '1', now(), 0
FROM (VALUES
    (134, 'DIRECT'), (135, 'DIRECT'), (136, 'DIRECT'), (137, 'FRANCHISE'),
    (138, 'FRANCHISE'), (139, 'DIRECT'), (140, 'DIRECT'), (141, 'FRANCHISE'),
    (142, 'DIRECT'), (143, 'FRANCHISE'), (144, 'DIRECT'), (145, 'DIRECT'), (146, 'FRANCHISE')
) AS v(dept_id, store_type)
JOIN system_dept d ON d.id = v.dept_id AND d.tenant_id = 1 AND d.deleted = 0;

-- 代理客户（挂在「直营门店」分支下，代表一个加盟商名下 3 家门店）
INSERT INTO erp_customer (id, name, contact, mobile, telephone, email, fax, remark, status, sort, tax_no, tax_percent, bank_name, bank_account, bank_address, dept_id, parent_customer_id, store_type, settlement_mode, credit_days, credit_limit, tenant_id, creator, create_time, updater, update_time, deleted)
VALUES ((SELECT COALESCE(MAX(id),0)+1 FROM erp_customer), '成都杨老头餐饮管理有限公司（代理）', '杨代理', '13900001000', '', '', '', 'demo-seed', 0, 10, '', 0, '', '', '', 144, NULL, 'FRANCHISE', 'PREPAID', NULL, NULL, 1, '1', now(), '1', now(), 0);

-- 把 3 家门店挂到代理名下（模拟"一个代理多门店"）
UPDATE erp_customer SET parent_customer_id = (SELECT id FROM erp_customer WHERE remark = 'demo-seed' AND name LIKE '%（代理）%' LIMIT 1)
 WHERE remark = 'demo-seed' AND tenant_id = 1 AND name NOT LIKE '%（代理）%'
   AND dept_id IN (SELECT d.id FROM system_dept d WHERE d.name IN ('成都杨老头', '萍姐成都', '卤校长广州店'));

-- ---------- E) 订货账号 ----------
-- 3 个门店账号（分别绑直营店/加盟店/代理名下门店）+ 1 个代理账号
INSERT INTO member_user (id, mobile, password, status, nickname, dept_id, customer_id, point, experience, tenant_id, creator, create_time, updater, update_time, deleted)
SELECT (SELECT COALESCE(MAX(id),0) FROM member_user) + row_number() OVER (),
       v.mobile, '', 0, v.nickname,
       c.dept_id, c.id, 0, 0, 1, '1', now(), '1', now(), 0
FROM (VALUES
    ('19000000101', '订货账号-耙二哥双碑店(直营)'),
    ('19000000102', '订货账号-卤校长杨家坪店(加盟)'),
    ('19000000103', '订货账号-成都杨老头(代理名下)')
) AS v(mobile, nickname)
JOIN erp_customer c ON c.remark = 'demo-seed' AND c.tenant_id = 1
 AND c.name = CASE v.mobile WHEN '19000000101' THEN '耙二哥双碑店（门店）'
                            WHEN '19000000102' THEN '卤校长杨家坪店（门店）'
                            ELSE '成都杨老头（门店）' END;

-- 代理账号：绑定代理客户（可切换名下门店下单）
INSERT INTO member_user (id, mobile, password, status, nickname, dept_id, customer_id, point, experience, tenant_id, creator, create_time, updater, update_time, deleted)
VALUES ((SELECT COALESCE(MAX(id),0)+1 FROM member_user), '19000000109', '', 0, '订货账号-杨老头代理(多门店)',
        (SELECT dept_id FROM erp_customer WHERE remark = 'demo-seed' AND name LIKE '%（代理）%' LIMIT 1),
        (SELECT id FROM erp_customer WHERE remark = 'demo-seed' AND name LIKE '%（代理）%' LIMIT 1),
        0, 0, 1, '1', now(), '1', now(), 0);

-- ---------- F) 仓库与期初库存 ----------
INSERT INTO erp_warehouse (id, name, address, sort, remark, principal, warehouse_price, truckage_price, status, default_status, tenant_id, creator, create_time, updater, update_time, deleted)
VALUES ((SELECT COALESCE(MAX(id),0)+1 FROM erp_warehouse), '中心库', '重庆市渝北区中心库', 1, 'demo-seed', '库管员', 0, 0, 0, TRUE, 1, '1', now(), '1', now(), 0),
       ((SELECT COALESCE(MAX(id),0)+2 FROM erp_warehouse), '门店虚拟仓-耙二哥双碑店', '', 2, 'demo-seed', '', 0, 0, 0, FALSE, 1, '1', now(), '1', now(), 0);

INSERT INTO erp_stock (id, product_id, warehouse_id, count, tenant_id, creator, create_time, updater, update_time, deleted)
SELECT (SELECT COALESCE(MAX(id),0) FROM erp_stock) + row_number() OVER (),
       p.id, (SELECT id FROM erp_warehouse WHERE remark = 'demo-seed' AND name = '中心库' LIMIT 1),
       (100 + (p.id * 7) % 400)::numeric, 1, '1', now(), '1', now(), 0
FROM erp_product p WHERE p.remark = 'demo-seed' AND p.tenant_id = 1;

-- ---------- G) 商城商品（前 10 个 demo 商品）----------
DO $$
DECLARE p RECORD; new_spu bigint; new_sku bigint; i int := 0;
BEGIN
  FOR p IN SELECT * FROM erp_product WHERE remark = 'demo-seed' AND tenant_id = 1 ORDER BY id LIMIT 10 LOOP
    i := i + 1;
    SELECT COALESCE(MAX(id),0) + 1 INTO new_spu FROM product_spu;
    INSERT INTO product_spu (id, name, keyword, introduction, description, category_id, brand_id, pic_url, slider_pic_urls, sort, status, spec_type,
                             price, market_price, cost_price, stock, delivery_template_id, give_integral, sub_commission_type, sales_count, virtual_sales_count, browse_count,
                             tenant_id, creator, create_time, updater, update_time, deleted)
    VALUES (new_spu, p.name, 'demo-seed', '', '', (SELECT id FROM product_category WHERE tenant_id = 1 AND deleted = 0 ORDER BY id LIMIT 1), NULL, '', '', i, 1, FALSE,
            ROUND(p.sale_price * 100)::int, ROUND(p.sale_price * 120)::int, ROUND(p.purchase_price * 100)::int, 500, NULL, 0, FALSE, 0, 0, 0,
            1, '1', now(), '1', now(), 0);
    SELECT COALESCE(MAX(id),0) + 1 INTO new_sku FROM product_sku;
    INSERT INTO product_sku (id, spu_id, properties, price, market_price, cost_price, bar_code, pic_url, stock, weight, volume, sales_count,
                             tenant_id, creator, create_time, updater, update_time, deleted)
    VALUES (new_sku, new_spu, '[{"propertyId":0,"propertyName":"默认","valueId":0,"valueName":"默认"}]',
            ROUND(p.sale_price * 100)::int, ROUND(p.sale_price * 120)::int, ROUND(p.purchase_price * 100)::int, p.bar_code, '', 500, 0, 0, 0,
            1, '1', now(), '1', now(), 0);
  END LOOP;
  RAISE NOTICE '商城商品已生成 % 个', i;
END $$;
