package com.lxjl.juling.module.system.api.dept;

import cn.hutool.core.collection.CollUtil;
import com.lxjl.juling.framework.common.util.collection.CollectionUtils;
import com.lxjl.juling.module.system.api.dept.dto.DeptCreateReqDTO;
import com.lxjl.juling.module.system.api.dept.dto.DeptRespDTO;

import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * 部门 API 接口
 *
 * @author 亚特
 */
public interface DeptApi {

    /**
     * 获得部门信息
     *
     * @param id 部门编号
     * @return 部门信息
     */
    /**
     * 创建部门（组织节点）
     *
     * <p>供 ERP 的「建门店」编排使用 —— 门店节点与客户档案必须**一次动作同时建**
     * （organization-architecture-design §7 决策 ④），否则会出现"只有节点没档案"的悬空单。
     * 调用方需处于事务中，本方法会随其一起回滚。
     *
     * @param reqDTO 创建信息
     * @return 部门编号
     */
    Long createDept(DeptCreateReqDTO reqDTO);

    DeptRespDTO getDept(Long id);

    /**
     * 获得部门信息数组
     *
     * @param ids 部门编号数组
     * @return 部门信息数组
     */
    List<DeptRespDTO> getDeptList(Collection<Long> ids);

    /**
     * 校验部门们是否有效。如下情况，视为无效：
     * 1. 部门编号不存在
     * 2. 部门被禁用
     *
     * @param ids 角色编号数组
     */
    void validateDeptList(Collection<Long> ids);

    /**
     * 获得指定编号的部门 Map
     *
     * @param ids 部门编号数组
     * @return 部门 Map
     */
    default Map<Long, DeptRespDTO> getDeptMap(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return Collections.emptyMap();
        }
        List<DeptRespDTO> list = getDeptList(ids);
        return CollectionUtils.convertMap(list, DeptRespDTO::getId);
    }

    /**
     * 获得指定部门的所有子部门
     *
     * @param id 部门编号
     * @return 子部门列表
     */
    default List<DeptRespDTO> getChildDeptList(Long id) {
        return getChildDeptList(Collections.singleton(id));
    }

    /**
     * 获得指定部门的所有子部门
     *
     * @param ids 部门编号数组
     * @return 子部门列表
     */
    List<DeptRespDTO> getChildDeptList(Collection<Long> ids);

    /**
     * 获得指定部门的所有父部门
     *
     * 按直属父部门到根部门的顺序返回，不包含指定部门自身。
     *
     * @param id 部门编号
     * @return 父部门列表
     */
    List<DeptRespDTO> getParentDeptList(Long id);

}
