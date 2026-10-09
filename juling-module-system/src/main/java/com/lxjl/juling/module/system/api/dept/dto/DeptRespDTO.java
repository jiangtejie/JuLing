package com.lxjl.juling.module.system.api.dept.dto;

import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import lombok.Data;

/**
 * 部门 Response DTO
 *
 * @author 亚特
 */
@Data
public class DeptRespDTO {

    /**
     * 部门编号
     */
    private Long id;
    /**
     * 部门名称
     */
    private String name;
    /**
     * 父部门编号
     */
    private Long parentId;
    /**
     * 负责人的用户编号
     */
    private Long leaderUserId;
    /**
     * 部门状态
     *
     * 枚举 {@link CommonStatusEnum}
     */
    private Integer status;
    /**
     * 节点类型：组织 / 门店（{@code DeptTypeEnum}）
     */
    private String deptType;
    /**
     * 营业状态：0 营业 / 1 已闭店（{@code DeptBusinessStatusEnum}）
     */
    private Integer businessStatus;

}
