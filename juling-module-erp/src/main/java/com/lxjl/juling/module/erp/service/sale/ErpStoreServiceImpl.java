package com.lxjl.juling.module.erp.service.sale;

import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.module.erp.controller.admin.sale.vo.customer.ErpCustomerSaveReqVO;
import com.lxjl.juling.module.erp.controller.admin.sale.vo.store.ErpStoreSaveReqVO;
import com.lxjl.juling.module.system.api.dept.DeptApi;
import com.lxjl.juling.module.system.api.dept.dto.DeptCreateReqDTO;
import com.lxjl.juling.module.system.api.dept.dto.DeptRespDTO;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.module.erp.enums.ErrorCodeConstants.*;

/**
 * 「建门店」Service 实现类
 *
 * <p>为什么必须是一个动作（而不是让用户先去组织架构建节点、再去客户信息建档）：
 * 门店节点与客户档案**强制一对一**（organization-architecture-design §7 决策 ④），
 * 分两步做迟早会出现「只有节点没档案」或反过来，订单的部门/结算口径就悬空了。
 *
 * <p>为什么必须是**后端一个事务**（而不是前端调两个接口）：前端两次调用之间失败，
 * 就会留下建了一半的数据；而这里任一环节抛异常，整体回滚。
 * 跨模块调用（erp → system）在同一个线程里，Spring 的事务传播保证它们同属一个事务。
 *
 * @author 亚特
 */
@Service
@Validated
public class ErpStoreServiceImpl implements ErpStoreService {

    /** 节点类型：门店（字典 system_dept_type；组织树只区分「是不是门店」，店型另存） */
    private static final String DEPT_TYPE_STORE = "STORE";

    @Resource
    private ErpCustomerService customerService;
    @Resource
    private DeptApi deptApi;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createStore(ErpStoreSaveReqVO createReqVO) {
        // 1. 父节点校验：按 §10 的约定，门店应直接挂在**品牌或公司**下，
        //    不能挂在另一个门店下 —— 否则又会出现「门店分组」那种中间层，
        //    品牌维度就会重新从结构里消失
        DeptRespDTO parent = deptApi.getDept(createReqVO.getParentId());
        if (parent == null) {
            throw exception(STORE_PARENT_NOT_EXISTS);
        }
        if (DEPT_TYPE_STORE.equals(parent.getDeptType())) {
            throw exception(STORE_PARENT_IS_STORE, parent.getName());
        }

        // 2. 建组织节点（门店类型）
        Long deptId = deptApi.createDept(new DeptCreateReqDTO()
                .setName(createReqVO.getName()).setParentId(createReqVO.getParentId())
                .setDeptType(DEPT_TYPE_STORE).setSort(0));

        // 3. 建客户档案，dept_id 指向刚建的节点 —— 一对一由 uk_erp_customer_dept_id 兜底
        ErpCustomerSaveReqVO customerReqVO = new ErpCustomerSaveReqVO();
        customerReqVO.setName(createReqVO.getName()).setDeptId(deptId)
                .setStoreType(createReqVO.getStoreType())
                .setSettlementMode(createReqVO.getSettlementMode())
                .setCreditDays(createReqVO.getCreditDays()).setCreditLimit(createReqVO.getCreditLimit())
                .setContact(createReqVO.getContact()).setMobile(createReqVO.getMobile())
                .setStatus(CommonStatusEnum.ENABLE.getStatus()).setSort(0);
        return customerService.createCustomer(customerReqVO);
    }

}
