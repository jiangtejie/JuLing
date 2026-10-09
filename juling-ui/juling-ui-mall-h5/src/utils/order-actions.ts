import type { PaymentProof } from '@/types';

/**
 * 「上传付款凭证」入口的可见性与文案（订单详情卡片按钮 + 底部操作栏共用）
 *
 * 为什么需要这个判断：
 * 1. 门店提交凭证后，订单在**两级审批**里（审核中 10）或已通过（20）——此时后端不允许再上传
 *    （会返回 1_011_000_043），前端必须把入口收起来，否则门店点进去只会被拒；
 * 2. 已提交但审批还没走完（凭证 status=0 待审核）时同理：等审核结果即可，不该再引导上传；
 * 3. 只有「货款没收齐、订单不在异常态、且没有待审核/已通过的凭证」才显示；
 *    凭证被驳回（status=2）时重新显示，文案改成「重新上传付款凭证」。
 *
 * 之前底部操作栏把文案写死成「上传凭证」，导致提交过凭证的订单看起来还在让门店上传——
 * 这里把文案与可见性一起收敛，两处入口共用同一份判断。
 */
export function resolveUploadAction(input: {
  auditStatus?: null | number;
  isAbnormal: boolean;
  proofs: PaymentProof[];
  remainAmount: number;
}): { barText: string; text: string; visible: boolean } {
  const { auditStatus, isAbnormal, proofs, remainAmount } = input;
  const hasProof = proofs.length > 0;
  // 还有待审核的凭证（已提交、等审批结果）
  const hasPendingProof = proofs.some((proof) => proof.status === 0);
  // 审核中(10) / 已通过(20)：凭证已在审批或已认定
  const auditLocked = auditStatus === 10 || auditStatus === 20;
  return {
    visible: remainAmount > 0 && !isAbnormal && !hasPendingProof && !auditLocked,
    text: hasProof ? '重新上传付款凭证' : '上传付款凭证',
    barText: hasProof ? '重新上传凭证' : '上传凭证',
  };
}
