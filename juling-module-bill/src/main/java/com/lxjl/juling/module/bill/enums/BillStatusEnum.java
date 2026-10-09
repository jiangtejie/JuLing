package com.lxjl.juling.module.bill.enums;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Objects;
import java.util.Set;

/**
 * 单据状态枚举（平台统一口径）
 *
 * 合法迁移见 {@link #canTransfer}；受控反审核（APPROVED → DRAFT）仅在未被下游引用时允许，
 * 由业务侧配合 {@link com.lxjl.juling.module.bill.api.BillPlatformApi#hasRelation} 判断。
 *
 * @author 亚特
 */
@Getter
@AllArgsConstructor
public enum BillStatusEnum {

    DRAFT(0, "草稿"),
    SUBMITTED(10, "已提交"),
    PROCESS(20, "审批中"),
    APPROVED(30, "已审核"),
    EXECUTING(40, "执行中"),
    COMPLETED(50, "已完成"),
    VOID(90, "已作废"),
    ;

    private final Integer status;
    private final String name;

    /** 允许的状态迁移 */
    private static final Set<String> TRANSFERS = Set.of(
            "0->10", "0->90", "10->20", "10->30", "10->0", "10->90",
            "20->30", "20->0", "20->90",
            "30->40", "30->50", "30->90",
            "40->50", "40->90",
            "50->90");

    public static BillStatusEnum valueOf(Integer status) {
        for (BillStatusEnum item : values()) {
            if (Objects.equals(item.getStatus(), status)) {
                return item;
            }
        }
        return null;
    }

    public static boolean canTransfer(Integer from, Integer to) {
        if (Objects.equals(from, to)) {
            return true;
        }
        if (from == null) {
            return Objects.equals(to, DRAFT.getStatus());
        }
        return TRANSFERS.contains(from + "->" + to);
    }

}
