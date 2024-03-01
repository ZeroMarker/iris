```objectscript
w ##Class(web.DHCOEOrdItemView).GetItemCongeriesToList($list(^TMPtan("GetItemCongeriesToList"),1),$list(^TMPtan("GetItemCongeriesToList"),2),$list(^TMPtan("GetItemCongeriesToList"),3),$list(^TMPtan("GetItemCongeriesToList"),4),$list(^TMPtan("GetItemCongeriesToList"),5))

s Check =##Class(web.DHCDocOrderCommon).CheckStockEnough(OrderARCIMRowid, BaseDoseQtySum, MOrderRecDepRowid,PAAdmType,ExpStr)

set IsEnableBatItem=##class(web.DHCOEDispensing).IsEnableBatItem(arcim,Adm,HospitalID)
s Ret=0
if (AllowOrderWOStockCheck="Y")&&(IsEnableBatItem="0") s Ret=1

;药品走批次价标识
s DrugRuleFlag=##Class(web.DHCSTCOMMPARA).GetRpRule(HospitalId)
;材料走批次价标识
//s MaterialRuleFlag=##class(web.DHCSTM.DHCSTMSERVICE).GetBatSpFlag(HospitalId)
s MaterialRuleFlag=##class(web.DHCSTMHUI.DHCSTMSERVICE).GetBatSpFlag(HospitalId,ARCIMRowId)
if ((+DrugRuleFlag=3)&&(cattype="R"))||((+MaterialRuleFlag=1)&&(cattype="M")){
    q 1
}else{
    q 0
}
```

```sql
SELECT ARCIM_AllowOrderWOStockCheck ,*
FROM ARC_ItmMast
WHERE ARCIM_RowId = "582||1";
```

- 把材料处理成药品了

