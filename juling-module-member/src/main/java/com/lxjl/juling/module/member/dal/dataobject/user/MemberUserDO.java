package com.lxjl.juling.module.member.dal.dataobject.user;

import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.framework.common.enums.TerminalEnum;
import com.lxjl.juling.framework.ip.core.Area;
import com.lxjl.juling.framework.tenant.core.db.TenantBaseDO;
import com.lxjl.juling.module.system.enums.common.SexEnum;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.time.LocalDateTime;

/**
 * 订货账号 DO
 *
 * 只保留「订货账号」能力：账号（username）+ 密码、绑定门店（客户 / 部门）。
 * 会员中心的等级、积分、经验、标签、分组已整体下线，对应的字段不再存在于本表映射中。
 *
 * uk_mobile 索引：基于 {@link #mobile} 字段
 *
 * @author 亚特
 */
@TableName("member_user")
@KeySequence("member_user_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MemberUserDO extends TenantBaseDO {

    // ========== 账号信息 ==========

    /**
     * 用户ID
     */
    @TableId
    private Long id;
    /**
     * 手机
     *
     * 私域订货场景下**可选**（会员是加盟客户，不一定留手机号）。
     */
    private String mobile;
    /**
     * 订货账号（登录名）
     *
     * 私域订货 H5 不开放给 C 端，订货人用「名字 + 密码」登录，所以登录名是独立字段，
     * **不复用 mobile**：mobile 是联系方式而不是身份键，复用会破坏语义，也无法与将来的 C 端账号共存。
     * 唯一性由部分唯一索引 uk_member_user_username 保证（见 sql/local/39）。
     */
    private String username;
    /**
     * 邮箱
     */
    private String email;
    /**
     * 加密后的密码
     *
     * 因为目前使用 {@link BCryptPasswordEncoder} 加密器，所以无需自己处理 salt 盐
     */
    private String password;
    /**
     * 帐号状态
     *
     * 枚举 {@link CommonStatusEnum}
     */
    private Integer status;
    /**
     * 注册 IP
     */
    private String registerIp;
    /**
     * 注册终端
     * 枚举 {@link TerminalEnum}
     */
    private Integer registerTerminal;
    /**
     * 最后登录IP
     */
    private String loginIp;
    /**
     * 最后登录时间
     */
    private LocalDateTime loginDate;

    // ========== 基础信息 ==========

    /**
     * 用户昵称
     */
    private String nickname;
    /**
     * 用户头像
     */
    private String avatar;

    /**
     * 真实名字
     */
    private String name;
    /**
     * 性别
     *
     * 枚举 {@link SexEnum}
     */
    private Integer sex;
    /**
     * 出生日期
     */
    private LocalDateTime birthday;
    /**
     * 所在地
     *
     * 关联 {@link Area#getId()} 字段
     */
    private Integer areaId;
    /**
     * 用户备注
     */
    private String mark;

    // ========== 订货主体 ==========

    /**
     * 所属部门（门店节点）编号
     *
     * 关联 {@link com.lxjl.juling.module.system.dal.dataobject.dept.DeptDO#getId()} 字段。
     * 门店订货链「一店三面」：组织面（部门）+ 经营面（客户）+ 账号面（本表）。
     */
    private Long deptId;
    /**
     * 所属客户（门店 / 代理）编号
     *
     * 关联 ERP 客户，代理账号可切换其名下门店下单。
     */
    private Long customerId;

}
