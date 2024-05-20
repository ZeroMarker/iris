## 绑定
```
/// creator: 宋春莉
/// date: 2020-07-03
/// desc: 根据医嘱录入需要审核的医嘱项目获取绑定的医嘱列表并重新整合需要插入的串
/// input:	Adm：就诊ID OrdItemStr:医嘱录入需要审核的医嘱项目拼接字符串 
/// 		Loc 录入科室ID
/// 		SessionStr:	websys.js->GetSessionStr\websys_getSessionStr;DHCDoc.Util.RegisteredObject->%SessionStr;部分通过接口传入，可能无完整数据
/// 		BaseParamJson:基本参数列表，可自行扩展
/// 			DisBindTypeList:不需要计算的绑定类型，关键字参照BindSource，逗号分隔
/// output:	包含绑定医嘱的新医嘱录入串
/// w ##class(web.DHCOEOrdAppendItem).GetAppendOrdItemArr()

/// Others: w ##class(DHCDoc.Interface.Inside.ServiceOrd).SaveOrderItems()
```