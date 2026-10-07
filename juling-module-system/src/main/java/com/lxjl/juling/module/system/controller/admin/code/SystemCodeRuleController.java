package com.lxjl.juling.module.system.controller.admin.code;

import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.system.controller.admin.code.vo.SystemCodeRulePageReqVO;
import com.lxjl.juling.module.system.controller.admin.code.vo.SystemCodeRuleRespVO;
import com.lxjl.juling.module.system.controller.admin.code.vo.SystemCodeRuleSaveReqVO;
import com.lxjl.juling.module.system.dal.dataobject.code.SystemCodeRuleDO;
import com.lxjl.juling.module.system.service.code.CodeRuleService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

import static com.lxjl.juling.framework.common.pojo.CommonResult.success;

/**
 * 管理后台 - 编码规则
 *
 * <p>主数据的业务编码由「基础资料 → 编码规则」统一配置：每个主数据对象一套前缀 + 流水长度，
 * 建档时自动发号。见 docs/master-data-unified-design.md §4.2。
 *
 * @author 亚特
 */
@Tag(name = "管理后台 - 编码规则")
@RestController
@RequestMapping("/system/code-rule")
@Validated
public class SystemCodeRuleController {

    @Resource
    private CodeRuleService codeRuleService;

    @PostMapping("/create")
    @Operation(summary = "创建编码规则")
    @PreAuthorize("@ss.hasPermission('system:code-rule:create')")
    public CommonResult<Long> createCodeRule(@Valid @RequestBody SystemCodeRuleSaveReqVO createReqVO) {
        return success(codeRuleService.createCodeRule(createReqVO));
    }

    @PutMapping("/update")
    @Operation(summary = "更新编码规则", description = "规则标识不可改；把流水值改小会发出重复编码，请谨慎")
    @PreAuthorize("@ss.hasPermission('system:code-rule:update')")
    public CommonResult<Boolean> updateCodeRule(@Valid @RequestBody SystemCodeRuleSaveReqVO updateReqVO) {
        codeRuleService.updateCodeRule(updateReqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除编码规则", description = "被主数据引用的规则不建议删除，否则该对象的新建会取不到编码")
    @Parameter(name = "id", description = "编号", required = true)
    @PreAuthorize("@ss.hasPermission('system:code-rule:delete')")
    public CommonResult<Boolean> deleteCodeRule(@RequestParam("id") Long id) {
        codeRuleService.deleteCodeRule(id);
        return success(true);
    }

    @GetMapping("/get")
    @Operation(summary = "获得编码规则")
    @Parameter(name = "id", description = "编号", required = true, example = "1")
    @PreAuthorize("@ss.hasPermission('system:code-rule:query')")
    public CommonResult<SystemCodeRuleRespVO> getCodeRule(@RequestParam("id") Long id) {
        SystemCodeRuleDO rule = codeRuleService.getCodeRule(id);
        SystemCodeRuleRespVO vo = BeanUtils.toBean(rule, SystemCodeRuleRespVO.class);
        fillNextCode(List.of(vo));
        return success(vo);
    }

    @GetMapping("/page")
    @Operation(summary = "获得编码规则分页")
    @PreAuthorize("@ss.hasPermission('system:code-rule:query')")
    public CommonResult<PageResult<SystemCodeRuleRespVO>> getCodeRulePage(@Valid SystemCodeRulePageReqVO pageReqVO) {
        PageResult<SystemCodeRuleDO> pageResult = codeRuleService.getCodeRulePage(pageReqVO);
        PageResult<SystemCodeRuleRespVO> result = BeanUtils.toBean(pageResult, SystemCodeRuleRespVO.class);
        fillNextCode(result.getList());
        return success(result);
    }

    @GetMapping("/simple-list")
    @Operation(summary = "获得编码规则精简列表", description = "主要用于前端的下拉选项")
    public CommonResult<List<SystemCodeRuleRespVO>> getCodeRuleSimpleList() {
        List<SystemCodeRuleDO> list = codeRuleService.getCodeRuleList();
        List<SystemCodeRuleRespVO> result = BeanUtils.toBean(list, SystemCodeRuleRespVO.class);
        fillNextCode(result);
        return success(result);
    }

    /**
     * 填充「下一个编码预览」：让管理员一眼看出当前配置会发什么号
     */
    private void fillNextCode(List<SystemCodeRuleRespVO> list) {
        list.forEach(vo -> vo.setNextCode(vo.getPrefix() + StrUtil.padPre(
                String.valueOf(ObjectUtil.defaultIfNull(vo.getCurrentValue(), 0L) + 1),
                vo.getSeqLength(), '0')));
    }

}