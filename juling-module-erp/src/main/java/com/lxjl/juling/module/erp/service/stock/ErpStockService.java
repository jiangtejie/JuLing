package com.lxjl.juling.module.erp.service.stock;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.erp.controller.admin.stock.vo.stock.ErpStockPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockDO;

import java.math.BigDecimal;

/**
 * ERP 物料库存 Service 接口
 *
 * @author 亚特
 */
public interface ErpStockService {

    /**
     * 获得物料库存
     *
     * @param id 编号
     * @return 库存
     */
    ErpStockDO getStock(Long id);

    /**
     * 基于物料 + 仓库，获得物料库存
     *
     * @param productId 物料编号
     * @param warehouseId 仓库编号
     * @return 物料库存
     */
    ErpStockDO getStock(Long productId, Long warehouseId);

    /**
     * 获得物料库存数量
     *
     * 如果不存在库存记录，则返回 0
     *
     * @param productId 物料编号
     * @return 物料库存数量
     */
    BigDecimal getStockCount(Long productId);

    /**
     * 获得物料库存分页
     *
     * @param pageReqVO 分页查询
     * @return 库存分页
     */
    PageResult<ErpStockDO> getStockPage(ErpStockPageReqVO pageReqVO);

    /**
     * 增量更新物料库存数量
     *
     * @param productId 物料编号
     * @param warehouseId 仓库编号
     * @param count 增量数量：正数，表示增加；负数，表示减少
     * @return 更新后的库存
     */
    BigDecimal updateStockCountIncrement(Long productId, Long warehouseId, BigDecimal count);

}