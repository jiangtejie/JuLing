package com.lxjl.juling.module.trade.dal.mysql.order;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderReceiptItemDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

/**
 * 门店收货单明细 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface TradeOrderReceiptItemMapper extends BaseMapperX<TradeOrderReceiptItemDO> {

    default List<TradeOrderReceiptItemDO> selectListByReceiptId(Long receiptId) {
        return selectList(new LambdaQueryWrapperX<TradeOrderReceiptItemDO>()
                .eq(TradeOrderReceiptItemDO::getReceiptId, receiptId)
                .orderByAsc(TradeOrderReceiptItemDO::getId));
    }

    default List<TradeOrderReceiptItemDO> selectListByReceiptIds(Collection<Long> receiptIds) {
        return selectList(new LambdaQueryWrapperX<TradeOrderReceiptItemDO>()
                .in(TradeOrderReceiptItemDO::getReceiptId, receiptIds)
                .orderByAsc(TradeOrderReceiptItemDO::getId));
    }

}
