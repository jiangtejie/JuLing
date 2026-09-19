package com.lxjl.juling.module.member.service.config;

import com.lxjl.juling.module.member.controller.admin.config.vo.MemberConfigSaveReqVO;
import com.lxjl.juling.module.member.dal.dataobject.config.MemberConfigDO;

import jakarta.validation.Valid;

/**
 * 会员配置 Service 接口
 *
 * @author 棱信矩灵
 */
public interface MemberConfigService {

    /**
     * 保存会员配置
     *
     * @param saveReqVO 更新信息
     */
    void saveConfig(@Valid MemberConfigSaveReqVO saveReqVO);

    /**
     * 获得会员配置
     *
     * @return 积分配置
     */
    MemberConfigDO getConfig();

}
