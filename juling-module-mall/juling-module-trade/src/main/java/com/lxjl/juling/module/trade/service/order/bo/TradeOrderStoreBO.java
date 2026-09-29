package com.lxjl.juling.module.trade.service.order.bo;

import lombok.Data;

/**
 * 下单门店信息 BO
 *
 * 门店订货链「一店三面」中的组织面（deptId）与经营面（customerId / 结算模式）。
 *
 * @author 亚特
 */
@Data
public class TradeOrderStoreBO {

    /**
     * 门店客户编号
     */
    private Long customerId;
    /**
     * 门店名称
     */
    private String customerName;
    /**
     * 门店所属部门编号
     */
    private Long deptId;
    /**
     * 代理客户编号（代理账号切换门店下单时非空）
     */
    private Long agentCustomerId;
    /**
     * 结算模式
     */
    private String settlementMode;
    /**
     * 店型：DIRECT 直营 / FRANCHISE 加盟
     *
     * 门店订货链：加盟店要货需财务审核后才进入订单工作台，直营店直接流转（见 CY-001 整体业务流程）。
     */
    private String storeType;

    /**
     * 是否加盟门店（加盟店要货需审核，直营店免审）
     */
    public boolean isFranchise() {
        return "FRANCHISE".equals(storeType);
    }

}
