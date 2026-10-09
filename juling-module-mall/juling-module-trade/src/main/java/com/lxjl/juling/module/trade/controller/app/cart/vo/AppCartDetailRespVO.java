package com.lxjl.juling.module.trade.controller.app.cart.vo;

import com.lxjl.juling.module.trade.controller.app.base.sku.AppProductSkuBaseRespVO;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

@Schema(description = "用户 App - 用户的购物车明细 Response VO")
@Data
public class AppCartDetailRespVO {

    /**
     * 商品分组数组
     */
    private List<ItemGroup> itemGroups;

    /**
     * 费用
     */
    private Order order;

    @Schema(description = "商品分组") // 多个商品，参加同一个活动，从而形成分组
    @Data
    public static class ItemGroup {

        /**
         * 商品数组
         */
        private List<Sku> items;

    }

    @Schema(description = "商品 SKU")
    @Data
    public static class Sku extends AppProductSkuBaseRespVO {

        /**
         * SPU 信息
         */
        private AppProductSkuBaseRespVO spu;

        // ========== 购物车相关的字段 ==========

        @Schema(description = "商品数量", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
        private Integer count;
        @Schema(description = "是否选中", requiredMode = Schema.RequiredMode.REQUIRED, example = "true")
        private Boolean selected;

        // ========== 价格相关的字段，对应 PriceCalculateRespDTO.OrderItem 的属性 ==========

        // TODO 亚特：后续可以去除一些无用的字段

        @Schema(description = "商品原价（单）", requiredMode = Schema.RequiredMode.REQUIRED, example = "100")
        private Integer originalPrice;
        @Schema(description = "商品原价（总）", requiredMode = Schema.RequiredMode.REQUIRED, example = "200")
        private Integer totalOriginalPrice;
        @Schema(description = "最终购买金额（总）", requiredMode = Schema.RequiredMode.REQUIRED, example = "400")
        private Integer totalPresentPrice;
        @Schema(description = "最终购买金额（单）", requiredMode = Schema.RequiredMode.REQUIRED, example = "500")
        private Integer presentPrice;
        @Schema(description = "应付金额（总）", requiredMode = Schema.RequiredMode.REQUIRED, example = "600")
        private Integer totalPayPrice;

    }

    @Schema(description = "订单") // 对应 PriceCalculateRespDTO.Order 类，用于费用（合计）
    @Data
    public static class Order {

        // TODO 亚特：后续可以去除一些无用的字段

        @Schema(description = "商品原价（总）", requiredMode = Schema.RequiredMode.REQUIRED, example = "100")
        private Integer skuOriginalPrice;
        @Schema(description = "运费金额", requiredMode = Schema.RequiredMode.REQUIRED, example = "400")
        private Integer deliveryPrice;
        @Schema(description = "应付金额（总）", requiredMode = Schema.RequiredMode.REQUIRED, example = "500")
        private Integer payPrice;

    }

}
