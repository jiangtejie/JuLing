package com.lxjl.juling.module.erp.service.sale;

import com.lxjl.juling.module.erp.controller.admin.sale.vo.store.ErpStoreSaveReqVO;

/**
 * 「建门店」Service 接口
 *
 * @author 亚特
 */
public interface ErpStoreService {

    /**
     * 建门店：**一个事务里**同时建组织节点与客户档案
     *
     * @param createReqVO 门店信息
     * @return 客户档案编号
     */
    Long createStore(ErpStoreSaveReqVO createReqVO);

}
