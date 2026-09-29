package com.lxjl.juling.module.statistics.service.trade.bo;

import lombok.Data;

/**
 * 交易统计 Resp BO
 *
 * @author 亚特
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
