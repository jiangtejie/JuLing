package com.lxjl.juling.module.ai.job.image;

import com.lxjl.juling.framework.quartz.core.handler.JobHandler;
import com.lxjl.juling.module.ai.service.image.AiImageService;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Midjourney 同步 Job：定时拉去 midjourney 绘制状态
 *
 * @author 棱信矩灵
 */
@Component
@Slf4j
public class AiMidjourneySyncJob implements JobHandler {

    @Resource
    private AiImageService imageService;

    @Override
    public String execute(String param) {
        Integer count = imageService.midjourneySync();
        log.info("[execute][同步 Midjourney ({}) 个]", count);
        return String.format("同步 Midjourney %s 个", count);
    }

}
