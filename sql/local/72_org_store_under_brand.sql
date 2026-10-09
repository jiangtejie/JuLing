-- ============================================================================
-- 72 组织架构：让门店挂在品牌节点下，清掉「门店」这个空的中间层
--
-- 来源：docs/organization-architecture-design.md §9.1 的两个复核发现。
--
-- 【问题一】门店不挂在品牌下 —— 品牌维度只存在于店名里，不在结构里。
--   实测 13 家门店全部挂在 `120 直营门店` 下，而 120 与品牌节点（119 萍姐 / 122 卤校长）
--   是**兄弟**。于是「卤校长杨家坪店」的组织位置是「亚特 → 直营门店 → 卤校长杨家坪店」，
--   **看不出它属于 122 卤校长品牌**，只能从店名猜。
--   任何「按品牌看门店 / 按品牌分权 / 按品牌出报表」都只能靠字符串匹配店名（脆弱且必然出错）。
--
-- 【问题二】`120 直营门店` 是个不准确的第二权威。
--   §7 决策① 定的是「店型以 erp_customer.store_type 为唯一权威，system_dept 不存店型」，
--   但这个**按店型命名的分组节点**把决策架空了一半：实测它下面挂着 6 家 store_type=FRANCHISE
--   的加盟店。（节点名已在 66 号脚本改为「门店」，但结构问题还在。）
--
-- 【目标层级】门店**直接挂在其品牌节点下**：
--   100 重庆亚特餐饮发展有限公司
--   ├─ 119 萍姐                 ← 品牌，门店直接挂这里
--   ├─ 121 中心库
--   └─ 122 卤校长               ← 品牌，门店直接挂这里
--   于是「卤校长杨家坪店」= 亚特 → 卤校长 → 卤校长杨家坪店，**品牌在结构里**。
--
-- 【本脚本做什么】软删空的 `120 门店` 节点（deleted=1，可逆）。
--   **带守卫**：只有「0 个子节点 且 0 个客户档案引用它」时才删；否则什么都不做并报出原因。
--   所以即使以后有人往它下面挂了门店，重跑本脚本也不会误删。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

DO $$ DECLARE child_cnt int; cust_cnt int; BEGIN SELECT count(*) INTO child_cnt FROM system_dept WHERE parent_id = 120 AND deleted = 0; SELECT count(*) INTO cust_cnt FROM erp_customer WHERE dept_id = 120 AND deleted = 0; IF child_cnt = 0 AND cust_cnt = 0 THEN UPDATE system_dept SET deleted = 1, updater = 'script72', update_time = now() WHERE id = 120 AND deleted = 0; ELSE RAISE NOTICE '跳过：120 门店 下面还有 % 个子节点、被 % 个客户档案引用', child_cnt, cust_cnt; END IF; END $$;

SELECT '120 门店 状态' AS item,
       COALESCE((SELECT CASE WHEN deleted = 0 THEN '在营（未删）' ELSE '已软删（可逆）' END
                   FROM system_dept WHERE id = 120), '不存在') AS value
UNION ALL SELECT '120 的子节点数',
       (SELECT count(*)::text FROM system_dept WHERE parent_id = 120 AND deleted = 0)
UNION ALL SELECT '引用 120 的客户档案数',
       (SELECT count(*)::text FROM erp_customer WHERE dept_id = 120 AND deleted = 0)
UNION ALL SELECT '公司下的在营节点',
       COALESCE((SELECT string_agg(id || ':' || name, ' | ' ORDER BY sort, id)
                   FROM system_dept WHERE parent_id = 100 AND deleted = 0), '无')
UNION ALL SELECT '门店节点数（应为 0，等有真实门店时直接挂品牌下）',
       (SELECT count(*)::text FROM system_dept WHERE deleted = 0 AND dept_type = 'STORE');

COMMIT;
