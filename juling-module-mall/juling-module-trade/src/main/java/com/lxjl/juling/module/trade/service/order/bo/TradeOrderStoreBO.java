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

}
