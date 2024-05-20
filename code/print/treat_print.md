## 导诊单
DHCDoc.OPDoc.TreatPrint.cls
LoadPrintItemTree()
// 门诊系统参数 是否打印导诊单
prepareHandle()
ClassName:"web.DHCDocPrescript",
MethodName:"GetXMLTemplateId",
ClassName : printmethod["class"],//"DHCDoc.OPDoc.TreatPrint",
MethodName : printmethod["method"]//"PrintOrder"
DHCDoc.OPDoc.TreatPrint.cls
GetDZDPrintData()
// 删除最后的分隔线
for i=1:1:($l(OrdItemInfo,$c(2))-2)
<txtdatapara name="PANoBarCode" xcol="1.587" yrow="0.794" defaultvalue="" printvalue="" fontbold="false" fontname="C39P36DmTt" fontsize="26" />