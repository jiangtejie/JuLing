-- =============================================================================
-- T2 改名同步：把数据库中残留的历史标识同步为 棱信矩灵 / com.lxjl.juling
-- 背景：Java 包名由 cn.iocoder.yudao 改为 com.lxjl.juling，但数据库里有几处
--       直接存了 Java 类全名 / 路径 / 历史域名，必须同步，否则新版本会出错。
-- 执行：docker cp 到容器后 psql -f（避免 PowerShell 管道破坏中文编码）
-- 可重复执行（幂等）。
-- =============================================================================

-- 统一的历史标识替换函数（覆盖点号/斜杠/反斜杠三种路径写法与制品名）
CREATE OR REPLACE FUNCTION pg_temp.fix_legacy(t text) RETURNS text AS $fn$
  SELECT replace(replace(replace(replace(replace(replace(replace(replace(replace(coalesce(t, ''),
    'cn.iocoder.yudao',   'com.lxjl.juling'),
    'cn.iocoder.boot',    'com.lxjl.boot'),
    'cn/iocoder/yudao',   'com/lxjl/juling'),
    'cn\iocoder\yudao',   'com\lxjl\juling'),
    'cn/iocoder/boot',    'com/lxjl/boot'),
    'cn\iocoder\boot',    'com\lxjl\boot'),
    'cn.iocoder',         'com.lxjl'),
    'yudao-module',       'juling-module'),
    'yudao-server',       'juling-server')
$fn$ LANGUAGE sql IMMUTABLE;

\echo '=== 执行前 ==='
SELECT id, storage, LEFT(config, 100) AS config_head FROM infra_file_config;
SELECT id, LEFT(logo, 60) AS logo FROM system_oauth2_client;
SELECT id, websites FROM system_tenant;
SELECT id, username, LEFT(avatar, 60) AS avatar FROM system_users WHERE avatar <> '';
SELECT count(*) AS 旧标识错误日志数 FROM infra_api_error_log
WHERE exception_stack_trace LIKE '%iocoder%' OR exception_stack_trace LIKE '%yudao-%';

BEGIN;

-- -----------------------------------------------------------------------------
-- 1.【功能性】文件存储配置：@class 是 Java 类全名，不同步会导致文件上传/URL 生成
--    报 ClassNotFoundException（com.lxjl.juling.module.infra.framework.file.core.client.*）
-- -----------------------------------------------------------------------------
UPDATE infra_file_config
SET config = pg_temp.fix_legacy(config)
WHERE config LIKE '%iocoder%';

-- 兜底：其它表里以 JSON 形式保存的配置（当前为 0 行，防止将来漏改）
UPDATE infra_config
SET value = pg_temp.fix_legacy(value)
WHERE value LIKE '%iocoder%';

-- -----------------------------------------------------------------------------
-- 2.【展示性】OAuth2 客户端 logo、租户域名、用户头像：历史测试 CDN 域名
-- -----------------------------------------------------------------------------
UPDATE system_oauth2_client SET logo = ''
WHERE logo LIKE '%iocoder%' OR logo LIKE '%yudao%';

UPDATE system_tenant SET websites = replace(websites, 'www.iocoder.cn,', '')
WHERE websites LIKE '%iocoder%';

UPDATE system_users SET avatar = ''
WHERE avatar LIKE '%iocoder%' OR avatar LIKE '%yudao%';

-- -----------------------------------------------------------------------------
-- 3.【可读性】历史错误日志：把栈里的类名/路径同步为新包名，
--    这样旧日志仍能对应到改名后的源码（不改动任何业务数据）
-- -----------------------------------------------------------------------------
UPDATE infra_api_error_log
SET application_name            = pg_temp.fix_legacy(application_name),
    exception_class_name        = pg_temp.fix_legacy(exception_class_name),
    exception_message           = pg_temp.fix_legacy(exception_message),
    exception_root_cause_message= pg_temp.fix_legacy(exception_root_cause_message),
    exception_stack_trace       = pg_temp.fix_legacy(exception_stack_trace)
WHERE application_name LIKE '%yudao%'
   OR exception_class_name LIKE '%iocoder%'
   OR exception_message LIKE '%iocoder%'
   OR exception_root_cause_message LIKE '%iocoder%'
   OR exception_stack_trace LIKE '%iocoder%'
   OR exception_stack_trace LIKE '%yudao-%';

COMMIT;

\echo '=== 执行后（第二列应全为 0）==='
SELECT
  (SELECT count(*) FROM infra_file_config   WHERE config LIKE '%iocoder%')  AS 文件配置残留,
  (SELECT count(*) FROM system_users        WHERE avatar LIKE '%iocoder%')  AS 头像残留,
  (SELECT count(*) FROM system_tenant       WHERE websites LIKE '%iocoder%')AS 租户域名残留,
  (SELECT count(*) FROM infra_api_error_log
     WHERE exception_stack_trace LIKE '%iocoder%'
        OR exception_stack_trace LIKE '%yudao-%'
        OR application_name LIKE '%yudao%')                                AS 错误日志残留;

SELECT id, storage, LEFT(config, 130) AS config_head FROM infra_file_config;
SELECT id, websites FROM system_tenant;
