package com.lxjl.juling.module.trade.controller.app.storeaccount;

import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.erp.api.customer.ErpCustomerAccountApi;
import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerAccountDetailRespDTO;
import com.lxjl.juling.module.erp.api.customer.dto.ErpCustomerAccountSummaryRespDTO;
import com.lxjl.juling.module.trade.service.order.TradeOrderStoreService;
import com.lxjl.juling.module.trade.service.order.bo.TradeOrderStoreBO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.pojo.CommonResult.success;
import static com.lxjl.juling.framework.security.core.util.SecurityFrameworkUtils.getLoginUserId;
import static com.lxjl.juling.module.trade.enums.ErrorCodeConstants.ORDER_CREATE_FAIL_STORE_NOT_BELONG;

/**
 * 用户 App - 门店往来（我的账）
 *
 * 门店在 H5 自助查看「欠总部多少 / 已付多少 / 余款多少」以及逐笔明细，
 * 解决「余款只能翻转账截图、明细查不到」的老问题。
 *
 * 可见范围 = 当前账号**可下单的门店**（门店账号只有自己；代理人账号是名下所有门店），
 * 指定 customerId 时也会校验它在这个范围内，避免越权看到别家门店的账。
 * 台账只读：数据由业务动作（配送出库审核、收款核验、收货差异）自动产生，前端不提供任何写入入口。
 *
 * @author 亚特
 */
@Tag(name = "用户 App - 门店往来")
@RestController
@RequestMapping("/trade/store-account")
@Validated
public class AppStoreAccountController {

    @Resource
    private TradeOrderStoreService tradeOrderStoreService;
    @Resource
    private ErpCustomerAccountApi erpCustomerAccountApi;

    @GetMapping("/summary")
    @Operation(summary = "获得我的门店往来汇总（累计应收 / 累计已收 / 当前余额）")
    public CommonResult<List<ErpCustomerAccountSummaryRespDTO>> getSummary() {
        return success(erpCustomerAccountApi.getSummaryList(getStoreCustomerIds()));
    }

    @GetMapping("/page")
    @Operation(summary = "获得门店往来明细分页")
    @Parameter(name = "customerId", description = "门店客户编号；不传=我名下全部门店", example = "6")
    public CommonResult<PageResult<ErpCustomerAccountDetailRespDTO>> getPage(
            @RequestParam(value = "customerId", required = false) Long customerId,
            @RequestParam(value = "pageNo", required = false) Integer pageNo,
            @RequestParam(value = "pageSize", required = false) Integer pageSize) {
        List<Long> storeCustomerIds = getStoreCustomerIds();
        if (customerId != null) {
            if (!storeCustomerIds.contains(customerId)) {
                throw exception(ORDER_CREATE_FAIL_STORE_NOT_BELONG);
            }
            storeCustomerIds = List.of(customerId);
        }
        return success(erpCustomerAccountApi.getAccountPage(storeCustomerIds, pageNo, pageSize));
    }

    /**
     * 当前账号可下单的门店编号（复用下单时的同一套归属解析：门店账号=自己，代理人账号=名下门店）
     */
    private List<Long> getStoreCustomerIds() {
        return tradeOrderStoreService.getStoreList(getLoginUserId()).stream()
                .map(TradeOrderStoreBO::getCustomerId).toList();
    }

}
