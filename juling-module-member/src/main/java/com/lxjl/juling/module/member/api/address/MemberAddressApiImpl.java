package com.lxjl.juling.module.member.api.address;

import com.lxjl.juling.module.member.api.address.dto.MemberAddressRespDTO;
import com.lxjl.juling.module.member.convert.address.AddressConvert;
import com.lxjl.juling.module.member.service.address.AddressService;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import jakarta.annotation.Resource;

/**
 * 用户收件地址 API 实现类
 *
 * @author 棱信矩灵
 */
@Service
@Validated
public class MemberAddressApiImpl implements MemberAddressApi {

    @Resource
    private AddressService addressService;

    @Override
    public MemberAddressRespDTO getAddress(Long id, Long userId) {
        return AddressConvert.INSTANCE.convert02(addressService.getAddress(userId, id));
    }

    @Override
    public MemberAddressRespDTO getDefaultAddress(Long userId) {
        return AddressConvert.INSTANCE.convert02(addressService.getDefaultUserAddress(userId));
    }

}
