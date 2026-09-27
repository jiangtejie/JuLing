# 门店自提下线说明

亚特的订单全部走快递发货，不做门店自提。本文记录本次下线的范围、保留项与回滚方式。

## 1. 背景

自提是上游商城模板自带的能力：自提门店管理（含核销员绑定）、订单核销（按订单或核销码）、
下单时的自提分支、商品级「配送方式」（快递/自提）、交易配置的自提开关、统计的「待核销」计数。
亚特只做快递发货，这些能力全部下线。

改造前实测：`trade_order` 中 0 条自提订单（`pick_up_store_id`/`pick_up_verify_code` 全空），
`trade_delivery_pick_up_store` 仅 1 行演示门店（删除前已导出备份到
`%TEMP%\yate-e2e\pickup-store-backup.sql`），自提菜单 0 条角色绑定。即删除不涉及真实业务数据。

## 2. 后端

删除（16 个文件）：

| 位置 | 内容 |
|---|---|
| `controller/admin/delivery` | `DeliveryPickUpStoreController` 与 `vo/pickup/` 下 7 个 VO |
| `controller/app/delivery` | `AppDeliverPickUpStoreController`、`vo/pickup/AppDeliveryPickUpStoreRespVO`、`vo/config/AppDeliveryConfigRespVO` |
| `service/delivery` | `DeliveryPickUpStoreService` 与 `Impl` |
| `dal` | `DeliveryPickUpStoreDO`、`DeliveryPickUpStoreMapper`、`resources/mapper` 无 |
| `convert/delivery` | `DeliveryPickUpStoreConvert` |

摘除引用（约 20 个文件）：

- 订单：`TradeOrderDO` 的 `pickUpStoreId`/`pickUpVerifyCode`；`TradeOrderUpdateServiceImpl` 的下单自提分支、
  核销实现（含拼团校验与核销员校验）、`pickUpOrderByAdmin` 两个重载、`getByPickUpVerifyCode`；
  `TradeOrderController` 的三个核销接口；`TradeOrderMapper` 的 `selectOneByPickUpVerifyCode` 与自提筛选条件；
  `TradeOrderPageReqVO`、`TradeOrderBaseVO`、`AppTradeOrderDetailRespVO`、`TradeOrderConvert`、`AppTradeOrderSettlementReqVO`。
- 运费：`TradeDeliveryPriceCalculator` 的自提分支（自提免运费）与商品配送方式校验；
  `TradePriceCalculateReqBO.pickUpStoreId`；`TradePriceCalculateRespBO.OrderItem.deliveryTypes`；
  `TradePriceCalculatorHelper`。
- 配置：`TradeConfigDO`、`TradeConfigBaseVO`、`AppTradeConfigRespVO` 的 `deliveryPickUpEnabled`。
- 商品：`ProductSpuDO`/`SaveReqVO`/`RespVO`/`RespDTO`/`AppProductSpuRespVO`/`ProductSpuMapper` 的 `deliveryTypes`。
- 枚举与错误码：`DeliveryTypeEnum.PICK_UP`、`TradeOrderOperateTypeEnum.ADMIN_PICK_UP_RECEIVE`、
  自提相关 `ORDER_PICK_UP_FAIL_*`/`ORDER_RECEIVE_FAIL_DELIVERY_TYPE_NOT_PICK_UP`/`PICK_UP_STORE_*` 错误码。
- 统计：`TradeStatisticsController` 的「待核销」计数、`TradeOrderCountRespVO.pickUp`、`TradeStatisticsConvert` 签名。
- 测试：`TradeDeliveryPriceCalculatorTest` 的自提用例与已删字段、测试 fixture `create_tables.sql`、
  `AppTradeOrderController.http` 里的自提示例请求。

**保留**：`trade_order.delivery_type` 字段与 `trade_delivery_type` 字典类型——订单列表/详情仍展示
「快递发货」，`deliveryOrder` 仍以它为判断依据；`DeliveryTypeEnum` 收敛为只剩 `EXPRESS`。

## 3. 前端

- `juling-ui-admin-vben` 三个模板（web-antd 在用、web-antdv-next、web-ele）：删除
  `views/mall/trade/delivery/pickUpStore/**`、`views/mall/trade/delivery/pickUpOrder/**`、
  `api/mall/trade/delivery/pickUpStore/**`；摘除订单列表/详情的自提门店与核销（搜索项、展示列、核销按钮与三个核销接口）、
  交易配置的「启用门店自提」、首页「待核销订单」卡片、商品表单的「配送方式」（运费模板改为常显必填）、
  客服订单状态的「待核销」分支；共享包 `@vben/constants` 的 `DeliveryTypeEnum.PICK_UP` 一并删除。
- `juling-ui-admin-uniapp`：删除 `pages-mall/trade/delivery/pick-up-order/**`、
  `pages-mall/trade/delivery/pick-up-store/**` 与对应两个 API 目录；摘除订单详情/搜索的自提与核销、
  交易配置开关、统计「待核销订单」、商品表单配送方式、`menu.json` 的自提菜单节点、常量枚举。
- H5 订货商城：客户侧本来就没有自提界面，只删掉 `types/backend.ts` 里 `deliveryTypes`、
  `pickUpStoreId`/`pickUpVerifyCode` 三个字段与相关注释、单测 fixture 中的对应字段。

## 4. 数据库

脚本 `sql/local/23_remove_pick_up.sql`（幂等，已执行）：

1. 删除自提菜单与角色关联（门店自提 / 门店管理 / 核销订单 / 自提门店增删改查导出 / 订单核销，共 9 条实测）；
2. 删除 `trade_delivery_type` 字典里的「用户自提」数据行（保留字典类型与「快递发货」）；
3. `DROP TABLE trade_delivery_pick_up_store`；
4. `DROP COLUMN`：`trade_config.delivery_pick_up_enabled`、`trade_order.pick_up_store_id`、
   `trade_order.pick_up_verify_code`、`product_spu.delivery_types`。

同时清理基线 `sql/postgresql/juling-baseline.sql` 里 10 行自提数据（菜单 9 条 + 字典数据 1 条），
避免全新安装把自提菜单装回来。

## 5. 回滚

- 代码：本次为独立提交，`git revert` 即可。
- 数据库：表与列已物理删除，回滚需重建表/列 DDL；1 行演示门店数据需从
  `%TEMP%\yate-e2e\pickup-store-backup.sql` 恢复。

## 6. 验收

- 后端：`mvn -DskipTests package` 通过；启动后管理端与 App 端下单/订单/商品/统计接口全部 `code=0`；
  自提接口返回「接口不存在」；统计订单数量不再返回 `pickUp` 字段。
- 前端：仓库内 grep `pickup|pick-up|自提|核销|deliveryTypes`（排除构建产物）只剩本迁移脚本；
  web-antd `vue-tsc` 0 错误；H5 `pnpm type-check` 0 错误与 `node --test` 27/27 通过；
  web-antdv-next / web-ele / admin-uniapp 均无新增类型错误。
- 数据库：`%pick%` 表与列均为 0，`trade_delivery_type` 只剩「快递发货」。
