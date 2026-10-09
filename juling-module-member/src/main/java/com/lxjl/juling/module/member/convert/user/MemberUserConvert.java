package com.lxjl.juling.module.member.convert.user;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.ip.core.utils.AreaUtils;
import com.lxjl.juling.module.member.api.user.dto.MemberUserRespDTO;
import com.lxjl.juling.module.member.controller.admin.user.vo.MemberUserRespVO;
import com.lxjl.juling.module.member.controller.admin.user.vo.MemberUserUpdateReqVO;
import com.lxjl.juling.module.member.controller.app.user.vo.AppMemberUserInfoRespVO;
import com.lxjl.juling.module.member.dal.dataobject.user.MemberUserDO;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface MemberUserConvert {

    MemberUserConvert INSTANCE = Mappers.getMapper(MemberUserConvert.class);

    AppMemberUserInfoRespVO convert(MemberUserDO bean);

    MemberUserRespDTO convert2(MemberUserDO bean);

    List<MemberUserRespDTO> convertList2(List<MemberUserDO> list);

    MemberUserDO convert(MemberUserUpdateReqVO bean);

    PageResult<MemberUserRespVO> convertPage(PageResult<MemberUserDO> page);

    @Mapping(source = "areaId", target = "areaName", qualifiedByName = "convertAreaIdToAreaName")
    MemberUserRespVO convert03(MemberUserDO bean);

    @Named("convertAreaIdToAreaName")
    default String convertAreaIdToAreaName(Integer areaId) {
        return AreaUtils.format(areaId);
    }

}
