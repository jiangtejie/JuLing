package com.lxjl.juling.module.erp.api.pricelist;

import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.erp.api.pricelist.dto.ErpPriceMatchRespDTO;
import com.lxjl.juling.module.erp.controller.admin.pricelist.vo.ErpPriceMatchRespVO;
import com.lxjl.juling.module.erp.service.pricelist.ErpPriceListService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

/**
 * 价目表 API 实现
 *
 * @author 亚特
 */
@Service
@Validated
public class ErpPriceApiImpl implements ErpPriceApi {

    @Resource
    private ErpPriceListService priceListService;

    @Override
    public ErpPriceMatchRespDTO matchPrice(String priceType, Long partnerId, Long productId) {
        ErpPriceMatchRespVO match = priceListService.matchPrice(priceType, partnerId, productId, null);
        return match == null ? null : BeanUtils.toBean(match, ErpPriceMatchRespDTO.class);
    }

}
