package com.lxjl.juling.module.erp.enums;

import com.lxjl.juling.framework.common.core.ArrayValuable;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

import java.util.Arrays;

/**
 * ERP 价目表类型枚举
 *
 * <p>决定「适用范围」里的对象是供应商还是门店 —— 见 erp_price_list_scope.partner_id 的列注释。
 *
 * @author 亚特
 */
@Getter
@RequiredArgsConstructor
public enum ErpPriceTypeEnum implements ArrayValuable<String> {

    PURCHASE("PURCHASE", "采购价目表", "供应商", "erp_price_list_purchase"),
    DELIVERY("DELIVERY", "配送价目表", "门店", "erp_price_list_delivery"),
    ;

    public static final String[] ARRAYS = Arrays.stream(values()).map(ErpPriceTypeEnum::getType).toArray(String[]::new);

    /** 类型 */
    private final String type;
    /** 名称 */
    private final String name;
    /** 适用范围里的对象叫什么（供应商 / 门店），用于错误提示与界面文案 */
    private final String partnerLabel;
    /** 对应的编码规则 ruleKey */
    private final String codeRuleKey;

    @Override
    public String[] array() {
        return ARRAYS;
    }

}
