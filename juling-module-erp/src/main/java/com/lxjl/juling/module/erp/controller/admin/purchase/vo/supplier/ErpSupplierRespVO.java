package com.lxjl.juling.module.erp.controller.admin.purchase.vo.supplier;

import com.lxjl.juling.framework.excel.core.annotations.DictFormat;
import com.lxjl.juling.framework.excel.core.convert.DictConvert;
import com.lxjl.juling.module.system.enums.DictTypeConstants;
import cn.idev.excel.annotation.ExcelIgnoreUnannotated;
import cn.idev.excel.annotation.ExcelProperty;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Schema(description = "管理后台 - ERP 供应商 Response VO")
@Data
@ExcelIgnoreUnannotated
public class ErpSupplierRespVO {

    @Schema(description = "供应商编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "17791")
    @ExcelProperty("供应商编号")
    private Long id;

    @Schema(description = "供应商名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "亚特")
    @ExcelProperty("供应商名称")
    private String name;

    @Schema(description = "业务编码（编码规则统一发号，建档后只读）", example = "KH000001")
    private String code;

    @Schema(description = "联系人", example = "亚特")
    @ExcelProperty("联系人")
    private String contact;

    @Schema(description = "手机号码", example = "15601691300")
    @ExcelProperty("手机号码")
    private String mobile;

    @Schema(description = "联系电话", example = "18818288888")
    @ExcelProperty("联系电话")
    private String telephone;

    @Schema(description = "电子邮箱", example = "76853@qq.com")
    @ExcelProperty("电子邮箱")
    private String email;

    @Schema(description = "传真", example = "20 7123 4567")
    @ExcelProperty("传真")
    private String fax;

    @Schema(description = "备注", example = "你猜")
    @ExcelProperty("备注")
    private String remark;

    @Schema(description = "开启状态", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @ExcelProperty(value = "开启状态", converter = DictConvert.class)
    @DictFormat(DictTypeConstants.COMMON_STATUS)
    private Integer status;

    @Schema(description = "排序", requiredMode = Schema.RequiredMode.REQUIRED, example = "10")
    @ExcelProperty("排序")
    private Integer sort;

    @Schema(description = "纳税人识别号", example = "91130803MA098BY05W")
    @ExcelProperty("纳税人识别号")
    private String taxNo;

    @Schema(description = "税率", example = "10")
    @ExcelProperty("税率")
    private BigDecimal taxPercent;

    @Schema(description = "开户行", example = "张三")
    @ExcelProperty("开户行")
    private String bankName;

    @Schema(description = "开户账号", example = "622908212277228617")
    @ExcelProperty("开户账号")
    private String bankAccount;

    @Schema(description = "开户地址", example = "兴业银行浦东支行")
    @ExcelProperty("开户地址")
    private String bankAddress;

    @Schema(description = "账户户名")
    @ExcelProperty("账户户名")
    private String accountName;

    @Schema(description = "注册地址")
    @ExcelProperty("注册地址")
    private String registeredAddress;

    @Schema(description = "结账方式")
    @ExcelProperty("结账方式")
    private String settlementType;

    @Schema(description = "账期天数")
    @ExcelProperty("账期天数")
    private Integer creditDays;

    @Schema(description = "开票情况")
    @ExcelProperty("开票情况")
    private String invoiceMode;

    @Schema(description = "开票比例(%)")
    @ExcelProperty("开票比例(%)")
    private BigDecimal invoiceRatio;

    @Schema(description = "开票类型")
    @ExcelProperty("开票类型")
    private String invoiceType;

    @Schema(description = "交期时间(天)")
    @ExcelProperty("交期时间(天)")
    private Integer deliveryDays;

    @Schema(description = "是否已签订合同")
    @ExcelProperty("是否已签订合同")
    private Boolean contractSigned;

    @Schema(description = "合同签订主体")
    @ExcelProperty("合同签订主体")
    private String contractEntity;

    @Schema(description = "营业执照")
    @ExcelProperty("营业执照")
    private String businessLicenseUrls;

    @Schema(description = "生产许可证")
    @ExcelProperty("生产许可证")
    private String productionLicenseUrls;

    @Schema(description = "创建时间", requiredMode = Schema.RequiredMode.REQUIRED)
    @ExcelProperty("创建时间")
    private LocalDateTime createTime;

}
