package com.lxjl.juling.module.mes.dal.mysql.wm.outsourceissue;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.module.mes.controller.admin.wm.outsourceissue.vo.line.MesWmOutsourceIssueLinePageReqVO;
import com.lxjl.juling.module.mes.dal.dataobject.wm.outsourceissue.MesWmOutsourceIssueLineDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * MES 外协发料单行 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
public interface MesWmOutsourceIssueLineMapper extends BaseMapperX<MesWmOutsourceIssueLineDO> {

    default PageResult<MesWmOutsourceIssueLineDO> selectPage(MesWmOutsourceIssueLinePageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<MesWmOutsourceIssueLineDO>()
                .eqIfPresent(MesWmOutsourceIssueLineDO::getIssueId, reqVO.getIssueId())
                .orderByDesc(MesWmOutsourceIssueLineDO::getId));
    }

    default List<MesWmOutsourceIssueLineDO> selectListByIssueId(Long issueId) {
        return selectList(MesWmOutsourceIssueLineDO::getIssueId, issueId);
    }

    default void deleteByIssueId(Long issueId) {
        delete(MesWmOutsourceIssueLineDO::getIssueId, issueId);
    }

}
