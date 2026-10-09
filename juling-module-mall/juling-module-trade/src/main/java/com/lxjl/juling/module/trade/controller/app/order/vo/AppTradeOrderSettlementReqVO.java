package com.lxjl.juling.module.trade.controller.app.order.vo;

import com.lxjl.juling.framework.common.validation.InEnum;
import com.lxjl.juling.framework.common.validation.Mobile;
import com.lxjl.juling.module.trade.enums.delivery.DeliveryTypeEnum;
import com.fasterxml.jackson.annotation.JsonIgnore;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Schema(description = "用户 App - 交易订单结算 Request VO")
@Data
@Valid
public class AppTradeOrderSettlementReqVO {

    @Schema(description = "商品项数组", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotEmpty(message = "商品不能为空")
    private List<Item> items;

    // ========== 门店订货链：下单门店 ==========
    @Schema(description = "下单门店客户编号（代理账号切换门店时传；不传则使用账号绑定门店）", example = "1")
    private Long storeCustomerId;

    // ========== 配送相关相关字段 ==========
    @Schema(description = "配送方式", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @InEnum(value = DeliveryTypeEnum.class, message = "配送方式不正确")
    private Integer deliveryType;

    // 会员中心（含会员地址簿）已下线，恒为空、不再消费；仅为兼容 H5 保留字段
    @Schema(description = "收件地址编号（会员中心已下线，恒为空）", example = "1")
    private Long addressId;

    @Schema(description = "收件人名称", example = "亚特")
    private String receiverName;
    @Schema(description = "收件人手机", example = "15601691300")
    @Mobile(message = "收件人手机格式不正确")
    private String receiverMobile;
    @Schema(description = "收件详细地址", example = "重庆市江北区xx路 1 号") // 未选择收件地址时，手填的收货详细地址
    private String receiverDetailAddress;

    @Data
    @Schema(description = "用户 App - 商品项")
    @Valid
    public static class Item {

        @Schema(description = "商品 SKU 编号", example = "2048")
        @NotNull(message = "商品 SKU 编号不能为空")
        private Long skuId;

        @Schema(description = "购买数量", example = "1")
        @Min(value = 1, message = "购买数量最小值为 {value}")
        private Integer count;

        @Schema(description = "购物车项的编号", example = "1024")
        private Long cartId;

        @AssertTrue(message = "商品不正确")
        @JsonIgnore
        public boolean isValid() {
            // 组合一：skuId + count 使用商品 SKU
            if (skuId != null && count != null) {
                return true;
            }
            // 组合二：cartId 使用购物车项
            return cartId != null;
        }

    }

}
