package com.lxjl.juling.module.promotion.api.bargain;

import com.lxjl.juling.module.promotion.api.bargain.dto.BargainValidateJoinRespDTO;
import com.lxjl.juling.module.promotion.service.bargain.BargainRecordService;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import jakarta.annotation.Resource;

/**
 * 砍价活动 API 实现类
 *
 * @author 棱信矩灵
 */
@Service
@Validated
public class BargainRecordApiImpl implements BargainRecordApi {

    @Resource
    private BargainRecordService bargainRecordService;

    @Override
    public BargainValidateJoinRespDTO validateJoinBargain(Long userId, Long bargainRecordId, Long skuId) {
        return bargainRecordService.validateJoinBargain(userId, bargainRecordId, skuId);
    }

    @Override
    public void updateBargainRecordOrderId(Long id, Long orderId) {
        bargainRecordService.updateBargainRecordOrderId(id, orderId);
    }

}
