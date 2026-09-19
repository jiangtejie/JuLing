package com.lxjl.juling.module.ai.framework.ai.core.websearch;

import com.lxjl.juling.framework.common.util.json.JsonUtils;
import com.lxjl.juling.module.ai.framework.ai.core.webserch.AiWebSearchRequest;
import com.lxjl.juling.module.ai.framework.ai.core.webserch.AiWebSearchResponse;
import com.lxjl.juling.module.ai.framework.ai.core.webserch.bocha.AiBoChaWebSearchClient;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

/**
 * {@link AiBoChaWebSearchClient} 集成测试类
 *
 * @author 棱信矩灵
 */
public class AiBoChaWebSearchClientTest {

    private final AiBoChaWebSearchClient webSearchClient = new AiBoChaWebSearchClient(
            "sk-test-placeholder-0000000000000000");

    @Test
    @Disabled
    public void testSearch() {
        AiWebSearchRequest request = new AiWebSearchRequest()
                .setQuery("阿里巴巴")
                .setCount(3);
        AiWebSearchResponse response = webSearchClient.search(request);
        System.out.println(JsonUtils.toJsonPrettyString(response));
    }

}