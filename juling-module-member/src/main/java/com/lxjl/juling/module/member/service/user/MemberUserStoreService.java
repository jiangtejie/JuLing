package com.lxjl.juling.module.member.service.user;

import com.lxjl.juling.module.member.dal.dataobject.user.MemberUserStoreDO;

import java.util.Collection;
import java.util.List;

/**
 * 订货账号「授权门店」Service 接口
 *
 * <p>回答一个且只回答一个问题：**这个账号能给哪些门店下单**。
 *
 * @author 亚特
 */
public interface MemberUserStoreService {

    /**
     * 账号的全部启用授权门店编号（按 sort、id 排序）
     *
     * @param userId 订货账号编号
     * @return 门店客户编号列表；无授权返回空列表
     */
    List<Long> getStoreIds(Long userId);

    /**
     * 账号的默认门店编号
     *
     * @param userId 订货账号编号
     * @return 默认门店编号；未设默认时取第一条；无授权返回 {@code null}
     */
    Long getDefaultStoreId(Long userId);

    /**
     * 账号的授权门店明细
     */
    List<MemberUserStoreDO> getStoreListByUserId(Long userId);

    /**
     * 多个账号的授权门店明细（批量，供后台列表拼装门店名）
     */
    List<MemberUserStoreDO> getStoreListByUserIds(Collection<Long> userIds);

    /**
     * 某门店被哪些账号授权（门店闭店 / 停用时看影响面）
     */
    List<MemberUserStoreDO> getStoreListByCustomerId(Long customerId);

    /**
     * 全量替换某账号的授权门店（开号 / 改号时调用）
     *
     * @param userId                 订货账号编号
     * @param storeCustomerIds       授权门店编号集合（至少一个）
     * @param defaultStoreCustomerId 默认门店编号；不在授权范围内时回退为第一家
     */
    void replaceGrants(Long userId, Collection<Long> storeCustomerIds, Long defaultStoreCustomerId);

}