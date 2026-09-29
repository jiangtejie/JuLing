# 商品分销下线说明

亚特的业务不涉及商品分销，本分支已把商城里的分销（推广员 / 佣金 / 提现）整体移除。
本文记录范围、保留项与回滚方式。

## 1. 背景

分销是上游商城模板自带的能力：分销用户与绑定关系、佣金记录与解冻、佣金提现、
SKU 两级佣金、订单推广人、分销统计与分销海报。亚特只做线下转账订货（见
`docs/offline-payment-refactor.md`），不需要推广返佣，故整体下线。

判定依据（改造前实测）：`trade_brokerage_user`、`trade_brokerage_record` 均为 0 行；
`trade_order.brokerage_user_id` 全为 NULL；`trade_statistics` 0 行；分销菜单 0 条角色绑定；
H5 订货商城 0 处分销界面。即删除不涉及任何订单/交易数据（仅 16 行 SKU 佣金配置值随之下线）。

## 2. 后端

删除（约 51 个文件 / 3200 行）：

| 位置 | 内容 |
|---|---|
| `juling-module-trade` | `controller/admin/brokerage`、`controller/app/brokerage`（含各自 VO）、`service/brokerage`（含 bo）、`dal/dataobject/brokerage`、`dal/mysql/brokerage`、`convert/brokerage`、`job/brokerage`、`resources/mapper/brokerage` |
| `juling-module-trade` | `service/order/handler/TradeBrokerageOrderHandler`（下单写推广人、付款后加佣金、取消后回退三个钩子） |
| `juling-module-trade-api` | `enums/brokerage`（6 个枚举）、`ErrorCodeConstants` 的 19 个 `BROKERAGE_*` 错误码、`DictTypeConstants` 的 3 个分销字典常量 |
| `juling-module-statistics` | `BrokerageStatisticsService/Impl/Mapper` 与 `BrokerageStatisticsMapper.xml` |
| 测试 | 分销相关测试类、`create_tables.sql`/`clean.sql` 里的分销表 |

摘除引用（不删文件，只去字段与逻辑）：

- `TradeOrderDO.brokerageUserId`、`TradeOrderBaseVO`、订单分页/详情 VO 的 `brokerageUser`、
  `TradeOrderController` 的「推广订单」筛选与详情补数、`TradeOrderConvert` 的推广人转换与
  `BrokerageAddReqBO` 构造方法。
- `TradeConfigDO` 与 Admin/App 配置 VO 的 10 个分销字段（开关、分佣模式、绑定模式、海报、
  两级比例、冻结天数、提现方式/费率/门槛）。
- `ProductSkuDO`/`RespDTO`/`RespVO`/`SaveReqVO` 的 `firstBrokeragePrice`/`secondBrokeragePrice`，
  `ProductSpuDO` 及 SPU 出入参的 `subCommissionType`（分销类型）。
- `AppMemberUserInfoRespVO.brokerageEnabled`（上游残留的死字段，服务端从未赋值）。
- 统计：`TradeStatisticsDO`/`TradeTrendSummaryRespVO`/`TradeTrendSummaryExcelVO` 的
  `brokerageSettlementPrice`、`TradeOrderCountRespVO.auditingWithdraw`（提现待审核），
  以及「支出金额 = 余额支付金额 + 支付佣金金额 + 商品退款金额」中的佣金项。

统计口径变更：支出金额改为 **余额支付金额 + 商品退款金额**。余额支付金额沿用上一轮
支付模块下线的处理方式（字段保留、固定为 0），佣金项则彻底不再参与计算。

## 3. 前端

- `juling-ui-admin-vben`：`web-antd`（在用）、`web-antdv-next`、`web-ele` 三个模板删除
  `views/mall/trade/brokerage/**`、`api/mall/trade/brokerage/**`、
  `views/member/user/detail/modules/brokerage-list.vue`；并摘除交易配置页的「分销」Tab、
  统计趋势卡的「支付佣金金额」、SPU 表单/规格表的「分销类型 / 一级二级返佣」、
  会员详情的「推广用户」Tab、订单详情的「推广用户」列、首页「分销管理」快捷入口与
  营销链接选择器里的分销页面项。
- `juling-ui-admin-uniapp`：删除 `pages-mall/trade/brokerage/**`、`api/mall/trade/brokerage/**`、
  会员详情的 `brokerage-list`/`brokerage-search-form` 组件，并摘除菜单节点
  (`pages/index/menu.json`)、字典枚举、SKU 佣金编辑项、订单详情推广人、统计页佣金项。
- H5 订货商城本来就没有分销界面，只删掉 `types/backend.ts` 里一行 `brokerageEnabled` 类型声明。

## 4. 数据库

脚本 `sql/local/22_remove_brokerage.sql`（幂等，可重复执行）已执行，做的是**物理清除**：

1. 删除分销菜单与角色关联（实测 11 条菜单、0 条角色绑定）；
2. 删除分销字典 6 类 23 条（`brokerage_enabled_condition`、`brokerage_bind_mode`、
   `brokerage_record_biz_type`、`brokerage_record_status`、`brokerage_withdraw_type`、
   `brokerage_withdraw_status`、`brokerage_bank_name`）；
3. 删除分销定时任务（佣金解冻 Job）；
4. `DROP TABLE` 三张分销表（含 20 号脚本归档出的 `zz_deprecated_trade_brokerage_withdraw`）；
5. `DROP COLUMN` 14 个分销列：`trade_config` 的 10 个 `brokerage_*`、`trade_order.brokerage_user_id`、
   `product_sku.first_brokerage_price`/`second_brokerage_price`、
   `trade_statistics.brokerage_settlement_price`。

执行前已确认无数据可丢：三张表均 0 行、`trade_config` 0 行、`trade_order.brokerage_user_id` 全 NULL、
`trade_statistics` 0 行；只有 `product_sku` 的两级佣金列存有 16 行配置值，随分销下线一并丢弃。

同时清理了基线 `sql/postgresql/juling-baseline.sql` 里 52 行分销数据（菜单、字典、
定时任务、提现审核演示通知），避免全新安装时又把分销菜单与任务装回来。

## 5. 回滚

- 代码：本改造是独立提交（`feat(mall)!: 商品分销整体下线`），`git revert` 即可。
- 数据库：表与列已物理删除，回滚需要重新执行建表/建列 DDL 并恢复业务配置；
  `product_sku` 两级佣金的历史配置值无法找回，需重新录入。
- 因此本改造只适合「确定不做分销」的前提；亚特已确认不做，故按物理清除处理。

## 6. 验收

- 后端：`mvn -DskipTests package` 通过；启动后管理端统计（含趋势列表与 Excel 导出）、订单分页/详情、
  交易配置、商品分页均 `code=0`；分销接口返回「接口不存在」；
  H5 下单 → 上传付款凭证 → 后台核验 → 发货主链路正常。
- 前端：仓库内 `grep -i brokerage`（排除 `target/`、`node_modules/`）只剩本文档与迁移脚本；
  web-antd `vue-tsc` 0 错误；H5 `pnpm type-check` 0 错误。
- 数据库：22 号脚本末尾的校验查询全部返回 0，`information_schema` 中已无任何 `%brokerage%`
  表与列（实测 tables_left=0、cols_left=0）。
