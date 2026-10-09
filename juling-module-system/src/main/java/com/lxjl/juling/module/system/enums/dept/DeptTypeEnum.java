package com.lxjl.juling.module.system.enums.dept;

import com.lxjl.juling.framework.common.core.ArrayValuable;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

import java.util.Arrays;

/**
 * 组织架构节点类型枚举
 *
 * <p>system_dept 从「部门树」升级为「组织架构树」：节点分「组织」与「门店」。
 * 门店的**店型（直营 / 加盟）刻意不落在本表** —— 以 {@code erp_customer.store_type} 为唯一权威，
 * 避免同一件事两处维护必然漂移。详见 docs/organization-architecture-design.md §7。
 *
 * @author 亚特
 */
@RequiredArgsConstructor
@Getter
public enum DeptTypeEnum implements ArrayValuable<String> {

    ORG("ORG", "组织"),
    STORE("STORE", "门店"),
    ;

    public static final String[] ARRAYS = Arrays.stream(values()).map(DeptTypeEnum::getType).toArray(String[]::new);

    /**
     * 类型
     */
    private final String type;
    /**
     * 名字
     */
    private final String name;

    @Override
    public String[] array() {
        return ARRAYS;
    }

}