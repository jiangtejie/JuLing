package com.lxjl.juling.server;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * 项目的启动类
 *
 * 如果你碰到启动的问题，请认真阅读 上游文档 文章
 * 如果你碰到启动的问题，请认真阅读 上游文档 文章
 * 如果你碰到启动的问题，请认真阅读 上游文档 文章
 *
 * @author 棱信矩灵
 */
@SuppressWarnings("SpringComponentScan") // 忽略 IDEA 无法识别 ${juling.info.base-package}
@SpringBootApplication(scanBasePackages = {"${juling.info.base-package}.server", "${juling.info.base-package}.module"})
public class JuLingServerApplication {

    public static void main(String[] args) {
        // 如果你碰到启动的问题，请认真阅读 上游文档 文章
        // 如果你碰到启动的问题，请认真阅读 上游文档 文章
        // 如果你碰到启动的问题，请认真阅读 上游文档 文章

        SpringApplication.run(JuLingServerApplication.class, args);
//        new SpringApplicationBuilder(JuLingServerApplication.class)
//                .applicationStartup(new BufferingApplicationStartup(20480))
//                .run(args);

        // 如果你碰到启动的问题，请认真阅读 上游文档 文章
        // 如果你碰到启动的问题，请认真阅读 上游文档 文章
        // 如果你碰到启动的问题，请认真阅读 上游文档 文章
    }

}
