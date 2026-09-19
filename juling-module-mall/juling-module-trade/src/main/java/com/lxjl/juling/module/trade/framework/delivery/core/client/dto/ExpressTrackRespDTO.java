package com.lxjl.juling.module.trade.framework.delivery.core.client.dto;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 快递查询的轨迹 Resp DTO
 *
 * @author 棱信矩灵
 */
@Data
public class ExpressTrackRespDTO {

    /**
     * 发生时间
     */
    private LocalDateTime time;

    /**
     * 快递状态
     */
    private String content;

}
