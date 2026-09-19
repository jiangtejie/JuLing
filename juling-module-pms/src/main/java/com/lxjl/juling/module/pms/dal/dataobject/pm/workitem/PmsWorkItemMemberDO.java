package com.lxjl.juling.module.pms.dal.dataobject.pm.workitem;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.lxjl.juling.module.pms.dal.dataobject.pm.project.PmsProjectDO;
import com.lxjl.juling.module.system.dal.dataobject.user.AdminUserDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

/**
 * PMS 工作项参与人 DO
 *
 * @author 棱信矩灵
 */
@TableName("pms_work_item_member")
@KeySequence("pms_work_item_member_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PmsWorkItemMemberDO extends BaseDO {

    /**
     * 编号
     */
    @TableId
    private Long id;
    /**
     * 项目编号
     *
     * 关联 {@link PmsProjectDO#getId()}
     */
    private Long projectId;
    /**
     * 工作项编号
     *
     * 关联 {@link PmsWorkItemDO#getId()}
     */
    private Long workItemId;
    /**
     * 后台用户编号
     *
     * 关联 {@link AdminUserDO#getId()}
     */
    private Long userId;

}
