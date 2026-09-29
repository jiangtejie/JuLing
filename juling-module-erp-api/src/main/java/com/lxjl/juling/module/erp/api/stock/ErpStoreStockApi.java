package com.lxjl.juling.module.erp.api.stock;

import com.lxjl.juling.module.erp.api.stock.dto.ErpStoreReceiptInReqDTO;
import com.lxjl.juling.module.erp.api.stock.dto.ErpStoreStockSummaryRespDTO;

import java.util.List;

/**
 * ERP 门店库存 API（门店收货入库 / 冲销 / 门店库存汇总）
 *
 * 背景（见 docs/store-receipt-and-receivables-design.md）：
 *   · 一店一仓 —— 每个门店客户对应一个「门店仓」（erp_warehouse.warehouse_type = STORE）；
 *   · 配送出库（中心库 → 门店）审核后，门店在 H5 确认收货，实收数量按批次记入门店仓，
 *     门店仓的库存因此可以直接复用库存中心（erp_stock_batch 四态 + 效期 + FIFO 成本）；
 *   · 门店仓入库以「收货单行」为幂等键（bizType = STORE_RECEIPT，bizItemId = 收货单行 id），
 *     同一行重复提交只入账一次；作废收货单按同一来源项冲销。
 *
 * 其它模块（商城/门店要货）**只能**通过本接口写门店库存，不允许直接操作 erp_stock_batch。
 *
 * @author 亚特
 */
public interface ErpStoreStockApi {

    /**
     * 门店仓编号（按门店客户查）
     *
     * @param customerId 门店客户编号
     * @return 门店仓编号；该门店没有门店仓时返回 null
     */
    Long getStoreWarehouseId(Long customerId);

    /**
     * 门店仓名称
     */
    String getStoreWarehouseName(Long customerId);

    /**
     * 门店收货入库：按收货单行把实收数量记入门店仓（按来源项幂等）
     *
     * @param reqDTO 收货入库请求（实收数量 <= 0 的行会被跳过）
     */
    void receiveStoreReceipt(ErpStoreReceiptInReqDTO reqDTO);

    /**
     * 冲销门店收货入库（收货单作废时调用）：按来源项幂等
     *
     * @param receiptItemId 收货单行编号
     * @param bizNo         收货单号（写流水用）
     * @return 是否发生冲销
     */
    boolean reverseStoreReceipt(Long receiptItemId, String bizNo);

    /**
     * 门店库存汇总（按门店客户；customerId 为空时返回全部门店仓）
     */
    List<ErpStoreStockSummaryRespDTO> getStoreStockSummary(Long customerId);

}
