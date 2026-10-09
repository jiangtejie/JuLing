package com.lxjl.juling.module.erp.controller.admin.product.vo.product;

import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import com.lxjl.juling.framework.common.pojo.PageParam;
import org.springframework.format.annotation.DateTimeFormat;
import java.time.LocalDateTime;

import static com.lxjl.juling.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

@Schema(description = "管理后台 - ERP 物料分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class ErpProductPageReqVO extends PageParam {

    @Schema(description = "物料名称", example = "李四")
    private String name;

    @Schema(description = "物料分类编号", example = "11161")
    private Long categoryId;

    @Schema(description = "创建时间")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private LocalDateTime[] createTime;

    @Schema(description = "是否允许统配", example = "true")
    private Boolean allowCentral;

    @Schema(description = "是否允许直拨", example = "true")
    private Boolean allowDirect;

}