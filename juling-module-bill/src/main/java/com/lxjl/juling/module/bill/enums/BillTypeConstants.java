package com.lxjl.juling.module.bill.enums;

/**
 * 单据类型常量（与 bill_type.code 一一对应）
 *
 * 画面/文档里用中文名，代码里用这里的常量，禁止硬编码字符串。
 *
 * @author 亚特
 */
public interface BillTypeConstants {

    String PURCHASE_REQ = "PURCHASE_REQ";
    String PURCHASE_ORDER = "PURCHASE_ORDER";
    String PURCHASE_IN = "PURCHASE_IN";
    String PURCHASE_RETURN = "PURCHASE_RETURN";
    String RECEIPT_NOTICE = "RECEIPT_NOTICE";
    String QUALITY_INSPECT = "QUALITY_INSPECT";
    String STORE_REQUISITION = "STORE_REQUISITION";
    String DELIVERY_OUT = "DELIVERY_OUT";
    String STORE_RECEIPT = "STORE_RECEIPT";
    String DELIVERY_DIFF = "DELIVERY_DIFF";
    String DELIVERY_SUPPLEMENT = "DELIVERY_SUPPLEMENT";
    String STORE_RETURN = "STORE_RETURN";
    String STORE_RETURN_OUT = "STORE_RETURN_OUT";
    String STORE_SCRAP = "STORE_SCRAP";
    String DIRECT_SALE = "DIRECT_SALE";
    String STORE_SELF_PURCHASE = "STORE_SELF_PURCHASE";
    String STOCK_TRANSFER = "STOCK_TRANSFER";
    String STOCK_CHECK = "STOCK_CHECK";
    String STOCK_CHECK_PROFIT = "STOCK_CHECK_PROFIT";
    String STOCK_CHECK_LOSS = "STOCK_CHECK_LOSS";
    String PAYABLE = "PAYABLE";
    String RECEIVABLE = "RECEIVABLE";
    String FINANCE_PAYMENT = "FINANCE_PAYMENT";
    String FINANCE_RECEIPT = "FINANCE_RECEIPT";
    String OTHER_IN = "OTHER_IN";
    String OTHER_OUT = "OTHER_OUT";

}
