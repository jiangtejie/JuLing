package com.lxjl.juling.module.erp.controller.admin.purchase;

import com.lxjl.juling.framework.apilog.core.annotation.ApiAccessLog;
import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.common.pojo.PageParam;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.framework.excel.core.util.ExcelUtils;
import com.lxjl.juling.module.erp.controller.admin.purchase.vo.price.ErpPurchasePriceMatchRespVO;
import com.lxjl.juling.module.erp.controller.admin.purchase.vo.price.ErpPurchasePricePageReqVO;
import com.lxjl.juling.module.erp.controller.admin.purchase.vo.price.ErpPurchasePriceRespVO;
import com.lxjl.juling.module.erp.controller.admin.purchase.vo.price.ErpPurchasePriceSaveReqVO;
import com.lxjl.juling.module.erp.controller.admin.product.vo.product.ErpProductRespVO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchasePriceDO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpPurchasePriceItemDO;
import com.lxjl.juling.module.erp.dal.dataobject.purchase.ErpSupplierDO;
import com.lxjl.juling.module.erp.service.product.ErpProductService;
import com.lxjl.juling.module.erp.service.purchase.ErpPurchasePriceService;
import com.lxjl.juling.module.erp.service.purchase.ErpSupplierService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import static com.lxjl.juling.framework.apilog.core.enums.OperateTypeEnum.EXPORT;
import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.pojo.CommonResult.success;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.*;
import static com.lxjl.juling.module.erp.enums.ErrorCodeConstants.PURCHASE_PRICE_NOT_EXISTS;

@Tag(name = "管理后台 - ERP 采购价目表")
@RestController
@RequestMapping("/erp/purchase-price")
@Validated
public class ErpPurchasePriceController {

    @Resource
    private ErpPurchasePriceService purchasePriceService;
    @Resource
    private ErpSupplierService supplierService;
    @Resource
    private ErpProductService productService;

    @PostMapping("/create")
    @Operation(summary = "创建采购价目表")
    @PreAuthorize("@ss.hasPermission('erp:purchase-price:create')")
    public CommonResult<Long> createPurchasePrice(@Valid @RequestBody ErpPurchasePriceSaveReqVO createReqVO) {
        return success(purchasePriceService.createPurchasePrice(createReqVO));
    }

    @PutMapping("/update")
    @Operation(summary = "更新采购价目表", description = "明细整体替换（先删后插）")
    @PreAuthorize("@ss.hasPermission('erp:purchase-price:update')")
    public CommonResult<Boolean> updatePurchasePrice(@Valid @RequestBody ErpPurchasePriceSaveReqVO updateReqVO) {
        purchasePriceService.updatePurchasePrice(updateReqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除采购价目表")
    @Parameter(name = "id", description = "编号", required = true)
    @PreAuthorize("@ss.hasPermission('erp:purchase-price:delete')")
    public CommonResult<Boolean> deletePurchasePrice(@RequestParam("id") Long id) {
        purchasePriceService.deletePurchasePrice(id);
        return success(true);
    }

    @DeleteMapping("/delete-list")
    @Operation(summary = "批量删除采购价目表")
    @Parameter(name = "ids", description = "编号列表", required = true)
    @PreAuthorize("@ss.hasPermission('erp:purchase-price:delete')")
    public CommonResult<Boolean> deletePurchasePriceList(@RequestParam("ids") List<Long> ids) {
        purchasePriceService.deletePurchasePriceList(ids);
        return success(true);
    }

    @GetMapping("/get")
    @Operation(summary = "获得采购价目表（含明细）")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('erp:purchase-price:query')")
    public CommonResult<ErpPurchasePriceRespVO> getPurchasePrice(@RequestParam("id") Long id) {
        ErpPurchasePriceDO price = purchasePriceService.getPurchasePrice(id);
        if (price == null) {
            throw exception(PURCHASE_PRICE_NOT_EXISTS);
        }
        ErpPurchasePriceRespVO vo = BeanUtils.toBean(price, ErpPurchasePriceRespVO.class);
        fillSupplierName(List.of(vo));
        // 明细 + 物料信息
        List<ErpPurchasePriceItemDO> items = purchasePriceService.getPurchasePriceItemList(id);
        List<ErpPurchasePriceRespVO.Item> itemVOs = BeanUtils.toBean(items, ErpPurchasePriceRespVO.Item.class);
        fillProductInfo(itemVOs);
        vo.setItems(itemVOs);
        vo.setItemCount(itemVOs.size());
        return success(vo);
    }

    @GetMapping("/page")
    @Operation(summary = "获得采购价目表分页")
    @PreAuthorize("@ss.hasPermission('erp:purchase-price:query')")
    public CommonResult<PageResult<ErpPurchasePriceRespVO>> getPurchasePricePage(@Valid ErpPurchasePricePageReqVO pageReqVO) {
        PageResult<ErpPurchasePriceDO> pageResult = purchasePriceService.getPurchasePricePage(pageReqVO);
        PageResult<ErpPurchasePriceRespVO> result = BeanUtils.toBean(pageResult, ErpPurchasePriceRespVO.class);
        fillSupplierName(result.getList());
        // 行数：一次查回所有价目表的明细，避免 N+1
        if (result.getList().size() > 0) {
            Map<Long, List<ErpPurchasePriceItemDO>> itemMap = convertMultiMap(
                    purchasePriceService.getPurchasePriceItemListByPriceIds(
                            convertList(result.getList(), ErpPurchasePriceRespVO::getId)),
                    ErpPurchasePriceItemDO::getPriceId);
            result.getList().forEach(vo -> vo.setItemCount(
                    itemMap.getOrDefault(vo.getId(), List.of()).size()));
        }
        return success(result);
    }

    @GetMapping("/export-excel")
    @Operation(summary = "导出采购价目表 Excel")
    @PreAuthorize("@ss.hasPermission('erp:purchase-price:export')")
    @ApiAccessLog(operateType = EXPORT)
    public void exportPurchasePriceExcel(@Valid ErpPurchasePricePageReqVO pageReqVO,
                                        HttpServletResponse response) throws IOException {
        pageReqVO.setPageSize(PageParam.PAGE_SIZE_NONE);
        List<ErpPurchasePriceDO> list = purchasePriceService.getPurchasePricePage(pageReqVO).getList();
        List<ErpPurchasePriceRespVO> vos = BeanUtils.toBean(list, ErpPurchasePriceRespVO.class);
        fillSupplierName(vos);
        ExcelUtils.write(response, "采购价目表.xls", "数据", ErpPurchasePriceRespVO.class, vos);
    }

    @GetMapping("/match")
    @Operation(summary = "取价", description = "按「供应商 + 物料 + 数量 + 日期」取适用单价与税率；价目表没命中时兜底取物料主数据上的采购价")
    public CommonResult<ErpPurchasePriceMatchRespVO> matchPrice(
            @RequestParam(value = "supplierId", required = false) Long supplierId,
            @RequestParam("productId") Long productId,
            @RequestParam(value = "quantity", required = false) BigDecimal quantity,
            @RequestParam(value = "date", required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate date) {
        // 故意不加 @PreAuthorize：这是采购订单录入时的辅助取价，与 simple-list 同性质，
        // 若要求 erp:purchase-price:query 会导致只有订单权限的采购员取不到价
        return success(purchasePriceService.matchPrice(supplierId, productId, quantity, date));
    }

    /** 补供应商名（通用价目表留空） */
    private void fillSupplierName(List<ErpPurchasePriceRespVO> list) {
        if (list.isEmpty()) {
            return;
        }
        Map<Long, ErpSupplierDO> supplierMap = convertMap(
                supplierService.getSupplierList(convertSet(list, ErpPurchasePriceRespVO::getSupplierId)),
                ErpSupplierDO::getId);
        list.forEach(vo -> {
            ErpSupplierDO supplier = supplierMap.get(vo.getSupplierId());
            if (supplier != null) {
                vo.setSupplierName(supplier.getName());
            }
        });
    }

    /** 补物料编码 / 名称 / 计价单位（计价单位取物料的单位，见 sql/local/65 的设计说明） */
    private void fillProductInfo(List<ErpPurchasePriceRespVO.Item> items) {
        if (items.isEmpty()) {
            return;
        }
        Map<Long, ErpProductRespVO> productMap = productService.getProductVOMap(
                convertSet(items, ErpPurchasePriceRespVO.Item::getProductId));
        items.forEach(item -> {
            ErpProductRespVO product = productMap.get(item.getProductId());
            if (product == null) {
                return;
            }
            item.setProductCode(product.getCode());
            item.setProductName(product.getName());
            item.setUnitName(product.getUnitName());
            // 含税单价是计算值，不落库（见 sql/local/65 的设计说明）
            if (item.getPrice() != null) {
                BigDecimal rate = item.getTaxPercent() == null ? BigDecimal.ZERO : item.getTaxPercent();
                item.setTaxPrice(item.getPrice()
                        .multiply(BigDecimal.ONE.add(rate.divide(BigDecimal.valueOf(100)))));
            }
        });
    }

}
