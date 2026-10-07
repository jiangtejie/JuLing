-- ============================================================================
-- 53 订货账号「授权门店」：建 member_user_store + 从客户树回填
--
-- 背景（2026-10）：订货账号今天靠「绑定一个客户主体」+ 从客户树推导来回答
--   「能给哪些门店下单」——member_user.customer_id 指向的客户若有下级子客户，就当代理人账号，
--   授权门店 = 全部子客户；否则就是门店账号，只能给自己下单。
--   这个推导有三个问题（详见 docs/ordering-account-authorization-design.md §2）：
--     · 「代理」这个概念在业务上并不存在（代理人只是帮忙下单，不承担账期与结算）；
--     · 授权关系不能独立配置（改授权就得改客户主数据，而客户档案上挂着账期/信用/结算）；
--     · 「代理本身不能下单」是推断规则而不是数据约束。
--
-- 本脚本只做「加」的部分，**不动任何旧字段**，因此可回退：
--   1) 建 member_user_store（账号 → 可下单门店，多对多 + 默认门店）；
--   2) 回填：主体客户有下级 → 授权其全部下级；无下级 → 授权自身；
--   3) 每个账号挑一个默认门店；
--   4) 唯一性约束：同一账号对同一门店只有一条有效授权；一个账号只有一个默认门店。
--
-- 删列在 54 号脚本，等代码切换并验证后再跑。
-- 幂等：可重复执行（CREATE ... IF NOT EXISTS + 按 NOT EXISTS 补插，不删任何既有授权）。
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. 建表
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS member_user_store (
    id          bigint      NOT NULL,
    user_id     bigint      NOT NULL,
    customer_id bigint      NOT NULL,
    is_default  boolean     NOT NULL DEFAULT false,
    sort        integer     NOT NULL DEFAULT 0,
    status      smallint    NOT NULL DEFAULT 0,
    tenant_id   bigint      NOT NULL DEFAULT 0,
    creator     varchar(64) DEFAULT '',
    create_time timestamp   NOT NULL DEFAULT now(),
    updater     varchar(64) DEFAULT '',
    update_time timestamp   NOT NULL DEFAULT now(),
    deleted     smallint    NOT NULL DEFAULT 0,
    CONSTRAINT pk_member_user_store PRIMARY KEY (id)
);
COMMENT ON TABLE  member_user_store             IS '订货账号授权门店：账号可给哪些门店下单（加盟店账号一条，片区订货管理人多条）';
COMMENT ON COLUMN member_user_store.user_id     IS '订货账号编号（member_user.id）';
COMMENT ON COLUMN member_user_store.customer_id IS '被授权门店（erp_customer.id；必须是组织架构里的门店节点，且未闭店）';
COMMENT ON COLUMN member_user_store.is_default  IS '账号默认门店：H5 首次进入用它，用户手动切换后以本地记忆为准';
COMMENT ON COLUMN member_user_store.status      IS '状态：0 启用 / 1 停用';

-- 同一账号对同一门店只允许一条有效授权
CREATE UNIQUE INDEX IF NOT EXISTS uk_member_user_store_user_customer
    ON member_user_store (user_id, customer_id) WHERE deleted = 0;
-- 一个账号只允许一个默认门店
CREATE UNIQUE INDEX IF NOT EXISTS uk_member_user_store_user_default
    ON member_user_store (user_id) WHERE deleted = 0 AND is_default = true;
CREATE INDEX IF NOT EXISTS idx_member_user_store_user
    ON member_user_store (user_id) WHERE deleted = 0;

-- ---------------------------------------------------------------------------
-- 2. 序列
-- ---------------------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS member_user_store_seq;
SELECT setval('member_user_store_seq', COALESCE((SELECT max(id) FROM member_user_store), 0) + 1, false);

-- ---------------------------------------------------------------------------
-- 3. 回填：从 member_user.customer_id 的客户树推导
--    主体客户有下级 → 授权其全部下级（代理账号）；无下级 → 授权自身（门店账号）。
--    已删除的账号不参与回填。
-- ---------------------------------------------------------------------------
WITH src AS (
    SELECT u.id AS user_id, u.customer_id AS owner_customer_id, u.tenant_id
    FROM member_user u
    WHERE u.deleted = 0 AND u.customer_id IS NOT NULL
), grants AS (
    SELECT s.user_id, s.owner_customer_id, COALESCE(c.id, s.owner_customer_id) AS customer_id, s.tenant_id
    FROM src s
    LEFT JOIN erp_customer c
           ON c.deleted = 0 AND c.parent_customer_id = s.owner_customer_id
)
INSERT INTO member_user_store (id, user_id, customer_id, is_default, sort, status,
                               tenant_id, creator, create_time, updater, update_time, deleted)
SELECT nextval('member_user_store_seq'), g.user_id, g.customer_id, false,
       row_number() OVER (PARTITION BY g.user_id
                          ORDER BY (g.customer_id = g.owner_customer_id) DESC, g.customer_id)::int,
       0, g.tenant_id, 'script53', now(), 'script53', now(), 0
FROM grants g
WHERE NOT EXISTS (SELECT 1 FROM member_user_store x
                   WHERE x.deleted = 0 AND x.user_id = g.user_id AND x.customer_id = g.customer_id);

-- ---------------------------------------------------------------------------
-- 4. 默认门店：优先账号自己的主体门店，否则取 sort 最小的那条
-- ---------------------------------------------------------------------------
UPDATE member_user_store s
SET is_default = true, updater = 'script53', update_time = now()
WHERE s.deleted = 0 AND s.is_default = false
  AND NOT EXISTS (SELECT 1 FROM member_user_store o
                   WHERE o.deleted = 0 AND o.user_id = s.user_id AND o.is_default = true)
  AND NOT EXISTS (SELECT 1 FROM member_user_store o
                   WHERE o.deleted = 0 AND o.user_id = s.user_id
                     AND (o.sort < s.sort OR (o.sort = s.sort AND o.id < s.id)));

-- ---------------------------------------------------------------------------
-- 5. 演示数据的授权门店
--    29 号脚本先于本脚本执行，且新模型下授权在 member_user_store（本脚本才建），
--    所以演示账号的授权在这里补。按手机号匹配，缺失即跳过（生产库没有这些账号）。
-- ---------------------------------------------------------------------------
-- 单门店账号：各授权一家
INSERT INTO member_user_store (id, user_id, customer_id, is_default, sort, status,
                               tenant_id, creator, create_time, updater, update_time, deleted)
SELECT nextval('member_user_store_seq'), u.id, c.id, true, 0, 0,
       u.tenant_id, 'script53', now(), 'script53', now(), 0
FROM member_user u
JOIN erp_customer c ON c.deleted = 0 AND c.tenant_id = 1
 AND c.name = CASE u.mobile WHEN '19000000101' THEN '耙二哥双碑店（门店）'
                            WHEN '19000000102' THEN '卤校长杨家坪店（门店）'
                            ELSE '成都杨老头（门店）' END
WHERE u.deleted = 0 AND u.mobile IN ('19000000101', '19000000102', '19000000103')
  AND NOT EXISTS (SELECT 1 FROM member_user_store x
                   WHERE x.deleted = 0 AND x.user_id = u.id AND x.customer_id = c.id);

-- 片区订货管理人：一个账号授权 3 家门店，默认「成都杨老头」
INSERT INTO member_user_store (id, user_id, customer_id, is_default, sort, status,
                               tenant_id, creator, create_time, updater, update_time, deleted)
SELECT nextval('member_user_store_seq'), u.id, c.id,
       (c.name = '成都杨老头（门店）'),
       (row_number() OVER (ORDER BY c.id))::int - 1, 0,
       u.tenant_id, 'script53', now(), 'script53', now(), 0
FROM member_user u
JOIN erp_customer c ON c.deleted = 0 AND c.tenant_id = 1
 AND c.name IN ('成都杨老头（门店）', '萍姐成都（门店）', '卤校长广州店（门店）')
WHERE u.deleted = 0 AND u.mobile = '19000000109'
  AND NOT EXISTS (SELECT 1 FROM member_user_store x
                   WHERE x.deleted = 0 AND x.user_id = u.id AND x.customer_id = c.id);

-- ---------------------------------------------------------------------------
-- 6. 自检
-- ---------------------------------------------------------------------------
SELECT setval('member_user_store_seq', COALESCE((SELECT max(id) FROM member_user_store), 0) + 1, false);

SELECT '授权行数' AS item, (SELECT count(*)::text FROM member_user_store WHERE deleted = 0) AS value
UNION ALL SELECT '有授权的账号数', (SELECT count(DISTINCT user_id)::text FROM member_user_store WHERE deleted = 0)
UNION ALL SELECT '待回填账号数（未授权，应为 0）',
       (SELECT count(*)::text FROM member_user WHERE deleted = 0 AND customer_id IS NOT NULL
          AND id NOT IN (SELECT user_id FROM member_user_store WHERE deleted = 0))
UNION ALL SELECT '多门店账号数（片区订货管理人）',
       (SELECT count(*)::text FROM (SELECT user_id FROM member_user_store WHERE deleted = 0
                                     GROUP BY user_id HAVING count(*) > 1) t)
UNION ALL SELECT '无默认门店的账号数（应为 0）',
       (SELECT count(*)::text FROM (SELECT user_id FROM member_user_store WHERE deleted = 0
                                     GROUP BY user_id
                                    HAVING count(*) FILTER (WHERE is_default) <> 1) t);

COMMIT;
