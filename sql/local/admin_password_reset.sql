-- 重置管理员密码（模板，可安全入库）
--
-- 用法：
--   1) 生成 BCrypt 口令值（本机执行，不要把明文写进任何提交里）：
--        cd script/local
--        java -cp "$env:USERPROFILE\.m2\repository\org\springframework\security\spring-security-crypto\6.5.11\spring-security-crypto-6.5.11.jar" GenHash.java '<新密码>'
--      或复用任意 BCryptPasswordEncoder（strength 10）生成的 $2a$10$... 值。
--   2) 用生成的值替换下面的 <BCRYPT_HASH>，然后执行：
--        docker cp sql/local/admin_password_reset.sql postgres:/tmp/reset.sql
--        docker exec postgres psql -U root -d juling -f /tmp/reset.sql
--
-- 说明：真实口令与哈希不入库，本机保留在 script/local/admin-password.txt 与 admin-password-hash.txt。

UPDATE system_users
   SET password    = '<BCRYPT_HASH>',
       updater     = '1',
       update_time = NOW()
 WHERE username = 'admin'
   AND deleted = 0;

-- 校验（应返回 1 行，password 以 $2a$10$ 开头）
SELECT id, username, LEFT(password, 7) AS hash_prefix, update_time
  FROM system_users
 WHERE username = 'admin' AND deleted = 0;
