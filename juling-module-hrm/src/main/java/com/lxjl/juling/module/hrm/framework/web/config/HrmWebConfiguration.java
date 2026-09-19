package com.lxjl.juling.module.hrm.framework.web.config;

import com.lxjl.juling.framework.swagger.config.JuLingSwaggerAutoConfiguration;
import org.springdoc.core.models.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * hrm 模块的 web 组件的 Configuration
 *
 * @author 棱信矩灵
 */
@Configuration(proxyBeanMethods = false)
public class HrmWebConfiguration {

    /**
     * hrm 模块的 API 分组
     */
    @Bean
    public GroupedOpenApi hrmGroupedOpenApi() {
        return JuLingSwaggerAutoConfiguration.buildGroupedOpenApi("hrm");
    }

}
