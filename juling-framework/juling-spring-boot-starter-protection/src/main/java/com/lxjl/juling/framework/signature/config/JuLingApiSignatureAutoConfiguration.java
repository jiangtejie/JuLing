package com.lxjl.juling.framework.signature.config;

import com.lxjl.juling.framework.redis.config.JuLingRedisAutoConfiguration;
import com.lxjl.juling.framework.signature.core.aop.ApiSignatureAspect;
import com.lxjl.juling.framework.signature.core.redis.ApiSignatureRedisDAO;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.data.redis.core.StringRedisTemplate;

/**
 * HTTP API 签名的自动配置类
 *
 * @author 棱信矩灵
 */
@AutoConfiguration(after = JuLingRedisAutoConfiguration.class)
public class JuLingApiSignatureAutoConfiguration {

    @Bean
    public ApiSignatureAspect signatureAspect(ApiSignatureRedisDAO signatureRedisDAO) {
        return new ApiSignatureAspect(signatureRedisDAO);
    }

    @Bean
    public ApiSignatureRedisDAO signatureRedisDAO(StringRedisTemplate stringRedisTemplate) {
        return new ApiSignatureRedisDAO(stringRedisTemplate);
    }

}
