package com.lxjl.juling.module.fms.framework.web.config;

import com.lxjl.juling.framework.swagger.config.JuLingSwaggerAutoConfiguration;
import org.springdoc.core.models.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * fms 模块的 web 组件的 Configuration
 *
 * @author 棱信矩灵
 */
@Configuration(proxyBeanMethods = false)
public class FmsWebConfiguration {

    /**
     * fms 模块的 API 分组
     *
     * @return fms 模块的 OpenAPI 分组
     */
    @Bean
    public GroupedOpenApi fmsGroupedOpenApi() {
        return JuLingSwaggerAutoConfiguration.buildGroupedOpenApi("fms");
    }

}
