package com.lxjl.juling.module.erp.dal.mysql.stock;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.erp.controller.admin.stock.vo.record.ErpStockRecordPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockRecordDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * ERP 物料库存明细 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface ErpStockRecordMapper extends BaseMapperX<ErpStockRecordDO> {

    default PageResult<ErpStockRecordDO> selectPage(ErpStockRecordPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<ErpStockRecordDO>()
                .eqIfPresent(ErpStockRecordDO::getProductId, reqVO.getProductId())
                .eqIfPresent(ErpStockRecordDO::getWarehouseId, reqVO.getWarehouseId())
                .eqIfPresent(ErpStockRecordDO::getBizType, reqVO.getBizType())
                .likeIfPresent(ErpStockRecordDO::getBizNo, reqVO.getBizNo())
                .betweenIfPresent(ErpStockRecordDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(ErpStockRecordDO::getId));
    }

    /**
     * 按来源（业务类型 + 业务项）查询流水：出库按 FIFO 拆批后，这里会返回「一行一批次」的多条记录
     */
    default List<ErpStockRecordDO> selectListByBizItem(Integer bizType, Long bizItemId) {
        return selectList(new LambdaQueryWrapperX<ErpStockRecordDO>()
                .eq(ErpStockRecordDO::getBizType, bizType)
                .eq(ErpStockRecordDO::getBizItemId, bizItemId)
                .orderByAsc(ErpStockRecordDO::getId));
    }

}