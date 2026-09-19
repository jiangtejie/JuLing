package com.lxjl.juling.module.product.framework.web.config;

import com.lxjl.juling.framework.swagger.config.JuLingSwaggerAutoConfiguration;
import org.springdoc.core.models.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * product 模块的 web 组件的 Configuration
 *
 * @author 棱信矩灵
 */
@Configuration(proxyBeanMethods = false)
public class ProductWebConfiguration {

    /**
     * product 模块的 API 分组
     */
    @Bean
    public GroupedOpenApi productGroupedOpenApi() {
        return JuLingSwaggerAutoConfiguration.buildGroupedOpenApi("product");
    }

}
