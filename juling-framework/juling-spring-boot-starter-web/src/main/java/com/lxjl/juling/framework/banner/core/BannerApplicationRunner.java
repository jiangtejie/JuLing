package com.lxjl.juling.framework.banner.core;

import cn.hutool.core.thread.ThreadUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.util.ClassUtils;

import java.util.concurrent.TimeUnit;

/**
 * 项目启动成功后，提供文档相关的地址
 *
 * @author 亚特
 */
@Slf4j
public class BannerApplicationRunner implements ApplicationRunner {

    @Override
    public void run(ApplicationArguments args) {
        ThreadUtil.execute(() -> {
            ThreadUtil.sleep(1, TimeUnit.SECONDS); // 延迟 1 秒，保证输出到结尾
            log.info("\n----------------------------------------------------------\n\t" +
                            "项目启动成功！\n\t" +
                            "项目地址: \thttps://github.com/jiangtejie/JuLing \n\t" +
                            "接口文档: \thttp://127.0.0.1:48080/doc.html \n" +
                            "----------------------------------------------------------");

            // 工作流
            if (isNotPresent("com.lxjl.juling.module.bpm.framework.flowable.config.BpmFlowableConfiguration")) {
                System.out.println("[工作流模块 juling-module-bpm - 未启用][模块启停见 README]");
            }
            // 商城系统
            if (isNotPresent("com.lxjl.juling.module.trade.framework.web.config.TradeWebConfiguration")) {
                System.out.println("[商城系统 juling-module-mall - 未启用][模块启停见 README]");
            }
            // ERP 系统
            if (isNotPresent("com.lxjl.juling.module.erp.framework.web.config.ErpWebConfiguration")) {
                System.out.println("[ERP 系统 juling-module-erp - 未启用][模块启停见 README]");
            }
            // WMS 仓库管理系统
            if (isNotPresent("com.lxjl.juling.module.wms.framework.web.config.WmsWebConfiguration")) {
                System.out.println("[WMS 仓库管理系统 juling-module-wms - 未启用][模块启停见 README]");
            }
            // AI 大模型
            if (isNotPresent("com.lxjl.juling.module.ai.framework.web.config.AiWebConfiguration")) {
                System.out.println("[AI 大模型 juling-module-ai - 未启用][模块启停见 README]");
            }
        });
    }

    private static boolean isNotPresent(String className) {
        return !ClassUtils.isPresent(className, ClassUtils.getDefaultClassLoader());
    }

}
