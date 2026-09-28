package com.lxjl.juling.module.trade.service.order;

import com.lxjl.juling.module.trade.service.order.bo.TradeOrderStoreBO;

/**
 * 下单门店解析 Service
 *
 * 门店订货链 S1：把「订货账号（会员）」映射到「门店（客户）+ 组织（部门）」，
 * 并校验代理账号只能为其名下门店下单。
 *
 * @author 亚特
 */
public interface TradeOrderStoreService {

    /**
     * 解析下单门店
     *
     * @param userId          订货账号（会员）编号
     * @param storeCustomerId 指定门店客户编号；为空时取账号绑定门店
     * @return 门店信息
     */
    TradeOrderStoreBO resolveStore(Long userId, Long storeCustomerId);

    /**
     * 获得订货账号可下单的门店列表
     *
     * 用于 H5 门店切换器：代理账号可切换其名下门店，普通门店账号只有自己。
     *
     * @param userId 订货账号（会员）编号
     * @return 门店列表（第一个为默认门店）
     */
    java.util.List<TradeOrderStoreBO> getStoreList(Long userId);

    /**
     * 是否加盟门店
     *
     * 门店订货链：加盟店要货需财务审核后才进入订单工作台，直营店直接流转。
     *
     * @param customerId 门店客户编号
     * @return true 加盟 / false 直营或未设置
     */
    boolean isFranchiseStore(Long customerId);

}
