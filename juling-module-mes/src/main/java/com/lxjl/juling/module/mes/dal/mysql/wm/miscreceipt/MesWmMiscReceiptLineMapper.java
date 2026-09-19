package com.lxjl.juling.module.mes.dal.mysql.wm.miscreceipt;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.mes.controller.admin.wm.miscreceipt.vo.line.MesWmMiscReceiptLinePageReqVO;
import com.lxjl.juling.module.mes.dal.dataobject.wm.miscreceipt.MesWmMiscReceiptLineDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * MES 杂项入库单行 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface MesWmMiscReceiptLineMapper extends BaseMapperX<MesWmMiscReceiptLineDO> {

    default List<MesWmMiscReceiptLineDO> selectListByReceiptId(Long receiptId) {
        return selectList(new LambdaQueryWrapperX<MesWmMiscReceiptLineDO>()
                .eq(MesWmMiscReceiptLineDO::getReceiptId, receiptId)
                .orderByAsc(MesWmMiscReceiptLineDO::getId));
    }

    default int deleteByReceiptId(Long receiptId) {
        return delete(new LambdaQueryWrapperX<MesWmMiscReceiptLineDO>()
                .eq(MesWmMiscReceiptLineDO::getReceiptId, receiptId));
    }

    default PageResult<MesWmMiscReceiptLineDO> selectPage(MesWmMiscReceiptLinePageReqVO pageReqVO) {
        return selectPage(pageReqVO, new LambdaQueryWrapperX<MesWmMiscReceiptLineDO>()
                .eq(MesWmMiscReceiptLineDO::getReceiptId, pageReqVO.getReceiptId())
                .orderByAsc(MesWmMiscReceiptLineDO::getId));
    }

}
