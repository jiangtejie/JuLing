package com.lxjl.juling.module.statistics.dal.mysql.infra;

import com.lxjl.juling.framework.mybatis.core.mapper.BaseMapperX;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;

// TODO @棱信矩灵：api 访问日志，现在会清理，可能要单独有个偏业务的访问表；
/**
 * API 访问日志的统计 Mapper
 *
 * @author 棱信矩灵
 */
@Mapper
@SuppressWarnings("rawtypes")
public interface ApiAccessLogStatisticsMapper extends BaseMapperX {

    Integer selectIpCountByUserTypeAndCreateTimeBetween(@Param("userType") Integer userType,
                                                        @Param("beginTime") LocalDateTime beginTime,
                                                        @Param("endTime") LocalDateTime endTime);

    Integer selectUserCountByUserTypeAndCreateTimeBetween(@Param("userType") Integer userType,
                                                          @Param("beginTime") LocalDateTime beginTime,
                                                          @Param("endTime") LocalDateTime endTime);

}
