package com.lxjl.juling.module.fms.dal.mysql.report.balance;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.fms.dal.dataobject.report.balance.FmsBalanceSheetReportDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * FMS 资产负债表数据 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface FmsBalanceSheetReportMapper extends BaseMapperX<FmsBalanceSheetReportDO> {

    default List<FmsBalanceSheetReportDO> selectListByPeriod(
            Long accountSetId, Integer fromPeriod, Integer toPeriod, Integer type) {
        return selectList(new LambdaQueryWrapperX<FmsBalanceSheetReportDO>()
                .eq(FmsBalanceSheetReportDO::getAccountSetId, accountSetId)
                .eq(FmsBalanceSheetReportDO::getFromPeriod, fromPeriod)
                .eq(FmsBalanceSheetReportDO::getToPeriod, toPeriod)
                .eq(FmsBalanceSheetReportDO::getType, type)
                .orderByAsc(FmsBalanceSheetReportDO::getSort)
                .orderByAsc(FmsBalanceSheetReportDO::getId));
    }

}
