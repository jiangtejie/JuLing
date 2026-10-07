package com.lxjl.juling.module.erp.dal.dataobject.purchase;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

import java.math.BigDecimal;

/**
 * ERP 供应商 DO
 *
 * @author 亚特
 */
@TableName("erp_supplier")
@KeySequence("erp_supplier_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErpSupplierDO extends BaseDO {

    /**
     * 供应商编号
     */
    @TableId
    private Long id;
    /**
     * 供应商名称
     */
    private String name;
    /**
     * 业务编码（由编码规则统一发号，见 docs/master-data-unified-design.md §4.2；建档后只读）
     */
    private String code;
    /**
     * 联系人
     */
    private String contact;
    /**
     * 手机号码
     */
    private String mobile;
    /**
     * 联系电话
     */
    private String telephone;
    /**
     * 电子邮箱
     */
    private String email;
    /**
     * 传真
     */
    private String fax;
    /**
     * 备注
     */
    private String remark;
    /**
     * 开启状态
     *
     * 枚举 {@link com.lxjl.juling.framework.common.enums.CommonStatusEnum}
     */
    private Integer status;
    /**
     * 排序
     */
    private Integer sort;
    /**
     * 纳税人识别号
     */
    private String taxNo;
    /**
     * 税率
     */
    private BigDecimal taxPercent;
    /**
     * 开户行
     */
    private String bankName;
    /**
     * 开户账号
     */
    private String bankAccount;
    /**
     * 开户地址（银行侧的地址，与 {@link #registeredAddress 注册地址} 是两回事）
     */
    private String bankAddress;

    /**
     * 账户户名（银行账户的开户名称，通常同公司全称）
     */
    private String accountName;
    /**
     * 注册地址（营业执照上的营业地址；开增值税专用发票需要）
     */
    private String registeredAddress;
    /**
     * 结账方式
     *
     * 枚举：MONTHLY 月结 / HALF_MONTH 半月结 / CASH_FIRST 次结(先款后货) / GOODS_FIRST 次结(先货后款)
     * <p>字典 erp_supplier_settlement_type
     */
    private String settlementType;
    /**
     * 账期天数（月结 / 半月结时有意义）
     */
    private Integer creditDays;
    /**
     * 开票情况
     *
     * 枚举：FULL 全额开票 / RATIO 按销售额比例开票 / PLUS_TAX 需加税点 / NONE 不开发票
     * <p>字典 erp_supplier_invoice_mode
     */
    private String invoiceMode;
    /**
     * 开票比例(%)：开票情况为「按销售额比例开票」时填写，如 15~25
     */
    private BigDecimal invoiceRatio;
    /**
     * 开票类型
     *
     * 枚举：VAT_NORMAL 增值税普通发票 / VAT_SPECIAL 增值税专用发票
     * <p>字典 erp_supplier_invoice_type
     */
    private String invoiceType;
    /**
     * 交期时间（天）：下单到到货的承诺天数
     */
    private Integer deliveryDays;
    /**
     * 是否已签订合同
     */
    private Boolean contractSigned;
    /**
     * 合同签订主体（由亚特哪个公司/主体签订）
     */
    private String contractEntity;
    /**
     * 营业执照（文件/图片，多个用逗号分隔）
     */
    private String businessLicenseUrls;
    /**
     * 生产许可证（文件/图片，多个用逗号分隔）
     */
    private String productionLicenseUrls;

}