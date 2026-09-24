/** 后端统一响应结构（juling-server / yudao 体系） */
export interface ApiResult<T = unknown> {
  code: number;
  data: T;
  msg: string;
}

/** 分页请求参数 */
export interface PageParam {
  pageNo: number;
  pageSize: number;
}

/** 分页响应结构 */
export interface PageResult<T> {
  list: T[];
  total: number;
}

/** 下拉选项 */
export interface Option<T = string> {
  label: string;
  value: T;
  disabled?: boolean;
}
