package com.lxjl.juling.module.bill.api;

import com.lxjl.juling.framework.common.util.object.BeanUtils;
import com.lxjl.juling.module.bill.api.dto.BillLogCreateReqDTO;
import com.lxjl.juling.module.bill.api.dto.BillRelationCreateReqDTO;
import com.lxjl.juling.module.bill.api.dto.BillTypeRespDTO;
import com.lxjl.juling.module.bill.dal.dataobject.BillExtDO;
import com.lxjl.juling.module.bill.dal.dataobject.BillLogDO;
import com.lxjl.juling.module.bill.dal.dataobject.BillNoSeqDO;
import com.lxjl.juling.module.bill.dal.dataobject.BillRelationDO;
import com.lxjl.juling.module.bill.dal.dataobject.BillTypeDO;
import com.lxjl.juling.module.bill.dal.mysql.BillExtMapper;
import com.lxjl.juling.module.bill.dal.mysql.BillLogMapper;
import com.lxjl.juling.module.bill.dal.mysql.BillNoSeqMapper;
import com.lxjl.juling.module.bill.dal.mysql.BillRelationMapper;
import com.lxjl.juling.module.bill.dal.mysql.BillTypeMapper;
import com.lxjl.juling.module.bill.enums.BillStatusEnum;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.module.bill.enums.ErrorCodeConstants.BILL_EXT_DUPLICATE;
import static com.lxjl.juling.module.bill.enums.ErrorCodeConstants.BILL_RELATION_DUPLICATE;
import static com.lxjl.juling.module.bill.enums.ErrorCodeConstants.BILL_STATUS_TRANSFER_ILLEGAL;
import static com.lxjl.juling.module.bill.enums.ErrorCodeConstants.BILL_TYPE_NOT_EXISTS;

/**
 * 单据平台 API 实现
 *
 * @author 亚特
 */
@Slf4j
@Service
@Validated
public class BillPlatformApiImpl implements BillPlatformApi {

    @Resource
    private BillTypeMapper billTypeMapper;
    @Resource
    private BillNoSeqMapper billNoSeqMapper;
    @Resource
    private BillRelationMapper billRelationMapper;
    @Resource
    private BillLogMapper billLogMapper;
    @Resource
    private BillExtMapper billExtMapper;

    // ==================== 单号 ====================

    @Override
    @Transactional(rollbackFor = Exception.class)
    public String generateNo(String billType, Long orgId) {
        // 1. 取单据类型（编号规则）
        BillTypeDO type = billTypeMapper.selectByCode(billType);
        if (type == null) {
            throw exception(BILL_TYPE_NOT_EXISTS, billType);
        }
        long org = orgId == null ? 0L : orgId;
        String period = resolvePeriod(type.getNoReset());

        // 2. 事务级咨询锁把「类型+组织+期间」的取号串行化，再"查—插/更新"。
        //    不用 catch(DuplicateKeyException) 重试：PostgreSQL 语句失败即把事务置为 aborted，
        //    同事务内后续语句会被拒绝（实测 10 并发只有 1 成功）。
        billNoSeqMapper.lockByKey("bill_no_seq:" + billType + ":" + org + ":" + period);
        BillNoSeqDO seq = billNoSeqMapper.selectByKey(billType, org, period);
        long next;
        if (seq == null) {
            billNoSeqMapper.insert(BillNoSeqDO.builder().billType(billType).orgId(org).period(period).lastNo(1L).build());
            next = 1L;
        } else {
            next = seq.getLastNo() + 1;
            seq.setLastNo(next);
            billNoSeqMapper.updateById(seq);
        }
        // 3. 拼号：前缀 + 日期 + 流水
        StringBuilder no = new StringBuilder(type.getNoPrefix() == null ? "" : type.getNoPrefix());
        if (!"ALL".equals(period)) {
            String fmt = type.getNoDateFormat() == null || type.getNoDateFormat().isEmpty() ? "yyyyMMdd" : type.getNoDateFormat();
            no.append(LocalDateTime.now().format(DateTimeFormatter.ofPattern(fmt)));
        }
        int len = type.getNoSeqLength() == null ? 4 : type.getNoSeqLength();
        no.append(String.format("%0" + len + "d", next));
        return no.toString();
    }

    private String resolvePeriod(String noReset) {
        String reset = noReset == null ? "D" : noReset;
        return switch (reset) {
            case "M" -> LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMM"));
            case "Y" -> LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy"));
            case "N" -> "ALL";
            default -> LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        };
    }

    // ==================== 状态机 ====================

    @Override
    public void validateTransition(String billType, Integer fromStatus, Integer toStatus) {
        if (!BillStatusEnum.canTransfer(fromStatus, toStatus)) {
            throw exception(BILL_STATUS_TRANSFER_ILLEGAL,
                    BillStatusEnum.valueOf(fromStatus), BillStatusEnum.valueOf(toStatus));
        }
    }

    // ==================== 日志 ====================

    @Override
    public void log(BillLogCreateReqDTO reqDTO) {
        BillLogDO logDO = BeanUtils.toBean(reqDTO, BillLogDO.class);
        logDO.setOperateTime(LocalDateTime.now());
        billLogMapper.insert(logDO);
    }

    // ==================== 关联（下推） ====================

    @Override
    public boolean addRelation(BillRelationCreateReqDTO reqDTO) {
        // 先查后写：避免撞唯一索引。注意 PostgreSQL 在语句失败后会把事务置为 aborted，
        // 因此**不能** catch 后继续执行——这里一旦真撞上（并发极端情况），明确抛业务异常让外层整体回滚。
        if (existsRelation(reqDTO.getSourceType(), reqDTO.getSourceId(), reqDTO.getSourceItemId(),
                reqDTO.getTargetType(), reqDTO.getTargetId(), reqDTO.getTargetItemId())) {
            return false;
        }
        try {
            billRelationMapper.insert(BeanUtils.toBean(reqDTO, BillRelationDO.class));
            return true;
        } catch (DuplicateKeyException e) {
            throw exception(BILL_RELATION_DUPLICATE);
        }
    }

    private boolean existsRelation(String sourceType, Long sourceId, Long sourceItemId,
                                   String targetType, Long targetId, Long targetItemId) {
        return billRelationMapper.selectCount(new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<BillRelationDO>()
                .eq(BillRelationDO::getSourceType, sourceType)
                .eq(BillRelationDO::getSourceId, sourceId)
                .eq(sourceItemId != null, BillRelationDO::getSourceItemId, sourceItemId)
                .eq(BillRelationDO::getTargetType, targetType)
                .eq(BillRelationDO::getTargetId, targetId)
                .eq(targetItemId != null, BillRelationDO::getTargetItemId, targetItemId)) > 0;
    }

    @Override
    public boolean hasRelation(String sourceType, Long sourceId, String targetType) {
        return billRelationMapper.selectCount(new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<BillRelationDO>()
                .eq(BillRelationDO::getSourceType, sourceType)
                .eq(BillRelationDO::getSourceId, sourceId)
                .eq(BillRelationDO::getTargetType, targetType)) > 0;
    }

    @Override
    public List<BillRelationDO> getUpstreamList(String targetType, Long targetId) {
        return billRelationMapper.selectList(new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<BillRelationDO>()
                .eq(BillRelationDO::getTargetType, targetType).eq(BillRelationDO::getTargetId, targetId));
    }

    @Override
    public List<BillRelationDO> getDownstreamList(String sourceType, Long sourceId) {
        return billRelationMapper.selectList(new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<BillRelationDO>()
                .eq(BillRelationDO::getSourceType, sourceType).eq(BillRelationDO::getSourceId, sourceId));
    }

    // ==================== 扩展字段 ====================

    @Override
    public void saveExt(String billType, Long billId, Map<String, String> extMap) {
        if (extMap == null || extMap.isEmpty()) {
            return;
        }
        extMap.forEach((key, value) -> {
            BillExtDO exists = billExtMapper.selectOne(new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<BillExtDO>()
                    .eq(BillExtDO::getBillType, billType).eq(BillExtDO::getBillId, billId).eq(BillExtDO::getFieldKey, key));
            if (exists == null) {
                try {
                    billExtMapper.insert(BillExtDO.builder().billType(billType).billId(billId)
                            .fieldKey(key).fieldValue(value).fieldType("string").build());
                } catch (DuplicateKeyException e) {
                    throw exception(BILL_EXT_DUPLICATE, key);
                }
            } else if (!Objects.equals(exists.getFieldValue(), value)) {
                exists.setFieldValue(value);
                billExtMapper.updateById(exists);
            }
        });
    }

    @Override
    public Map<String, String> getExtMap(String billType, Long billId) {
        List<BillExtDO> list = billExtMapper.selectList(new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<BillExtDO>()
                .eq(BillExtDO::getBillType, billType).eq(BillExtDO::getBillId, billId));
        Map<String, String> map = new HashMap<>();
        list.forEach(item -> map.put(item.getFieldKey(), item.getFieldValue()));
        return map;
    }

    // ==================== 类型配置 ====================

    @Override
    public BillTypeRespDTO getType(String billType) {
        return BeanUtils.toBean(billTypeMapper.selectByCode(billType), BillTypeRespDTO.class);
    }

}
