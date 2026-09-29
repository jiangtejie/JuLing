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
        // 2. 解析下单门店。账号绑定的「订货主体」有两种口径：
        //    · 没有下级 → 门店账号，只能给自己下单（未指定门店时默认就是它）；
        //    · 有下级   → 代理人账号，可给名下门店下单，但**代理本身不是收货门店**，
        //                 所以必须显式选择，不能默认把订单挂到代理头上。
        List<Long> childIds = erpCustomerApi.getChildCustomerIds(member.getCustomerId());
        boolean agentAccount = !childIds.isEmpty();
        Long storeId;
        if (storeCustomerId != null) {
            if (agentAccount && Objects.equals(storeCustomerId, member.getCustomerId())) {
                throw exception(ORDER_CREATE_FAIL_STORE_REQUIRED);
            }
            if (!Objects.equals(storeCustomerId, member.getCustomerId()) && !childIds.contains(storeCustomerId)) {
                throw exception(ORDER_CREATE_FAIL_STORE_NOT_BELONG);
            }
            storeId = storeCustomerId;
        } else {
            if (agentAccount) {
                throw exception(ORDER_CREATE_FAIL_STORE_REQUIRED);
            }
            storeId = member.getCustomerId();
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
        bo.setStoreType(store.getStoreType());
        return bo;
    }

    @Override
    public boolean isFranchiseStore(Long customerId) {
        if (customerId == null) {
            return false;
        }
        ErpCustomerRespDTO customer = erpCustomerApi.getCustomer(customerId);
        return customer != null && "FRANCHISE".equals(customer.getStoreType());
    }

    @Override
    public List<TradeOrderStoreBO> getStoreList(Long userId) {
        // 1. 账号必须绑定门店
        MemberUserRespDTO member = memberUserApi.getUser(userId);
        if (member == null || member.getCustomerId() == null) {
            throw exception(ORDER_CREATE_FAIL_STORE_NOT_BOUND);
        }
        // 2. 可下单门店：
        //    · 门店账号（绑定的订货主体没有下级）→ 只有自己；
        //    · 代理人账号（有下级）→ 只列名下门店。**代理本身不出现在列表里**：
        //      代理是管理主体，不收货、不结算配送，把它当成可下单门店会让订单挂错主体。
        List<Long> childIds = erpCustomerApi.getChildCustomerIds(member.getCustomerId());
        List<Long> customerIds = childIds.isEmpty()
                ? List.of(member.getCustomerId()) : new ArrayList<>(childIds);
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
                    bo.setStoreType(customer.getStoreType());
                    return bo;
                }).toList();
    }

}
