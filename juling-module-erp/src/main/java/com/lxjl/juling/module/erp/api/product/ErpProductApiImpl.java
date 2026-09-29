package com.lxjl.juling.module.erp.api.product;

import cn.hutool.core.collection.CollUtil;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.erp.api.product.dto.ErpProductRespDTO;
import com.lxjl.juling.module.erp.dal.dataobject.product.ErpProductDO;
import com.lxjl.juling.module.erp.dal.mysql.product.ErpProductMapper;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;

import java.util.Collection;
import java.util.List;

/**
 * ERP 物料（产品）API 实现
 *
 * @author 亚特
 */
@Service
public class ErpProductApiImpl implements ErpProductApi {

    @Resource
    private ErpProductMapper productMapper;

    @Override
    public List<ErpProductRespDTO> getProductListByBarCodes(Collection<String> barCodes) {
        if (CollUtil.isEmpty(barCodes)) {
            return List.of();
        }
        List<ErpProductDO> list = productMapper.selectListByBarCodes(barCodes);
        return BeanUtils.toBean(list, ErpProductRespDTO.class);
    }

    @Override
    public ErpProductRespDTO getProduct(Long id) {
        return BeanUtils.toBean(productMapper.selectById(id), ErpProductRespDTO.class);
    }

    @Override
    public List<ErpProductRespDTO> getProductList(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return List.of();
        }
        return BeanUtils.toBean(productMapper.selectByIds(ids), ErpProductRespDTO.class);
    }

}
