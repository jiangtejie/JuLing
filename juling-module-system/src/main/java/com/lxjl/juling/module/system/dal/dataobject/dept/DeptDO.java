package com.lxjl.juling.module.system.dal.dataobject.dept;

import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.framework.tenant.core.db.TenantBaseDO;
import com.lxjl.juling.module.system.dal.dataobject.user.AdminUserDO;
import com.lxjl.juling.module.system.enums.dept.DeptBusinessStatusEnum;
import com.lxjl.juling.module.system.enums.dept.DeptTypeEnum;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 部门表
 *
 * @author 亚特
 * @author 亚特
 */
@TableName("system_dept")
@KeySequence("system_dept_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
public class DeptDO extends TenantBaseDO {

    public static final Long PARENT_ID_ROOT = 0L;

    /**
     * 部门ID
     */
    @TableId
    private Long id;
    /**
     * 部门名称
     */
    private String name;
    /**
     * 父部门ID
     *
     * 关联 {@link #id}
     */
    private Long parentId;
    /**
     * 显示顺序
     */
    private Integer sort;
    /**
     * 负责人
     *
     * 关联 {@link AdminUserDO#getId()}
     */
    private Long leaderUserId;
    /**
     * 联系电话
     */
    private String phone;
    /**
     * 邮箱
     */
    private String email;
    /**
     * 部门状态
     *
     * 枚举 {@link CommonStatusEnum}
     */
    private Integer status;

    /**
     * 节点类型：组织 / 门店
     *
     * 枚举 {@link DeptTypeEnum}
     */
    private String deptType;
    /**
     * 营业状态（仅门店有意义）；组织节点恒为「营业」
     *
     * 枚举 {@link DeptBusinessStatusEnum}
     */
    private Integer businessStatus;
    /**
     * 闭店时间（复开时清空）
     */
    private LocalDateTime closedTime;
    /**
     * 闭店原因
     */
    private String closedReason;

}
