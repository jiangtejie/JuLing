package com.lxjl.juling.module.bill.api;

import com.lxjl.juling.module.bill.api.dto.BillLogCreateReqDTO;
import com.lxjl.juling.module.bill.api.dto.BillRelationCreateReqDTO;
import com.lxjl.juling.module.bill.api.dto.BillTypeRespDTO;
import com.lxjl.juling.module.bill.dal.dataobject.BillRelationDO;

import java.util.List;
import java.util.Map;

/**
 * 单据平台 API
 *
 * 其它模块（ERP/商城/WMS…）**只能**通过本接口使用单据能力：
 * 单号生成、状态机校验、单据关联（下推）、操作日志、扩展字段。
 *
 * @author 亚特
 */
public interface BillPlatformApi {

    /** 生成单据号（按 bill_type 的编号规则 + 组织 + 期间，事务内原子递增） */
    String generateNo(String billType, Long orgId);

    /** 单据状态迁移校验（不合法抛异常） */
    void validateTransition(String billType, Integer fromStatus, Integer toStatus);

    /** 写单据操作日志 */
    void log(BillLogCreateReqDTO reqDTO);

    /** 建立单据关联（下推）；重复下推返回 false */
    boolean addRelation(BillRelationCreateReqDTO reqDTO);

    /** 是否已下推过某类下游单据 */
    boolean hasRelation(String sourceType, Long sourceId, String targetType);

    /** 查询上游单据（我是谁下推来的） */
    List<BillRelationDO> getUpstreamList(String targetType, Long targetId);

    /** 查询下游单据（我下推了谁） */
    List<BillRelationDO> getDownstreamList(String sourceType, Long sourceId);

    /** 保存单据扩展字段 */
    void saveExt(String billType, Long billId, Map<String, String> extMap);

    /** 读取单据扩展字段 */
    Map<String, String> getExtMap(String billType, Long billId);

    /** 获得单据类型配置 */
    BillTypeRespDTO getType(String billType);

}
