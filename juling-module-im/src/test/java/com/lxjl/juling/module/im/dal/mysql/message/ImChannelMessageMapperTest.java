package com.lxjl.juling.module.im.dal.mysql.message;

import com.lxjl.juling.framework.test.core.ut.BaseDbUnitTest;
import com.lxjl.juling.module.im.dal.dataobject.message.ImChannelMessageDO;
import jakarta.annotation.Resource;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * {@link ImChannelMessageMapper} 的单元测试
 * <p>
 * 回归背景：{@link ImChannelMessageDO#getReceiverUserIds()} 声明为 {@code List<Long>} 且带
 * {@code LongListTypeHandler}，若在 Wrapper 里用 {@code eq(字段, "")} 传字符串字面量，
 * MyBatis 会在参数绑定时把 String 强转 List 抛
 * {@code ClassCastException: String cannot be cast to List}，导致拉取接口恒 500。
 * 此处用真实 SQL（H2）锁定「收件人为空 = 全员可见」的筛选行为。
 *
 * @author 棱信矩灵
 */
public class ImChannelMessageMapperTest extends BaseDbUnitTest {

    @Resource
    private ImChannelMessageMapper mapper;

    @Test
    public void testSelectListByUserAndMinId_receiverEmptyMeansBroadcast() {
        // 准备：全员(null) / 全员(空串) / 定向给用户 2
        ImChannelMessageDO nullReceiver = buildMessage(null);
        mapper.insert(nullReceiver);
        ImChannelMessageDO emptyReceiver = buildMessage(List.of());
        mapper.insert(emptyReceiver);
        ImChannelMessageDO directedOther = buildMessage(List.of(2L));
        mapper.insert(directedOther);

        // 调用：用户 1 拉取（不带游标）
        List<ImChannelMessageDO> result = mapper.selectListByUserAndMinId(1L, 0L, 100);

        // 断言：两条「全员」消息可见，定向给他人（用户 2）的不可见；按 id 升序
        assertEquals(2, result.size());
        assertEquals(nullReceiver.getId(), result.get(0).getId());
        assertEquals(emptyReceiver.getId(), result.get(1).getId());
    }

    @Test
    public void testSelectListByUserAndMinId_includesTargetedReceiver() {
        // 准备：一条快照含用户 1，一条只含用户 2
        ImChannelMessageDO targeted = buildMessage(List.of(1L, 2L));
        mapper.insert(targeted);
        ImChannelMessageDO other = buildMessage(List.of(2L, 3L));
        mapper.insert(other);

        List<ImChannelMessageDO> result = mapper.selectListByUserAndMinId(1L, 0L, 100);

        // 断言：仅快照包含用户 1 的消息被拉取
        assertEquals(1, result.size());
        assertEquals(targeted.getId(), result.get(0).getId());
    }

    @Test
    public void testSelectListByUserAndMinId_minIdCursorAndLimit() {
        // 准备：三条全员消息
        ImChannelMessageDO m1 = buildMessage(List.of());
        mapper.insert(m1);
        ImChannelMessageDO m2 = buildMessage(List.of());
        mapper.insert(m2);
        ImChannelMessageDO m3 = buildMessage(List.of());
        mapper.insert(m3);

        // 调用：游标排除 m1，且 size=2
        List<ImChannelMessageDO> result = mapper.selectListByUserAndMinId(1L, m1.getId(), 2);

        assertEquals(2, result.size());
        assertEquals(m2.getId(), result.get(0).getId());
        assertEquals(m3.getId(), result.get(1).getId());
    }

    private ImChannelMessageDO buildMessage(List<Long> receiverUserIds) {
        return ImChannelMessageDO.builder()
                .channelId(10L)
                .materialId(100L)
                .type(1)
                .content("{\"title\":\"test\"}")
                .receiverUserIds(receiverUserIds)
                .sendTime(LocalDateTime.now())
                .build();
    }

}
