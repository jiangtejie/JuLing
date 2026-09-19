package com.lxjl.juling.module.member.convert.config;

import com.lxjl.juling.module.member.api.config.dto.MemberConfigRespDTO;
import com.lxjl.juling.module.member.controller.admin.config.vo.MemberConfigRespVO;
import com.lxjl.juling.module.member.controller.admin.config.vo.MemberConfigSaveReqVO;
import com.lxjl.juling.module.member.dal.dataobject.config.MemberConfigDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

/**
 * 会员配置 Convert
 *
 * @author 棱信矩灵
 */
@Mapper
public interface MemberConfigConvert {

    MemberConfigConvert INSTANCE = Mappers.getMapper(MemberConfigConvert.class);

    MemberConfigRespVO convert(MemberConfigDO bean);

    MemberConfigDO convert(MemberConfigSaveReqVO bean);

    MemberConfigRespDTO convert01(MemberConfigDO config);
}
