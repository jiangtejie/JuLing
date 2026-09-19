package com.lxjl.juling.module.im.service.websocket.notification.group;

import lombok.Data;

import java.util.List;

/**
 * 群事件成员列表通知基类
 *
 * @author 棱信矩灵
 */
@Data
public abstract class GroupMemberListNotification extends BaseGroupNotification {

    /**
     * 受影响的成员用户编号列表
     */
    private List<Long> memberUserIds;

}
