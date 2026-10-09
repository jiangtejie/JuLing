package com.lxjl.juling.module.member.api.user.dto;

import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 订货账号信息 Response DTO
 *
 * @author 亚特
 */
@Data
public class MemberUserRespDTO {

    /**
     * 用户ID
     */
    private Long id;
    /**
     * 用户昵称
     */
    private String nickname;
    /**
     * 帐号状态
     *
     * 枚举 {@link CommonStatusEnum}
     */
    private Integer status;
    /**
     * 用户头像
     */
    private String avatar;
    /**
     * 手机
     */
    private String mobile;
    /**
     * 邮箱
     */
    private String email;
    /**
     * 创建时间（注册时间）
     */
    private LocalDateTime createTime;

}
