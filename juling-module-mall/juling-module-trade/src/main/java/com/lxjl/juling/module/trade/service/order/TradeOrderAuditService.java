package com.lxjl.juling.module.trade.service.order;

import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderDO;

/**
 * 交易订单（门店要货）审核 Service
 *
 * 门店订货链 S1：付款核验通过后提交供应链审核（BPM 审批流），审核通过才允许发货。
 *
 * @author 亚特
 */
public interface TradeOrderAuditService {

    /**
     * 门店要货审核的 BPM 流程定义 Key
     */
    String BPM_PROCESS_DEFINITION_KEY = "trade-order-store-audit";

    /**
     * 提交审核
     *
     * @param orderId  订单编号
     * @param userId   操作人（管理后台用户）编号，作为流程发起人
     */
    void submitAudit(Long orderId, Long userId);

    /**
     * 事务提交后自动提交审核（独立事务，失败只记日志，不影响已提交的收款核验）
     *
     * 为什么需要单独一个入口：BPM 创建流程实例内部是嵌套事务，一旦抛错会把**当前**事务标记为
     * rollback-only；若在外层用 try/catch 吞掉，外层提交时仍会抛 UnexpectedRollbackException
     * （操作人看到的是"系统异常"，且失败原因彻底丢失）。因此自动提交必须在收款核验事务**提交之后**
     * 用独立事务执行，失败则订单停留在「待提交审核」，可在订单详情页手工重新提交。
     *
     * @param orderId 订单编号
     * @param userId  操作人编号
     */
    void submitAuditAfterCommit(Long orderId, Long userId);

    /**
     * 更新审核结果（BPM 审批完成时回调）
     *
     * @param orderId   订单编号
     * @param bpmStatus BPM 流程实例状态 {@link com.lxjl.juling.module.bpm.enums.task.BpmProcessInstanceStatusEnum}
     */
    void updateAuditStatus(Long orderId, Integer bpmStatus);

    /**
     * 校验订单允许发货（发货闸门）
     *
     * @param order 订单
     */
    void validateCanDelivery(TradeOrderDO order);

}
