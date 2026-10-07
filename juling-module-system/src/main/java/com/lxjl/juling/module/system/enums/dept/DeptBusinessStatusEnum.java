package com.lxjl.juling.module.system.enums.dept;

import com.lxjl.juling.framework.common.core.ArrayValuable;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

import java.util.Arrays;

/**
 * 门店营业状态枚举（开店 / 闭店）
 *
 * <p>只对 {@link DeptTypeEnum#STORE} 节点有意义；组织节点恒为「营业」。
 * 口径：**已闭店的门店不可被订货账号授权、不可下单**。
 * 与 {@code status}（主数据是否可用）语义不同，两者不要混用。
 *
 * @author 亚特
 */
@RequiredArgsConstructor
@Getter
public enum DeptBusinessStatusEnum implements ArrayValuable<Integer> {

    OPEN(0, "营业"),
    CLOSED(1, "已闭店"),
    ;

    public static final Integer[] ARRAYS = Arrays.stream(values()).map(DeptBusinessStatusEnum::getStatus).toArray(Integer[]::new);

    /**
     * 状态
     */
    private final Integer status;
    /**
     * 名字
     */
    private final String name;

    @Override
    public Integer[] array() {
        return ARRAYS;
    }

}