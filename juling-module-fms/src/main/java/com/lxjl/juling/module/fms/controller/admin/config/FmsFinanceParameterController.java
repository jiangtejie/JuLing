package com.lxjl.juling.module.fms.controller.admin.config;

import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.fms.controller.admin.config.vo.financeparameter.FmsFinanceParameterRespVO;
import com.lxjl.juling.module.fms.controller.admin.config.vo.financeparameter.FmsFinanceParameterUpdateReqVO;
import com.lxjl.juling.module.fms.dal.dataobject.config.FmsFinanceParameterDO;
import com.lxjl.juling.module.fms.service.config.FmsFinanceParameterService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import static com.lxjl.juling.framework.common.pojo.CommonResult.success;
import static com.lxjl.juling.framework.security.core.util.SecurityFrameworkUtils.getLoginUserId;

@Tag(name = "管理后台 - FMS 财务参数")
@RestController
@RequestMapping("/fms/config/finance-parameter")
@Validated
public class FmsFinanceParameterController {

    @Resource
    private FmsFinanceParameterService financeParameterService;

    @GetMapping("/get")
    @Operation(summary = "获得财务参数")
    @Parameter(name = "accountSetId", description = "账套编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('fms:config:finance-parameter:query')")
    public CommonResult<FmsFinanceParameterRespVO> getFinanceParameter(
            @RequestParam("accountSetId") Long accountSetId) {
        FmsFinanceParameterDO financeParameter = financeParameterService.getFinanceParameter(
                accountSetId, getLoginUserId());
        return success(BeanUtils.toBean(financeParameter, FmsFinanceParameterRespVO.class));
    }

    @PutMapping("/update")
    @Operation(summary = "更新财务参数")
    @PreAuthorize("@ss.hasPermission('fms:config:finance-parameter:update')")
    public CommonResult<Boolean> updateFinanceParameter(
            @Valid @RequestBody FmsFinanceParameterUpdateReqVO updateReqVO) {
        financeParameterService.updateFinanceParameter(updateReqVO, getLoginUserId());
        return success(true);
    }

}
