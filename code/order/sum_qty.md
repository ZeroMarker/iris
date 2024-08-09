氧气吸入数量单位
ClassName: web.DHCDocInPatPortalCommon
QueryName: FindInPatOrder
papmi: 38
adm: 261
doctor: 全部
scope: 1
stloc: 1
nursebill: ALL
inputOrderDesc: 
PriorType: ALL
CatType: ALL
SortType: DT
OrderPriorType: 
InstrID: 
FreqID: 
focusOrdList: 
Pagerows: 99999
ScrollView: 1
rows: 99999

TOrderDesc: 
"&nbsp氧气吸入&nbsp&nbsp<font style=font-style:italic;text-decoration:underline></font>"
TOrderName: 
"&nbsp氧气吸入"

TOrderDesc: 
"<font color=red>停止</font>&nbsp&nbsp(基)0.9%氯化钠注射液[袋装100ml]&nbsp&nbsp1<font style=font-style:italic;text-decoration:underline>袋</font>&nbsp&nbspivdrip&nbsp&nbspBID&nbsp&nbsp首日:1"
TOrderName: 
"<font color=red>停止</font>&nbsp&nbsp(基)0.9%氯化钠注射液[袋装100ml]&nbsp&nbsp首日:1"
240||86

w ##Class(web.DHCDocInPatPortalCommon).OrderInfo("240||86")

w (^OEORD(240,"I",86,2))

;长嘱剂量为空数量去除"共"
if (##class(appcom.OEOrdItem).ISLongOrderPrior(PriorityDR))&&(doseUnitDr="") {
	s TOrderDesc = $replace(TOrderDesc, "共：", "")	
	s TOrderName = TOrderName_space_SumQty
	s SumQty = ""
}