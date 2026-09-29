package com.lxjl.juling.module.trade.convert.order;

import cn.hutool.core.util.BooleanUtil;
import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.framework.common.enums.UserTypeEnum;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.collection.CollectionUtils;
import com.lxjl.juling.framework.common.util.string.StrUtils;
import com.lxjl.juling.framework.dict.core.DictFrameworkUtils;
import com.lxjl.juling.framework.ip.core.utils.AreaUtils;
import com.lxjl.juling.module.member.api.user.dto.MemberUserRespDTO;
import com.lxjl.juling.module.product.api.comment.dto.ProductCommentCreateReqDTO;
import com.lxjl.juling.module.product.api.property.dto.ProductPropertyValueDetailRespDTO;
import com.lxjl.juling.module.product.api.sku.dto.ProductSkuRespDTO;
import com.lxjl.juling.module.product.api.sku.dto.ProductSkuUpdateStockReqDTO;
import com.lxjl.juling.module.product.api.spu.dto.ProductSpuRespDTO;
import com.lxjl.juling.module.promotion.api.combination.dto.CombinationRecordCreateReqDTO;
import com.lxjl.juling.module.trade.api.order.dto.TradeOrderRespDTO;
import com.lxjl.juling.module.trade.controller.admin.base.member.user.MemberUserRespVO;
import com.lxjl.juling.module.trade.controller.admin.base.product.property.ProductPropertyValueDetailRespVO;
import com.lxjl.juling.module.trade.controller.admin.order.vo.*;
import com.lxjl.juling.module.trade.controller.app.base.property.AppProductPropertyValueDetailRespVO;
import com.lxjl.juling.module.trade.controller.app.order.vo.*;
import com.lxjl.juling.module.trade.controller.app.order.vo.item.AppTradeOrderItemCommentCreateReqVO;
import com.lxjl.juling.module.trade.controller.app.order.vo.item.AppTradeOrderItemRespVO;
import com.lxjl.juling.module.trade.dal.dataobject.cart.CartDO;
import com.lxjl.juling.module.trade.dal.dataobject.delivery.DeliveryExpressDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderItemDO;
import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderLogDO;
import com.lxjl.juling.module.trade.enums.order.TradeOrderItemAfterSaleStatusEnum;
import com.lxjl.juling.module.trade.framework.delivery.core.client.dto.ExpressTrackRespDTO;
import com.lxjl.juling.module.trade.framework.order.config.TradeOrderProperties;
import com.lxjl.juling.module.trade.service.price.bo.TradePriceCalculateReqBO;
import com.lxjl.juling.module.trade.service.price.bo.TradePriceCalculateRespBO;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Mappings;
import org.mapstruct.Named;
import org.mapstruct.factory.Mappers;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertMap;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertMultiMap;
import static com.lxjl.juling.framework.common.util.date.LocalDateTimeUtils.addTime;

@Mapper
public interface TradeOrderConvert {

    TradeOrderConvert INSTANCE = Mappers.getMapper(TradeOrderConvert.class);

    @Mappings({
            @Mapping(target = "id", ignore = true),
            @Mapping(source = "userId", target = "userId"),
            @Mapping(source = "createReqVO.couponId", target = "couponId"),
            @Mapping(target = "remark", ignore = true),
            @Mapping(source = "createReqVO.remark", target = "userRemark"),
            @Mapping(source = "calculateRespBO.price.totalPrice", target = "totalPrice"),
            @Mapping(source = "calculateRespBO.price.discountPrice", target = "discountPrice"),
            @Mapping(source = "calculateRespBO.price.deliveryPrice", target = "deliveryPrice"),
            @Mapping(source = "calculateRespBO.price.couponPrice", target = "couponPrice"),
            @Mapping(source = "calculateRespBO.price.pointPrice", target = "pointPrice"),
            @Mapping(source = "calculateRespBO.price.vipPrice", target = "vipPrice"),
            @Mapping(source = "calculateRespBO.price.payPrice", target = "payPrice")
    })
    TradeOrderDO convert(Long userId, AppTradeOrderCreateReqVO createReqVO, TradePriceCalculateRespBO calculateRespBO);

    TradeOrderRespDTO convert(TradeOrderDO orderDO);

    default List<TradeOrderItemDO> convertList(TradeOrderDO tradeOrderDO, TradePriceCalculateRespBO calculateRespBO) {
        return CollectionUtils.convertList(calculateRespBO.getItems(), item -> {
            TradeOrderItemDO orderItem = convert(item);
            orderItem.setOrderId(tradeOrderDO.getId());
            orderItem.setUserId(tradeOrderDO.getUserId());
            orderItem.setAfterSaleStatus(TradeOrderItemAfterSaleStatusEnum.NONE.getStatus());
            orderItem.setCommentStatus(false);
            return orderItem;
        });
    }

    TradeOrderItemDO convert(TradePriceCalculateRespBO.OrderItem item);

    default ProductSkuUpdateStockReqDTO convert(List<TradeOrderItemDO> list) {
        List<ProductSkuUpdateStockReqDTO.Item> items = CollectionUtils.convertList(list, item ->
                new ProductSkuUpdateStockReqDTO.Item().setId(item.getSkuId()).setIncrCount(item.getCount()));
        return new ProductSkuUpdateStockReqDTO(items);
    }

    default ProductSkuUpdateStockReqDTO convertNegative(List<TradeOrderItemDO> list) {
        List<ProductSkuUpdateStockReqDTO.Item> items = CollectionUtils.convertList(list, item ->
                new ProductSkuUpdateStockReqDTO.Item().setId(item.getSkuId()).setIncrCount(-item.getCount()));
        return new ProductSkuUpdateStockReqDTO(items);
    }

    default PageResult<TradeOrderPageItemRespVO> convertPage(PageResult<TradeOrderDO> pageResult,
                                                             List<TradeOrderItemDO> orderItems,
                                                             Map<Long, MemberUserRespDTO> memberUserMap) {
        Map<Long, List<TradeOrderItemDO>> orderItemMap = convertMultiMap(orderItems, TradeOrderItemDO::getOrderId);
        // 转化 List
        List<TradeOrderPageItemRespVO> orderVOs = CollectionUtils.convertList(pageResult.getList(), order -> {
            List<TradeOrderItemDO> xOrderItems = orderItemMap.get(order.getId());
            TradeOrderPageItemRespVO orderVO = convert(order, xOrderItems);
            // 处理收货地址
            orderVO.setReceiverAreaName(AreaUtils.format(order.getReceiverAreaId()));
            // 增加用户信息
            orderVO.setUser(convertUser(memberUserMap.get(orderVO.getUserId())));
            return orderVO;
        });
        return new PageResult<>(orderVOs, pageResult.getTotal());
    }

    MemberUserRespVO convertUser(MemberUserRespDTO memberUserRespDTO);

    TradeOrderPageItemRespVO convert(TradeOrderDO order, List<TradeOrderItemDO> items);

    ProductPropertyValueDetailRespVO convert(ProductPropertyValueDetailRespDTO bean);

    default TradeOrderDetailRespVO convert(TradeOrderDO order, List<TradeOrderItemDO> orderItems,
                                           List<TradeOrderLogDO> orderLogs,
                                           MemberUserRespDTO user) {
        TradeOrderDetailRespVO orderVO = convert2(order, orderItems);
        // 处理收货地址
        orderVO.setReceiverAreaName(AreaUtils.format(order.getReceiverAreaId()));
        // 处理用户信息
        orderVO.setUser(convert(user));
        // 处理日志
        orderVO.setLogs(convertList03(orderLogs));
        return orderVO;
    }
    List<TradeOrderDetailRespVO.OrderLog> convertList03(List<TradeOrderLogDO> orderLogs);

    TradeOrderDetailRespVO convert2(TradeOrderDO order, List<TradeOrderItemDO> items);

    MemberUserRespVO convert(MemberUserRespDTO bean);

    default PageResult<AppTradeOrderPageItemRespVO> convertPage02(PageResult<TradeOrderDO> pageResult,
                                                                  List<TradeOrderItemDO> orderItems) {
        Map<Long, List<TradeOrderItemDO>> orderItemMap = convertMultiMap(orderItems, TradeOrderItemDO::getOrderId);
        // 转化 List
        List<AppTradeOrderPageItemRespVO> orderVOs = CollectionUtils.convertList(pageResult.getList(), order -> {
            List<TradeOrderItemDO> xOrderItems = orderItemMap.get(order.getId());
            return convert02(order, xOrderItems);
        });
        return new PageResult<>(orderVOs, pageResult.getTotal());
    }

    AppTradeOrderPageItemRespVO convert02(TradeOrderDO order, List<TradeOrderItemDO> items);

    AppProductPropertyValueDetailRespVO convert02(ProductPropertyValueDetailRespDTO bean);

    default AppTradeOrderDetailRespVO convert02(TradeOrderDO order, List<TradeOrderItemDO> orderItems,
                                                TradeOrderProperties tradeOrderProperties,
                                                DeliveryExpressDO express) {
        AppTradeOrderDetailRespVO orderVO = convert3(order, orderItems);
        orderVO.setPayExpireTime(order.getCreateTime().plus(tradeOrderProperties.getPayExpireTime()));
        if (StrUtil.isNotEmpty(order.getPayChannelCode())) {
            // 收款渠道名取字典 pay_channel_code（线下收款后不再依赖 pay 模块的常量类）
            orderVO.setPayChannelName(DictFrameworkUtils.parseDictDataLabel("pay_channel_code", order.getPayChannelCode()));
        }
        // 处理收货地址
        orderVO.setReceiverAreaName(AreaUtils.format(order.getReceiverAreaId()));
        if (express != null) {
            orderVO.setLogisticsId(express.getId()).setLogisticsName(express.getName());
        }
        return orderVO;
    }

    AppTradeOrderDetailRespVO convert3(TradeOrderDO order, List<TradeOrderItemDO> items);

    AppTradeOrderItemRespVO convert03(TradeOrderItemDO bean);

    @Mappings({
            @Mapping(target = "skuId", source = "tradeOrderItemDO.skuId"),
            @Mapping(target = "orderId", source = "tradeOrderItemDO.orderId"),
            @Mapping(target = "orderItemId", source = "tradeOrderItemDO.id"),
            @Mapping(target = "descriptionScores", source = "createReqVO.descriptionScores"),
            @Mapping(target = "benefitScores", source = "createReqVO.benefitScores"),
            @Mapping(target = "content", source = "createReqVO.content"),
            @Mapping(target = "picUrls", source = "createReqVO.picUrls"),
            @Mapping(target = "anonymous", source = "createReqVO.anonymous"),
            @Mapping(target = "userId", source = "tradeOrderItemDO.userId")
    })
    ProductCommentCreateReqDTO convert04(AppTradeOrderItemCommentCreateReqVO createReqVO, TradeOrderItemDO tradeOrderItemDO);

    TradePriceCalculateReqBO convert(AppTradeOrderSettlementReqVO settlementReqVO);

    default TradePriceCalculateReqBO convert(Long userId, AppTradeOrderSettlementReqVO settlementReqVO,
                                             List<CartDO> cartList) {
        TradePriceCalculateReqBO reqBO = new TradePriceCalculateReqBO().setUserId(userId)
                .setItems(new ArrayList<>(settlementReqVO.getItems().size()))
                .setCouponId(settlementReqVO.getCouponId()).setPointStatus(settlementReqVO.getPointStatus())
                // 物流信息
                .setDeliveryType(settlementReqVO.getDeliveryType()).setAddressId(settlementReqVO.getAddressId())
                // 各种活动
                .setSeckillActivityId(settlementReqVO.getSeckillActivityId())
                .setBargainRecordId(settlementReqVO.getBargainRecordId())
                .setCombinationActivityId(settlementReqVO.getCombinationActivityId())
                .setCombinationHeadId(settlementReqVO.getCombinationHeadId())
                .setPointActivityId(settlementReqVO.getPointActivityId());
        // 商品项的构建
        Map<Long, CartDO> cartMap = convertMap(cartList, CartDO::getId);
        for (AppTradeOrderSettlementReqVO.Item item : settlementReqVO.getItems()) {
            // 情况一：skuId + count
            if (item.getSkuId() != null) {
                reqBO.getItems().add(new TradePriceCalculateReqBO.Item().setSkuId(item.getSkuId()).setCount(item.getCount())
                        .setSelected(true)); // true 的原因，下单一定选中
                continue;
            }
            // 情况二：cartId
            CartDO cart = cartMap.get(item.getCartId());
            if (cart == null) {
                continue;
            }
            reqBO.getItems().add(new TradePriceCalculateReqBO.Item().setSkuId(cart.getSkuId()).setCount(cart.getCount())
                    .setCartId(item.getCartId()).setSelected(true)); // true 的原因，下单一定选中
        }
        return reqBO;
    }

    default AppTradeOrderSettlementRespVO convert(TradePriceCalculateRespBO calculate) {
        return convert0(calculate);
    }

    /**
     * 会员中心（含会员地址簿）已下线，结算返回不再携带收货地址，address 恒为 null
     */
    @Mapping(target = "address", ignore = true)
    AppTradeOrderSettlementRespVO convert0(TradePriceCalculateRespBO calculate);

    List<AppOrderExpressTrackRespDTO> convertList02(List<ExpressTrackRespDTO> list);

    TradeOrderDO convert(TradeOrderUpdateAddressReqVO reqVO);

    TradeOrderDO convert(TradeOrderUpdatePriceReqVO reqVO);

    TradeOrderDO convert(TradeOrderRemarkReqVO reqVO);

    @Named("convertList04")
    List<TradeOrderRespDTO> convertList04(List<TradeOrderDO> list);

    @Mappings({
            @Mapping(target = "activityId", source = "order.combinationActivityId"),
            @Mapping(target = "spuId", source = "item.spuId"),
            @Mapping(target = "skuId", source = "item.skuId"),
            @Mapping(target = "count", source = "item.count"),
            @Mapping(target = "orderId", source = "order.id"),
            @Mapping(target = "userId", source = "order.userId"),
            @Mapping(target = "headId", source = "order.combinationHeadId"),
            @Mapping(target = "combinationPrice", source = "item.payPrice"),
    })
    CombinationRecordCreateReqDTO convert(TradeOrderDO order, TradeOrderItemDO item);

}
