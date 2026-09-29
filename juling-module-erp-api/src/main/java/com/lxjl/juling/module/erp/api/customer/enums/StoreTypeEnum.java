package com.lxjl.juling.module.erp.api.customer.enums;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Objects;

/**
 * 门店店型枚举（erp_customer.store_type，字典 erp_store_type）
 *
 * 门店订货链：加盟店（FRANCHISE）要货需审核后才进订单工作台；直营店（DIRECT）免审。
 *
 * @author 亚特
 */
@Getter
@AllArgsConstructor
public enum StoreTypeEnum {

    DIRECT("DIRECT", "直营"),
    FRANCHISE("FRANCHISE", "加盟"),
    ;

    /**
     * 店型
     */
    private final String type;
    /**
     * 名字
     */
    private final String name;

    /**
     * 是否加盟店（店型为空时按直营处理，与发货闸门口径一致：不卡历史数据）
     */
    public static boolean isFranchise(String type) {
        return Objects.equals(FRANCHISE.getType(), type);
    }

}
