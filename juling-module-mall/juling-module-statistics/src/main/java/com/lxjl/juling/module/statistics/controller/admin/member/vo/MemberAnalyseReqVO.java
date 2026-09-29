package com.lxjl.juling.module.statistics.controller.admin.member.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import lombok.Data;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDateTime;

import static com.lxjl.juling.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

@Schema(description = "管理后台 - 会员分析 Request VO")
@Data
public class MemberAnalyseReqVO {

    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    @Schema(description = "时间范围")
    @NotEmpty(message = "时间范围不能为空") // 不校验会走到 Service 里 NPE（beginTime.minusDays），对外表现为「系统异常」
    private LocalDateTime[] times;

}
