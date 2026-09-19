package com.lxjl.juling.module.statistics.dal.mysql.trade;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.module.statistics.dal.dataobject.trade.TradeStatisticsDO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;

/**
 * 订单分销的统计 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface BrokerageStatisticsMapper extends BaseMapperX<TradeStatisticsDO> {

    Integer selectSummaryPriceByStatusAndUnfreezeTimeBetween(@Param("bizType") Integer bizType,
                                                             @Param("status") Integer status,
                                                             @Param("beginTime") LocalDateTime beginTime,
                                                             @Param("endTime") LocalDateTime endTime);

    Long selectWithdrawCountByStatus(@Param("status") Integer status);

}
