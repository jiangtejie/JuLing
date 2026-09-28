package com.lxjl.juling.module.erp.dal.redis.no;

import cn.hutool.core.date.DatePattern;
import cn.hutool.core.date.DateUtil;
import com.lxjl.juling.module.erp.dal.redis.RedisKeyConstants;
import jakarta.annotation.Resource;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Repository;

import java.time.Duration;
import java.time.LocalDateTime;


/**
 * Erp 订单序号的 Redis DAO
 *
 * @author 亚特
 */
@Repository
public class ErpNoRedisDAO {

    // 注意：单号规则的唯一真相来源是「单据平台」的 bill_type 表（规则：前缀 + yyyyMMdd + 6 位流水），
    // 取号统一走 billPlatformApi.generateNo(billType, orgId)。
    // 已迁移的单据：采购订单(CGDD)、采购入库(CGRK)、采购退货(CGTH)、销售订单(XSDD)、
    //              销售出库/配送出库(XSCK)、销售退货(XSTH)、付款单(FKD)、收款单(SKD)。
    // 迁移一张就从这里删一个常量 —— 常量与平台规则并存 = 同一号码空间两个序列，同日两个入口会撞号。
    // 本类目前只服务于尚未迁移的库存单据（其它入库 QTRK / 其它出库 QCKD / 调拨 QCDB / 盘点 QCPD）。

    /**
     * 其它入库 {@link com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockInDO}
     */
    public static final String STOCK_IN_NO_PREFIX = "QTRK";
    /**
     * 其它出库 {@link com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockOutDO}
     */
    public static final String STOCK_OUT_NO_PREFIX = "QCKD";

    /**
     * 库存调拨 {@link com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockMoveDO}
     */
    public static final String STOCK_MOVE_NO_PREFIX = "QCDB";

    /**
     * 库存盘点 {@link com.lxjl.juling.module.erp.dal.dataobject.stock.ErpStockCheckDO}
     */
    public static final String STOCK_CHECK_NO_PREFIX = "QCPD";

    @Resource
    private StringRedisTemplate stringRedisTemplate;

    /**
     * 生成序号，使用当前日期，格式为 {PREFIX} + yyyyMMdd + 6 位自增
     * 例如说：QTRK 202109 000001 （没有中间空格）
     *
     * 仅剩尚未迁移到单据平台的库存单据使用；新单据请用 BillPlatformApi#generateNo。
     *
     * @param prefix 前缀
     * @return 序号
     */
    public String generate(String prefix) {
        // 递增序号
        String noPrefix = prefix + DateUtil.format(LocalDateTime.now(), DatePattern.PURE_DATE_PATTERN);
        String key = RedisKeyConstants.NO + noPrefix;
        Long no = stringRedisTemplate.opsForValue().increment(key);
        // 设置过期时间
        stringRedisTemplate.expire(key, Duration.ofDays(1L));
        return noPrefix + String.format("%06d", no);
    }

}
