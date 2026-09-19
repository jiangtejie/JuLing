package com.lxjl.juling.framework.desensitize.core.annotation;

import com.lxjl.juling.framework.desensitize.core.DesensitizeTest;
import com.lxjl.juling.framework.desensitize.core.handler.AddressHandler;
import com.lxjl.juling.framework.desensitize.core.base.annotation.DesensitizeBy;
import com.fasterxml.jackson.annotation.JacksonAnnotationsInside;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 地址
 *
 * 用于 {@link DesensitizeTest} 测试使用
 *
 * @author 棱信矩灵
 */
@Documented
@Target({ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
@JacksonAnnotationsInside
@DesensitizeBy(handler = AddressHandler.class)
public @interface Address {

    String replacer() default "*";

}
