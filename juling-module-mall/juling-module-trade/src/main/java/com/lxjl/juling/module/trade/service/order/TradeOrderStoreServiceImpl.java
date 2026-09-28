package com.lxjl.juling.module.trade.service.order;

import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.module.erp.api.customer.ErpCustomerApi;
import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerRespDTO;
import com.lxjl.juling.module.member.api.user.MemberUserApi;
import com.lxjl.juling.module.member.api.user.dto.MemberUserRespDTO;
import com.lxjl.juling.module.trade.enums.order.TradeSettlementModeEnum;
import com.lxjl.juling.module.trade.service.order.bo.TradeOrderStoreBO;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.ORDER_CREATE_FAIL_STORE_NOT_BELONG;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.ORDER_CREATE_FAIL_STORE_NOT_BOUND;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.ORDER_CREATE_FAIL_STORE_NOT_EXISTS;

/**
 * 下单门店解析 Service 实现类
 *
 * @author 亚特
 */
@Service
@Validated
public class TradeOrderStoreServiceImpl implements TradeOrderStoreService {

    @Resource
    private MemberUserApi memberUserApi;
    @Resource
    private ErpCustomerApi erpCustomerApi;

    @Override
    public TradeOrderStoreBO resolveStore(Long userId, Long storeCustomerId) {
        // 1. 校验订货账号已绑定门店（一店三面：账号面）
        MemberUserRespDTO member = memberUserApi.getUser(userId);
        if (member == null || member.getCustomerId() == null) {
            throw exception(ORDER_CREATE_FAIL_STORE_NOT_BOUND);
        }
        // 2. 未指定门店时用账号绑定门店；指定时必须是自身或名下门店（代理切换门店下单）
        Long storeId = storeCustomerId != null ? storeCustomerId : member.getCustomerId();
        if (!Objects.equals(storeId, member.getCustomerId())) {
            List<Long> childIds = erpCustomerApi.getChildCustomerIds(member.getCustomerId());
            if (!childIds.contains(storeId)) {
                throw exception(ORDER_CREATE_FAIL_STORE_NOT_BELONG);
            }
        }
        // 3. 校验门店存在且启用
        ErpCustomerRespDTO store = erpCustomerApi.getCustomer(storeId);
        if (store == null || CommonStatusEnum.isDisable(store.getStatus())) {
            throw exception(ORDER_CREATE_FAIL_STORE_NOT_EXISTS);
        }
        // 4. 组装（部门缺失时回退账号绑定部门）
        TradeOrderStoreBO bo = new TradeOrderStoreBO();
        bo.setCustomerId(store.getId());
        bo.setCustomerName(store.getName());
        bo.setDeptId(store.getDeptId() != null ? store.getDeptId() : member.getDeptId());
        // 代理编号：门店挂在代理下且当前账号不是该门店自身账号时，记为代理下单
        bo.setAgentCustomerId(!Objects.equals(store.getId(), member.getCustomerId())
                ? member.getCustomerId() : store.getParentCustomerId());
        bo.setSettlementMode(store.getSettlementMode() != null
                ? store.getSettlementMode() : TradeSettlementModeEnum.DEFAULT_MODE);
        return bo;
    }

    @Override
    public List<TradeOrderStoreBO> getStoreList(Long userId) {
        // 1. 账号必须绑定门店
        MemberUserRespDTO member = memberUserApi.getUser(userId);
        if (member == null || member.getCustomerId() == null) {
            throw exception(ORDER_CREATE_FAIL_STORE_NOT_BOUND);
        }
        // 2. 可下单门店 = 自身 + 名下门店（代理 → 多门店）
        List<Long> customerIds = new ArrayList<>();
        customerIds.add(member.getCustomerId());
        customerIds.addAll(erpCustomerApi.getChildCustomerIds(member.getCustomerId()));
        List<ErpCustomerRespDTO> customers = erpCustomerApi.getCustomerList(customerIds);
        // 3. 组装（保持自身在首位作为默认门店）
        return customers.stream()
                .filter(customer -> !CommonStatusEnum.isDisable(customer.getStatus()))
                .sorted(Comparator.comparing(customer -> !Objects.equals(customer.getId(), member.getCustomerId())))
                .map(customer -> {
                    TradeOrderStoreBO bo = new TradeOrderStoreBO();
                    bo.setCustomerId(customer.getId());
                    bo.setCustomerName(customer.getName());
                    bo.setDeptId(customer.getDeptId() != null ? customer.getDeptId() : member.getDeptId());
                    bo.setAgentCustomerId(!Objects.equals(customer.getId(), member.getCustomerId())
                            ? member.getCustomerId() : customer.getParentCustomerId());
                    bo.setSettlementMode(customer.getSettlementMode() != null
                            ? customer.getSettlementMode() : TradeSettlementModeEnum.DEFAULT_MODE);
                    return bo;
                }).toList();
    }

}
