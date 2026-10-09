package com.lxjl.juling.module.trade.service.order;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.trade.controller.admin.workbench.vo.TradeOrderWorkbenchItemRespVO;
import com.lxjl.juling.module.trade.controller.admin.workbench.vo.TradeOrderWorkbenchPageReqVO;
import com.lxjl.juling.module.trade.controller.admin.workbench.vo.TradeOrderWorkbenchPushReqVO;
import com.lxjl.juling.module.trade.controller.admin.workbench.vo.TradeOrderWorkbenchPushRespVO;
import com.lxjl.juling.module.trade.controller.admin.workbench.vo.TradeOrderWorkbenchRespVO;

import java.util.List;

/**
 * 订单工作台 Service（中心库操作中枢）
 *
 * 门店订货链 S2 切片一：要货单审核通过后不直接变成出库单，而是先在工作台逐行分料：
 * 统配 → 配送出库单；直拨 → 采购订单（供应商直送门店）。下推幂等由单据平台 bill_relation 保证。
 *
 * @author 亚特
 */
public interface TradeOrderWorkbenchService {

    /**
     * 待处理要货单分页（待发货 + 审核通过/直营免审 + 存在未分料行）
     */
    PageResult<TradeOrderWorkbenchRespVO> getWorkbenchPage(TradeOrderWorkbenchPageReqVO pageReqVO);

    /**
     * 要货单明细行（含物料分料属性、已下推情况、可下推数量）
     *
     * @param orderId 要货单编号
     */
    List<TradeOrderWorkbenchItemRespVO> getWorkbenchItemList(Long orderId);

    /**
     * 分料下推：按行生成 ERP 配送出库单 / 采购订单
     *
     * @param pushReqVO 下推请求
     * @return 各行的目标单据
     */
    TradeOrderWorkbenchPushRespVO pushDown(TradeOrderWorkbenchPushReqVO pushReqVO);

}
