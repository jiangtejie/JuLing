package com.lxjl.juling.module.erp.service.stock;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.erp.controller.admin.stock.vo.record.ErpStockRecordPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockRecordDO;
import com.lxjl.juling.module.erp.service.stock.bo.ErpStockRecordCreateReqBO;
import jakarta.validation.Valid;

import java.util.List;

/**
 * ERP 物料库存明细 Service 接口
 *
 * @author 亚特
 */
public interface ErpStockRecordService {

    /**
     * 获得物料库存明细
     *
     * @param id 编号
     * @return 物料库存明细
     */
    ErpStockRecordDO getStockRecord(Long id);

    /**
     * 获得物料库存明细分页
     *
     * @param pageReqVO 分页查询
     * @return 物料库存明细分页
     */
    PageResult<ErpStockRecordDO> getStockRecordPage(ErpStockRecordPageReqVO pageReqVO);

    /**
     * 创建库存明细
     *
     * @param createReqBO 创建库存明细 BO
     */
    void createStockRecord(@Valid ErpStockRecordCreateReqBO createReqBO);

    /**
     * 按来源（业务类型 + 业务项）查询库存流水
     *
     * 批次库存用来做「反审核冲销」：出库按 FIFO 拆批后，一行流水对应一个批次。
     *
     * @param bizType   业务类型
     * @param bizItemId 业务项编号
     * @return 流水列表（按 id 升序，即发生顺序）
     */
    List<ErpStockRecordDO> getStockRecordListByBizItem(Integer bizType, Long bizItemId);

}