package com.lxjl.juling.module.iot.dal.mysql.device;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.iot.core.biz.dto.IotModbusDeviceConfigListReqDTO;
import com.lxjl.juling.module.iot.dal.dataobject.device.IotDeviceModbusConfigDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * IoT 设备 Modbus 连接配置 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface IotDeviceModbusConfigMapper extends BaseMapperX<IotDeviceModbusConfigDO> {

    default IotDeviceModbusConfigDO selectByDeviceId(Long deviceId) {
        return selectOne(IotDeviceModbusConfigDO::getDeviceId, deviceId);
    }

    default List<IotDeviceModbusConfigDO> selectList(IotModbusDeviceConfigListReqDTO reqDTO) {
        return selectList(new LambdaQueryWrapperX<IotDeviceModbusConfigDO>()
                .eqIfPresent(IotDeviceModbusConfigDO::getStatus, reqDTO.getStatus())
                .eqIfPresent(IotDeviceModbusConfigDO::getMode, reqDTO.getMode())
                .inIfPresent(IotDeviceModbusConfigDO::getDeviceId, reqDTO.getDeviceIds()));
    }

}
