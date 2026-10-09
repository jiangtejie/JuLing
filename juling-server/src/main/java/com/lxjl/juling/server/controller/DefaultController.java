package com.lxjl.juling.server.controller;

import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.common.util.servlet.ServletUtils;
import jakarta.annotation.security.PermitAll;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import static com.lxjl.juling.framework.common.exception.enums.GlobalErrorCodeConstants.NOT_IMPLEMENTED;

/**
 * 默认 Controller，解决**已从工程移除**的 module 的 404 提示（pay / report）。
 *
 * 注意：只保留「本仓库确实没有该模块」的兜底。已在工程内的模块（member/bpm/product/trade/statistics/
 * erp/bill/ai/wms/fms）**不要**在这里加兜底——它会把「路径写错」误报成「模块未启用」，
 * 掩盖真实原因（该返回的是一条普通 404「请求地址不存在」）。
 *
 * @author 亚特
 */
@RestController
@Slf4j
public class DefaultController {

    @RequestMapping(value = { "/admin-api/report/**"})
    public CommonResult<Boolean> report404() {
        return CommonResult.error(NOT_IMPLEMENTED.getCode(),
                "[报表模块 juling-module-report 未启用：该模块与 JimuReport（闭源商业引擎、自有表结构与 token 机制）一起从本仓库移除]"
                + "[如需自助看板，建议独立部署 BI（Metabase/Superset）；如需从上游取回模块见 README「模块启停」章节]");
    }

    @RequestMapping(value = { "/admin-api/pay/**"})
    public CommonResult<Boolean> pay404() {
        return CommonResult.error(NOT_IMPLEMENTED.getCode(),
                "[支付模块 juling-module-pay 未启用或接口不存在][模块启停见 README「模块启停」章节]");
    }

    /**
     * 测试接口：打印 query、header、body
     */
    @RequestMapping(value = { "/test" })
    @PermitAll
    public CommonResult<Boolean> test(HttpServletRequest request) {
        // 打印查询参数
        log.info("Query: {}", ServletUtils.getParamMap(request));
        // 打印请求头
        log.info("Header: {}", ServletUtils.getHeaderMap(request));
        // 打印请求体
        log.info("Body: {}", ServletUtils.getBody(request));
        return CommonResult.success(true);
    }

}
