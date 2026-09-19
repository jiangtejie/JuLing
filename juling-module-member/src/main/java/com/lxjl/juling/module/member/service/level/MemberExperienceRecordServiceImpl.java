package com.lxjl.juling.module.member.service.level;

import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.framework.common.pojo.PageParam;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.member.controller.admin.level.vo.experience.MemberExperienceRecordPageReqVO;
import com.lxjl.juling.module.member.convert.level.MemberExperienceRecordConvert;
import com.lxjl.juling.module.member.dal.dataobject.level.MemberExperienceRecordDO;
import com.lxjl.juling.module.member.dal.mysql.level.MemberExperienceRecordMapper;
import com.lxjl.juling.module.member.enums.MemberExperienceBizTypeEnum;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import jakarta.annotation.Resource;
import java.util.Collection;
import java.util.List;

/**
 * 会员经验记录 Service 实现类
 *
 * @author 棱信矩灵
 */
@Service
@Validated
public class MemberExperienceRecordServiceImpl implements MemberExperienceRecordService {

    @Resource
    private MemberExperienceRecordMapper experienceLogMapper;

    @Override
    public MemberExperienceRecordDO getExperienceRecord(Long id) {
        return experienceLogMapper.selectById(id);
    }

    @Override
    public PageResult<MemberExperienceRecordDO> getExperienceRecordPage(MemberExperienceRecordPageReqVO pageReqVO) {
        return experienceLogMapper.selectPage(pageReqVO);
    }

    @Override
    public PageResult<MemberExperienceRecordDO> getExperienceRecordPage(Long userId, PageParam pageParam) {
         return experienceLogMapper.selectPage(userId, pageParam);
    }

    @Override
    public void createExperienceRecord(Long userId, Integer experience, Integer totalExperience,
                                       MemberExperienceBizTypeEnum bizType, String bizId) {
        String description = StrUtil.format(bizType.getDescription(), experience);
        MemberExperienceRecordDO record = MemberExperienceRecordConvert.INSTANCE.convert(
                userId, experience, totalExperience,
                bizId, bizType.getType(), bizType.getTitle(), description);
        experienceLogMapper.insert(record);
    }

}
