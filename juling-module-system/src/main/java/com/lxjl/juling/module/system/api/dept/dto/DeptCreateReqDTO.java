package com.lxjl.juling.module.system.api.dept.dto;

import lombok.Data;

/**
 * 部门（组织节点）创建 Request DTO（跨模块）
 *
 * <p>为什么用窄 DTO 而不是直接暴露 {@code DeptSaveReqVO}：这是跨模块 API，
 * 只放开调用方真正需要的字段，避免其它模块随手改组织节点的内部属性。
 *
 * @author 亚特
 */
@Data
public class DeptCreateReqDTO {

    /** 部门名称 */
    private String name;
    /** 父部门编号 */
    private Long parentId;
    /** 节点类型：ORG 组织 / STORE 门店（见 organization-architecture-design §2.1） */
    private String deptType;
    /** 显示顺序 */
    private Integer sort;

}
