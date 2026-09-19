package com.lxjl.juling.module.product.api.category;

import com.lxjl.juling.module.product.service.category.ProductCategoryService;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import jakarta.annotation.Resource;
import java.util.Collection;

/**
 * 商品分类 API 接口实现类
 *
 * @author 棱信矩灵
 */
@Service
@Validated
public class ProductCategoryApiImpl implements ProductCategoryApi {

    @Resource
    private ProductCategoryService productCategoryService;

    @Override
    public void validateCategoryList(Collection<Long> ids) {
        productCategoryService.validateCategoryList(ids);
    }

}
