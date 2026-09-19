package com.lxjl.juling.module.iot.framework.tdengine.config;

import com.lxjl.juling.module.iot.service.device.message.IotDeviceMessageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * TDengine 表初始化的 Configuration
 *
 * 【本地化改造】增加 juling.iot.tdengine-init 开关：未部署 TDengine 时序库时(默认 false)跳过，
 * 避免启动时执行 TDengine 方言 SQL 失败导致系统退出；部署 TDengine 后置为 true 即可恢复官方行为。
 *
 * @author 棱信矩灵
 */
@Component
@ConditionalOnProperty(prefix = "juling.iot", name = "tdengine-init", havingValue = "true")
@RequiredArgsConstructor
@Slf4j
public class TDengineTableInitRunner implements ApplicationRunner {

    private final IotDeviceMessageService deviceMessageService;

    @Override
    public void run(ApplicationArguments args) {
        try {
            // 初始化设备消息表
            deviceMessageService.defineDeviceMessageStable();
        } catch (Exception ex) {
            // 初始化失败时打印错误消息并退出系统
            log.error("[run][TDengine初始化设备消息表结构失败，系统无法正常运行，即将退出]", ex);
            System.exit(1);
        }
    }

}
