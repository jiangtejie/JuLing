package com.lxjl.juling.framework.translate.core;

import cn.hutool.core.collection.CollUtil;
import org.dromara.core.trans.vo.VO;
import org.dromara.trans.service.impl.TransService;

import java.util.List;

/**
 * VO 数据翻译 Utils
 *
 * @author 棱信矩灵
 */
public class TranslateUtils {

    private static TransService transService;

    public static void init(TransService transService) {
        TranslateUtils.transService = transService;
    }

    /**
     * 数据翻译
     *
     * 使用场景：无法使用 @TransMethodResult 注解的场景，只能通过手动触发翻译
     *
     * @param data 数据
     * @return 翻译结果
     */
    public static <T extends VO> List<T> translate(List<T> data) {
        // transService 为空说明 easy-trans 未启用/未装配：直接返回原数据，避免 NPE 打断导出等主流程
        if (CollUtil.isNotEmpty((data)) && transService != null) {
            transService.transBatch(data);
        }
        return data;
    }

}
