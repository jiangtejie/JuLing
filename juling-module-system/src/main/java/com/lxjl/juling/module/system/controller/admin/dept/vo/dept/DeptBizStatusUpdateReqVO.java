package com.lxjl.juling.module.system.controller.admin.dept.vo.dept;

import com.lxjl.juling.framework.common.validation.InEnum;
import com.lxjl.juling.module.system.enums.dept.DeptBusinessStatusEnum;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 管理后台 - 门店开店 / 闭店 Request VO
 *
 * <p>只对门店节点（dept_type = STORE）有效；组织节点调用会被拒绝。
 *
 * @author 亚特
 */
@Schema(description = "管理后台 - 门店开店/闭店 Request VO")
@Data
public class DeptBizStatusUpdateReqVO {

    @Schema(description = "部门编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "134")
    @NotNull(message = "部门编号不能为空")
    private Long id;

    @Schema(description = "营业状态：0 营业 / 1 已闭店", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "营业状态不能为空")
    @InEnum(value = DeptBusinessStatusEnum.class, message = "营业状态必须是 {value}")
    private Integer businessStatus;

    @Schema(description = "闭店原因（闭店时填写，复开时忽略）", example = "租约到期")
    @Size(max = 255, message = "闭店原因长度不能超过 255 个字符")
    private String closedReason;

}