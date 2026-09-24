-- 补齐支付应用（pay_app），修复商城/订货 H5 提交订单报「App 不存在」
--
-- 现象：
--   POST /app-api/trade/order/create 返回 { code: 1007000000, msg: "App 不存在" }
--
-- 根因（后端数据缺失，与前端无关）：
--   交易订单创建后的后置逻辑，只要 payPrice > 0 就会无条件生成支付单：
--     TradeOrderUpdateServiceImpl.afterCreateTradeOrder
--       -> createPayOrder -> payOrderApi.createOrder(...)
--       -> PayAppServiceImpl.validPayApp(appKey)
--       -> appMapper.selectByAppKey(appKey) 查不到行 => 抛 APP_NOT_FOUND
--   错误码定义：juling-module-pay ErrorCodeConstants.APP_NOT_FOUND
--               = (1_007_000_000, "App 不存在")
--
--   appKey 来自 TradeOrderProperties.payAppKey，默认值 "mall"
--   （juling-module-trade/framework/order/config/TradeOrderProperties.java）；
--   application.yaml / application-local.yaml 均未配置 juling.trade.order.pay-app-key，
--   因此线上取的就是默认值 "mall"。
--   基线 sql/postgresql/juling-baseline.sql 完全不含 pay_* 表与种子数据，
--   全新环境的 pay_app 因此是空的。
--
-- 另一种同样可行的修法（不改库）：
--   在后台「支付管理 -> 应用信息」里把应用标识填成 mall 并开启；
--   或把 juling.trade.order.pay-app-key 改成已存在的 app_key。
--
-- 幂等：靠 NOT EXISTS 判断，重复执行安全。
-- pay_* 表不在基线脚本中（由 pay 模块单独建表）：
--   表不存在时本脚本打印 NOTICE 后跳过，不报错（与 12_fix_erp_null_counters.sql 同约定）。
--
-- 执行：psql -U root -d juling -f sql/local/13_pay_app_seed.sql

DO $do$
DECLARE
    order_notify_url    constant text := 'https://yutou.mynatapp.cc/admin-api/pay/notify/order';
    refund_notify_url   constant text := 'https://yutou.mynatapp.cc/admin-api/pay/notify/refund';
    transfer_notify_url constant text := 'https://yutou.mynatapp.cc/admin-api/pay/notify/transfer';
    id_expr   text;
    seq_name  text;
    app_key   text;
    app_name  text;
    app_remark text;
    apps constant text[][] := ARRAY[
        ['mall',   '商城应用', '交易订单默认支付应用（TradeOrderProperties.payAppKey 默认值）'],
        ['wallet', '钱包应用', '钱包支付默认支付应用（PayProperties.walletPayAppKey 默认值）']
    ];
    i int;
BEGIN
    IF to_regclass('public.pay_app') IS NULL THEN
        RAISE NOTICE 'pay_app 表不存在，跳过本脚本（请先初始化 pay 模块表结构）';
        RETURN;
    END IF;

    -- 主键取值方式：identity/serial 序列 -> @KeySequence 约定的 pay_app_seq -> 表默认值
    seq_name := pg_get_serial_sequence('public.pay_app', 'id');
    IF seq_name IS NOT NULL THEN
        id_expr := format('nextval(%L)', seq_name);
    ELSIF to_regclass('public.pay_app_seq') IS NOT NULL THEN
        id_expr := 'nextval(''pay_app_seq'')';
    ELSE
        id_expr := 'DEFAULT';
        RAISE NOTICE '未找到 pay_app 主键序列，改用表默认值插入';
    END IF;

    FOR i IN 1 .. array_length(apps, 1) LOOP
        app_key    := apps[i][1];
        app_name   := apps[i][2];
        app_remark := apps[i][3];

        IF EXISTS (SELECT 1 FROM pay_app WHERE app_key = apps[i][1] AND deleted = 0) THEN
            RAISE NOTICE '支付应用 % 已存在，跳过', app_key;
            CONTINUE;
        END IF;

        EXECUTE format(
            'INSERT INTO pay_app (id, app_key, name, status, remark, order_notify_url, refund_notify_url, transfer_notify_url, creator, create_time, updater, update_time, deleted) '
            'VALUES (%s, %L, %L, 0, %L, %L, %L, %L, %L, now(), %L, now(), 0)',
            id_expr, app_key, app_name, app_remark,
            order_notify_url, refund_notify_url, transfer_notify_url, '1', '1'
        );
        RAISE NOTICE '已创建支付应用：% (app_key=%)', app_name, app_key;
    END LOOP;

    RAISE NOTICE 'pay_app 现有应用：%', (
        SELECT string_agg(app_key || '=' || name, ', ' ORDER BY id) FROM pay_app WHERE deleted = 0
    );
END
$do$;
