## 修改建卡
cardreg.hui.csp
cardreg.show.hui.csp

web.DHCEntity.PCA.PATMAS.cls    add property to middle store class

CardReg.hui.js
$("#NewCard").click(NewCardclick);
function GetPatDetailByPAPMINo() {
}

web.DHCBL.CARDIF.ICardRefInfo.cls
web.DHCBL.CARD.UCardPatRegBuilder.cls

web.DHCBL.CARD.UCardPaPatMasInfo.cls

User.PAPatMas.cls

web.DHCEntity.PCA.CardPatInfoReg.cls
建卡信息存储中间类

// 建卡信息回传
CardReg.hui.js
function GetPatDetailByPAPMINo()
ClassName: "web.DHCBL.CARD.UCardPaPatMasInfo",
MethodName: "GetPatInfoByPANo",

.csp -> .show.csp -> .js -> .cls -> cls

## 医嘱录入搜索提示添加集采字段

oeorder.oplistcustom.new.csp

scripts/dhcdoc/UDHCOEOrder.List.Custom.New.js

oeorder.oplistcustom.show.csp

web.DHCDocOrderEntry.cls
Query LookUpItem(args)	// 位置决定字段值的位置
LookUpItemExecute(){
	s data = $lb()	// 位置决定字段值的位置
}

## 挂号

opadm.reg.hui.csp

reg.show.hui.csp

reg.hui.js

web.DHCOPAdmReg.cls

## 读卡挂号建卡不重复读卡

```js
function BRegExpClickHandle(PatientNo) {
	if (typeof PatientNo == undefined) { PatientNo = ""; }
	if ((PatientNo == "undefined") || (PatientNo == undefined)) { PatientNo = ""; }
	var src = "reg.cardreg.hui.csp?PatientNoReg=" + PatientNo;
	var $code = "<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='" + src + "'></iframe>";
	createModalDialog("CardReg", "建卡", PageLogicObj.dw + 160, PageLogicObj.dh, "icon-w-edit", "", $code, "");
}
BRegExpClickHandle(PatientNo);
```

## 挂号科室搜索前缀匹配排序
web.DHCOPAdmReg.cls
[Code](./doc/code/opDeptList.md##挂号科室搜索前缀匹配排序)

## 病历浏览没有治疗记录

dhcdoc/dhcdoccure/dhcdoc.cure.applylist
q 查询科室和就诊科室不一致

## 卡管理卡操作查询排序
Reg.CardManagement.hui.js

[Code](./doc/code/cardListSort.md##卡管理卡操作查询排序)

## 建卡入院来源下拉框
医生站配置 -> 本地化参数设置

## 毒麻处方打印总量
oeorder.printall.js
```js
if ((PoisonClass=='[麻 精一]')||(PoisonClass=='[精二]')){
	var inststring = "   			用法:每次" + DoseQty + "     " + Freq + "     " + PackQty + Inst + Testflag + "     " + Ordremark
}
```
ClassName : "web.DHCDocPrescript",
MethodName : "GetPrescInfoByOrd",

## 毒麻疼痛评分
```js
var lnk="dhcdoccheckpoison.csp?PatID="+PatientID+"&EpisodeID="+EpisodeID;
var retval=window.showModalDialog(lnk,"","dialogwidth:575px;dialogheight:180px;status:no;center:1;resizable:no");
if(retval){
	//web.DHCDocCheckPoison.UpdateAgencyInfo
	var encmeth=GlobalObj.UpdateAgencyInfoMethod;
	if (encmeth!=""){
		var rtn=cspRunServerMethod(encmeth,PatientID,retval,EpisodeID);
		if(rtn=="-100"){
			dhcsys_alert(ItemDesc+t['POISONSAVE_FAILED'])
			return false;   
		}
	}               
}
```

## 就诊号到达时间
DHCQueue

DHCQueueStatus

PerState

///^PAADMi("No",$$ALPHAUP({PAADM_ADMNo}),{PAADM_RowID})
///^User.DHCQueueI("QuePaadmDrIndex",QuePaadmDr)

[Code](./doc/code/admNoArriveTime.md##就诊号到达时间)

## 修改患者信息接口
【需求背景】:提供住院患者修改个人信息的接口，所需修改的字段已提供
民族（必填）
婚姻状况（必填）
身份证号
籍贯：省、市、县、地址（必填）
现住址：省、市、县、地址（必填）
户口：省、市、县、地址（必填）
联系人：（必填，不能是本人姓名，也不是“本人”俩字）
与患者关系（必填）
联系人电话（必填）
联系人证件类型
联系人证件号
联系人地址（必填）
电脑和小程序信息互通，如果在电脑上填了，手机上也会显示
【使用环境】:住院患者信息修改，接口，互联网医院住院患者信息修改

DHCExternalService.RegInterface.Service.SelfRegService.cls

DHCExternalService.CardInterface.CardManager.cls

[Code](./doc/code/updatePatInfo.md##修改患者信息接口)

## 处方
web.DHCDocPrescript.cls

## 医嘱
web.DHCDocOrderEntry.cls

## 挂号
web.DHCOPAdmReg.cls

## 治疗记录
User.DHCDocCureRecode.cls
DHCDoc.DHCDocCure.Record.cls
/scripts/dhcdoc/dhcdoccure_hui/app.emr.cureapplist.js

## 生物标本库查询修改日志
doc.patientinfoupdate.hui.csp
doc.patientinfoupdateforbiobank.hui.csp
doc.patientinfoupdatebiobank.hui.csp

## 草药代煎接受科室
opdoc.oeorder.cmlistcustom.csp
web.DHCDocOrderCommon

## 患者信息修改接口
dhcbill.ipbill.reg.csp

## 患者列表转出记录链接
d ##class(%ResultSet).RunQuery("web.DHCDocInPatientListNew", "GetChangeDeptPatList",16,18881,"currentLoc",66739,66745)

-- 电子病历维护
code null

## 医嘱备注保存医嘱套

WARG_1:web.DHCUserFavItems
WARG_2:InsertUserARCOS

WARG_1:web.DHCARCOrdSets
WARG_2:InsertItem
开始空格保存为空

## 停医嘱提示已经停止
w ##class(web.DHCDocInPatPortalCommon).MulOrdDealWithCom("2657||78"_$c(1)_"2021-12-20 21:17:31","","","U","1","12178^114^23^1^","")
w ##class(appcom.OEOrdItem).StopMulti("531546||1",590,"")
if PAADMType'="I" {
	s OrdList=$tr(OrdList,"!","&")
	Q ##class(web.UDHCStopOrderLook).StopOrder("","",OrdList,UserID,PinNum,PWFlag,"",.ErrMsg)
}
s OrdListStr=..GetMulOrdGroup(OrdList,UserID)

关联遗嘱

;重新组织停医嘱串,根据配置停主医嘱
s StopGroupOrder=..%GetConfig("StopGroupOrder",AdmHospDr)
;医生站设置菜单 停子医嘱同时停主医嘱 不勾选可以单独停子医嘱（仅支持门诊停医嘱界面）
;写死参数，让配置对住院不生效
s StopGroupOrder=1

## 关联医嘱主医嘱不显示深绿色
UDHCOEOrder.List.Custom.New.js
function OrderMasterChangeHandler

[Code](./doc/code/bindOrder.md)

## 病理申请推送
SELECT * 
FROM Ens_InterfaceMethod
WHERE method_Desc [ "病理"
ORDER BY method_Code

## 门诊诊断证明书打印
xml模板参数图片地址

## 首日回车换行
UDHCOEOrder.List.Custom.New.js
function FrequencyLookUpSelect

[Code](./doc/code/orderJump.md)

## 阿帕奇评分死亡转科出院医嘱

## 手麻接受科室医嘱库存