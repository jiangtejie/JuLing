package com.lxjl.juling.module.statistics.service.trade.bo;

import lombok.Data;

/**
 * 交易统计 Resp BO
 *
 * @author 棱信矩灵
 */
@Data
public class TradeSummaryRespBO {

    /**
     * 数量
     */
    private Integer count;

    /**
     * 合计
     */
    private Integer summary;

}
