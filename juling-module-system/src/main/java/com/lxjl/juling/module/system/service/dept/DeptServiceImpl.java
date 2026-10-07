package com.lxjl.juling.module.system.service.dept;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.ObjectUtil;
import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.framework.datapermission.core.annotation.DataPermission;
import com.lxjl.juling.module.system.controller.admin.dept.vo.dept.DeptBizStatusUpdateReqVO;
import com.lxjl.juling.module.system.controller.admin.dept.vo.dept.DeptListReqVO;
import com.lxjl.juling.module.system.controller.admin.dept.vo.dept.DeptSaveReqVO;
import com.lxjl.juling.module.system.dal.dataobject.dept.DeptDO;
import com.lxjl.juling.module.system.dal.mysql.dept.DeptMapper;
import com.lxjl.juling.module.system.dal.redis.RedisKeyConstants;
import com.lxjl.juling.module.system.enums.dept.DeptBusinessStatusEnum;
import com.lxjl.juling.module.system.enums.dept.DeptTypeEnum;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.google.common.annotations.VisibleForTesting;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import jakarta.annotation.Resource;
import java.time.LocalDateTime;
import java.util.*;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertSet;
import static com.lxjl.juling.module.system.enums.ErrorCodeConstants.*;

/**
 * 部门 Service 实现类
 *
 * @author 亚特
 */
@Service
@Validated
@Slf4j
public class DeptServiceImpl implements DeptService {

    @Resource
    private DeptMapper deptMapper;

    @Override
    @CacheEvict(cacheNames = RedisKeyConstants.DEPT_CHILDREN_ID_LIST,
            allEntries = true) // allEntries 清空所有缓存，因为操作一个部门，涉及到多个缓存
    public Long createDept(DeptSaveReqVO createReqVO) {
        if (createReqVO.getParentId() == null) {
            createReqVO.setParentId(DeptDO.PARENT_ID_ROOT);
        }
        // 校验父部门的有效性
        validateParentDept(null, createReqVO.getParentId());
        // 校验部门名的唯一性
        validateDeptNameUnique(null, createReqVO.getParentId(), createReqVO.getName());

        // 插入部门
        DeptDO dept = BeanUtils.toBean(createReqVO, DeptDO.class);
        normalizeDeptBusiness(dept); // 组织节点无营业状态；闭店写留痕
        deptMapper.insert(dept);
        return dept.getId();
    }

    @Override
    @CacheEvict(cacheNames = RedisKeyConstants.DEPT_CHILDREN_ID_LIST,
            allEntries = true) // allEntries 清空所有缓存，因为操作一个部门，涉及到多个缓存
    public void updateDept(DeptSaveReqVO updateReqVO) {
        if (updateReqVO.getParentId() == null) {
            updateReqVO.setParentId(DeptDO.PARENT_ID_ROOT);
        }
        // 校验自己存在
        validateDeptExists(updateReqVO.getId());
        // 校验父部门的有效性
        validateParentDept(updateReqVO.getId(), updateReqVO.getParentId());
        // 校验部门名的唯一性
        validateDeptNameUnique(updateReqVO.getId(), updateReqVO.getParentId(), updateReqVO.getName());

        // 更新部门
        DeptDO updateObj = BeanUtils.toBean(updateReqVO, DeptDO.class);
        boolean clearClosed = normalizeDeptBusiness(updateObj);
        deptMapper.updateById(updateObj);
        if (clearClosed) {
            // updateById 会忽略 null 字段：复开 / 组织节点必须显式清空闭店留痕
            clearDeptClosedFields(updateObj.getId());
        }
    }

    @Override
    @CacheEvict(cacheNames = RedisKeyConstants.DEPT_CHILDREN_ID_LIST,
            allEntries = true) // allEntries 清空所有缓存，因为操作一个部门，涉及到多个缓存
    public void updateDeptBusinessStatus(DeptBizStatusUpdateReqVO reqVO) {
        DeptDO dept = getDept(reqVO.getId());
        if (dept == null) {
            throw exception(DEPT_NOT_FOUND);
        }
        if (!DeptTypeEnum.STORE.getType().equals(dept.getDeptType())) {
            throw exception(DEPT_BUSINESS_STATUS_ONLY_STORE);
        }
        boolean closed = DeptBusinessStatusEnum.CLOSED.getStatus().equals(reqVO.getBusinessStatus());
        DeptDO updateObj = new DeptDO();
        updateObj.setId(reqVO.getId());
        updateObj.setBusinessStatus(reqVO.getBusinessStatus());
        if (closed) {
            updateObj.setClosedTime(LocalDateTime.now());
            updateObj.setClosedReason(reqVO.getClosedReason());
        }
        deptMapper.updateById(updateObj);
        if (!closed) {
            clearDeptClosedFields(reqVO.getId());
        }
    }

    /**
     * 归一化「营业状态 / 闭店留痕」
     *
     * <p>· 组织节点没有营业状态 —— 强制「营业」且不留闭店痕迹；
     * <br>· 门店闭店 —— 记闭店时间（原因由 VO 带入）；
     * <br>· 门店复开 —— 清空留痕。
     *
     * @return 是否需要显式清空 closed_time / closed_reason（updateById 会忽略 null 字段）
     */
    private boolean normalizeDeptBusiness(DeptDO dept) {
        if (!DeptTypeEnum.STORE.getType().equals(dept.getDeptType())) {
            dept.setDeptType(DeptTypeEnum.ORG.getType());
            dept.setBusinessStatus(DeptBusinessStatusEnum.OPEN.getStatus());
            dept.setClosedTime(null);
            dept.setClosedReason(null);
            return true;
        }
        if (DeptBusinessStatusEnum.CLOSED.getStatus().equals(dept.getBusinessStatus())) {
            dept.setClosedTime(LocalDateTime.now());
            return false;
        }
        dept.setBusinessStatus(DeptBusinessStatusEnum.OPEN.getStatus());
        dept.setClosedTime(null);
        dept.setClosedReason(null);
        return true;
    }

    /** 显式清空闭店留痕（updateById 忽略 null 字段，只能走 UpdateWrapper） */
    private void clearDeptClosedFields(Long id) {
        deptMapper.update(null, new LambdaUpdateWrapper<DeptDO>()
                .eq(DeptDO::getId, id)
                .set(DeptDO::getClosedTime, null)
                .set(DeptDO::getClosedReason, null));
    }

    @Override
    @CacheEvict(cacheNames = RedisKeyConstants.DEPT_CHILDREN_ID_LIST,
            allEntries = true) // allEntries 清空所有缓存，因为操作一个部门，涉及到多个缓存
    public void deleteDept(Long id) {
        // 校验是否存在
        validateDeptExists(id);
        // 校验是否有子部门
        if (deptMapper.selectCountByParentId(id) > 0) {
            throw exception(DEPT_EXITS_CHILDREN);
        }
        // 删除部门
        deptMapper.deleteById(id);
    }

    @Override
    @CacheEvict(cacheNames = RedisKeyConstants.DEPT_CHILDREN_ID_LIST,
            allEntries = true) // allEntries 清空所有缓存，因为操作一个部门，涉及到多个缓存
    public void deleteDeptList(List<Long> ids) {
        // 校验是否有子部门
        for (Long id : ids) {
            if (deptMapper.selectCountByParentId(id) > 0) {
                throw exception(DEPT_EXITS_CHILDREN);
            }
        }

        // 批量删除部门
        deptMapper.deleteByIds(ids);
    }

    @VisibleForTesting
    void validateDeptExists(Long id) {
        if (id == null) {
            return;
        }
        DeptDO dept = deptMapper.selectById(id);
        if (dept == null) {
            throw exception(DEPT_NOT_FOUND);
        }
    }

    @VisibleForTesting
    void validateParentDept(Long id, Long parentId) {
        if (parentId == null || DeptDO.PARENT_ID_ROOT.equals(parentId)) {
            return;
        }
        // 1. 不能设置自己为父部门
        if (Objects.equals(id, parentId)) {
            throw exception(DEPT_PARENT_ERROR);
        }
        // 2. 父部门不存在
        DeptDO parentDept = deptMapper.selectById(parentId);
        if (parentDept == null) {
            throw exception(DEPT_PARENT_NOT_EXITS);
        }
        // 3. 递归校验父部门，如果父部门是自己的子部门，则报错，避免形成环路
        if (id == null) { // id 为空，说明新增，不需要考虑环路
            return;
        }
        for (int i = 0; i < Short.MAX_VALUE; i++) {
            // 3.1 校验环路
            parentId = parentDept.getParentId();
            if (Objects.equals(id, parentId)) {
                throw exception(DEPT_PARENT_IS_CHILD);
            }
            // 3.2 继续递归下一级父部门
            if (parentId == null || DeptDO.PARENT_ID_ROOT.equals(parentId)) {
                break;
            }
            parentDept = deptMapper.selectById(parentId);
            if (parentDept == null) {
                break;
            }
        }
    }

    @VisibleForTesting
    void validateDeptNameUnique(Long id, Long parentId, String name) {
        DeptDO dept = deptMapper.selectByParentIdAndName(parentId, name);
        if (dept == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的部门
        if (id == null) {
            throw exception(DEPT_NAME_DUPLICATE);
        }
        if (ObjectUtil.notEqual(dept.getId(), id)) {
            throw exception(DEPT_NAME_DUPLICATE);
        }
    }

    @Override
    public DeptDO getDept(Long id) {
        return deptMapper.selectById(id);
    }

    @Override
    public List<DeptDO> getDeptList(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return Collections.emptyList();
        }
        return deptMapper.selectByIds(ids);
    }

    @Override
    public List<DeptDO> getDeptList(DeptListReqVO reqVO) {
        List<DeptDO> list = deptMapper.selectList(reqVO);
        list.sort(Comparator.comparing(DeptDO::getSort));
        return list;
    }

    @Override
    public List<DeptDO> getChildDeptList(Collection<Long> ids) {
        List<DeptDO> children = new LinkedList<>();
        // 遍历每一层
        Collection<Long> parentIds = ids;
        for (int i = 0; i < Short.MAX_VALUE; i++) { // 使用 Short.MAX_VALUE 避免 bug 场景下，存在死循环
            // 查询当前层，所有的子部门
            List<DeptDO> depts = deptMapper.selectListByParentId(parentIds);
            // 1. 如果没有子部门，则结束遍历
            if (CollUtil.isEmpty(depts)) {
                break;
            }
            // 2. 如果有子部门，继续遍历
            children.addAll(depts);
            parentIds = convertSet(depts, DeptDO::getId);
        }
        return children;
    }

    @Override
    public List<DeptDO> getParentDeptList(Long id) {
        List<DeptDO> parents = new ArrayList<>();
        Set<Long> visitedDeptIds = new HashSet<>();
        visitedDeptIds.add(id);
        DeptDO dept = getDept(id);
        // TODO DONE @AI：使用 Short.MAX_VALUE 限制父链遍历次数，并通过已访问集合提前结束脏数据环路。
        for (int i = 0; i < Short.MAX_VALUE; i++) {
            if (dept == null || dept.getParentId() == null
                    || ObjectUtil.equal(dept.getParentId(), DeptDO.PARENT_ID_ROOT)
                    || visitedDeptIds.contains(dept.getParentId())) {
                break;
            }
            visitedDeptIds.add(dept.getParentId());
            dept = getDept(dept.getParentId());
            if (dept == null) {
                break;
            }
            parents.add(dept);
        }
        return parents;
    }

    @Override
    public List<DeptDO> getDeptListByLeaderUserId(Long id) {
        return deptMapper.selectListByLeaderUserId(id);
    }

    @Override
    @DataPermission(enable = false) // 禁用数据权限，避免建立不正确的缓存
    @Cacheable(cacheNames = RedisKeyConstants.DEPT_CHILDREN_ID_LIST, key = "#id")
    public Set<Long> getChildDeptIdListFromCache(Long id) {
        List<DeptDO> children = getChildDeptList(id);
        return convertSet(children, DeptDO::getId);
    }

    @Override
    public void validateDeptList(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return;
        }
        // 获得科室信息
        Map<Long, DeptDO> deptMap = getDeptMap(ids);
        // 校验
        ids.forEach(id -> {
            DeptDO dept = deptMap.get(id);
            if (dept == null) {
                throw exception(DEPT_NOT_FOUND);
            }
            if (!CommonStatusEnum.ENABLE.getStatus().equals(dept.getStatus())) {
                throw exception(DEPT_NOT_ENABLE, dept.getName());
            }
        });
    }

}
