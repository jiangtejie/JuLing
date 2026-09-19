package com.lxjl.juling.module.pms.service.pm.project;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.pms.controller.admin.pm.project.vo.template.PmsProjectTemplatePageReqVO;
import com.lxjl.juling.module.pms.controller.admin.pm.project.vo.template.PmsProjectTemplateSaveReqVO;
import com.lxjl.juling.module.pms.dal.dataobject.pm.project.PmsProjectTemplateDO;

/**
 * PMS 项目模板 Service 接口
 *
 * @author 棱信矩灵
 */
public interface PmsProjectTemplateService {

    /**
     * 创建项目模板
     *
     * @param createReqVO 创建信息
     * @return 模板编号
     */
    Long createProjectTemplate(PmsProjectTemplateSaveReqVO createReqVO);

    /**
     * 更新项目模板
     *
     * @param updateReqVO 更新信息
     */
    void updateProjectTemplate(PmsProjectTemplateSaveReqVO updateReqVO);

    /**
     * 删除项目模板
     *
     * @param id 模板编号
     */
    void deleteProjectTemplate(Long id);

    /**
     * 获得项目模板
     *
     * @param id 模板编号
     * @return 项目模板
     */
    PmsProjectTemplateDO getProjectTemplate(Long id);

    /**
     * 获得项目模板分页
     *
     * @param pageReqVO 分页查询
     * @return 项目模板分页
     */
    PageResult<PmsProjectTemplateDO> getProjectTemplatePage(PmsProjectTemplatePageReqVO pageReqVO);

}
