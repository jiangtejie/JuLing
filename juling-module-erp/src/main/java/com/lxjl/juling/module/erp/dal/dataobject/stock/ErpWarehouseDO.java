package com.lxjl.juling.module.erp.dal.dataobject.stock;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

import java.math.BigDecimal;

/**
 * ERP 仓库 DO
 *
 * @author 亚特
 */
@TableName("erp_warehouse")
@KeySequence("erp_warehouse_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErpWarehouseDO extends BaseDO {

    /**
     * 仓库编号
     */
    @TableId
    private Long id;
    /**
     * 仓库名称
     */
    private String name;
    /**
     * 业务编码（由编码规则统一发号，见 docs/master-data-unified-design.md §4.2；建档后只读）
     */
    private String code;
    /**
     * 仓库地址
     */
    private String address;
    /**
     * 排序
     */
    private Long sort;
    /**
     * 备注
     */
    private String remark;
    /**
     * 负责人
     */
    private String principal;
    /**
     * 仓储费，单位：元
     */
    private BigDecimal warehousePrice;
    /**
     * 搬运费，单位：元
     */
    private BigDecimal truckagePrice;
    /**
     * 开启状态
     *
     * 枚举 {@link com.lxjl.juling.framework.common.enums.CommonStatusEnum}
     */
    private Integer status;
    /**
     * 是否默认
     */
    private Boolean defaultStatus;
    /**
     * 仓库类型：CENTER 中心库 / STORE 门店仓
     *
     * 门店仓由 sql/local/38 脚本按「一店一仓」自动生成，承载门店收货后的门店库存账。
     */
    private String warehouseType;
    /**
     * 门店客户编号（erp_customer.id）；中心库为空
     */
    private Long storeCustomerId;
    /**
     * 门店部门编号（system_dept.id）；中心库为空
     */
    private Long deptId;

}