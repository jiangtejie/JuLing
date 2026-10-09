package com.lxjl.juling.module.erp.service.product;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.erp.controller.admin.product.vo.product.ErpProductPageReqVO;
import com.lxjl.juling.module.erp.controller.admin.product.vo.product.ErpProductRespVO;
import com.lxjl.juling.module.erp.controller.admin.product.vo.product.ProductSaveReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.product.ErpProductDO;
import jakarta.validation.Valid;

import java.util.Collection;
import java.util.List;
import java.util.Map;

import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertMap;

/**
 * ERP 物料 Service 接口
 *
 * @author 亚特
 */
public interface ErpProductService {

    /**
     * 创建物料
     *
     * @param createReqVO 创建信息
     * @return 编号
     */
    Long createProduct(@Valid ProductSaveReqVO createReqVO);

    /**
     * 更新物料
     *
     * @param updateReqVO 更新信息
     */
    void updateProduct(@Valid ProductSaveReqVO updateReqVO);

    /**
     * 删除物料
     *
     * @param id 编号
     */
    void deleteProduct(Long id);

    /**
     * 校验物料们的有效性
     *
     * @param ids 编号数组
     * @return 物料列表
     */
    List<ErpProductDO> validProductList(Collection<Long> ids);

    /**
     * 获得物料
     *
     * @param id 编号
     * @return 物料
     */
    ErpProductDO getProduct(Long id);

    /**
     * 获得指定状态的物料 VO 列表
     *
     * @param status 状态
     * @return 物料 VO 列表
     */
    List<ErpProductRespVO> getProductVOListByStatus(Integer status);

    /**
     * 获得物料 VO 列表
     *
     * @param ids 编号数组
     * @return 物料 VO 列表
     */
    List<ErpProductRespVO> getProductVOList(Collection<Long> ids);

    /**
     * 获得物料 VO Map
     *
     * @param ids 编号数组
     * @return 物料 VO Map
     */
    default Map<Long, ErpProductRespVO> getProductVOMap(Collection<Long> ids) {
        return convertMap(getProductVOList(ids), ErpProductRespVO::getId);
    }

    /**
     * 获得物料 VO 分页
     *
     * @param pageReqVO 分页查询
     * @return 物料分页
     */
    PageResult<ErpProductRespVO> getProductVOPage(ErpProductPageReqVO pageReqVO);

    /**
     * 基于物料分类编号，获得物料数量
     *
     * @param categoryId 物料分类编号
     * @return 物料数量
     */
    Long getProductCountByCategoryId(Long categoryId);

    /**
     * 基于物料单位编号，获得物料数量
     *
     * @param unitId 物料单位编号
     * @return 物料数量
     */
    Long getProductCountByUnitId(Long unitId);

}