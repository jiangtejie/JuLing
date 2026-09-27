# 商品分销下线说明

亚特的业务不涉及商品分销，本分支已把商城里的分销（推广员 / 佣金 / 提现）整体移除。
本文记录范围、保留项与回滚方式。

## 1. 背景

分销是上游商城模板自带的能力：分销用户与绑定关系、佣金记录与解冻、佣金提现、
SKU 两级佣金、订单推广人、分销统计与分销海报。亚特只做线下转账订货（见
`docs/offline-payment-refactor.md`），不需要推广返佣，故整体下线。

判定依据（改造前实测）：`trade_brokerage_user`、`trade_brokerage_record` 均为 0 行；
`trade_order.brokerage_user_id` 全为 NULL；`trade_statistics` 0 行；分销菜单 0 条角色绑定；
H5 订货商城 0 处分销界面。即删除不涉及任何真实业务数据。

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

新脚本 `sql/local/22_remove_brokerage.sql`（幂等，可重复执行）：

1. 删除分销菜单与角色关联（实测 11 条菜单、0 条角色绑定）；
2. 删除分销字典 6 类 23 条（`brokerage_enabled_condition`、`brokerage_bind_mode`、
   `brokerage_record_biz_type`、`brokerage_record_status`、`brokerage_withdraw_type`、
   `brokerage_withdraw_status`、`brokerage_bank_name`）；
3. 删除分销定时任务（佣金解冻 Job）；
4. 分销表重命名归档：`trade_brokerage_user` → `zz_deprecated_trade_brokerage_user`、
   `trade_brokerage_record` → `zz_deprecated_trade_brokerage_record`
   （提现表上一轮已归档为 `zz_deprecated_trade_brokerage_withdraw`）。

同时清理了基线 `sql/postgresql/juling-baseline.sql` 里 52 行分销数据（菜单、字典、
定时任务、提现审核演示通知），避免全新安装时又把分销菜单与任务装回来。

## 5. 保留项与回滚

- **列一律保留、不 DROP**：`trade_config` 的 10 个 `brokerage_*`、`trade_order.brokerage_user_id`、
  `product_sku.first_brokerage_price`/`second_brokerage_price`、
  `trade_statistics.brokerage_settlement_price`。这些列均可空、无默认值，代码已不读写。
  确认无历史依赖后再执行 22 号脚本末尾注释掉的 `ALTER TABLE ... DROP COLUMN`。
- **表用重命名归档、不 DROP**，回滚即反向改名：
  `ALTER TABLE zz_deprecated_trade_brokerage_user RENAME TO trade_brokerage_user;`
- 代码回滚：本改造是独立提交，`git revert` 对应提交即可（数据库侧配合上面的改名）。

## 6. 验收

- 后端：`mvn -DskipTests package` 通过；启动后 H5 下单 → 上传付款凭证 → 后台核验 →
  发货主链路正常，后台交易统计页可正常打开（无佣金项），订单列表/详情无「推广用户」。
- 前端：仓库内 `grep -i brokerage`（排除 `target/`、`node_modules/`）为 0 处；
  vben web-antd 类型检查无新增错误；H5 `pnpm type-check` 0 错误。
- 数据库：22 号脚本末尾的校验查询全部返回 0，`information_schema` 中只剩
  `zz_deprecated_trade_brokerage_*` 三张归档表。
