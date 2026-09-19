package com.lxjl.juling.module.fms.service.closing;

import com.lxjl.juling.module.fms.controller.admin.closing.vo.FmsClosingOverviewRespVO;
import com.lxjl.juling.module.fms.controller.admin.closing.vo.FmsClosingQueryReqVO;

import java.time.LocalDateTime;
import java.time.YearMonth;

/**
 * FMS 结账期间 Service 接口
 *
 * @author 棱信矩灵
 */
public interface FmsClosingPeriodService {

    /**
     * 校验业务时间所属期间未结账
     *
     * @param accountSetId 账套编号
     * @param businessTime 业务时间
     */
    void validatePeriodOpen(Long accountSetId, LocalDateTime businessTime);

    /**
     * 判断业务时间所属期间是否已结账
     *
     * @param accountSetId 账套编号
     * @param businessTime 业务时间
     * @return 是否已结账
     */
    boolean isPeriodClosed(Long accountSetId, LocalDateTime businessTime);

    /**
     * 获得当前会计期间
     *
     * @param accountSetId 账套编号
     * @param startTime 账套启用时间
     * @return 当前会计期间
     */
    YearMonth getCurrentMonth(Long accountSetId, LocalDateTime startTime);

    /**
     * 获得当前会计期间
     *
     * @param accountSetId 账套编号
     * @param userId 用户编号
     * @return 当前会计期间
     */
    String getCurrentMonth(Long accountSetId, Long userId);

    /**
     * 获得结账概况
     *
     * @param queryReqVO 查询参数
     * @param userId 用户编号
     * @return 结账概况
     */
    FmsClosingOverviewRespVO getClosingOverview(FmsClosingQueryReqVO queryReqVO, Long userId);

    /**
     * 判断指定期间内各月的损益是否均已结转（逐月损益余额均为 0）
     *
     * <p>供资产负债表 / 现金流量表的取数条件检查使用。实现上直接计算各月损益余额，
     * **不经过 {@link #getClosingOverview}**：结账概览内部会反向调用报表检查，
     * 若此处再回调概览会形成互相调用的死循环（StackOverflowError）。
     *
     * @param accountSetId 账套编号
     * @param startMonth 起始月份（yyyy-MM）
     * @param endMonth 结束月份（yyyy-MM）
     * @param userId 用户编号
     * @return 是否已结转
     */
    boolean isProfitLossTransferred(Long accountSetId, String startMonth, String endMonth, Long userId);

    /**
     * 结账
     *
     * @param queryReqVO 结账期间
     * @param userId 用户编号
     */
    void closePeriod(FmsClosingQueryReqVO queryReqVO, Long userId);

    /**
     * 反结账
     *
     * @param queryReqVO 结账期间
     * @param userId 用户编号
     */
    void cancelClosePeriod(FmsClosingQueryReqVO queryReqVO, Long userId);

    /**
     * 判断指定会计期间是否已结账
     *
     * @param accountSetId 账套编号
     * @param month 会计期间
     * @return 是否已结账
     */
    boolean isPeriodClosed(Long accountSetId, String month);

}
