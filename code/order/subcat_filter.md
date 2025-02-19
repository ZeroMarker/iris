# code

```objectscript
web.DHCDocNurseBatchSupplementOrd.cls(GetItemToList+278)
if (OrderType = "R") {
	;s CallBackFunParams=ArcimDesc_" 在此页面仅支持【取药医嘱】类型,若非取药医嘱，请使用常规“医嘱录入”功能录入"
	s SubCat = $p(^ARCIM(+ARCIMRowId,$p(ARCIMRowId,"||",2),1),"^",10)
	//医嘱子类其他
	if (SubCat'=36) {
		s CallBackFunParams=ArcimDesc_" 在此页面开立的医嘱为【取药医嘱】类型，是否确认录入？"
		s CallBackFunStr=##class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
	}
}
```
