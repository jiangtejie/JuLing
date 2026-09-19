package com.lxjl.juling.module.fms.util;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;

import java.util.List;

/**
 * FMS 实体工具类
 *
 * @author 棱信矩灵
 */
public class FmsEntityUtils {

    /**
     * 把「由数据库读出的实体复制而来的新实体」整理成可插入状态
     * <p>
     * 背景：{@code BeanUtils.toBean(dbDO, XxxDO.class)} 会连 {@link BaseDO} 的审计字段与逻辑删除标记一起复制。
     * 其中 {@code deleted} 一旦是非 null 的 Boolean，MyBatis-Plus 就会把它拼进 INSERT 语句，
     * 而本项目 PG 库的 {@code deleted} 列统一是 smallint（495 张表一致），Boolean 参数会直接报
     * {@code column "deleted" is of type smallint but expression is of type boolean}。
     * <p>
     * 正常情况下 {@code deleted} 为 null 时 MyBatis-Plus 会省略该列、走数据库默认值 0，
     * 所以只有「读库 → 复制 → 插入」这一种写法会踩到；凡此类场景请用本方法包一层：
     * <pre>
     * configs = convertList(templates, template -&gt; FmsEntityUtils.asNewRecord(
     *         BeanUtils.toBean(template, FmsXxxConfigDO.class).setId(null)...));
     * </pre>
     *
     * @param entity 待插入的实体
     * @param <T>    实体类型
     * @return 同一个实体对象（便于链式书写）
     */
    public static <T extends BaseDO> T asNewRecord(T entity) {
        if (entity == null) {
            return null;
        }
        // 清空 creator / createTime / updater / updateTime，交由 DefaultDBFieldHandler 填充当前登录人与当前时间
        entity.clean();
        // 置空逻辑删除标记，让 MyBatis-Plus 省略 deleted 列，走数据库默认值
        entity.setDeleted(null);
        return entity;
    }

    /**
     * {@link #asNewRecord(BaseDO)} 的批量版本
     *
     * @param entities 待插入的实体列表
     * @param <T>      实体类型
     * @return 同一个列表对象
     */
    public static <T extends BaseDO> List<T> asNewRecords(List<T> entities) {
        if (entities != null) {
            entities.forEach(FmsEntityUtils::asNewRecord);
        }
        return entities;
    }

}
