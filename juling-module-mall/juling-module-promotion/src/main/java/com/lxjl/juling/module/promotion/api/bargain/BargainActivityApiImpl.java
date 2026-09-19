package com.lxjl.juling.module.promotion.api.bargain;

import com.lxjl.juling.module.promotion.service.bargain.BargainActivityService;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import jakarta.annotation.Resource;

/**
 * 砍价活动 Api 接口实现类
 *
 * @author 棱信矩灵
 */
@Service
@Validated
public class BargainActivityApiImpl implements BargainActivityApi {

    @Resource
    private BargainActivityService bargainActivityService;

    @Override
    public void updateBargainActivityStock(Long id, Integer count) {
        bargainActivityService.updateBargainActivityStock(id, count);
    }

}
