package com.lxjl.juling.module.fms.dal.dataobject.config;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

/**
 * FMS 常用摘要 DO
 *
 * @author 棱信矩灵
 */
@TableName("fms_digest")
@KeySequence("fms_digest_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class FmsDigestDO extends BaseDO {

    /**
     * 编号
     */
    @TableId
    private Long id;
    /**
     * 摘要内容
     */
    private String content;
    /**
     * 账套编号
     *
     * 关联 {@link com.lxjl.juling.module.fms.dal.dataobject.config.FmsAccountSetDO#getId()}
     */
    private Long accountSetId;

}
