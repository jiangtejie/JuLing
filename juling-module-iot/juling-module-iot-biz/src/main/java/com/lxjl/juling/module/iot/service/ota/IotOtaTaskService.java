package com.lxjl.juling.module.iot.service.ota;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.iot.controller.admin.ota.vo.task.IotOtaTaskCreateReqVO;
import com.lxjl.juling.module.iot.controller.admin.ota.vo.task.IotOtaTaskPageReqVO;
import com.lxjl.juling.module.iot.dal.dataobject.ota.IotOtaTaskDO;
import jakarta.validation.Valid;

/**
 * IoT OTA 升级任务 Service 接口
 *
 * @author 棱信矩灵
 */
public interface IotOtaTaskService {

    /**
     * 创建 OTA 升级任务
     *
     * @param createReqVO 创建请求对象
     * @return 升级任务编号
     */
    Long createOtaTask(@Valid IotOtaTaskCreateReqVO createReqVO);

    /**
     * 取消 OTA 升级任务
     *
     * @param id 升级任务编号
     */
    void cancelOtaTask(Long id);

    /**
     * 获取 OTA 升级任务
     *
     * @param id 升级任务编号
     * @return 升级任务
     */
    IotOtaTaskDO getOtaTask(Long id);

    /**
     * 分页查询 OTA 升级任务
     *
     * @param pageReqVO 分页查询请求
     * @return 升级任务分页结果
     */
    PageResult<IotOtaTaskDO> getOtaTaskPage(@Valid IotOtaTaskPageReqVO pageReqVO);

    /**
     * 更新 OTA 任务状态为已结束
     *
     * @param id 任务编号
     */
    void updateOtaTaskStatusEnd(Long id);

}
