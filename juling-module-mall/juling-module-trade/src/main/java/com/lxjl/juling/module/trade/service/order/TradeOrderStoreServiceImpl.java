package com.lxjl.juling.module.trade.service.order;

import cn.hutool.core.collection.CollUtil;
import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.module.erp.api.customer.ErpCustomerApi;
import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerRespDTO;
import com.lxjl.juling.module.member.api.user.MemberUserStoreApi;
import com.lxjl.juling.module.system.api.dept.DeptApi;
import com.lxjl.juling.module.system.api.dept.dto.DeptRespDTO;
import com.lxjl.juling.module.system.enums.dept.DeptBusinessStatusEnum;
import com.lxjl.juling.module.system.enums.dept.DeptTypeEnum;
import com.lxjl.juling.module.trade.service.order.bo.TradeOrderStoreBO;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.ORDER_CREATE_FAIL_STORE_NOT_BELONG;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.ORDER_CREATE_FAIL_STORE_NOT_BOUND;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.ORDER_CREATE_FAIL_STORE_REQUIRED;

/**
 * 下单门店解析 Service 实现类
 *
 * @author 亚特
 */
@Service
@Validated
public class TradeOrderStoreServiceImpl implements TradeOrderStoreService {

    @Resource
    private MemberUserStoreApi memberUserStoreApi;
    @Resource
    private ErpCustomerApi erpCustomerApi;
    @Resource
    private DeptApi deptApi;

    @Override
    public TradeOrderStoreBO resolveStore(Long userId, Long storeCustomerId) {
        List<ErpCustomerRespDTO> stores = getAuthorizedStores(userId);
        ErpCustomerRespDTO store;
        if (storeCustomerId == null) {
            // 只有一家授权门店 = 加盟店账号，直接用；多家 = 片区订货管理人，必须显式选，
            // 否则「把 A 店的货下到 B 店」——门店订货方反馈过的真实问题
            if (stores.size() > 1) {
                throw exception(ORDER_CREATE_FAIL_STORE_REQUIRED);
            }
            store = stores.get(0);
        } else {
            store = stores.stream()
                    .filter(item -> Objects.equals(item.getId(), storeCustomerId))
                    .findFirst()
                    .orElseThrow(() -> exception(ORDER_CREATE_FAIL_STORE_NOT_BELONG));
        }
        return TradeOrderStoreBO.of(store, null);
    }

    @Override
    public List<TradeOrderStoreBO> getStoreList(Long userId) {
        Long defaultStoreId = memberUserStoreApi.getDefaultStoreId(userId);
        return getAuthorizedStores(userId).stream()
                .map(store -> TradeOrderStoreBO.of(store, defaultStoreId))
                .toList();
    }

    @Override
    public boolean isFranchiseStore(Long customerId) {
        if (customerId == null) {
            return false;
        }
        ErpCustomerRespDTO customer = erpCustomerApi.getCustomer(customerId);
        return customer != null && "FRANCHISE".equals(customer.getStoreType());
    }

    /**
     * 账号的**可用**授权门店
     *
     * <p>三道过滤，任一不满足即不可下单：
     * <ol>
     *   <li>账号有授权（无授权直接报错，不是返回空列表 —— 空列表会让 H5 显示成「没有可下单门店」而无从排查）；</li>
     *   <li>门店主数据存在且启用；</li>
     *   <li>门店挂在组织架构的**门店**节点上，且**未闭店**（已确认口径，见组织架构设计 §7）。</li>
     * </ol>
     */
    private List<ErpCustomerRespDTO> getAuthorizedStores(Long userId) {
        List<Long> storeIds = memberUserStoreApi.getStoreIds(userId);
        if (CollUtil.isEmpty(storeIds)) {
            throw exception(ORDER_CREATE_FAIL_STORE_NOT_BOUND);
        }
        List<ErpCustomerRespDTO> stores = erpCustomerApi.getCustomerList(storeIds).stream()
                .filter(item -> !CommonStatusEnum.isDisable(item.getStatus()))
                .toList();
        if (CollUtil.isEmpty(stores)) {
            throw exception(ORDER_CREATE_FAIL_STORE_NOT_BOUND);
        }
        Set<Long> deptIds = stores.stream().map(ErpCustomerRespDTO::getDeptId)
                .filter(Objects::nonNull).collect(Collectors.toSet());
        Map<Long, DeptRespDTO> deptMap = deptApi.getDeptMap(deptIds);
        List<ErpCustomerRespDTO> openStores = stores.stream()
                .filter(item -> isOpenStore(deptMap.get(item.getDeptId())))
                .toList();
        if (CollUtil.isEmpty(openStores)) {
            throw exception(ORDER_CREATE_FAIL_STORE_NOT_BOUND);
        }
        return openStores;
    }

    /**
     * 是否「可下单的门店」：组织架构里类型为门店，且未闭店
     */
    private boolean isOpenStore(DeptRespDTO dept) {
        return dept != null
                && DeptTypeEnum.STORE.getType().equals(dept.getDeptType())
                && !DeptBusinessStatusEnum.CLOSED.getStatus().equals(dept.getBusinessStatus());
    }

}