package com.lxjl.juling.module.statistics.service.trade;

import com.lxjl.juling.module.statistics.dal.mysql.trade.BrokerageStatisticsMapper;
import com.lxjl.juling.module.trade.enums.brokerage.BrokerageRecordBizTypeEnum;
import com.lxjl.juling.module.trade.enums.brokerage.BrokerageRecordStatusEnum;
import com.lxjl.juling.module.trade.enums.brokerage.BrokerageWithdrawStatusEnum;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import jakarta.annotation.Resource;
import java.time.LocalDateTime;

/**
 * 分销统计 Service 实现类
 *
 * @author 亚特
 */
@Service
@Validated
public class BrokerageStatisticsServiceImpl implements BrokerageStatisticsService {

    @Resource
    private BrokerageStatisticsMapper brokerageStatisticsMapper;

    @Override
    public Integer getBrokerageSettlementPriceSummary(LocalDateTime beginTime, LocalDateTime endTime) {
        return brokerageStatisticsMapper.selectSummaryPriceByStatusAndUnfreezeTimeBetween(
                BrokerageRecordBizTypeEnum.ORDER.getType(), BrokerageRecordStatusEnum.SETTLEMENT.getStatus(),
                beginTime, endTime);
    }

    @Override
    public Long getWithdrawCountByStatus(BrokerageWithdrawStatusEnum status) {
        // 佣金提现功能已下线，提现记录数量固定返回 0
        return 0L;
    }

}
