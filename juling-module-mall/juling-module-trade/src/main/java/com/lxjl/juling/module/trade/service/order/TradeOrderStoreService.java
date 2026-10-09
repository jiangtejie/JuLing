package com.lxjl.juling.module.trade.service.order;

import com.lxjl.juling.module.trade.service.order.bo.TradeOrderStoreBO;

import java.util.List;

/**
 * 下单门店解析 Service
 *
 * <p>把「订货账号」映射到它的**授权门店**，并校验账号只能为授权门店下单。
 * 授权关系由 member 模块的 {@code member_user_store} 承载；本服务在其之上补两道门店有效性校验：
 * **门店主数据启用**，且**挂在组织架构的「门店」节点上、未闭店**。
 *
 * <p>改造前这里靠「客户树有没有下级」推断代理账号，并从账号上兜底取部门
 * （会把下单账号的部门写进订单，见 docs/ordering-account-authorization-design.md §2.2）。现已整体移除。
 *
 * @author 亚特
 */
public interface TradeOrderStoreService {

    /**
     * 解析下单门店
     *
     * @param userId          订货账号（会员）编号
     * @param storeCustomerId 指定门店客户编号；为空时：只有一家授权门店就取它，多家则报「请先选择下单门店」
     * @return 门店信息
     */
    TradeOrderStoreBO resolveStore(Long userId, Long storeCustomerId);

    /**
     * 获得订货账号可下单的门店列表（H5 门店切换器）
     *
     * <p>加盟店账号只有一家；片区订货管理人有多家（业务口中的「代理人」只是帮忙下单）。
     *
     * @param userId 订货账号（会员）编号
     * @return 门店列表（含默认门店标记）
     */
    List<TradeOrderStoreBO> getStoreList(Long userId);

    /**
     * 是否加盟门店
     *
     * <p>门店订货链：加盟店要货需审批后才进入订单工作台，直营店直接流转。
     *
     * @param customerId 门店客户编号
     * @return true 加盟 / false 直营或未设置
     */
    boolean isFranchiseStore(Long customerId);

}