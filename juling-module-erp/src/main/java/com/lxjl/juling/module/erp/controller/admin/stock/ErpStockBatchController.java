package com.lxjl.juling.module.erp.controller.admin.stock;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.collection.MapUtils;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.erp.api.stock.ErpStoreStockApi;
import com.lxjl.juling.module.erp.api.stock.dto.ErpStoreStockSummaryRespDTO;
import com.lxjl.juling.module.erp.controller.admin.product.vo.product.ErpProductRespVO;
import com.lxjl.juling.module.erp.controller.admin.stock.vo.batch.ErpStockBatchPageReqVO;
import com.lxjl.juling.module.erp.controller.admin.stock.vo.batch.ErpStockBatchRespVO;
import com.lxjl.juling.module.erp.controller.admin.stock.vo.batch.ErpStockBatchStateReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockBatchDO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpWarehouseDO;
import com.lxjl.juling.module.erp.service.product.ErpProductService;
import com.lxjl.juling.module.erp.service.stock.ErpStockBatchService;
import com.lxjl.juling.module.erp.service.stock.ErpWarehouseService;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockAvailableRespBO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockBatchStateReqBO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import static com.lxjl.juling.framework.common.pojo.CommonResult.success;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertSet;

/**
 * 管理后台 - ERP 批次库存（库存中心 · 多状态 + 批次/效期）
 *
 * 可用量口径：在仓 − 占用 + 在途。
 *
 * @author 亚特
 */
@Tag(name = "管理后台 - ERP 批次库存")
@RestController
@RequestMapping("/erp/stock-batch")
@Validated
public class ErpStockBatchController {

    /**
     * 无有效期
     */
    private static final String EXPIRY_NONE = "NONE";
    /**
     * 已过期
     */
    private static final String EXPIRY_EXPIRED = "EXPIRED";
    /**
     * 临期
     */
    private static final String EXPIRY_WARNING = "WARNING";
    /**
     * 正常
     */
    private static final String EXPIRY_NORMAL = "NORMAL";

    @Resource
    private ErpStockBatchService stockBatchService;

    @Resource
    private ErpProductService productService;
    @Resource
    private ErpWarehouseService warehouseService;
    @Resource
    private ErpStoreStockApi storeStockApi;

    @GetMapping("/page")
    @Operation(summary = "获得批次库存分页")
    @PreAuthorize("@ss.hasPermission('erp:stock:query')")
    public CommonResult<PageResult<ErpStockBatchRespVO>> getBatchPage(@Valid ErpStockBatchPageReqVO pageReqVO) {
        // 门店库存页（按门店过滤）：先解析出该门店的门店仓，再交给批次库存分页
        if (pageReqVO.getCustomerId() != null) {
            Long storeWarehouseId = storeStockApi.getStoreWarehouseId(pageReqVO.getCustomerId());
            if (storeWarehouseId == null) {
                return success(PageResult.empty());
            }
            pageReqVO.setWarehouseIds(List.of(storeWarehouseId));
        }
        // 门店库存页：按仓库类型（STORE 门店仓 / CENTER 中心库）先解析出仓库编号集合，
        // 再交给批次库存分页；没有匹配的仓库时直接返回空页，避免生成非法的 IN () 语句。
        if (CollUtil.isEmpty(pageReqVO.getWarehouseIds()) && StrUtil.isNotBlank(pageReqVO.getWarehouseType())) {
            List<Long> warehouseIds = warehouseService.getWarehouseListByType(pageReqVO.getWarehouseType())
                    .stream().map(ErpWarehouseDO::getId).toList();
            if (warehouseIds.isEmpty()) {
                return success(PageResult.empty());
            }
            pageReqVO.setWarehouseIds(warehouseIds);
        }
        PageResult<ErpStockBatchDO> pageResult = stockBatchService.getBatchPage(pageReqVO);
        return success(buildVOPageResult(pageResult));
    }

    @GetMapping("/store-summary")
    @Operation(summary = "获得门店库存汇总（一店一仓，按门店客户）")
    @Parameter(name = "customerId", description = "门店客户编号；不传=全部门店", example = "6")
    @PreAuthorize("@ss.hasPermission('erp:stock:store:query')")
    public CommonResult<List<ErpStoreStockSummaryRespDTO>> getStoreSummary(
            @RequestParam(value = "customerId", required = false) Long customerId) {
        return success(storeStockApi.getStoreStockSummary(customerId));
    }

    @GetMapping("/list")
    @Operation(summary = "获得批次列表（按 FIFO 顺序：先入库先出，同入库日期先到期先出）")
    @Parameter(name = "onlyPositive", description = "是否只要在仓数量大于 0 的批次", example = "true")
    @PreAuthorize("@ss.hasPermission('erp:stock:query')")
    public CommonResult<List<ErpStockBatchRespVO>> getBatchList(@RequestParam("warehouseId") Long warehouseId,
                                                               @RequestParam("productId") Long productId,
                                                               @RequestParam(value = "onlyPositive", required = false, defaultValue = "true") Boolean onlyPositive) {
        List<ErpStockBatchDO> list = stockBatchService.getBatchList(warehouseId, productId, onlyPositive);
        return success(buildVOList(list));
    }

    @GetMapping("/available")
    @Operation(summary = "获得可用量：在仓 − 占用 + 在途")
    @PreAuthorize("@ss.hasPermission('erp:stock:query')")
    public CommonResult<BigDecimal> getAvailableCount(@RequestParam("warehouseId") Long warehouseId,
                                                     @RequestParam("productId") Long productId) {
        return success(stockBatchService.getAvailableCount(warehouseId, productId));
    }

    @GetMapping("/available-map")
    @Operation(summary = "批量获得可用量与四态数量")
    @PreAuthorize("@ss.hasPermission('erp:stock:query')")
    public CommonResult<Map<Long, ErpStockAvailableRespBO>> getAvailableMap(@RequestParam("warehouseId") Long warehouseId,
                                                                           @RequestParam("productIds") Collection<Long> productIds) {
        return success(stockBatchService.getAvailableSummaryMap(warehouseId, productIds));
    }

    @GetMapping("/expiry-list")
    @Operation(summary = "获得临期 / 过期批次列表")
    @Parameter(name = "warnDays", description = "临期预警天数，默认 30", example = "30")
    @Parameter(name = "expiredOnly", description = "true 只列已过期；false 列出已过期 + 临期", example = "false")
    @PreAuthorize("@ss.hasPermission('erp:stock:query')")
    public CommonResult<List<ErpStockBatchRespVO>> getExpiryList(@RequestParam(value = "warehouseId", required = false) Long warehouseId,
                                                                 @RequestParam(value = "productId", required = false) Long productId,
                                                                 @RequestParam(value = "warnDays", required = false) Integer warnDays,
                                                                 @RequestParam(value = "expiredOnly", required = false) Boolean expiredOnly) {
        List<ErpStockBatchDO> list = stockBatchService.getExpiryBatchList(warehouseId, productId, warnDays, expiredOnly);
        return success(buildVOList(list));
    }

    @PostMapping("/update-state")
    @Operation(summary = "登记批次状态数量（在途 / 占用 / 待检）")
    @PreAuthorize("@ss.hasPermission('erp:stock:update')")
    public CommonResult<ErpStockBatchRespVO> updateState(@Valid @RequestBody ErpStockBatchStateReqVO reqVO) {
        ErpStockBatchDO batch = stockBatchService.updateStateCount(new ErpStockBatchStateReqBO()
                .setWarehouseId(reqVO.getWarehouseId()).setProductId(reqVO.getProductId())
                .setBatchNo(reqVO.getBatchNo()).setState(reqVO.getState())
                .setDelta(reqVO.getDelta()).setRemark(reqVO.getRemark()));
        return success(buildVOList(List.of(batch)).get(0));
    }

    // ==================== 组装 VO ====================

    private PageResult<ErpStockBatchRespVO> buildVOPageResult(PageResult<ErpStockBatchDO> pageResult) {
        if (pageResult == null || pageResult.getList() == null || pageResult.getList().isEmpty()) {
            return PageResult.empty(pageResult == null ? 0 : pageResult.getTotal());
        }
        return new PageResult<>(buildVOList(pageResult.getList()), pageResult.getTotal());
    }

    private List<ErpStockBatchRespVO> buildVOList(List<ErpStockBatchDO> list) {
        if (list == null || list.isEmpty()) {
            return List.of();
        }
        Map<Long, ErpProductRespVO> productMap = productService.getProductVOMap(
                convertSet(list, ErpStockBatchDO::getProductId));
        Map<Long, ErpWarehouseDO> warehouseMap = warehouseService.getWarehouseMap(
                convertSet(list, ErpStockBatchDO::getWarehouseId));
        LocalDate today = LocalDate.now();
        return BeanUtils.toBean(list, ErpStockBatchRespVO.class, vo -> {
            MapUtils.findAndThen(productMap, vo.getProductId(), product -> vo.setProductName(product.getName()));
            MapUtils.findAndThen(warehouseMap, vo.getWarehouseId(), warehouse -> vo.setWarehouseName(warehouse.getName()));
            // 可用量 = 在仓 − 占用 + 在途
            vo.setAvailableCount(nvl(vo.getCount()).subtract(nvl(vo.getOccupiedCount())).add(nvl(vo.getTransitCount())));
            vo.setExpiryStatus(resolveExpiryStatus(vo.getExpiryDate(), today));
            vo.setExpiryDays(vo.getExpiryDate() == null ? null : ChronoUnit.DAYS.between(today, vo.getExpiryDate()));
        });
    }

    private String resolveExpiryStatus(LocalDate expiryDate, LocalDate today) {
        if (expiryDate == null) {
            return EXPIRY_NONE;
        }
        if (expiryDate.isBefore(today)) {
            return EXPIRY_EXPIRED;
        }
        // 临期口径与查询一致：默认 30 天
        return expiryDate.isAfter(today.plusDays(30)) ? EXPIRY_NORMAL : EXPIRY_WARNING;
    }

    private static BigDecimal nvl(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }

}
