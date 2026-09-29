package com.lxjl.juling.module.member.service.user;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.collection.ListUtil;
import cn.hutool.core.lang.Assert;
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
import com.lxjl.juling.module.member.convert.auth.AuthConvert;
import com.lxjl.juling.module.member.convert.user.MemberUserConvert;
import com.lxjl.juling.module.member.dal.dataobject.user.MemberUserDO;
import com.lxjl.juling.module.member.dal.mysql.user.MemberUserMapper;
import com.lxjl.juling.module.member.mq.producer.user.MemberUserProducer;
import com.lxjl.juling.module.system.api.sms.SmsCodeApi;
import com.lxjl.juling.module.system.api.sms.dto.code.SmsCodeUseReqDTO;
import com.lxjl.juling.module.system.api.social.SocialClientApi;
import com.lxjl.juling.module.system.api.social.dto.SocialWxPhoneNumberInfoRespDTO;
import com.lxjl.juling.module.system.enums.sms.SmsSceneEnum;
import com.google.common.annotations.VisibleForTesting;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.util.servlet.ServletUtils.getClientIP;
import static com.lxjl.juling.module.member.enums.ErrorCodeConstants.*;

/**
 * 会员 User Service 实现类
 *
 * @author 亚特
 */
@Service
@Valid
@Slf4j
public class MemberUserServiceImpl implements MemberUserService {

    @Resource
    private MemberUserMapper memberUserMapper;

    @Resource
    private SmsCodeApi smsCodeApi;
    @Resource
    private SocialClientApi socialClientApi;
    @Resource
    private OAuth2TokenCommonApi oauth2TokenApi;

    @Resource
    private PasswordEncoder passwordEncoder;

    @Resource
    private MemberUserProducer memberUserProducer;

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
        // 3. 必须绑门店：订货账号不绑门店，下单时会被 TradeOrderStoreService 直接拦下，不如开号时就挡住
        if (createReqVO.getCustomerId() == null) {
            throw exception(USER_STORE_NOT_BOUND);
        }
        // 4. 落库（C 端那套昵称/头像/等级对订货账号没意义，只留最小集合）
        MemberUserDO user = MemberUserDO.builder()
                .username(username)
                .nickname(StrUtil.blankToDefault(createReqVO.getNickname(), username))
                .mobile(StrUtil.trimToNull(createReqVO.getMobile()))
                .email(StrUtil.trimToNull(createReqVO.getEmail()))
                .deptId(createReqVO.getDeptId())
                .customerId(createReqVO.getCustomerId())
                .mark(createReqVO.getMark())
                .status(ObjectUtil.defaultIfNull(createReqVO.getStatus(), CommonStatusEnum.ENABLE.getStatus()))
                .password(encodePassword(createReqVO.getPassword()))
                .registerIp(getClientIP())
                .build();
        memberUserMapper.insert(user);
        log.info("[createOrderUser][开订货账号({}) 成功，绑定门店({})，会员编号({})]",
                username, createReqVO.getCustomerId(), user.getId());
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
    @Transactional(rollbackFor = Exception.class)
    public MemberUserDO createUserIfAbsent(String mobile, String registerIp, Integer terminal) {
        // 用户已经存在
        MemberUserDO user = memberUserMapper.selectByMobile(mobile);
        if (user != null) {
            return user;
        }
        // 用户不存在，则进行创建
        return createUser(mobile, null, null, registerIp, terminal);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public MemberUserDO createUser(String nickname, String avtar, String registerIp, Integer terminal) {
        return createUser(null, nickname, avtar, registerIp, terminal);
    }

    private MemberUserDO createUser(String mobile, String nickname, String avtar,
                                    String registerIp, Integer terminal) {
        // 生成密码
        String password = IdUtil.fastSimpleUUID();
        // 插入用户
        MemberUserDO user = new MemberUserDO();
        user.setMobile(mobile);
        user.setStatus(CommonStatusEnum.ENABLE.getStatus()); // 默认开启
        user.setPassword(encodePassword(password)); // 加密密码
        user.setRegisterIp(registerIp).setRegisterTerminal(terminal);
        user.setNickname(nickname).setAvatar(avtar); // 基础信息
        if (StrUtil.isEmpty(nickname)) {
            // 昵称为空时，随机一个名字，避免一些依赖 nickname 的逻辑报错，或者有点丑。例如说，短信发送有昵称时~
            user.setNickname("用户" + RandomUtil.randomNumbers(6));
        }
        memberUserMapper.insert(user);

        // 发送 MQ 消息：用户创建
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {

            @Override
            public void afterCommit() {
                memberUserProducer.sendUserCreateMessage(user.getId());
            }

        });
        return user;
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
    @Transactional(rollbackFor = Exception.class)
    public void updateUserMobile(Long userId, AppMemberUserUpdateMobileReqVO reqVO) {
        // 1.1 检测用户是否存在
        MemberUserDO user = validateUserExists(userId);
        // 1.2 校验新手机是否已经被绑定
        validateMobileUnique(null, reqVO.getMobile());

        // 2.1 校验旧手机和旧验证码
        // 补充说明：从安全性来说，老手机也校验 oldCode 验证码会更安全。但是由于 uni-app 商城界面暂时没做，所以这里不强制校验
        if (StrUtil.isNotEmpty(reqVO.getOldCode())) {
            smsCodeApi.useSmsCode(new SmsCodeUseReqDTO().setMobile(user.getMobile()).setCode(reqVO.getOldCode())
                    .setScene(SmsSceneEnum.MEMBER_UPDATE_MOBILE.getScene()).setUsedIp(getClientIP()));
        }
        // 2.2 使用新验证码
        smsCodeApi.useSmsCode(new SmsCodeUseReqDTO().setMobile(reqVO.getMobile()).setCode(reqVO.getCode())
                .setScene(SmsSceneEnum.MEMBER_UPDATE_MOBILE.getScene()).setUsedIp(getClientIP()));

        // 3. 更新用户手机
        memberUserMapper.updateById(MemberUserDO.builder().id(userId).mobile(reqVO.getMobile()).build());
    }

    @Override
    public void updateUserMobileByWeixin(Long userId, AppMemberUserUpdateMobileByWeixinReqVO reqVO) {
        // 1.1 获得对应的手机号信息
        SocialWxPhoneNumberInfoRespDTO phoneNumberInfo = socialClientApi.getWxMaPhoneNumberInfo(
                UserTypeEnum.MEMBER.getValue(), reqVO.getCode());
        Assert.notNull(phoneNumberInfo, "获得手机信息失败，结果为空");
        // 1.2 校验新手机是否已经被绑定
        validateMobileUnique(userId, phoneNumberInfo.getPhoneNumber());

        // 2. 更新用户手机
        memberUserMapper.updateById(MemberUserDO.builder().id(userId).mobile(phoneNumberInfo.getPhoneNumber()).build());
    }

    @Override
    public void updateUserPassword(Long userId, AppMemberUserUpdatePasswordReqVO reqVO) {
        // 检测用户是否存在
        MemberUserDO user = validateUserExists(userId);
        // 校验验证码
        smsCodeApi.useSmsCode(new SmsCodeUseReqDTO().setMobile(user.getMobile()).setCode(reqVO.getCode())
                .setScene(SmsSceneEnum.MEMBER_UPDATE_PASSWORD.getScene()).setUsedIp(getClientIP()));

        // 更新用户密码
        memberUserMapper.updateById(MemberUserDO.builder().id(userId)
                .password(passwordEncoder.encode(reqVO.getPassword())).build());
    }

    @Override
    public void resetUserPassword(AppMemberUserResetPasswordReqVO reqVO) {
        // 检验用户是否存在
        MemberUserDO user = validateUserExists(reqVO.getMobile());

        // 使用验证码
        smsCodeApi.useSmsCode(AuthConvert.INSTANCE.convert(reqVO, SmsSceneEnum.MEMBER_RESET_PASSWORD,
                getClientIP()));

        // 更新密码
        memberUserMapper.updateById(MemberUserDO.builder().id(user.getId())
                .password(passwordEncoder.encode(reqVO.getPassword())).build());
    }

    private MemberUserDO validateUserExists(String mobile) {
        MemberUserDO user = memberUserMapper.selectByMobile(mobile);
        if (user == null) {
            throw exception(USER_MOBILE_NOT_EXISTS);
        }
        return user;
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

    @Override
    public void updateUserLevel(Long id, Long levelId, Integer experience) {
        // 0 代表无等级：防止UpdateById时，会被过滤掉的问题
        levelId = ObjectUtil.defaultIfNull(levelId, 0L);
        memberUserMapper.updateById(new MemberUserDO()
                .setId(id)
                .setLevelId(levelId).setExperience(experience)
        );
    }

    @Override
    public Long getUserCountByGroupId(Long groupId) {
        return memberUserMapper.selectCountByGroupId(groupId);
    }

    @Override
    public Long getUserCountByLevelId(Long levelId) {
        return memberUserMapper.selectCountByLevelId(levelId);
    }

    @Override
    public Long getUserCountByTagId(Long tagId) {
        return memberUserMapper.selectCountByTagId(tagId);
    }

    @Override
    public boolean updateUserPoint(Long id, Integer point) {
        if (point > 0) {
            memberUserMapper.updatePointIncr(id, point);
        } else if (point < 0) {
            return memberUserMapper.updatePointDecr(id, point) > 0;
        }
        return true;
    }

}
