import { TradeOrderStatusEnum } from '@vben/constants';

/**
 * 门店要货订单状态的展示口径（列表与详情共用）。
 *
 * 为什么「待发货」还要再按审核状态细分：
 * 后台的手工发货入口已下线——发货动作只由 ERP 配送出库单审核承接（出库审核时后端把订单
 * 置为已发货并生成门店收货单）。而一张门店要货单要走到发货环节，必须先通过
 * 「供应链 → 财务出纳」两级审批（auditStatus=20 已通过），审批没通过时后端不允许发货。
 *
 * status=10（待发货）只是一个「已收款、等发货」的状态位：它同时覆盖了「审批中」和
 * 「审批已驳回」的订单。如果这里一律显示成「待发货」，操作员会以为马上可以安排发货，
 * 实际却发不出去（审批未通过），也无法从列表看出卡在哪一级审批。
 * 因此待发货必须按 auditStatus 细分出「审核中 / 审核已驳回」，
 * 只有审批通过（20）或直营免审的订单才显示「待发货」。
 */

/** 审核中（TradeOrderAuditStatusEnum：0 待提交、10 审核中、20 已通过、30 已驳回） */
const AUDIT_STATUS_REVIEWING = 10;

/** 审核已驳回 */
const AUDIT_STATUS_REJECTED = 30;

/** 待提交（自动提交审批失败时会停在这里，此时同样不允许发货） */
const AUDIT_STATUS_DRAFT = 0;

/**
 * 根据订单状态与审核状态推导出展示用的颜色与文案。
 *
 * @param row 订单（只需要 status 与 auditStatus）
 * @returns ant-design-vue Tag 可用的 color 与要显示的文字
 */
export function deriveOrderStatus(row: {
  auditStatus?: number;
  status?: number;
}): { color: string; text: string } {
  // 待发货：按审核状态细分（审核通过前不允许发货，避免「待发货」看起来可以发货）
  if (row.status === TradeOrderStatusEnum.UNDELIVERED.status) {
    if (row.auditStatus === AUDIT_STATUS_REVIEWING) {
      return { color: 'processing', text: '审核中' };
    }
    if (row.auditStatus === AUDIT_STATUS_REJECTED) {
      return { color: 'error', text: '审核已驳回' };
    }
    if (row.auditStatus === AUDIT_STATUS_DRAFT) {
      // 自动提交审批失败（如 BPM 流程定义缺失）会停在这里，可在列表点「提交审核」补交
      return { color: 'warning', text: '待提交审核' };
    }
    // 其余情况（20 已通过、直营免审/历史数据没有审核状态）才算真正可发货
    return { color: 'warning', text: '待发货' };
  }

  switch (row.status) {
    // case 顺序按枚举名升序（perfectionist/sort-switch-case），与状态值大小无关
    case TradeOrderStatusEnum.CANCELED.status: {
      return { color: 'default', text: '已取消' };
    }
    case TradeOrderStatusEnum.COMPLETED.status: {
      return { color: 'success', text: '已完成' };
    }
    case TradeOrderStatusEnum.DELIVERED.status: {
      return { color: 'processing', text: '已发货' };
    }
    case TradeOrderStatusEnum.UNPAID.status: {
      return { color: 'default', text: '待支付' };
    }
    default: {
      return { color: 'default', text: '-' };
    }
  }
}
