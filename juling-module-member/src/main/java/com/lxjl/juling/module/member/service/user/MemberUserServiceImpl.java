package com.lxjl.juling.module.member.service.user;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.collection.ListUtil;
import cn.hutool.core.util.*;
import com.lxjl.juling.framework.common.biz.system.oauth2.OAuth2TokenCommonApi;
import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.framework.common.enums.UserTypeEnum;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.member.controller.admin.user.vo.MemberUserCreateReqVO;
import com.lxjl.juling.module.member.controller.admin.user.vo.MemberUserPageReqVO;
import com.lxjl.juling.module.member.controller.admin.user.vo.MemberUserUpdateReqVO;
import com.lxjl.juling.module.member.controller.app.user.vo.*;
import com.lxjl.juling.module.member.convert.user.MemberUserConvert;
import com.lxjl.juling.module.member.dal.dataobject.user.MemberUserDO;
import com.lxjl.juling.module.member.dal.mysql.user.MemberUserMapper;
import com.google.common.annotations.VisibleForTesting;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.util.servlet.ServletUtils.getClientIP;
import static com.lxjl.juling.module.member.enums.ErrorCodeConstants.*;

/**
 * 订货账号 Service 实现类
 *
 * @author 亚特
 */
@Service
@Valid
@Slf4j
public class MemberUserServiceImpl implements MemberUserService {

    @Resource
    private MemberUserMapper memberUserMapper;

    /** 授权门店：账号「能给哪些门店下单」存在 member_user_store 上，不在本表 */
    @Resource
    private MemberUserStoreService memberUserStoreService;

    /** 交易订单 API：删除订货账号前校验该账号是否已有订单 */
    @Resource
    private com.lxjl.juling.module.trade.api.order.TradeOrderApi tradeOrderApi;

    @Resource
    private OAuth2TokenCommonApi oauth2TokenApi;

    @Resource
    private PasswordEncoder passwordEncoder;

    @Override
    public MemberUserDO getUserByMobile(String mobile) {
        return memberUserMapper.selectByMobile(mobile);
    }

    @Override
    public MemberUserDO getUserByUsername(String username) {
        return memberUserMapper.selectByUsername(username);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createOrderUser(MemberUserCreateReqVO createReqVO) {
        // 1. 订货账号不能为空 + 唯一（部分唯一索引 uk_member_user_username 兜并发）
        String username = StrUtil.trim(createReqVO.getUsername());
        if (StrUtil.isBlank(username)) {
            throw exception(USER_USERNAME_BLANK);
        }
        if (memberUserMapper.selectByUsername(username) != null) {
            throw exception(USER_USERNAME_USED, username);
        }
        // 2. 手机号可选；填了就必须唯一（否则「手机兜底登录」会歧义）
        validateMobileUnique(null, createReqVO.getMobile());
        // 3. 必须授权门店：没有可下单门店的账号登进来也下不了单，不如开号时就挡住
        if (CollUtil.isEmpty(createReqVO.getStoreCustomerIds())) {
            throw exception(USER_STORE_NOT_GRANTED);
        }
        // 4. 落库（C 端那套昵称/头像对订货账号没意义，只留最小集合）
        MemberUserDO user = MemberUserDO.builder()
                .username(username)
                .nickname(StrUtil.blankToDefault(createReqVO.getNickname(), username))
                .mobile(StrUtil.trimToNull(createReqVO.getMobile()))
                .email(StrUtil.trimToNull(createReqVO.getEmail()))
                .mark(createReqVO.getMark())
                .status(ObjectUtil.defaultIfNull(createReqVO.getStatus(), CommonStatusEnum.ENABLE.getStatus()))
                .password(encodePassword(createReqVO.getPassword()))
                .registerIp(getClientIP())
                .build();
        memberUserMapper.insert(user);
        // 5. 落授权门店：与账号同一个事务，开号失败不留下孤儿授权
        memberUserStoreService.replaceGrants(user.getId(), createReqVO.getStoreCustomerIds(),
                createReqVO.getDefaultStoreCustomerId());
        log.info("[createOrderUser][开订货账号({}) 成功，授权门店({})，会员编号({})]",
                username, createReqVO.getStoreCustomerIds(), user.getId());
        return user.getId();
    }

    @Override
    public void resetUserPasswordByAdmin(Long id, String password) {
        validateUserExists(id);
        memberUserMapper.updateById(MemberUserDO.builder().id(id).password(encodePassword(password)).build());
        // 重置密码后强制下线：否则旧 token 在有效期内仍可继续用，等于没改
        oauth2TokenApi.removeAccessToken(id, UserTypeEnum.MEMBER.getValue());
        log.info("[resetUserPasswordByAdmin][会员({}) 密码已被后台重置，已强制下线]", id);
    }

    @Override
    public void updateUserPasswordByOld(Long userId, AppMemberUserUpdatePasswordByOldReqVO reqVO) {
        MemberUserDO user = validateUserExists(userId);
        if (!isPasswordMatch(reqVO.getOldPassword(), user.getPassword())) {
            throw exception(USER_OLD_PASSWORD_ERROR);
        }
        memberUserMapper.updateById(MemberUserDO.builder().id(userId)
                .password(encodePassword(reqVO.getNewPassword())).build());
    }

    @Override
    public List<MemberUserDO> getUserListByNickname(String nickname) {
        return memberUserMapper.selectListByNicknameLike(nickname);
    }

    @Override
    public void updateUserLogin(Long id, String loginIp) {
        memberUserMapper.updateById(new MemberUserDO().setId(id)
                .setLoginIp(loginIp).setLoginDate(LocalDateTime.now()));
    }

    @Override
    public MemberUserDO getUser(Long id) {
        return memberUserMapper.selectById(id);
    }

    @Override
    public List<MemberUserDO> getUserList(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return ListUtil.empty();
        }
        return memberUserMapper.selectByIds(ids);
    }

    @Override
    public void updateUser(Long userId, AppMemberUserUpdateReqVO reqVO) {
        // 1.1 检测用户是否存在
        validateUserExists(userId);
        // 1.2 校验手机是否已经被绑定
        validateEmailUnique(userId, reqVO.getEmail());

        // 2. 更新用户
        MemberUserDO updateObj = BeanUtils.toBean(reqVO, MemberUserDO.class).setId(userId);
        memberUserMapper.updateById(updateObj);
    }

    @Override
    public void deleteUser(Long id) {
        validateUserExists(id);
        // 已经有订单的账号：订单只存 user_id（收货单/往来台账也按账号串联），删掉会让历史数据失去归属，
        // 因此引导改用「停用」——停用后登不进来，但历史仍可追溯。
        Long orderCount = tradeOrderApi.getOrderCountByUserId(id);
        if (orderCount != null && orderCount > 0) {
            throw exception(USER_DELETE_FAIL_HAS_ORDER, orderCount);
        }
        memberUserMapper.deleteById(id);
    }

    @Override
    public void updateUserStatus(Long id, Integer status) {
        validateUserExists(id);
        memberUserMapper.updateById(new MemberUserDO().setId(id).setStatus(status));
    }

    @Override
    public boolean isPasswordMatch(String rawPassword, String encodedPassword) {
        return passwordEncoder.matches(rawPassword, encodedPassword);
    }

    /**
     * 对密码进行加密
     *
     * @param password 密码
     * @return 加密后的密码
     */
    private String encodePassword(String password) {
        return passwordEncoder.encode(password);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateUser(MemberUserUpdateReqVO updateReqVO) {
        // 校验存在
        validateUserExists(updateReqVO.getId());
        // 校验订货账号唯一（改账号名时不能撞别人）
        validateUsernameUnique(updateReqVO.getId(), updateReqVO.getUsername());
        // 校验手机唯一
        validateMobileUnique(updateReqVO.getId(), updateReqVO.getMobile());
        // 校验邮箱唯一
        validateEmailUnique(updateReqVO.getId(), updateReqVO.getEmail());

        // 更新
        MemberUserDO updateObj = MemberUserConvert.INSTANCE.convert(updateReqVO);
        // 空账号名一律按"不修改"处理：updateById 只忽略 null 不忽略空串，
        // 直接透传会把账号名清成 ''，门店第二天就登不进来了
        if (StrUtil.isBlank(updateObj.getUsername())) {
            updateObj.setUsername(null);
        }
        memberUserMapper.updateById(updateObj);

        // 授权门店：传了才替换 —— 不传表示本次不改授权，避免「编辑手机号」这类操作把授权清空
        if (CollUtil.isNotEmpty(updateReqVO.getStoreCustomerIds())) {
            memberUserStoreService.replaceGrants(updateReqVO.getId(), updateReqVO.getStoreCustomerIds(),
                    updateReqVO.getDefaultStoreCustomerId());
        }

        // 如果是禁用用户，则删除其 Token 信息
        if (CommonStatusEnum.isDisable(updateObj.getStatus())) {
            oauth2TokenApi.removeAccessToken(updateObj.getId(), UserTypeEnum.MEMBER.getValue());
        }
    }

    @VisibleForTesting
    MemberUserDO validateUserExists(Long id) {
        if (id == null) {
            return null;
        }
        MemberUserDO user = memberUserMapper.selectById(id);
        if (user == null) {
            throw exception(USER_NOT_EXISTS);
        }
        return user;
    }

    @VisibleForTesting
    void validateUsernameUnique(Long id, String username) {
        if (StrUtil.isBlank(username)) {
            return;
        }
        MemberUserDO user = memberUserMapper.selectByUsername(username.trim());
        if (user != null && !user.getId().equals(id)) {
            throw exception(USER_USERNAME_USED, username);
        }
    }

    @VisibleForTesting
    void validateMobileUnique(Long id, String mobile) {
        if (StrUtil.isBlank(mobile)) {
            return;
        }
        MemberUserDO user = memberUserMapper.selectByMobile(mobile);
        if (user == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的用户
        if (id == null) {
            throw exception(USER_MOBILE_USED, mobile);
        }
        if (!user.getId().equals(id)) {
            throw exception(USER_MOBILE_USED, mobile);
        }
    }

    @VisibleForTesting
    void validateEmailUnique(Long id, String email) {
        if (StrUtil.isBlank(email)) {
            return;
        }
        MemberUserDO user = memberUserMapper.selectByEmail(email);
        if (user == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的用户
        if (id == null) {
            throw exception(USER_EMAIL_USED, email);
        }
        if (!user.getId().equals(id)) {
            throw exception(USER_EMAIL_USED, email);
        }
    }

    @Override
    public PageResult<MemberUserDO> getUserPage(MemberUserPageReqVO pageReqVO) {
        return memberUserMapper.selectPage(pageReqVO);
    }

}
