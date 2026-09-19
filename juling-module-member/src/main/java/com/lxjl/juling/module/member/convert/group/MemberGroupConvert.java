package com.lxjl.juling.module.member.convert.group;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.member.controller.admin.group.vo.MemberGroupCreateReqVO;
import com.lxjl.juling.module.member.controller.admin.group.vo.MemberGroupRespVO;
import com.lxjl.juling.module.member.controller.admin.group.vo.MemberGroupSimpleRespVO;
import com.lxjl.juling.module.member.controller.admin.group.vo.MemberGroupUpdateReqVO;
import com.lxjl.juling.module.member.dal.dataobject.group.MemberGroupDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

/**
 * 用户分组 Convert
 *
 * @author 棱信矩灵
 */
@Mapper
public interface MemberGroupConvert {

    MemberGroupConvert INSTANCE = Mappers.getMapper(MemberGroupConvert.class);

    MemberGroupDO convert(MemberGroupCreateReqVO bean);

    MemberGroupDO convert(MemberGroupUpdateReqVO bean);

    MemberGroupRespVO convert(MemberGroupDO bean);

    List<MemberGroupRespVO> convertList(List<MemberGroupDO> list);

    PageResult<MemberGroupRespVO> convertPage(PageResult<MemberGroupDO> page);

    List<MemberGroupSimpleRespVO> convertSimpleList(List<MemberGroupDO> list);
}
