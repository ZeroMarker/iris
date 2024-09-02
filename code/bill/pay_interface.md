## 挂号调用支付接口
```objectscript
/// Creator: zhenghao
/// CreatDate: 2018-03-07
/// Descripiton: 根据支付方式ID取配置表
/// Input: PayMode:支付方式ID
/// Return: 支付方式扩展表字段(调用标志、调用方法、调用方式、退费标志)
/// Debug: w ##class(DHCBILL.Common.DHCBILLCommon).GetCallModeByPayMode(4)
ClassMethod GetCallModeByPayMode(PayMode As %String) As %String
```
```sql
SELECT *
FROM CT_PayMode

SELECT *
FROM DHC_CTPayModeExp

INSERT INTO SQLUser.DHC_CTPayModeExp (PME_AppRefundPM_DR, PME_ClassName, PME_HardCom_DR, PME_IFMode, PME_IOType, PME_MethodName, PME_PayMode_DR, PME_RefundFlag)
VALUES
(NULL, NULL, NULL, 'SP', 'OP', NULL, '3', NULL),
('Y', 'DHCBILL.MisPos.Adapter.YLSWMisPosSYDEFY', 1, 'DLL', 'OP', NULL, '48', NULL),
('Y', 'DHCBILL.MisPos.Adapter.YLSWMisPosSYDEFY', 1, 'DLL', 'OP', NULL, '49', NULL),
('Y', NULL, 1, 'YDGZ', 'OP', NULL, '50', NULL),
('Y', NULL, 1, 'DZPZ', 'OP', NULL, '53', NULL),
('Y', NULL, 1, 'YDGZ', 'OP', NULL, '54', NULL),
('Y', NULL, 1, 'SP', 'OP', NULL, '65', NULL),
('Y', NULL, 1, 'SP', 'OP', NULL, '66', NULL),
('Y', NULL, 1, 'WS', 'OP', NULL, '58', NULL),
('Y', NULL, 1, 'SPYLSW', 'OP', NULL, '47', NULL),
('Y', '', 1, 'SPYLSW', 'OP', NULL, '46', NULL);
```

MisPosePublic.js
DHCBillPayService.js
DHCBillMisPosPay.js
