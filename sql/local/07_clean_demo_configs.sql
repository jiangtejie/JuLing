-- 清理演示用的文件存储 / 邮箱 / 社交登录 / 短信渠道配置
BEGIN;

-- 1) 文件存储：仅保留“本地存储”并设为 master（basePath 改为本项目目录）
DELETE FROM infra_file_config WHERE id IN (4, 22, 24, 25, 26, 27, 28, 30, 34, 35);
UPDATE infra_file_config
   SET name = '本地存储',
       master = TRUE,
       config = '{"@class":"com.lxjl.juling.module.infra.framework.file.core.client.local.LocalFileClientConfig","basePath":"D:/A_ERP/java17/JuLing/run/uploads","domain":"http://127.0.0.1:48080"}',
       updater = '1',
       update_time = NOW()
 WHERE id = 29;

-- 2) 演示邮箱账号
DELETE FROM system_mail_account;

-- 3) 演示社交登录客户端及其社交用户
DELETE FROM system_social_user;
DELETE FROM system_social_client;

-- 4) 演示短信渠道（保留短信模板作为示例数据）
DELETE FROM system_sms_channel;

COMMIT;

\echo '--- 文件存储配置 ---'
SELECT id, name, storage, master, (config::json->>'basePath') AS base_path FROM infra_file_config ORDER BY id;
\echo '--- 邮箱/社交/短信渠道 ---'
SELECT 'mail_account' t, count(*) n FROM system_mail_account
UNION ALL SELECT 'social_client', count(*) FROM system_social_client
UNION ALL SELECT 'sms_channel', count(*) FROM system_sms_channel
UNION ALL SELECT 'sms_template', count(*) FROM system_sms_template;
