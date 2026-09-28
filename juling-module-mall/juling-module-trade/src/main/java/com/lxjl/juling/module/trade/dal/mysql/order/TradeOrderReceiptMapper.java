package com.lxjl.juling.module.trade.dal.mysql.order;

import com.lxjl.juling.framework.common.pojo.PageParam;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.trade.controller.admin.order.vo.TradeStoreReceiptPageReqVO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderReceiptDO;
import com.lxjl.juling.module.trade.enums.order.TradeStoreReceiptStatusEnum;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 门店收货单 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface TradeOrderReceiptMapper extends BaseMapperX<TradeOrderReceiptDO> {

    default PageResult<TradeOrderReceiptDO> selectPage(TradeStoreReceiptPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<TradeOrderReceiptDO>()
                .likeIfPresent(TradeOrderReceiptDO::getNo, reqVO.getNo())
                .likeIfPresent(TradeOrderReceiptDO::getOrderNo, reqVO.getOrderNo())
                .likeIfPresent(TradeOrderReceiptDO::getSaleOutNo, reqVO.getSaleOutNo())
                .eqIfPresent(TradeOrderReceiptDO::getCustomerId, reqVO.getCustomerId())
                .eqIfPresent(TradeOrderReceiptDO::getDeptId, reqVO.getDeptId())
                .eqIfPresent(TradeOrderReceiptDO::getStatus, reqVO.getStatus())
                .eqIfPresent(TradeOrderReceiptDO::getDiffType, reqVO.getDiffType())
                .betweenIfPresent(TradeOrderReceiptDO::getReceiveTime, reqVO.getReceiveTime())
                .betweenIfPresent(TradeOrderReceiptDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(TradeOrderReceiptDO::getId));
    }

    /**
     * 按收货单号查询（取号后做唯一性兜底校验）
     */
    default TradeOrderReceiptDO selectByNo(String no) {
        return selectOne(TradeOrderReceiptDO::getNo, no);
    }

    /**
     * 按配送出库单查询**有效**收货单（未作废的那一张）
     *
     * 注意必须排除已作废：出库单反审核会把收货单置为「已作废」，之后**重新审核**时
     * 要能再生成一张新的收货单 —— 若把作废单也算作"已有收货单"，重新审核后就永远没有收货单，
     * 门店收不了货、订单卡在「已发货」。
     */
    default TradeOrderReceiptDO selectBySaleOutId(Long saleOutId) {
        if (saleOutId == null) {
            return null;
        }
        return selectOne(new LambdaQueryWrapperX<TradeOrderReceiptDO>()
                .eq(TradeOrderReceiptDO::getSaleOutId, saleOutId)
                .ne(TradeOrderReceiptDO::getStatus, TradeStoreReceiptStatusEnum.CANCELED.getStatus())
                .orderByDesc(TradeOrderReceiptDO::getId)
                .last("LIMIT 1"));
    }

    /**
     * 查询订单的收货单（按 id 倒序，最新一张在前）
     */
    default List<TradeOrderReceiptDO> selectListByOrderId(Long orderId) {
        return selectList(new LambdaQueryWrapperX<TradeOrderReceiptDO>()
                .eq(TradeOrderReceiptDO::getOrderId, orderId)
                .orderByDesc(TradeOrderReceiptDO::getId));
    }

    /**
     * 查询订单当前「有效」的收货单（未作废的那一张）
     */
    default TradeOrderReceiptDO selectValidByOrderId(Long orderId) {
        return selectOne(new LambdaQueryWrapperX<TradeOrderReceiptDO>()
                .eq(TradeOrderReceiptDO::getOrderId, orderId)
                .ne(TradeOrderReceiptDO::getStatus, TradeStoreReceiptStatusEnum.CANCELED.getStatus())
                .orderByDesc(TradeOrderReceiptDO::getId)
                .last("LIMIT 1"));
    }

    /**
     * 会员的待收货分页（H5「待收货」列表）
     *
     * 口径：收货单归属的订货会员 = 下单账号（trade_order.user_id 在建单时快照到 member_user_id），
     * 且收货单处于「待确认」。
     */
    default PageResult<TradeOrderReceiptDO> selectPendingPageByMember(Long memberUserId, Integer pageNo, Integer pageSize) {
        PageParam pageParam = new PageParam();
        pageParam.setPageNo(pageNo);
        pageParam.setPageSize(pageSize);
        return selectPage(pageParam, new LambdaQueryWrapperX<TradeOrderReceiptDO>()
                .eq(TradeOrderReceiptDO::getMemberUserId, memberUserId)
                .eq(TradeOrderReceiptDO::getStatus, TradeStoreReceiptStatusEnum.PENDING.getStatus())
                .orderByDesc(TradeOrderReceiptDO::getId));
    }

}
