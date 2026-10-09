package com.lxjl.juling.module.product.service.spu;

import com.lxjl.juling.module.system.api.code.CodeRuleApi;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.ObjectUtil;
import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.common.util.collection.CollectionUtils;
import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.product.controller.admin.category.vo.ProductCategoryListReqVO;
import com.lxjl.juling.module.product.controller.admin.spu.vo.ProductSkuSaveReqVO;
import com.lxjl.juling.module.product.controller.admin.spu.vo.ProductSpuPageReqVO;
import com.lxjl.juling.module.product.controller.admin.spu.vo.ProductSpuSaveReqVO;
import com.lxjl.juling.module.product.controller.admin.spu.vo.ProductSpuUpdateStatusReqVO;
import com.lxjl.juling.module.product.controller.app.spu.vo.AppProductSpuPageReqVO;
import com.lxjl.juling.module.product.dal.dataobject.category.ProductCategoryDO;
import com.lxjl.juling.module.product.dal.dataobject.spu.ProductSpuDO;
import com.lxjl.juling.module.product.dal.mysql.spu.ProductSpuMapper;
import com.lxjl.juling.module.product.enums.spu.ProductSpuStatusEnum;
import com.lxjl.juling.module.product.service.brand.ProductBrandService;
import com.lxjl.juling.module.product.service.category.ProductCategoryService;
import com.lxjl.juling.module.product.service.sku.ProductSkuService;
import com.google.common.collect.Maps;
import jakarta.annotation.Resource;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.util.*;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.*;
import static com.lxjl.juling.module.product.enums.ErrorCodeConstants.*;

/**
 * 商品 SPU Service 实现类
 *
 * @author 亚特
 */
@Service
@Validated
public class ProductSpuServiceImpl implements ProductSpuService {

    @Resource
    private ProductSpuMapper productSpuMapper;

    @Resource
    @Lazy // 循环依赖，避免报错
    private ProductSkuService productSkuService;
    @Resource
    private ProductBrandService brandService;
    @Resource
    private ProductCategoryService categoryService;

    @Resource
    private CodeRuleApi codeRuleApi;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createSpu(ProductSpuSaveReqVO createReqVO) {
        // 校验分类、品牌
        validateCategory(createReqVO.getCategoryId());
        brandService.validateProductBrand(createReqVO.getBrandId());
        // 校验 SKU
        List<ProductSkuSaveReqVO> skuSaveReqList = createReqVO.getSkus();
        productSkuService.validateSkuList(skuSaveReqList, createReqVO.getSpecType());

        ProductSpuDO spu = BeanUtils.toBean(createReqVO, ProductSpuDO.class);
        // 业务编码：由编码规则统一发号（见 docs/master-data-unified-design.md §4.2）
        spu.setCode(codeRuleApi.generateCode("product_spu"));
        // 初始化 SPU 中 SKU 相关属性
        initSpuFromSkus(spu, skuSaveReqList);
        // 插入 SPU
        productSpuMapper.insert(spu);
        // 插入 SKU
        productSkuService.createSkuList(spu.getId(), skuSaveReqList);
        // 返回
        return spu.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateSpu(ProductSpuSaveReqVO updateReqVO) {
        // 校验 SPU 是否存在
        ProductSpuDO spu = validateSpuExists(updateReqVO.getId());
        // 校验分类、品牌
        validateCategory(updateReqVO.getCategoryId());
        brandService.validateProductBrand(updateReqVO.getBrandId());
        // 校验SKU
        List<ProductSkuSaveReqVO> skuSaveReqList = updateReqVO.getSkus();
        productSkuService.validateSkuList(skuSaveReqList, updateReqVO.getSpecType());

        // 更新 SPU
        ProductSpuDO updateObj = BeanUtils.toBean(updateReqVO, ProductSpuDO.class).setStatus(spu.getStatus());
        initSpuFromSkus(updateObj, skuSaveReqList);
        productSpuMapper.updateById(updateObj);
        // 批量更新 SKU
        productSkuService.updateSkuList(updateObj.getId(), updateReqVO.getSkus());
    }

    /**
     * 基于 SKU 的信息，初始化 SPU 的信息
     * 主要是计数相关的字段，例如说市场价、最大最小价、库存等等
     *
     * @param spu  商品 SPU
     * @param skus 商品 SKU 数组
     */
    private void initSpuFromSkus(ProductSpuDO spu, List<ProductSkuSaveReqVO> skus) {
        // sku 单价最低的商品的价格
        spu.setPrice(getMinValue(skus, ProductSkuSaveReqVO::getPrice));
        // sku 单价最低的商品的市场价格
        spu.setMarketPrice(getMinValue(skus, ProductSkuSaveReqVO::getMarketPrice));
        // sku 单价最低的商品的成本价格
        spu.setCostPrice(getMinValue(skus, ProductSkuSaveReqVO::getCostPrice));
        // skus 库存总数
        spu.setStock(getSumValue(skus, ProductSkuSaveReqVO::getStock, Math::addExact));
        // 若是 spu 已有状态则不处理
        if (spu.getStatus() == null) {
            spu.setStatus(ProductSpuStatusEnum.ENABLE.getStatus()); // 默认状态为上架
            spu.setSalesCount(0); // 默认商品销量
            spu.setBrowseCount(0); // 默认商品浏览量
        }
    }

    /**
     * 校验商品分类是否合法
     *
     * 说明：不强制要求挂在二级分类上——亚特的订货场景品类层级浅，一级分类下允许直接挂商品
     * （一级分类若没有二级子分类，商品此前无处可挂）。分类树本身仍最多两级。
     *
     * @param id 商品分类编号
     */
    private void validateCategory(Long id) {
        categoryService.validateCategory(id);
    }

    @Override
    public List<ProductSpuDO> validateSpuList(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return Collections.emptyList();
        }
        // 获得商品信息
        List<ProductSpuDO> list = productSpuMapper.selectByIds(ids);
        Map<Long, ProductSpuDO> spuMap = CollectionUtils.convertMap(list, ProductSpuDO::getId);
        // 校验
        ids.forEach(id -> {
            ProductSpuDO spu = spuMap.get(id);
            if (spu == null) {
                throw exception(SPU_NOT_EXISTS);
            }
            if (!ProductSpuStatusEnum.isEnable(spu.getStatus())) {
                throw exception(SPU_NOT_ENABLE, spu.getName());
            }
        });
        return list;
    }

    @Override
    public void updateBrowseCount(Long id, int incrCount) {
        productSpuMapper.updateBrowseCount(id , incrCount);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteSpu(Long id) {
        // 校验存在
        validateSpuExists(id);
        // 校验商品状态不是回收站不能删除
        ProductSpuDO spuDO = productSpuMapper.selectById(id);
        // 判断 SPU 状态是否为回收站
        if (ObjectUtil.notEqual(spuDO.getStatus(), ProductSpuStatusEnum.RECYCLE.getStatus())) {
            throw exception(SPU_NOT_RECYCLE);
        }
        // TODO 亚特：【可选】参与活动中的商品，不允许删除？？？

        // 删除 SPU
        productSpuMapper.deleteById(id);
        // 删除关联的 SKU
        productSkuService.deleteSkuBySpuId(id);
    }

    private ProductSpuDO validateSpuExists(Long id) {
        ProductSpuDO spuDO = productSpuMapper.selectById(id);
        if (spuDO == null) {
            throw exception(SPU_NOT_EXISTS);
        }
        return spuDO;
    }

    @Override
    public ProductSpuDO getSpu(Long id) {
        return productSpuMapper.selectById(id);
    }

    @Override
    public ProductSpuDO getSpu(Long id, boolean includeDeleted) {
        if (includeDeleted) {
            return productSpuMapper.selectByIdIncludeDeleted(id);
        }
        return getSpu(id);
    }

    @Override
    public List<ProductSpuDO> getSpuList(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return Collections.emptyList();
        }
        Map<Long, ProductSpuDO> spuMap = convertMap(productSpuMapper.selectByIds(ids), ProductSpuDO::getId);
        // 需要按照 ids 顺序返回。例如说：店铺装修选择了 [3, 1, 2] 三个商品，返回结果还是 [3, 1, 2]  这样的顺序
        return convertList(ids, spuMap::get);
    }

    @Override
    public List<ProductSpuDO> getSpuListByStatus(Integer status) {
        return productSpuMapper.selectList(ProductSpuDO::getStatus, status);
    }

    @Override
    public PageResult<ProductSpuDO> getSpuPage(ProductSpuPageReqVO pageReqVO) {
        // 分类筛选：连同子分类一起查（一级分类也能筛出挂在二级分类下的商品）
        Set<Long> categoryIds = getCategoryIdsWithChildren(pageReqVO.getCategoryId());
        return productSpuMapper.selectPage(pageReqVO, categoryIds);
    }

    @Override
    public PageResult<ProductSpuDO> getSpuPage(AppProductSpuPageReqVO pageReqVO) {
        // 查找时，如果查找某个分类编号，则包含它的子分类（一级分类下也可能直接挂商品）
        Set<Long> categoryIds = new HashSet<>(getCategoryIdsWithChildren(pageReqVO.getCategoryId()));
        if (CollUtil.isNotEmpty(pageReqVO.getCategoryIds())) {
            categoryIds.addAll(pageReqVO.getCategoryIds());
            List<ProductCategoryDO> categoryChildren = categoryService.getCategoryList(new ProductCategoryListReqVO()
                    .setStatus(CommonStatusEnum.ENABLE.getStatus()).setParentIds(pageReqVO.getCategoryIds()));
            categoryIds.addAll(convertList(categoryChildren, ProductCategoryDO::getId));
        }
        // 分页查询
        return productSpuMapper.selectPage(pageReqVO, categoryIds);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateSpuStock(Map<Long, Integer> stockIncrCounts) {
        stockIncrCounts.forEach((id, incCount) -> productSpuMapper.updateStock(id, incCount));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateSpuStatus(ProductSpuUpdateStatusReqVO updateReqVO) {
        // 校验存在
        validateSpuExists(updateReqVO.getId());
        // TODO 亚特：【可选】参与活动中的商品，不允许下架？？？

        // 更新状态
        ProductSpuDO productSpuDO = productSpuMapper.selectById(updateReqVO.getId()).setStatus(updateReqVO.getStatus());
        productSpuMapper.updateById(productSpuDO);
    }

    @Override
    public Map<Integer, Long> getTabsCount(ProductSpuPageReqVO reqVO) {
        Map<Integer, Long> counts = Maps.newLinkedHashMapWithExpectedSize(5);
        // 分类范围与列表页保持一致（含子分类），否则 tab 数量与列表条数会对不上
        Set<Long> categoryIds = getCategoryIdsWithChildren(reqVO.getCategoryId());
        // 每个 tab 的数量 = 筛选条件（name/categoryId/createTime）+ 该 tab 的状态/库存条件
        counts.put(ProductSpuPageReqVO.FOR_SALE,
                productSpuMapper.selectCountByTab(reqVO, ProductSpuPageReqVO.FOR_SALE, categoryIds));
        counts.put(ProductSpuPageReqVO.IN_WAREHOUSE,
                productSpuMapper.selectCountByTab(reqVO, ProductSpuPageReqVO.IN_WAREHOUSE, categoryIds));
        counts.put(ProductSpuPageReqVO.SOLD_OUT,
                productSpuMapper.selectCountByTab(reqVO, ProductSpuPageReqVO.SOLD_OUT, categoryIds));
        counts.put(ProductSpuPageReqVO.ALERT_STOCK,
                productSpuMapper.selectCountByTab(reqVO, ProductSpuPageReqVO.ALERT_STOCK, categoryIds));
        counts.put(ProductSpuPageReqVO.RECYCLE_BIN,
                productSpuMapper.selectCountByTab(reqVO, ProductSpuPageReqVO.RECYCLE_BIN, categoryIds));
        return counts;
    }

    /**
     * 计算分类筛选范围：选中某个分类时，连同其（启用的）子分类一起筛选。
     *
     * 一级分类本身也可能直接挂商品，因此范围里始终包含入参分类自身。
     *
     * @param categoryId 选中的分类编号，可为空
     * @return 分类编号集合；入参为空时返回空集合（表示不按分类筛选）
     */
    private Set<Long> getCategoryIdsWithChildren(Long categoryId) {
        if (categoryId == null || categoryId <= 0) {
            return Collections.emptySet();
        }
        Set<Long> categoryIds = new HashSet<>();
        categoryIds.add(categoryId);
        List<ProductCategoryDO> categoryChildren = categoryService.getCategoryList(new ProductCategoryListReqVO()
                .setStatus(CommonStatusEnum.ENABLE.getStatus()).setParentId(categoryId));
        categoryIds.addAll(convertList(categoryChildren, ProductCategoryDO::getId));
        return categoryIds;
    }

    @Override
    public Long getSpuCountByCategoryId(Long categoryId) {
        return productSpuMapper.selectCount(ProductSpuDO::getCategoryId, categoryId);
    }

}
