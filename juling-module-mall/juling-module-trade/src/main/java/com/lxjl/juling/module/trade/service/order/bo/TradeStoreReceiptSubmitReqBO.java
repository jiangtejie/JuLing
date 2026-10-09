package com.lxjl.juling.module.trade.service.order.bo;

import lombok.Data;
import lombok.experimental.Accessors;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * 门店确认收货 - 提交 BO（H5 门店端与后台代录共用）
 *
 * @author 亚特
 */
@Data
@Accessors(chain = true)
public class TradeStoreReceiptSubmitReqBO {

    /**
     * 门店要货单编号
     */
    private Long orderId;
    /**
     * 收货人
     */
    private String receiverName;
    /**
     * 收货人手机号
     */
    private String receiverMobile;
    /**
     * 收货凭证图片
     */
    private List<String> fileUrls;
    /**
     * 备注
     */
    private String remark;
    /**
     * 操作人（登录会员 / 后台管理员），用于写订单日志与收货单留痕
     */
    private Long operatorUserId;
    /**
     * 操作人类型，枚举 {@link com.lxjl.juling.framework.common.enums.UserTypeEnum}
     */
    private Integer operatorUserType;
    /**
     * 收货明细（为空表示「全部按应收数量收货」）
     */
    private List<Item> items;

    /**
     * 收货明细行
     */
    @Data
    @Accessors(chain = true)
    public static class Item {

        /**
         * 门店要货单行编号
         */
        private Long orderItemId;
        /**
         * 实收数量
         */
        private BigDecimal receiptCount;
        /**
         * 差异原因（实收 ≠ 应收时必填）
         */
        private String diffReason;
        /**
         * 批次号
         */
        private String batchNo;
        /**
         * 生产日期
         */
        private LocalDate productionDate;
        /**
         * 到期日期
         */
        private LocalDate expiryDate;
        /**
         * 备注
         */
        private String remark;

    }

}
