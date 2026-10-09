package com.lxjl.juling.module.erp.service.pricelist;

import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.erp.controller.admin.pricelist.vo.ErpPriceListPageReqVO;
import com.lxjl.juling.module.erp.controller.admin.pricelist.vo.ErpPriceListSaveReqVO;
import com.lxjl.juling.module.erp.controller.admin.pricelist.vo.ErpPriceMatchRespVO;
import com.lxjl.juling.module.erp.dal.dataobject.pricelist.ErpPriceListDO;
import com.lxjl.juling.module.erp.dal.dataobject.pricelist.ErpPriceListItemDO;
import com.lxjl.juling.module.erp.dal.dataobject.pricelist.ErpPriceListItemLogDO;
import com.lxjl.juling.module.erp.dal.dataobject.pricelist.ErpPriceListScopeDO;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;

/**
 * ERP 价目表 Service 接口
 *
 * <p>采购价目表与配送价目表共用本服务，靠 priceType 区分。
 *
 * @author 亚特
 */
public interface ErpPriceListService {

    Long createPriceList(ErpPriceListSaveReqVO createReqVO);

    void updatePriceList(ErpPriceListSaveReqVO updateReqVO);

    void deletePriceList(Long id);

    void deletePriceListList(List<Long> ids);

    ErpPriceListDO getPriceList(Long id);

    List<ErpPriceListScopeDO> getScopeList(Long priceId);

    List<ErpPriceListItemDO> getItemList(Long priceId);

    /** 分页列表用：一次取回多张价目表的明细，避免 N+1 */
    List<ErpPriceListItemDO> getItemListByPriceIds(Collection<Long> priceIds);

    /** 分页列表用：一次取回多张价目表的适用范围 */
    List<ErpPriceListScopeDO> getScopeListByPriceIds(Collection<Long> priceIds);

    /** 按价目表查价格变更历史（新的在前） */
    List<ErpPriceListItemLogDO> getItemLogList(Long priceId);

    /** 按物料查价格变更历史 —— **核算主要用这个**：某物料历次改价 */
    List<ErpPriceListItemLogDO> getItemLogListByProductId(Long productId);

    PageResult<ErpPriceListDO> getPriceListPage(ErpPriceListPageReqVO pageReqVO);

    /**
     * 取价：给定「价目表类型 + 适用对象 + 物料 + 日期」，返回适用的单价与税率
     *
     * <p>优先级（详见 sql/local/69 的评估说明）：
     * <ol>
     *   <li>适用范围行上标了「默认价目表」的优先</li>
     *   <li>再：价目表生效日期新 优先</li>
     *   <li>再：编号大 优先（保证结果稳定，不依赖数据库返回顺序）</li>
     * </ol>
     * 过滤条件：类型匹配 + 已启用 + 当日落在有效期内 + 物料在明细里。
     *
     * <p>都没命中时兜底取物料主数据：采购取 purchase_price、配送取 sale_price，
     * 此时返回结果的 source 为 PRODUCT。
     *
     * @param priceType  价目表类型
     * @param partnerId  适用对象编号（采购=供应商，配送=门店）；可为空表示只匹配通用范围
     * @return 命中的价格；没有命中且无兜底时返回 null
     */
    ErpPriceMatchRespVO matchPrice(String priceType, Long partnerId, Long productId, LocalDate date);

}
