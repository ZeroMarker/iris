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

Reg.hui.js

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
demo: 科室排序定义排序

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

## 门诊诊断证明书打印
xml模板参数图片地址

## 首日回车换行
UDHCOEOrder.List.Custom.New.js
function FrequencyLookUpSelect

[Code](./doc/code/orderJump.md)

## 阿帕奇评分死亡转科出院医嘱
oeorder.oplistcustom.new.csp
UDHCOEOrder.List.Custom.New.js

## 手麻接受科室医嘱库存
##class(web.DHCOEOrdItem).SaveOrderItems(EpisodeID, oeoriStr, userId, locId, careprovId)
;是否在插入医嘱之前调用审查方法,如果在插入医嘱之前未调用CheckBeforeSave,需传入此参数(例如以此方法作为接口调用)
s IsCheckOrdItemStr=$p(ExpStr,"^",4)

## 诊间预约提前取号
OPAdm/Reg.hui.js
ClassName : "web.DHCRBAppointment",
MethodName : "GetAppInfo",
...//Quit:ASDate<+$h  不允许提前取号 刘亚提
...Quit:ASDate'=+$h
...Q:(AdvanceAppAdm'=1)&&(ASDate'=..%SysDate())
...Q:((RBAppRowIDStr'="")&&(("^"_RBAppRowIDStr_"^")[("^"_RBAppRowID_"^")))
...do OutAppInfo(ASRowId)

## 病理申请推送地址

SELECT * 
FROM Ens_InterfaceMethod
-- WHERE method_Code [ "MES0048"
WHERE method_Desc [ "病理"


SELECT * 
FROM Ens_InterfaceV8
WHERE method_Code [ "S00000042"

SELECT * 
FROM Ens_SubApiSysConfig
WHERE method_Code [ "S00000042"
^Config.ENS.EnsApiSysConfigD

SELECT * 
FROM Ens_ApiSysConfig
WHERE method_Code [ "S00000042"

SELECT * FROM OE_OrdItem
WHERE OEORI_OEORD_ParRef IN
(
	SELECT OEORD_RowId1 FROM OE_Order
	WHERE OEORD_Adm_DR IN
	(
		SELECT PAADM_RowID FROM PA_Adm
		WHERE PAADM_PAPMI_DR = 95
	)
)
[Code](./doc/code/pisApply.md)

demo
医院信息平台
服务列表

## 门诊传染病报卡
dhcdoc.DHCDocDiagnoEntry.V8.js
function CheckBeforeInsertMRDiag(callBackFun)
if ((MRCIDRowId!="")&&(MRCIDRowId!=null)){
	if (!CheckDiagIsEnabled(MRCIDRowId)) return false;
	var SeriousDisease=cspRunServerMethod(ServerObj.GetSeriousDiseaseByICDMethod,MRCIDRowId);
	if (SeriousDisease=="Y"){
		if (SeriousDiseaseICDStr=="") SeriousDiseaseICDStr=DiagnosICDDesc;
		else  SeriousDiseaseICDStr=SeriousDiseaseICDStr+","+DiagnosICDDesc;
	}
}
select *
from MRC_ICDDx

## 将医嘱停止时间后的所有未执行记录变为"停止执行"状态
w ##class(appcom.OEOrdExec).DiscontinueExec("531546||1",590)
if (StopAllExecFlag'=1)&&
	((XDate=ExeDate)&&(XTime>=ExeTime)&&(XTime'=0)) {
	//XTime如果是0，则认为当天所有的执行记录都需要停止，包括要求执行时间为0的；等同于||((XDate>ExeDate)&&(XTime=0))
	Continue	;CurrDate换XDate
}
if XDate=ExeDate,XTime>ExeTime,StopAllExecFlag'=1 Continue	;CurrDate换XDate

## 回诊 复诊
web.DHCAlloc
PatAgain

## 显示挂号职称
OPAdm/ScheduleAdjust.hui.js
//InitSingleCombo(id,valueField,textField,ClassName,Query,exp,multipleField)
//InitSingleCombo('DocSessionNew','ID','Desc','RBCSessionTypeQuery',false,"web.DHCBL.BaseReg.BaseDataQuery");
InitSingleCombo('DocSessionNew','ID','Desc','web.DHCBL.BaseReg.BaseDataQuery','RBCSessionTypeQuery',"&Arg1="+HospitalDr+"&ArgCnt=1");
// d ##class(%ResultSet).RunQuery("web.DHCBL.BaseReg.BaseDataQuery","RBCSessionTypeQuery",2)

分诊优先患者不能取消报到
Alloc.NurseTriage.hui.js
function InitAllocListTabDataGrid()
if (row["Prior"]=="优先"){
	ChangeMenuDisable("CancleQueCheckin",true);
}

## 获取患者信息后光标跳转
Reg.hui.js
```js
if (SrcObj.id=="CardNo"){
	CardNoKeydownHandler(e);
	$('#DeptList').focus();
	return false;
}else if(SrcObj.id=="PatientNo"){
	PatientNoKeydownHandler(e);
	$('#DeptList').focus();
	return false;
}
```
CardNoKeyDownCallBack

## 医嘱氧气吸入数量显示
[Code](./doc/code/sumQty.md)

w ##Class(web.DHCDocInPatPortalCommon).OrderInfo("240||86")

w (^OEORD(240,"I",86,2))

;长嘱剂量为空数量去除"共"
if (##class(appcom.OEOrdItem).ISLongOrderPrior(PriorityDR))&&(doseUnitDr="") {
	s TOrderDesc = $replace(TOrderDesc, "共：", "")	
	s TOrderName = TOrderName_space_SumQty
	s SumQty = ""
}

## 挂号速度慢
w ##class(web.DHCENS.BLL.Message.Method.public).SendMessageInfo("MES0072","44$#$17855606389,17631666188$#$1")
s soap=##class(web.DHCENS.BLL.Message.Soap.PUB0009Soap).%New()
		b ; 101
		;s stream=soap.HIPService(MessageCode,streams)


## 挂号调用支付接口
/// Creator: zhenghao
/// CreatDate: 2018-03-07
/// Descripiton: 根据支付方式ID取配置表
/// Input: PayMode:支付方式ID
/// Return: 支付方式扩展表字段(调用标志、调用方法、调用方式、退费标志)
/// Debug: w ##class(DHCBILL.Common.DHCBILLCommon).GetCallModeByPayMode(4)
ClassMethod GetCallModeByPayMode(PayMode As %String) As %String

SELECT *
FROM
CT_PayMode

SELECT *
FROM
DHC_CTPayModeExp

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

MisPosePublic.js
DHCBillPayService.js
DHCBillMisPosPay.js

## 病理申请单Not Found

dhcapp.docpopwin.csp
i mListDataDoc'="" D
.D ##Class(web.DHCAPPPisInterface).GetExaItemListDoc(mListDataDoc, .itemTmpArr)

.s Type=##Class(web.DHCAPPExaReportQuery).GetTraType(arcimid)
	.i Type="P" D
	..s LinkUrl=..GetLinkUrl(arcimid
	
s PisType=..GetPisType(arcimid) 	             /// 取病理类型
	Q:PisType="" "-1"

n (arcimid)
Q:arcimid="" ""
b ;xz--001
s TraID=$o(^DHCAPARCCA(0,"Arc",arcimid,""))
Q:TraID="" ""
s PisType=$p(^DHCAPARCCA(TraID),"^",1)
Q PisType

SELECT *
FROM DHC_AppCatLinkArcItm