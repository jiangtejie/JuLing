package com.lxjl.juling.module.infra.framework.file.config;

import com.lxjl.juling.module.infra.framework.file.core.client.FileClientFactory;
import com.lxjl.juling.module.infra.framework.file.core.client.FileClientFactoryImpl;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * 文件配置类
 *
 * @author 棱信矩灵
 */
@Configuration(proxyBeanMethods = false)
public class JuLingFileAutoConfiguration {

    @Bean
    public FileClientFactory fileClientFactory() {
        return new FileClientFactoryImpl();
    }

}
