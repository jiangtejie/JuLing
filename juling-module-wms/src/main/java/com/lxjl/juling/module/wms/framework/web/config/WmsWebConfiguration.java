package com.lxjl.juling.module.wms.framework.web.config;

import com.lxjl.juling.framework.swagger.config.JuLingSwaggerAutoConfiguration;
import org.springdoc.core.models.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * WMS 模块的 web 组件的 Configuration
 *
 * @author 棱信矩灵
 */
@Configuration(proxyBeanMethods = false)
public class WmsWebConfiguration {

    /**
     * WMS 模块的 API 分组
     */
    @Bean
    public GroupedOpenApi wmsGroupedOpenApi() {
        return JuLingSwaggerAutoConfiguration.buildGroupedOpenApi("wms");
    }

}
