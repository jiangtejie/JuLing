package com.lxjl.juling.module.trade.controller.admin.workbench;

import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.trade.controller.admin.workbench.vo.TradeOrderWorkbenchItemRespVO;
import com.lxjl.juling.module.trade.controller.admin.workbench.vo.TradeOrderWorkbenchPageReqVO;
import com.lxjl.juling.module.trade.controller.admin.workbench.vo.TradeOrderWorkbenchPushReqVO;
import com.lxjl.juling.module.trade.controller.admin.workbench.vo.TradeOrderWorkbenchPushRespVO;
import com.lxjl.juling.module.trade.controller.admin.workbench.vo.TradeOrderWorkbenchRespVO;
import com.lxjl.juling.module.trade.service.order.TradeOrderWorkbenchService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

import static com.lxjl.juling.framework.common.pojo.CommonResult.success;

/**
 * 管理后台 - 订单工作台（中心库操作中枢）
 *
 * 门店订货链 S2 切片一：要货单审核通过后在这里逐行分料并下推 ERP 单据。
 *
 * @author 亚特
 */
@Tag(name = "管理后台 - 订单工作台")
@RestController
@RequestMapping("/trade/workbench")
@Validated
public class TradeOrderWorkbenchController {

    @Resource
    private TradeOrderWorkbenchService tradeOrderWorkbenchService;

    @GetMapping("/page")
    @Operation(summary = "获得待处理要货单分页", description = "待发货 + 审核通过（直营免审）+ 存在未分料行")
    @PreAuthorize("@ss.hasPermission('trade:workbench:query')")
    public CommonResult<PageResult<TradeOrderWorkbenchRespVO>> getWorkbenchPage(TradeOrderWorkbenchPageReqVO pageReqVO) {
        return success(tradeOrderWorkbenchService.getWorkbenchPage(pageReqVO));
    }

    @GetMapping("/get-items")
    @Operation(summary = "获得要货单明细行", description = "含物料分料属性（允许统配/允许直拨）、已下推情况与可下推数量")
    @Parameter(name = "orderId", description = "要货单编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('trade:workbench:query')")
    public CommonResult<List<TradeOrderWorkbenchItemRespVO>> getWorkbenchItemList(@RequestParam("orderId") Long orderId) {
        return success(tradeOrderWorkbenchService.getWorkbenchItemList(orderId));
    }

    @PostMapping("/push")
    @Operation(summary = "分料下推", description = "统配生成配送出库单（XSCK…），直拨生成采购订单（CGDD…）；同一行重复下推会被拒绝")
    @PreAuthorize("@ss.hasPermission('trade:workbench:push')")
    public CommonResult<TradeOrderWorkbenchPushRespVO> pushDown(@Valid @RequestBody TradeOrderWorkbenchPushReqVO pushReqVO) {
        return success(tradeOrderWorkbenchService.pushDown(pushReqVO));
    }

}
