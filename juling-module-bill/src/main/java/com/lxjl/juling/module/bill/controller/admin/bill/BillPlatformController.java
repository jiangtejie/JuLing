package com.lxjl.juling.module.bill.controller.admin.bill;

import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.bill.api.BillPlatformApi;
import com.lxjl.juling.module.bill.dal.dataobject.BillLogDO;
import com.lxjl.juling.module.bill.dal.dataobject.BillTypeDO;
import com.lxjl.juling.module.bill.dal.mysql.BillLogMapper;
import com.lxjl.juling.module.bill.dal.mysql.BillTypeMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

import static com.lxjl.juling.framework.common.pojo.CommonResult.success;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;

/**
 * 管理后台 - 单据平台
 *
 * 单据类型注册表、单据关联（上溯下推）、单据操作日志的只读查询。
 *
 * @author 亚特
 */
@Tag(name = "管理后台 - 单据平台")
@RestController
@RequestMapping("/bill/platform")
public class BillPlatformController {

    @Resource
    private BillTypeMapper billTypeMapper;
    @Resource
    private BillLogMapper billLogMapper;
    @Resource
    private BillPlatformApi billPlatformApi;

    @PreAuthorize("@ss.hasPermission('bill:platform:query')")
    @GetMapping("/type-list")
    @Operation(summary = "获得单据类型清单")
    public CommonResult<List<BillTypeDO>> getTypeList() {
        return success(billTypeMapper.selectList());
    }

    @PreAuthorize("@ss.hasPermission('bill:platform:query')")
    @GetMapping("/type")
    @Operation(summary = "获得单据类型配置")
    @Parameter(name = "code", description = "单据类型编码", required = true, example = "PURCHASE_ORDER")
    public CommonResult<Object> getType(@RequestParam("code") String code) {
        return success(billPlatformApi.getType(code));
    }

    @PreAuthorize("@ss.hasPermission('bill:platform:query')")
    @GetMapping("/relation/downstream")
    @Operation(summary = "获得下游单据（我下推了谁）")
    public CommonResult<Object> getDownstream(@RequestParam("sourceType") String sourceType,
                                              @RequestParam("sourceId") Long sourceId) {
        return success(billPlatformApi.getDownstreamList(sourceType, sourceId));
    }

    @PreAuthorize("@ss.hasPermission('bill:platform:query')")
    @GetMapping("/relation/upstream")
    @Operation(summary = "获得上游单据（我是谁下推来的）")
    public CommonResult<Object> getUpstream(@RequestParam("targetType") String targetType,
                                            @RequestParam("targetId") Long targetId) {
        return success(billPlatformApi.getUpstreamList(targetType, targetId));
    }

    @PreAuthorize("@ss.hasPermission('bill:platform:query')")
    @GetMapping("/log/list")
    @Operation(summary = "获得单据操作日志")
    public CommonResult<List<BillLogDO>> getLogList(@RequestParam("billType") String billType,
                                                    @RequestParam(value = "billId", required = false) Long billId) {
        return success(billLogMapper.selectList(new LambdaQueryWrapperX<BillLogDO>()
                .eq(BillLogDO::getBillType, billType)
                .eqIfPresent(BillLogDO::getBillId, billId)
                .orderByDesc(BillLogDO::getId)));
    }

    @PreAuthorize("@ss.hasPermission('bill:platform:query')")
    @GetMapping("/ext/list")
    @Operation(summary = "获得单据扩展字段")
    public CommonResult<Map<String, String>> getExtList(@RequestParam("billType") String billType,
                                                        @RequestParam("billId") Long billId) {
        return success(billPlatformApi.getExtMap(billType, billId));
    }

}
