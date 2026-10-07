# 供应商主数据扩展设计（采购部门需求）

> **状态：一期已落地**（2026-10，[sql/local/62](../sql/local/62_supplier_profile.sql)）。落地字段与本文 §2.1
> 原提案**不完全一致** —— 按用户最新清单收敛（账户与合同做成主表字段，未做多账户/合同-组织子表），
> 实际落地以 §2.1 的「实际落地」表为准。
>
> 来源：采购部门 —— 金蝶建档时采购端口只能录供应商名称，缺开票资质、结账方式、税点、
> 账户、合同签订（含签订的组织）、交期等信息，导致下游报销/财务/计划拿不到这些数据。
> 本文给出在这套系统里的落地方案。相关蓝图见 `docs/intelligent-system-blueprint.md`。

## 1. 现状盘点

`erp_supplier` 现有 21 列：`name / contact / mobile / telephone / email / fax / remark / status / sort /
taxNo / taxPercent / bankName / bankAccount / bankAddress`（+ 租户与审计列）。
库里已有 1 条真实数据（重庆彩云西南食品有限公司，含工行账户），说明账户字段已在用。

供应商被 19 个文件引用：采购订单、采购入库、采购退货、付款单、其他入库单
（`ErpPurchaseOrderDO`、`ErpPurchaseInDO`、`ErpPurchaseReturnDO`、`ErpFinancePaymentDO`、`ErpStockInDO`）
—— 也就是**档案已经贯穿采购与付款链路**，缺的是字段与子表。

| 需求项 | 现状 | 结论 |
|---|---|---|
| 供应商名称 | 有 | 保留 |
| 是否能开票 | **无** | 新增 |
| 结账方式 | **无** | 新增（与蓝图第 7 节账期抽象一致） |
| 开票税点 | 有 `taxPercent`（单值，未区分默认/实际） | 扩展为「默认税率 + 发票类型」 |
| 账户信息 | 有单账户（bankName/bankAccount/bankAddress） | 升级为**多账户子表**，支持默认账户与币种 |
| 合同签订（是否签订 / 哪几个组织） | **无** | 新增**合同×组织**子表 |
| 交期时间 | **无** | 新增（供应商级，按品类细化留二期） |
| 证照/合同附件 | **无** | 新增附件字段（复用 infra 文件服务） |

跨模块现状：**没有 `juling-module-erp-api`**（Mall 侧的 trade-api 是既有范例），也没有 FMS 的 api 包，
所以下游模块目前无法通过标准方式读取供应商扩展信息 —— 这是本需求要一并补的基础设施。

## 2. 数据模型

### 2.1 `erp_supplier` 扩展列（一期）—— **实际落地**

**复用现有列（不重复造字段）**：供应商名称 → `name`；税号 → `tax_no`；银行账号 → `bank_account`；
开户银行 → `bank_name`；**开票税点 → `tax_percent`**（语义明确为开票税率，0 表示免税）。
`bank_address`（开户地址）保留 —— 它与新增的注册地址是两回事：注册地址是开专票要的营业地址，
开户地址是银行侧的地址。

**新增 12 列**（[sql/local/62](../sql/local/62_supplier_profile.sql)，实测连续执行 3 次结果一致）：

| 需求项 | 列 | 类型 | 说明 |
|---|---|---|---|
| 账户信息 | `account_name` | varchar(128) | 户名（银行账户的开户名称） |
| 账户信息 | `registered_address` | varchar(255) | 注册地址（营业执照地址；开专票需要） |
| 结账方式 | `settlement_type` | varchar(32) | 字典 `erp_supplier_settlement_type`：月结 / 半月结 / 次结(先款后货) / 次结(先货后款) |
| 结账方式 | `credit_days` | int4 | 账期天数（月结 30、半月结 15） |
| 开票情况 | `invoice_mode` | varchar(32) | 字典 `erp_supplier_invoice_mode`：全额开票 / 按销售额比例开票 / 需加税点 / 不开发票 |
| 开票情况 | `invoice_ratio` | numeric(5,2) | 开票比例(%)，如 15~25 |
| 开票类型 | `invoice_type` | varchar(32) | 字典 `erp_supplier_invoice_type`：增值税普通发票 / 增值税专用发票 |
| 交期时间 | `delivery_days` | int4 | 下单到到货的承诺天数 |
| 合同签订 | `contract_signed` | boolean | 是否已签订 |
| 合同签订 | `contract_entity` | varchar(128) | 签订主体（由亚特哪个公司签订） |
| 证照 | `business_license_urls` | varchar(1024) | 营业执照（文件/图片，逗号分隔） |
| 证照 | `production_license_urls` | varchar(1024) | 生产许可证（文件/图片，逗号分隔） |

**与原提案的差异（有意收敛）**：

| 原提案 | 实际 | 原因 |
|---|---|---|
| `invoiceable` 是否能开票 | 并入 `invoice_mode` 的「不开发票」选项 | 一个字段能表达完，不必两个 |
| 结账方式 = 现结/月结/货到付款/预付 | 改为月结/半月结/次结(先款后货/先货后款) | 按采购实际口径 |
| 多账户子表 | **未做**，主表单账户 + 户名 | 用户要求主表字段；子表留二期 |
| 合同×组织子表 | **未做**，主表 `contract_signed` + `contract_entity` | 同上；`contract_entity` 为自由文本，将来可升级为指向 `system_dept` |
| `cooperation_status` / `license_expiry` / `settle_day` | **未做** | 用户清单里没有，避免过度设计 |

**配套**：3 个字典（11580-11582）；后端 DO / SaveReqVO / RespVO（含 `@ExcelProperty` 导出）/
PageReqVO 与 Mapper 筛选（结账方式、开票情况、开票类型、是否签订合同）；前端表单按
「基础信息 / 账户与税务 / 开票 / 结算与交期 / 合同与证照」五组用 `Divider` 分组，
列表新增结账方式/账期/开票情况/开票类型/税点/交期/合同/签订主体 8 列，
搜索新增结账方式/开票情况/是否签订合同，弹窗宽度 `w-1/2` → `w-3/4`。

### 2.2 新增子表（二期）

**`erp_supplier_account`（多账户）**：`supplier_id / account_name / bank_name / bank_account /
bank_address / currency / is_default / remark`
> 金蝶只能存一个账户；实际付款常需按币种或用途选账户。付款单选定供应商后默认带出 `is_default` 的账户，
> 允许按单覆盖（覆盖需留痕）。

**`erp_supplier_org_contract`（合同 × 组织）**：`supplier_id / org_id / signed / contract_no /
sign_date / start_date / end_date / file_url / remark`
> 这是需求里「签订了哪几个组织」的落点：一个供应商在多个组织下各自可能有/没有合同。
> **`org_id` 指向 `system_dept.id`**，取公司层节点（128 重庆萍姐品牌管理公司 / 131 亚特萍姐商贸公司 …），
> 即"这份合同由亚特哪个主体签的"。组织语义已核实关闭，见
> [`docs/organization-model.md`](./organization-model.md)。

**（三期，按需）`erp_supplier_product` / `erp_supplier_category`**：按商品或品类维护交期、供货比例、
最小起订量 —— 用于计划侧更精确的排期。

### 2.3 字典

`erp_supplier_settlement_type`（结账方式）、`erp_supplier_invoice_type`（发票类型）、
`erp_supplier_cooperation_status`（合作状态）——前端下拉与列表筛选用字典，不硬编码。

## 3. 下游怎么拿到（关键：本系统内不需要"同步/推送"）

替代金蝶的意义正在这里：**报销 / 财务 / 计划与供应商在同一个库里**，做成主数据后下游直接引用即可，
不需要金蝶那种跨模块同步配置。

| 下游 | 用到的字段 | 接入方式 |
|---|---|---|
| 财务（付款单 `erp_finance_payment`）| 默认账户、账户列表、结账方式、开票信息 | 选供应商自动带出默认账户；付款审批页显示税点与发票类型 |
| 报销（**当前无此模块，需新建**）| 是否可开票、发票类型、税号 | 报销单选供应商时校验「该供应商不可开票」并提示，发票信息自动带出 |
| 计划（**当前无任何计划模块，需新建**）| 交期天数（+ 品类交期） | 采购计划按交期倒排下单日期、到货预警；到货后回写实际交期用于准时率考核 |
| 采购单据（订单/入库）| 交期、结算方式、默认税率 | 采购订单默认带出、允许按单覆盖 |

技术落地：**新建 `juling-module-erp-api`**，暴露 `ErpSupplierApi#getSupplier(id)` /
`getSupplierList(ids)` 返回含扩展字段的 DTO；跨模块统一走该 API，不直连表（沿用本仓库 trade-api 的惯例）。
后续 ERP 业务单据自动生成凭证时，同样需要给 FMS 建 `juling-module-fms-api`。

## 4. 建档与变更管控

- 流程：采购建档 → 财务复核（税率 / 账户 / 结算方式）→ 生效；可通过 BPM 配置审批流（引擎已在库中）。
- 关键字段（账户、税点、结算方式、合同）**变更必须留痕**：建议独立变更历史表，或统一走 BPM 审批记录。
- 权限点：`erp:supplier:query / create / update / delete` + 财务复核专属权限；列表可按合作状态、
  是否可开票、结账方式筛选。

## 5. 分期落地

| 阶段 | 内容 | 工期 |
|---|---|---|
| 一期 | 扩展列 + 3 个字典 + 供应商表单分组（基础 / 开票 / 结算账期 / 交期与证照）+ 列表列与筛选 + `erp-api` 暴露查询 | 4–5 天 |
| 二期 | 多账户子表 + 合同×组织子表 + 附件上传 + 变更留痕 | 3–5 天 |
| 三期 | 采购订单/入库带出交期与结算方式；财务付款带出默认账户；报销与计划接入（依赖这两个模块先建） | 与采购链同期 |

## 6. 待确认（影响表结构）

1. ~~「组织」指什么维度~~ **已关闭**：组织 = `system_dept` 部门树节点（加盟店 134–146、公司 128/131…、
   采购 163 均在树上），合同 `org_id` 直接指向它，不新建组织档案。见 `docs/organization-model.md`。
2. **报销与计划是否在本系统新建**：当前没有报销模块；计划侧无任何模块（原 MES 日历/点检计划已随 MES 模块删除），
   没有采购计划/物料需求计划。若对接外部系统，则要改成接口推送方案。
3. **交期粒度**：供应商统一一个值，还是按商品/品类分别？是否需要记录**实际到货交期**做准时率考核？
4. **多账户**：是否允许按币种设置多个默认账户？付款时是否允许临时改账户（需留痕）？
5. **税率来源**：供应商默认税率与商品税率冲突时以谁为准（建议：商品 > 供应商默认，且允许按单覆盖）？
