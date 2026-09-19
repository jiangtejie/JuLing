package com.lxjl.juling.module.statistics.controller.admin.trade.vo;

import com.lxjl.juling.framework.excel.core.convert.MoneyConvert;
import cn.idev.excel.annotation.ExcelProperty;
import cn.idev.excel.annotation.format.DateTimeFormat;
import lombok.Data;

import java.time.LocalDate;

import static com.lxjl.juling.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY;

/**
 * 交易状况统计 Excel VO
 *
 * @author 棱信矩灵
 */
@Data
public class TradeTrendSummaryExcelVO {

    @ExcelProperty(value = "日期")
    @DateTimeFormat(FORMAT_YEAR_MONTH_DAY)
    private LocalDate date;

    @ExcelProperty(value = "营业额", converter = MoneyConvert.class)
    private Integer turnoverPrice;

    @ExcelProperty(value = "商品支付金额", converter = MoneyConvert.class)
    private Integer orderPayPrice;

    @ExcelProperty(value = "充值金额", converter = MoneyConvert.class)
    private Integer rechargePrice;

    @ExcelProperty(value = "支出金额", converter = MoneyConvert.class)
    private Integer expensePrice;

    @ExcelProperty(value = "余额支付金额", converter = MoneyConvert.class)
    private Integer walletPayPrice;

    @ExcelProperty(value = "支付佣金金额", converter = MoneyConvert.class)
    private Integer brokerageSettlementPrice;

    @ExcelProperty(value = "商品退款金额", converter = MoneyConvert.class)
    private Integer afterSaleRefundPrice;
}
