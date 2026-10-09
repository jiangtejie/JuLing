package com.lxjl.juling.module.member.dal.mysql.user;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.member.controller.admin.user.vo.MemberUserPageReqVO;
import com.lxjl.juling.module.member.dal.dataobject.user.MemberUserDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 订货账号 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface MemberUserMapper extends BaseMapperX<MemberUserDO> {

    /**
     * 按订货账号查询（H5 登录用）
     *
     * 空账号直接返回 null：selectOne(字段, null) 会退化成"随便取一行"，必须挡住。
     */
    default MemberUserDO selectByUsername(String username) {
        if (username == null || username.trim().isEmpty()) {
            return null;
        }
        return selectOne(MemberUserDO::getUsername, username.trim());
    }

    default MemberUserDO selectByMobile(String mobile) {
        return selectOne(MemberUserDO::getMobile, mobile);
    }

    default MemberUserDO selectByEmail(String email) {
        return selectOne(MemberUserDO::getEmail, email);
    }

    default List<MemberUserDO> selectListByNicknameLike(String nickname) {
        return selectList(new LambdaQueryWrapperX<MemberUserDO>()
                .likeIfPresent(MemberUserDO::getNickname, nickname));
    }

    default PageResult<MemberUserDO> selectPage(MemberUserPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<MemberUserDO>()
                .likeIfPresent(MemberUserDO::getUsername, reqVO.getUsername())
                .likeIfPresent(MemberUserDO::getMobile, reqVO.getMobile())
                .likeIfPresent(MemberUserDO::getEmail, reqVO.getEmail())
                .betweenIfPresent(MemberUserDO::getLoginDate, reqVO.getLoginDate())
                .likeIfPresent(MemberUserDO::getNickname, reqVO.getNickname())
                .betweenIfPresent(MemberUserDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(MemberUserDO::getId));
    }

}
