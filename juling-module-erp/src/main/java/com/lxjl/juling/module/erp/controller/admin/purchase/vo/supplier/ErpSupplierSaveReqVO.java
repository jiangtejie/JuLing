package com.lxjl.juling.module.erp.controller.admin.purchase.vo.supplier;

import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.framework.common.validation.InEnum;
import com.lxjl.juling.framework.common.validation.Mobile;
import com.lxjl.juling.framework.common.validation.Telephone;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

@Schema(description = "管理后台 - ERP 供应商新增/修改 Request VO")
@Data
public class ErpSupplierSaveReqVO {

    @Schema(description = "供应商编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "17791")
    private Long id;

    @Schema(description = "供应商名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "亚特")
    @NotEmpty(message = "供应商名称不能为空")
    private String name;

    @Schema(description = "联系人", example = "亚特")
    private String contact;

    @Schema(description = "手机号码", example = "15601691300")
    @Mobile
    private String mobile;

    @Schema(description = "联系电话", example = "18818288888")
    @Telephone
    private String telephone;

    @Schema(description = "电子邮箱", example = "76853@qq.com")
    @Email
    private String email;

    @Schema(description = "传真", example = "20 7123 4567")
    private String fax;

    @Schema(description = "备注", example = "你猜")
    private String remark;

    @Schema(description = "开启状态", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "开启状态不能为空")
    @InEnum(value = CommonStatusEnum.class)
    private Integer status;

    @Schema(description = "排序", requiredMode = Schema.RequiredMode.REQUIRED, example = "10")
    @NotNull(message = "排序不能为空")
    private Integer sort;

    @Schema(description = "纳税人识别号", example = "91130803MA098BY05W")
    private String taxNo;

    @Schema(description = "税率", example = "10")
    private BigDecimal taxPercent;

    @Schema(description = "开户行", example = "张三")
    private String bankName;

    @Schema(description = "开户账号", example = "622908212277228617")
    private String bankAccount;

    @Schema(description = "开户地址", example = "兴业银行浦东支行")
    private String bankAddress;

    @Schema(description = "账户户名", example = "重庆彩云西南食品有限公司")
    private String accountName;

    @Schema(description = "注册地址", example = "重庆市渝北区XX路1号")
    private String registeredAddress;

    @Schema(description = "结账方式", example = "MONTHLY")
    private String settlementType;

    @Schema(description = "账期天数", example = "30")
    private Integer creditDays;

    @Schema(description = "开票情况", example = "FULL")
    private String invoiceMode;

    @Schema(description = "开票比例(%)", example = "20.00")
    private BigDecimal invoiceRatio;

    @Schema(description = "开票类型", example = "VAT_SPECIAL")
    private String invoiceType;

    @Schema(description = "交期时间（天）", example = "7")
    private Integer deliveryDays;

    @Schema(description = "是否已签订合同", example = "true")
    private Boolean contractSigned;

    @Schema(description = "合同签订主体", example = "亚特萍姐商贸公司")
    private String contractEntity;

    @Schema(description = "营业执照（文件/图片，逗号分隔）")
    private String businessLicenseUrls;

    @Schema(description = "生产许可证（文件/图片，逗号分隔）")
    private String productionLicenseUrls;

}