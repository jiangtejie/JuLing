package com.lxjl.juling.module.system.dal.dataobject.sms;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.lxjl.juling.framework.tenant.core.aop.TenantIgnore;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

import java.time.LocalDateTime;

/**
 * 手机验证码 DO
 *
 * idx_mobile 索引：基于 {@link #mobile} 字段
 *
 * @author 棱信矩灵
 */
@TableName("system_sms_code")
@KeySequence("system_sms_code_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
@TenantIgnore
public class SmsCodeDO extends BaseDO {

    /**
     * 编号
     */
    private Long id;
    /**
     * 手机号
     */
    private String mobile;
    /**
     * 验证码
     */
    private String code;
    /**
     * 发送场景
     *
     * 枚举 {@link SmsCodeDO}
     */
    private Integer scene;
    /**
     * 创建 IP
     */
    private String createIp;
    /**
     * 今日发送的第几条
     */
    private Integer todayIndex;
    /**
     * 是否使用
     * <p>
     * 用 Integer 而非 Boolean：system_sms_code.used 列在 PostgreSQL 下是 smallint（0=未使用、1=已使用），
     * Boolean 参数写入 smallint 列会报 column "used" is of type smallint but expression is of type boolean
     */
    private Integer used;
    /**
     * 使用时间
     */
    private LocalDateTime usedTime;
    /**
     * 使用 IP
     */
    private String usedIp;

}
