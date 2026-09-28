package com.lxjl.juling.module.erp.api.customer.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * ERP 客户（门店 / 代理）Response DTO
 *
 * 供其它模块读取门店归属与结算信息，避免跨模块直连表。
 *
 * @author 亚特
 */
@Data
public class ErpCustomerRespDTO {

    /**
     * 客户编号
     */
    private Long id;
    /**
     * 客户名称（门店名）
     */
    private String name;
    /**
     * 联系人
     */
    private String contact;
    /**
     * 手机号码
     */
    private String mobile;
    /**
     * 开启状态
     */
    private Integer status;

    /**
     * 所属部门（门店节点，system_dept.id）
     */
    private Long deptId;
    /**
     * 上级代理客户编号（代理 → 多门店）
     */
    private Long parentCustomerId;
    /**
     * 店型：DIRECT 直营 / FRANCHISE 加盟
     */
    private String storeType;
    /**
     * 结算模式：PREPAID 先款后货 / MONTHLY 月结
     */
    private String settlementMode;
    /**
     * 账期天数
     */
    private Integer creditDays;
    /**
     * 信用额度
     */
    private BigDecimal creditLimit;

}
