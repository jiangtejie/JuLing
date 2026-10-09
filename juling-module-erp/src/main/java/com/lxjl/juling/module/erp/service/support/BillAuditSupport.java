package com.lxjl.juling.module.erp.service.support;

import com.lxjl.juling.framework.common.exception.ErrorCode;
import com.lxjl.juling.module.erp.enums.ErpAuditStatus;

import java.util.Objects;
import java.util.function.IntSupplier;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;

/**
 * 单据审核的公共骨架
 *
 * <p><b>为什么需要它</b>：12 个单据 Service 各自实现了同一套
 * 「判定 approve → 同状态守卫 → CAS 更新 → 失败报错」，合计约 54 处重复。
 * 而 {@code docs/store-ordering-flow-design.md} §3 段规划的是
 * **审核（BPM 混合式，按店型分流）** —— 一旦要接 BPM，这 12 处全都要改，
 * 且极易漏掉一个（漏掉的那个单据就会绕过审批）。重复的代价不是「难看」，
 * 是**下一次改动无法保证改全**。
 *
 * <p><b>只收机械的三步，不收业务规则</b>：各单据自己的校验（如采购订单
 * 「已有入库不可反审核」、入库单「已付款不可反审核」）仍留在各自的 Service 里 ——
 * 那些是业务规则，被框架吞掉之后就更难读懂了。
 *
 * <p><b>调用顺序必须保持原样</b>：先 {@link #validateStatusChange}（同状态守卫），
 * 再各单据的业务校验，最后 {@link #casUpdate}。顺序换了错误提示就会变
 * （「单据已是该状态」和「已有入库不能反审核」是两句不同的话）。
 *
 * @author 亚特
 */
public final class BillAuditSupport {

    private BillAuditSupport() {
    }

    /** 本次状态流转是不是「审核」 */
    public static boolean isApprove(Integer status) {
        return ErpAuditStatus.APPROVE.getStatus().equals(status);
    }

    /**
     * 同状态守卫：单据已经是目标状态时拦下
     *
     * <p>这一步同时挡两类问题：**重复点击**（用户连点两次审核）与**并发**（两个人同时审核）。
     * 真正把并发挡住的是后面的 CAS，这里负责给出可读的提示。
     */
    public static void validateStatusChange(Integer currentStatus, Integer targetStatus,
                                            ErrorCode approveFail, ErrorCode processFail) {
        if (Objects.equals(currentStatus, targetStatus)) {
            throw exception(isApprove(targetStatus) ? approveFail : processFail);
        }
    }

    /**
     * CAS 更新状态：以「旧状态」为条件更新，影响行数为 0 即说明被别人抢先改了
     *
     * @param casUpdater 条件更新，返回受影响行数
     *                   （通常是 {@code mapper.updateByIdAndStatus(id, 旧状态, new DO().setStatus(新))}）
     */
    public static void casUpdate(IntSupplier casUpdater, Integer targetStatus,
                                 ErrorCode approveFail, ErrorCode processFail) {
        if (casUpdater.getAsInt() == 0) {
            throw exception(isApprove(targetStatus) ? approveFail : processFail);
        }
    }

}
