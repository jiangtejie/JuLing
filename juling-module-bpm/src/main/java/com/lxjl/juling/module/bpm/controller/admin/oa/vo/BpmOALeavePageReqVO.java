package com.lxjl.juling.module.bpm.controller.admin.oa.vo;

import com.lxjl.juling.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDateTime;

import static com.lxjl.juling.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

@Schema(description = "管理后台 - 请假申请分页 Request VO")
@Data
public class BpmOALeavePageReqVO extends PageParam {

    @Schema(description = "状态", example = "1")
    private Integer status; // 参见 BpmProcessInstanceResultEnum 枚举

    @Schema(description = "请假类型，参见 bpm_oa_type", example = "1")
    private Integer type;

    @Schema(description = "原因，模糊匹配", example = "阅读棱信矩灵")
    private String reason;

    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    @Schema(description = "申请时间")
    private LocalDateTime[] createTime;

}
