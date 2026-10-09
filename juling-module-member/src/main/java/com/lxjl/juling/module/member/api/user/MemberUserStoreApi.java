package com.lxjl.juling.module.member.api.user;

import java.util.Collection;
import java.util.List;

/**
 * 订货账号「授权门店」API 接口
 *
 * <p>供 trade 模块在做下单门店解析时读取：**这个账号能给哪些门店下单**。
 * 门店是否存在 / 启用 / 未闭店，由调用方经 erp-api 与 system 的 DeptApi 校验。
 *
 * @author 亚特
 */
public interface MemberUserStoreApi {

    /**
     * 账号的全部启用授权门店编号
     *
     * @param userId 订货账号编号
     * @return 门店客户编号列表；无授权返回空列表
     */
    List<Long> getStoreIds(Long userId);

    /**
     * 账号的默认门店编号
     *
     * @param userId 订货账号编号
     * @return 默认门店编号；无授权返回 {@code null}
     */
    Long getDefaultStoreId(Long userId);

}