package com.lxjl.juling.module.member.service.user;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.member.controller.admin.user.vo.MemberUserCreateReqVO;
import com.lxjl.juling.module.member.controller.admin.user.vo.MemberUserPageReqVO;
import com.lxjl.juling.module.member.controller.admin.user.vo.MemberUserUpdateReqVO;
import com.lxjl.juling.module.member.controller.app.user.vo.*;
import com.lxjl.juling.module.member.dal.dataobject.user.MemberUserDO;

import jakarta.validation.Valid;
import java.util.Collection;
import java.util.List;

/**
 * 订货账号 Service 接口
 *
 * @author 亚特
 */
public interface MemberUserService {

    /**
     * 通过手机查询用户
     *
     * @param mobile 手机
     * @return 用户对象
     */
    MemberUserDO getUserByMobile(String mobile);

    /**
     * 按订货账号获得用户（登录名，私域订货的主口径）
     *
     * @param username 订货账号
     * @return 用户；不存在时返回 null
     */
    MemberUserDO getUserByUsername(String username);

    /**
     * 开订货账号（后台给加盟客户开账号：账号名 + 初始密码 + 绑定门店）
     *
     * @param createReqVO 开账号信息
     * @return 会员编号
     */
    Long createOrderUser(@Valid MemberUserCreateReqVO createReqVO);

    /**
     * 后台重置密码（不需要短信验证码；重置后强制下线，旧 token 立即失效）
     */
    void resetUserPasswordByAdmin(Long id, String password);

    /**
     * 用原密码修改密码（H5 自助改密；不依赖短信渠道）
     */
    void updateUserPasswordByOld(Long userId, AppMemberUserUpdatePasswordByOldReqVO reqVO);

    /**
     * 基于用户昵称，模糊匹配用户列表
     *
     * @param nickname 用户昵称，模糊匹配
     * @return 用户信息的列表
     */
    List<MemberUserDO> getUserListByNickname(String nickname);

    /**
     * 更新用户的最后登陆信息
     *
     * @param id      用户编号
     * @param loginIp 登陆 IP
     */
    void updateUserLogin(Long id, String loginIp);

    /**
     * 通过用户 ID 查询用户
     *
     * @param id 用户ID
     * @return 用户对象信息
     */
    MemberUserDO getUser(Long id);

    /**
     * 通过用户 ID 查询用户们
     *
     * @param ids 用户 ID
     * @return 用户对象信息数组
     */
    List<MemberUserDO> getUserList(Collection<Long> ids);

    /**
     * 【会员】修改基本信息
     *
     * @param userId 用户编号
     * @param reqVO  基本信息
     */
    void updateUser(Long userId, AppMemberUserUpdateReqVO reqVO);

    /**
     * 判断密码是否匹配
     *
     * @param rawPassword     未加密的密码
     * @param encodedPassword 加密后的密码
     * @return 是否匹配
     */
    boolean isPasswordMatch(String rawPassword, String encodedPassword);

    /**
     * 【管理员】更新订货账号
     *
     * @param updateReqVO 更新信息
     */
    void updateUser(@Valid MemberUserUpdateReqVO updateReqVO);

    /**
     * 【管理员】删除订货账号
     *
     * 已绑定门店/部门的账号会拒绝删除（历史订单只存 user_id，删掉就失去归属），引导改用「停用」。
     *
     * @param id 账号编号
     */
    void deleteUser(Long id);

    /**
     * 【管理员】停用 / 启用订货账号
     *
     * 停用后无法登录（登录时会校验状态），但订单与台账仍可追溯。
     *
     * @param id     账号编号
     * @param status 状态：0 开启、1 停用（{@link com.lxjl.juling.framework.common.enums.CommonStatusEnum}）
     */
    void updateUserStatus(Long id, Integer status);

    /**
     * 【管理员】获得订货账号分页
     *
     * @param pageReqVO 分页查询
     * @return 订货账号分页
     */
    PageResult<MemberUserDO> getUserPage(MemberUserPageReqVO pageReqVO);

}
