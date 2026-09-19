package com.lxjl.juling.framework.excel.core.convert;

import cn.hutool.core.convert.Convert;
import com.lxjl.juling.framework.ip.core.Area;
import com.lxjl.juling.framework.ip.core.utils.AreaUtils;
import cn.idev.excel.converters.Converter;
import cn.idev.excel.enums.CellDataTypeEnum;
import cn.idev.excel.metadata.GlobalConfiguration;
import cn.idev.excel.metadata.data.ReadCellData;
import cn.idev.excel.metadata.data.WriteCellData;
import cn.idev.excel.metadata.property.ExcelContentProperty;
import lombok.extern.slf4j.Slf4j;

/**
 * Excel 数据地区转换器
 *
 * 读（导入）：把「地区全路径名称」解析成地区编号
 * 写（导出 / 下载导入模板）：把地区编号格式化成「地区全路径名称」
 *
 * @author 棱信矩灵
 */
@Slf4j
public class AreaConvert implements Converter<Object> {

    @Override
    public Class<?> supportJavaTypeKey() {
        throw new UnsupportedOperationException("暂不支持，也不需要");
    }

    @Override
    public CellDataTypeEnum supportExcelTypeKey() {
        throw new UnsupportedOperationException("暂不支持，也不需要");
    }

    @Override
    public Object convertToJavaData(ReadCellData readCellData, ExcelContentProperty contentProperty,
                                    GlobalConfiguration globalConfiguration) {
        // 解析地区编号
        String label = readCellData.getStringValue();
        Area area = AreaUtils.parseArea(label);
        if (area == null) {
            log.error("[convertToJavaData][label({}) 解析不掉]", label);
            return null;
        }
        // 将 value 转换成对应的属性
        Class<?> fieldClazz = contentProperty.getField().getType();
        return Convert.convert(fieldClazz, area.getId());
    }

    /**
     * 写出 Excel 数据：把地区编号转换为地区全路径名称
     *
     * 说明：此前只实现了读（导入），写会走 {@link Converter} 接口的默认实现，抛
     * UnsupportedOperationException: The current operation is not supported by the current converter，
     * 导致所有含地区列的导入模板下载失败（HRM 员工导入、CRM 客户导入等）。
     *
     * 分隔符用 "/"：与 {@link AreaUtils#parseArea(String)} 的拆分方式一致，
     * 保证模板里的示例值可以原样回填导入。
     */
    @Override
    public WriteCellData<String> convertToExcelData(Object value, ExcelContentProperty contentProperty,
                                                   GlobalConfiguration globalConfiguration) {
        if (value == null) {
            return new WriteCellData<>("");
        }
        Integer areaId = Convert.toInt(value);
        String label = areaId == null ? null : AreaUtils.format(areaId, "/");
        return new WriteCellData<>(label == null ? "" : label);
    }

}
