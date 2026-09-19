package com.lxjl.juling.framework.common.enums;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 文档地址
 *
 * @author 棱信矩灵
 */
@Getter
@AllArgsConstructor
public enum DocumentEnum {

    REDIS_INSTALL("https://redis.io/docs/", "Redis 安装文档"),
    TENANT("https://github.com/jiangtejie/JuLing#readme", "SaaS 多租户文档");

    private final String url;
    private final String memo;

}
