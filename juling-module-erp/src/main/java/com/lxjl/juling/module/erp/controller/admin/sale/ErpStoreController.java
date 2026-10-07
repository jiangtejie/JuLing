package com.lxjl.juling.module.erp.controller.admin.sale;

import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.module.erp.controller.admin.sale.vo.store.ErpStoreSaveReqVO;
import com.lxjl.juling.module.erp.service.sale.ErpStoreService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import static com.lxjl.juling.framework.common.pojo.CommonResult.success;

@Tag(name = "管理后台 - 建门店")
@RestController
@RequestMapping("/erp/store")
@Validated
public class ErpStoreController {

    @Resource
    private ErpStoreService storeService;

    @PostMapping("/create")
    @Operation(summary = "建门店", description = "一个事务里同时建组织节点（STORE）与客户档案，保证两者一对一")
    @PreAuthorize("@ss.hasPermission('erp:customer:create')")
    public CommonResult<Long> createStore(@Valid @RequestBody ErpStoreSaveReqVO createReqVO) {
        return success(storeService.createStore(createReqVO));
    }

}
