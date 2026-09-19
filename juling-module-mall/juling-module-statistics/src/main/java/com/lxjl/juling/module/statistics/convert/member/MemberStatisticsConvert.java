package com.lxjl.juling.module.statistics.convert.member;

import cn.hutool.core.map.MapUtil;
import cn.hutool.core.util.ObjUtil;
import com.lxjl.juling.framework.common.util.collection.CollectionUtils;
import com.lxjl.juling.framework.ip.core.Area;
import com.lxjl.juling.module.statistics.controller.admin.common.vo.DataComparisonRespVO;
import com.lxjl.juling.module.statistics.controller.admin.member.vo.MemberAnalyseDataRespVO;
import com.lxjl.juling.module.statistics.controller.admin.member.vo.MemberAnalyseRespVO;
import com.lxjl.juling.module.statistics.controller.admin.member.vo.MemberAreaStatisticsRespVO;
import com.lxjl.juling.module.statistics.controller.admin.member.vo.MemberSummaryRespVO;
import com.lxjl.juling.module.statistics.service.member.bo.MemberAreaStatisticsRespBO;
import com.lxjl.juling.module.statistics.service.pay.bo.RechargeSummaryRespBO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * 会员统计 Convert
 *
 * @author 棱信矩灵
 */
@Mapper
public interface MemberStatisticsConvert {

    MemberStatisticsConvert INSTANCE = Mappers.getMapper(MemberStatisticsConvert.class);

    default List<MemberAreaStatisticsRespVO> convertList(List<Area> areaList,
                                                         Map<Integer, Integer> userCountMap,
                                                         Map<Integer, MemberAreaStatisticsRespBO> orderMap) {
        return CollectionUtils.convertList(areaList, area -> {
            MemberAreaStatisticsRespBO orderVo = Optional.ofNullable(orderMap.get(area.getId()))
                    .orElseGet(MemberAreaStatisticsRespBO::new);
            return new MemberAreaStatisticsRespVO()
                    .setAreaId(area.getId()).setAreaName(area.getName())
                    .setUserCount(MapUtil.getInt(userCountMap, area.getId(), 0))
                    .setOrderCreateUserCount(ObjUtil.defaultIfNull(orderVo.getOrderCreateUserCount(), 0))
                    .setOrderPayUserCount(ObjUtil.defaultIfNull(orderVo.getOrderPayUserCount(), 0))
                    .setOrderPayPrice(ObjUtil.defaultIfNull(orderVo.getOrderPayPrice(), 0));
        });
    }

    MemberSummaryRespVO convert(RechargeSummaryRespBO rechargeSummary, Integer expensePrice, Integer userCount);

    MemberAnalyseRespVO convert(Integer visitUserCount, Integer orderUserCount, Integer payUserCount, int atv,
                                DataComparisonRespVO<MemberAnalyseDataRespVO> comparison);

}
