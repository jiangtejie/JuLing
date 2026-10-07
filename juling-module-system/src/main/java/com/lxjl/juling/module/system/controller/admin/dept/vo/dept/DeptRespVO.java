package com.lxjl.juling.module.system.controller.admin.dept.vo.dept;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Schema(description = "管理后台 - 部门信息 Response VO")
@Data
public class DeptRespVO {

    @Schema(description = "部门编号", example = "1024")
    private Long id;

    @Schema(description = "部门名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "亚特")
    private String name;

    @Schema(description = "父部门 ID", example = "1024")
    private Long parentId;

    @Schema(description = "显示顺序", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    private Integer sort;

    @Schema(description = "负责人的用户编号", example = "2048")
    private Long leaderUserId;

    @Schema(description = "联系电话", example = "15601691000")
    private String phone;

    @Schema(description = "邮箱", example = "juling@example.com")
    private String email;

    @Schema(description = "状态,见 CommonStatusEnum 枚举", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Integer status;

    @Schema(description = "节点类型：ORG 组织 / STORE 门店", example = "STORE")
    private String deptType;

    @Schema(description = "营业状态：0 营业 / 1 已闭店（仅门店有意义）", example = "0")
    private Integer businessStatus;

    @Schema(description = "闭店时间")
    private LocalDateTime closedTime;

    @Schema(description = "闭店原因")
    private String closedReason;

    @Schema(description = "创建时间", requiredMode = Schema.RequiredMode.REQUIRED, example = "时间戳格式")
    private LocalDateTime createTime;

}
