package com.lxjl.juling.module.erp.dal.mysql.product;

import cn.hutool.core.collection.CollUtil;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import com.lxjl.juling.module.erp.controller.admin.product.vo.product.ErpProductPageReqVO;
import com.lxjl.juling.module.erp.dal.dataobject.product.ErpProductDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.Collections;
import java.util.List;

/**
 * ERP 物料 Mapper
 *
 * @author 亚特
 */
@Mapper
public interface ErpProductMapper extends BaseMapperX<ErpProductDO> {

    default PageResult<ErpProductDO> selectPage(ErpProductPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<ErpProductDO>()
                .likeIfPresent(ErpProductDO::getName, reqVO.getName())
                .eqIfPresent(ErpProductDO::getCategoryId, reqVO.getCategoryId())
                .betweenIfPresent(ErpProductDO::getCreateTime, reqVO.getCreateTime())
                // 分料属性过滤：工作台/运营按"能否统配/能否直拨"挑物料
                .eqIfPresent(ErpProductDO::getAllowCentral, reqVO.getAllowCentral())
                .eqIfPresent(ErpProductDO::getAllowDirect, reqVO.getAllowDirect())
                .orderByDesc(ErpProductDO::getId));
    }

    default Long selectCountByCategoryId(Long categoryId) {
        return selectCount(ErpProductDO::getCategoryId, categoryId);
    }

    default Long selectCountByUnitId(Long unitId) {
        return selectCount(ErpProductDO::getUnitId, unitId);
    }

    default List<ErpProductDO> selectListByStatus(Integer status) {
        return selectList(ErpProductDO::getStatus, status);
    }

    /**
     * 按条码批量查询物料
     *
     * 商城 SKU 的 bar_code 与 erp_product.bar_code 对齐，是「商城商品 ↔ ERP 物料」的对应关系。
     */
    default List<ErpProductDO> selectListByBarCodes(Collection<String> barCodes) {
        if (CollUtil.isEmpty(barCodes)) {
            return Collections.emptyList();
        }
        return selectList(ErpProductDO::getBarCode, barCodes);
    }

}