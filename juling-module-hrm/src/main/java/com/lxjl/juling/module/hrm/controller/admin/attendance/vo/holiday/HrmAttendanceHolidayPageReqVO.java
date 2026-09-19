package com.lxjl.juling.module.hrm.controller.admin.attendance.vo.holiday;

import com.lxjl.juling.framework.common.pojo.PageParam;
import com.lxjl.juling.framework.common.validation.InEnum;
import com.lxjl.juling.module.hrm.enums.attendance.config.HrmAttendanceHolidayTypeEnum;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDateTime;

import static com.lxjl.juling.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

@Schema(description = "管理后台 - HRM 考勤节假日分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class HrmAttendanceHolidayPageReqVO extends PageParam {

    @Schema(description = "日期范围")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private LocalDateTime[] date;

    @Schema(description = "节假日类型", example = "1")
    @InEnum(value = HrmAttendanceHolidayTypeEnum.class, message = "节假日类型必须是 {value}")
    private Integer type;

}
