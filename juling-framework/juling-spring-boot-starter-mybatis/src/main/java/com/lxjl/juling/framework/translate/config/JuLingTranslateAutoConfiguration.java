package com.lxjl.juling.framework.translate.config;

import com.lxjl.juling.framework.translate.core.TranslateUtils;
import org.dromara.trans.service.impl.TransService;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.context.annotation.Bean;

/**
 * VO 数据翻译的自动配置
 *
 * 说明：这里**不能**用 {@code @ConditionalOnBean(TransService.class)} —— 该条件在自动配置评估期生效，
 * 而 easy-trans 的 {@code TransServiceConfig} 何时注册 bean 取决于自动配置顺序，评估期常常还看不到它，
 * 于是本配置被判定为不匹配、TranslateUtils 未初始化，调用 {@code TranslateUtils.translate} 时抛 NPE
 * （典型表现：操作日志导出 500）。
 *
 * 因此改为：用 {@code @ConditionalOnClass} 判断 easy-trans 是否在类路径（稳定的静态条件），
 * 再用 {@link ObjectProvider} 在 bean 创建时按需取 TransService（此时 bean 定义已就绪，取不到则为 null，
 * TranslateUtils 内部已做空值保护）。
 */
@AutoConfiguration
@ConditionalOnClass(TransService.class)
public class JuLingTranslateAutoConfiguration {

    @Bean
    @SuppressWarnings("InstantiationOfUtilityClass")
    public TranslateUtils translateUtils(ObjectProvider<TransService> transServiceProvider) {
        TranslateUtils.init(transServiceProvider.getIfAvailable());
        return new TranslateUtils();
    }

}
