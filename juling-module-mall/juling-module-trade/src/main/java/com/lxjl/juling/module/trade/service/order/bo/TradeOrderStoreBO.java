package com.lxjl.juling.module.trade.service.order.bo;

import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerRespDTO;
import com.lxjl.juling.module.trade.enums.order.TradeSettlementModeEnum;
import lombok.Data;

import java.util.Objects;

/**
 * 下单门店信息 BO
 *
 * <p>订单归属只由**门店**决定：门店客户编号（经营面）+ 门店所属部门（组织面）。
 * 下单账号不参与这两项 —— 它只决定「能选哪些门店」。
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
     * 门店所属部门编号（来自门店主数据；为空表示门店未挂组织节点，后台会提示补档）
     */
    private Long deptId;
    /**
     * 结算模式
     */
    private String settlementMode;
    /**
     * 店型：DIRECT 直营 / FRANCHISE 加盟
     */
    private String storeType;
    /**
     * 是否账号的默认门店（H5 首次进入用它）
     */
    private Boolean isDefault;

    /**
     * 由门店主数据组装（**唯一**的组装入口，避免各处散落兜底逻辑）
     *
     * @param store          门店主数据
     * @param defaultStoreId 账号的默认门店编号（可为 null）
     */
    public static TradeOrderStoreBO of(ErpCustomerRespDTO store, Long defaultStoreId) {
        TradeOrderStoreBO bo = new TradeOrderStoreBO();
        bo.setCustomerId(store.getId());
        bo.setCustomerName(store.getName());
        bo.setDeptId(store.getDeptId());
        bo.setSettlementMode(store.getSettlementMode() != null
                ? store.getSettlementMode() : TradeSettlementModeEnum.DEFAULT_MODE);
        bo.setStoreType(store.getStoreType());
        bo.setIsDefault(Objects.equals(store.getId(), defaultStoreId));
        return bo;
    }

    /**
     * 是否加盟门店（加盟店要货需审核，直营店免审）
     */
    public boolean isFranchise() {
        return "FRANCHISE".equals(storeType);
    }

}