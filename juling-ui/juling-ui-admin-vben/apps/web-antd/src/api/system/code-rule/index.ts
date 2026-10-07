import type { PageParam, PageResult } from '@vben/request';

import { requestClient } from '#/api/request';

export namespace SystemCodeRuleApi {
  /** 编码规则（主数据业务编码的前缀与流水，对齐金蝶「编码规则」） */
  export interface CodeRule {
    id?: number;
    /** 规则标识，与主数据对象一一对应，如 erp_customer */
    ruleKey?: string;
    /** 规则名称 */
    name?: string;
    /** 编码前缀，如 KH */
    prefix?: string;
    /** 流水位数（左补零） */
    seqLength?: number;
    /** 当前已分配到的流水值 */
    currentValue?: number;
    /** 下一个编码预览（后端算好返回） */
    nextCode?: string;
    remark?: string;
    createTime?: number;
  }
}

/** 查询编码规则分页 */
export function getCodeRulePage(params: PageParam) {
  return requestClient.get<PageResult<SystemCodeRuleApi.CodeRule>>(
    '/system/code-rule/page',
    { params },
  );
}

/** 查询编码规则详情 */
export function getCodeRule(id: number) {
  return requestClient.get<SystemCodeRuleApi.CodeRule>(
    `/system/code-rule/get?id=${id}`,
  );
}

/** 新增编码规则 */
export function createCodeRule(data: SystemCodeRuleApi.CodeRule) {
  return requestClient.post('/system/code-rule/create', data);
}

/** 修改编码规则 */
export function updateCodeRule(data: SystemCodeRuleApi.CodeRule) {
  return requestClient.put('/system/code-rule/update', data);
}

/** 删除编码规则 */
export function deleteCodeRule(id: number) {
  return requestClient.delete(`/system/code-rule/delete?id=${id}`);
}
