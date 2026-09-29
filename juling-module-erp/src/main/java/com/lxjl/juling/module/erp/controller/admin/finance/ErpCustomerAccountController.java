package com.lxjl.juling.module.erp.controller.admin.finance;

import cn.hutool.core.collection.CollUtil;
import com.lxjl.juling.framework.apilog.core.annotation.ApiAccessLog;
import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.common.pojo.PageParam;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.collection.MapUtils;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.framework.excel.core.util.ExcelUtils;
import com.lxjl.juling.module.erp.api.customer.enums.CustomerAccountBizTypeEnum;
import com.lxjl.juling.module.erp.controller.admin.finance.vo.customeraccount.ErpCustomerAccountPageReqVO;
import com.lxjl.juling.module.erp.controller.admin.finance.vo.customeraccount.ErpCustomerAccountRespVO;
import com.lxjl.juling.module.erp.controller.admin.finance.vo.customeraccount.ErpCustomerAccountSummaryRespVO;
import com.lxjl.juling.module.erp.dal.dataobject.finance.ErpCustomerAccountDO;
import com.lxjl.juling.module.erp.dal.dataobject.sale.ErpCustomerDO;
import com.lxjl.juling.module.erp.service.finance.ErpCustomerAccountService;
import com.lxjl.juling.module.erp.service.finance.bo.ErpCustomerAccountSummaryBO;
import com.lxjl.juling.module.erp.service.sale.ErpCustomerService;
import com.lxjl.juling.module.system.api.dept.DeptApi;
import com.lxjl.juling.module.system.api.dept.dto.DeptRespDTO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import static com.lxjl.juling.framework.apilog.core.enums.OperateTypeEnum.EXPORT;
import static com.lxjl.juling.framework.common.pojo.CommonResult.success;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertMap;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertSet;

/**
 * 管理后台 - 门店往来台账（门店应收 / 收款 / 差异调整）
 *
 * 口径：金额正数 = 门店欠总部增加，负数 = 减少；余额 = 该门店全部记账之和。
 * 本控制器只提供查询与导出 —— 台账由业务动作（配送出库审核、收款核验、门店收货差异）自动产生，
 * 不允许后台手工改数，保证「账实一致、逐笔可回溯」。
 *
 * @author 亚特
 */
@Tag(name = "管理后台 - ERP 门店往来台账")
@RestController
@RequestMapping("/erp/customer-account")
@Validated
public class ErpCustomerAccountController {

    @Resource
    private ErpCustomerAccountService customerAccountService;

    @Resource
    private ErpCustomerService customerService;
    @Resource
    private DeptApi deptApi;

    @GetMapping("/page")
    @Operation(summary = "获得门店往来台账分页")
    @PreAuthorize("@ss.hasPermission('erp:customer-account:query')")
    public CommonResult<PageResult<ErpCustomerAccountRespVO>> getPage(@Valid ErpCustomerAccountPageReqVO pageReqVO) {
        PageResult<ErpCustomerAccountDO> pageResult = customerAccountService.getPage(pageReqVO);
        return success(new PageResult<>(buildVOList(pageResult.getList()), pageResult.getTotal()));
    }

    @GetMapping("/summary")
    @Operation(summary = "获得门店往来余额汇总")
    @Parameter(name = "customerId", description = "门店客户编号", example = "6")
    @Parameter(name = "deptId", description = "门店部门编号", example = "134")
    @PreAuthorize("@ss.hasPermission('erp:customer-account:query')")
    public CommonResult<List<ErpCustomerAccountSummaryRespVO>> getSummary(
            @RequestParam(value = "customerId", required = false) Long customerId,
            @RequestParam(value = "deptId", required = false) Long deptId) {
        List<ErpCustomerAccountSummaryBO> list = customerAccountService.getSummaryList(customerId, deptId);
        if (CollUtil.isEmpty(list)) {
            return success(List.of());
        }
        Map<Long, ErpCustomerDO> customerMap = convertMap(
                customerService.getCustomerList(convertSet(list, ErpCustomerAccountSummaryBO::getCustomerId)),
                ErpCustomerDO::getId);
        Map<Long, DeptRespDTO> deptMap = deptApi.getDeptMap(convertSet(list, ErpCustomerAccountSummaryBO::getDeptId));
        return success(BeanUtils.toBean(list, ErpCustomerAccountSummaryRespVO.class, vo -> {
            MapUtils.findAndThen(customerMap, vo.getCustomerId(), customer -> vo.setCustomerName(customer.getName()));
            MapUtils.findAndThen(deptMap, vo.getDeptId(), dept -> vo.setDeptName(dept.getName()));
        }));
    }

    @GetMapping("/balance")
    @Operation(summary = "获得门店往来余额")
    @Parameter(name = "customerId", description = "门店客户编号", required = true, example = "6")
    @PreAuthorize("@ss.hasPermission('erp:customer-account:query')")
    public CommonResult<BigDecimal> getBalance(@RequestParam("customerId") Long customerId) {
        return success(customerAccountService.getBalance(customerId));
    }

    @GetMapping("/export-excel")
    @Operation(summary = "导出门店往来台账 Excel")
    @PreAuthorize("@ss.hasPermission('erp:customer-account:export')")
    @ApiAccessLog(operateType = EXPORT)
    public void exportExcel(@Valid ErpCustomerAccountPageReqVO exportReqVO,
                           HttpServletResponse response) throws IOException {
        exportReqVO.setPageSize(PageParam.PAGE_SIZE_NONE);
        List<ErpCustomerAccountDO> list = customerAccountService.getPage(exportReqVO).getList();
        ExcelUtils.write(response, "门店往来台账.xlsx", "数据", ErpCustomerAccountRespVO.class, buildVOList(list));
    }

    // ==================== 组装 VO ====================

    private List<ErpCustomerAccountRespVO> buildVOList(List<ErpCustomerAccountDO> list) {
        if (CollUtil.isEmpty(list)) {
            return List.of();
        }
        Map<Long, ErpCustomerDO> customerMap = convertMap(
                customerService.getCustomerList(convertSet(list, ErpCustomerAccountDO::getCustomerId)),
                ErpCustomerDO::getId);
        Map<Long, DeptRespDTO> deptMap = deptApi.getDeptMap(convertSet(list, ErpCustomerAccountDO::getDeptId));
        return BeanUtils.toBean(list, ErpCustomerAccountRespVO.class, vo -> {
            MapUtils.findAndThen(customerMap, vo.getCustomerId(), customer -> vo.setCustomerName(customer.getName()));
            MapUtils.findAndThen(deptMap, vo.getDeptId(), dept -> vo.setDeptName(dept.getName()));
            Arrays.stream(CustomerAccountBizTypeEnum.values())
                    .filter(item -> item.getType().equals(vo.getBizType()))
                    .findFirst()
                    .ifPresent(item -> vo.setBizTypeName(item.getName()));
        });
    }

}
