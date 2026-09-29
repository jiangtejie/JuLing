package com.lxjl.juling.module.trade.service.order;

import com.lxjl.juling.module.trade.dal.dataobject.order.TradeOrderDO;

/**
 * 交易订单（门店要货）审核 Service
 *
 * 门店订货链 S1（2026-09 调整）：门店在 H5 提交付款凭证后**直接**提交两级审批
 * （BPM 流程 {@link #BPM_PROCESS_DEFINITION_KEY}：供应链 → 财务出纳），审核通过才允许发货；
 * 原来的后台「收款核验」已取消，核收款的职责由财务审批节点承接。
 *
 * @author 亚特
 */
public interface TradeOrderAuditService {

    /**
     * 门店要货审核的 BPM 流程定义 Key
     */
    String BPM_PROCESS_DEFINITION_KEY = "trade-order-store-audit";

    /**
     * 提交审核（管理后台手工提交）
     *
     * @param orderId  订单编号
     * @param userId   操作人（管理后台用户）编号，作为流程发起人
     */
    void submitAudit(Long orderId, Long userId);

    /**
     * 事务提交后自动提交审核（独立事务，失败只记日志，不影响已提交的收款）
     *
     * 为什么需要单独一个入口：BPM 创建流程实例内部是嵌套事务，一旦抛错会把**当前**事务标记为
     * rollback-only；若在外层用 try/catch 吞掉，外层提交时仍会抛 UnexpectedRollbackException
     * （操作人看到的是"系统异常"，且失败原因彻底丢失）。因此自动提交必须在收款事务**提交之后**
     * 用独立事务执行，失败则订单停留在「待发货 + 待提交审核」，可在订单详情页手工重新提交。
     *
     * @param orderId 订单编号
     * @param userId  操作人编号
     */
    void submitAuditAfterCommit(Long orderId, Long userId);

    /**
     * 事务提交后自动提交审核，流程发起人用系统配置的账号
     *
     * <p>门店在 H5 提交凭证时触发，此时登录身份是会员（没有该流程定义的发起权限），
     * 因此改用 `juling.trade.order-audit.start-user-id`（默认 1 超级管理员）作为流程发起人。
     *
     * @param orderId 订单编号
     */
    void submitAuditAutoAfterCommit(Long orderId);

    /**
     * 更新审核结果（BPM 审批完成时回调）
     *
     * <p>审批结果同时回写付款凭证：通过 = 凭证「已认定」（confirmed_amount = 申报金额）；
     * 驳回 = 凭证「已驳回」、订单已收金额归零，门店可在 H5 重新上传后自动再次提交审批。
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
