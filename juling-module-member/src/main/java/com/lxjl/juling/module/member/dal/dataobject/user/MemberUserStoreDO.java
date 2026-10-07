package com.lxjl.juling.module.member.dal.dataobject.user;

import com.lxjl.juling.framework.tenant.core.db.TenantBaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

/**
 * 订货账号「授权门店」DO
 *
 * <p>回答一个且只回答一个问题：**这个账号能给哪些门店下单**。
 * 加盟店账号只有一条授权；片区订货管理人（业务口中的「代理人」，只是帮忙下单）有多条。
 *
 * <p>刻意不在这里放「所属部门」—— 账号没有部门，部门是门店的属性（system_dept 的门店节点）。
 * 也刻意不放「所属客户」—— 账号没有自己的经营主体，它有的是一组授权门店。
 *
 * @author 亚特
 */
@TableName("member_user_store")
@KeySequence("member_user_store_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MemberUserStoreDO extends TenantBaseDO {

    /**
     * 编号
     */
    @TableId
    private Long id;
    /**
     * 订货账号编号
     *
     * 关联 {@link MemberUserDO#getId()}
     */
    private Long userId;
    /**
     * 被授权门店（erp_customer.id）
     *
     * 必须是组织架构里的门店节点（system_dept.dept_type = STORE）且未闭店。
     */
    private Long customerId;
    /**
     * 是否账号默认门店（H5 首次进入用它）
     */
    private Boolean isDefault;
    /**
     * 显示顺序
     */
    private Integer sort;
    /**
     * 状态
     *
     * 枚举 {@link com.lxjl.juling.framework.common.enums.CommonStatusEnum}
     */
    private Integer status;

}