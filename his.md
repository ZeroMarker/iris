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
(.csp -> .show.csp -> .js -> .cls -> cls)
// 建卡信息回传
CardReg.hui.js
function GetPatDetailByPAPMINo()
ClassName: "web.DHCBL.CARD.UCardPaPatMasInfo",
MethodName: "GetPatInfoByPANo",
$o(^PAADM(5),-1)
4

## 医嘱录入搜索提示添加集采字段

安全组
医嘱录入表格列设置
BDP

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
doc.patientinfoupdate.hui.csp

s IPAddress=##class(%SYSTEM.Process).ClientIPAddress()    ;获取IP地址

s %session.Data("LOGON.USERID")=UserID
s %session.Data("LOGON.CTLOCID")=LocID
s %session.Data("LOGON.GROUPID")=GroupID
s %session.Data("LOGON.HOSPID")=HospID
s %session.Data("LOGON.WARDID")=WARDID
s %session.Data("LOGON.LANGID")=LANGID
s %session.Data("LOGON.SSUSERLOGINID")=SSUSERLOGINID

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
[Code](./doc/code/apache.md)

## 手麻接受科室医嘱库存
##class(web.DHCOEOrdItem).SaveOrderItems(EpisodeID, oeoriStr, userId, locId, careprovId)
;是否在插入医嘱之前调用审查方法,如果在插入医嘱之前未调用CheckBeforeSave,需传入此参数(例如以此方法作为接口调用)
s IsCheckOrdItemStr=$p(ExpStr,"^",4)
s retStr=##class(web.DHCOEOrdItem).SaveOrderItems(EpisodeID,oeoriStr,userId,locId,docId,"","^^^Y")

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

[Code](./doc/code/pisApply.md)

demo
医院信息平台
服务列表

医院院内服务总线 iBus

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

## 分诊优先患者不能取消报到
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
[Code](./doc/code/payInterface.md)

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

## 费用明细默认分页行数

安全组 安全组设置 列编辑器

## 医生预停医嘱护士补录关联医嘱同步预停时间

//子医嘱预停信息为空
//子医嘱同步显示主医嘱预停信息
if (+oeorioeoridr>0){
	if TStopDate="" {
		s oeorioeoriParref=+oeorioeoridr
		s oeorioeoriId=$p(oeorioeoridr,"||",2)
		s TStopDate = $p(^OEORD(oeorioeoriParref,"I",oeorioeoriId,3),"^",34)		;XDate
		s:$d(^OEORD(oeorioeoriParref,"I",oeorioeoriId,2)) TStopTime = $p(^OEORD(oeorioeoriParref,"I",oeorioeoriId,2),"^",15)		;XTime
		s TExEndDate = $p(^OEORD(oeorioeoriParref,"I",oeorioeoriId,9),"^",9)		;OEORI_EndDate	
		s TExEndTime = $p(^OEORD(oeorioeoriParref,"I",oeorioeoriId,9),"^",10) 	;OEORI_EndTime
		s TStopDate = $s(TStopDate="":TExEndDate, 1:TStopDate)			;没停止日期时,取预停日期	
		s TStopTime = $s(TStopTime="":TExEndTime, 1:TStopTime)

		s:TStopDate'="" TStopDate=..%ZD(TStopDate) //$zd(TStopDate,3)
		s:TStopTime'="" TStopTime=..%ZT(TStopTime,2) 
		s itemStatDr = $p(str1,"^",13) 		;OEORI_ItemStat_DR ;OEC_OrderStatus
		s:+itemStatDr>0 TItemStatCode = $p(^OEC("OSTAT",itemStatDr),"^",1)

		s userUpdateDr=$p($g(^OEORD(oeorioeoriParref,"I",oeorioeoriId,8)),"^",12)
		s:(+userUpdateDr>0)&&(TExEndDate'="") TStopDoctor = $p($g(^SSU("SSUSR",userUpdateDr)),"^",2)	;预停医生
		s StopDoctorDR = $p(^OEORD(oeorioeoriParref,"I",oeorioeoriId,3),"^",29)
		s:+StopDoctorDR>0 TStopDoctor = $p(^CTPCP(StopDoctorDR,1),"^",2)	;重新覆盖停医嘱医生
		s TStDateHide=TStDate,TStTimeHide=TStTime
		s TStopNurse = ##class(web.DHCDocMainOrderInterface).GetXOrderNurseName(oeorioeoriParref,oeorioeoriId)	
	}
}

## 病理申请标本类型表单显示
ClassName: web.DHCAppPisMasterQuery
MethodName: JsonBaseItemList
dataType: json
Title: 标本类型
Name: SpceTypelist
Type: LIVN
HospID: 2

/// Descritp: 病理基础字典数据
/// w ##class(web.DHCAppPisMasterQuery).JsonBaseItemList("采集方式","CollectTypelist","LIVN","2")
ClassMethod JsonBaseItemList(Title, Name, Type As %String = "", HospID As %String)
{
	s ^temp("JsonBaseItemList")=$LB(Title, Name, Type, HospID)
	Set langid=..%LanguageID()
	s Stream=##class(%Stream.GlobalCharacter).%New()
	d Stream.Write("[")
	s TitleText=##class(User.DHCAppPisDicType).GetTranByDesc("APDesc",Title,langid)
	d Stream.Write(##class(web.DHCAPPJsonCommon).getJsonTreeStartSign(1,TitleText))
	d Stream.Write(",""items"":")
	d Stream.Write(##Class(web.DHCAppPisMasterQuery).JsonGetPisDicTypeNew(Title,HospID,Name,Type))
	d Stream.Write("}")
	d Stream.Write("]")
	Q Stream.Read()
}

## 导诊单合管打印

/// Creator: ZhYW
/// CreatDate: 2020-02-03
/// Description: 获取导诊单打印数据
/// Input: PrtRowid:DHC_INVPRT.PRT_Rowid
/// Output: 
/// Return: 
/// Debug: w ##class(BILL.OP.BL.Direct.Interface).GetPrintJsonStr("631616","21202^239^389")

/// add by xz   山一大二附院
/// 门诊医生要打未交费的导诊单  格式与计费组打出来的一致  复写计费组打印导诊单代码 
/// w ##class(DHCDoc.Interface.Inside.ServicePrint).GetDocPrintJson("448","18881^28^1")

//.set ^||TMP($j,"LabSort",labNo,labPrtBarPosition)=tmpInfo
..set ^||TMP($j,"LabSort",labNo,labPrtBarPosition,labNoDesc)=tmpInfo

i packQty="" s packQty=1

s Prior=$p($g(^OEORD(OrderRowid,"I",OrdSub,1)),"^",8)  //add by zhangtong 门诊自备药即刻不上未缴费导诊单
continue:Prior=6

## 挂号一次三天优惠，做强制控制，三天内有非0元费用挂号，强制挂0元号
[Code](./doc/code/regCon.md)

## 	回龙观可以维护同医生、同时段、同开始时间、不同门诊的排班，且均可以生成排班记录，需在新增排班时增加提示
[Code](./doc/code/checkSchedule.md)

## PACS回传报告地址

/// Creator:QQA
/// CreatTime:2018-02-24
/// Descript:检查结果查询与病理合并使用:检查项目内容获取
/// w ##class(web.DHCAPPSeePatPacs).GetLisInspectOrdNew("1","10","547^217^2022-08-14^2023-02-10^21068^^^^")
ClassMethod GetLisInspectOrdNew(page As %String, rows As %String, Params As %String)

## 住院登记加载县区

[Code](./doc/code/defaultArea.md)

## 挂号弹窗可用开关立即生效
Reg.hui.js
[Code](./doc/code/switchbox.md)

## 勾选无库存医嘱依然提示库存不足
[Code](./doc/code/checkStock.md)

## 撤销检验医嘱
web.UDHCStopOrderLook.cls
[Code](./doc/code/cancelOrder.md)

## 挂号统计增加出诊时段筛选
[Code](./doc/code/regDocLog.md)

## 整包装发药不能开长期医嘱
[Code](./doc/code/needPackQty.md)

## 检验结果显示其他人检验项目
[Code](./doc/code/report.md)

## 0元挂号计费出错
w ##class(web.DHCOPAdmReg).OPRegistBroker("518","3514||14","1","","5||5||0||0||0||0||0","CASH","","19084","239","","","","","","","","","","","","","")
w ##class(web.DHCOPAdmReg).OPRegist("2","5||1","1","","0||0||0||0||0||0||0","CASH","","7","119","","","","","","","","","","","","","","","","上午","","1^0000060001")
b //修复挂号医嘱不为空(且不是免费医嘱),但挂号费、诊查费的折扣系数为1,导致未插入任何挂号医嘱,计费错误
if (InsertOrdFlag=0)&&(Price=0)&&(FreeOrder'="") {
	s ArcimId=FreeOrder
	s err=$$insertitem()
}

挂号设置 免费医嘱
计费 允许零元医嘱

## 门诊日志 初诊复诊筛选条件
<!--opdoc.recadmlog.hui.csp HISUI门诊日志--> 
OPDoc.RecAdmLog.hui.js
ClassName : "web.DHCOPDOCLog",
QueryName : "DHCOPLocLog",
[Code](./doc/code/opLocLog.md)

## 挂号筛选便民号
web.DHCOPAdmReg.cls
..S resDesc = $p(^RB("RES",RowId),"^",17)
..S groupDesc = $p(^SSU("SSGRP",GroupRowId),"^",1)
..Q:(groupDesc'["收费")&&(resDesc["便民号")

## 自助机筛选便民号
/// DHCExternalService.RegInterface.Service.SelfRegService
/// TODO: 查询排班记录
Method QueryAdmSchedule(XMLRequest As %String, SeachType As %String = "") As %Stream.GlobalCharacter [ WebMethod ]
{
	set rtn=##class(DHCExternalService.RegInterface.SelfRegMethods).QueryAdmSchedule(XMLRequest,SeachType)
	do rtn.XMLExportToStream(.OutputStream,"Response")
	quit OutputStream
}
## 就诊登记便民号
OPDoc.RapidRegist.hui.js
w ##class(web.DHCDoc.OP.PatConfigQuery).FindDocMarkStr(22005,1)

## 滚床位费

[Code](./doc/code/bedFee.md)
d first^CHQTASKNEW(2)
床位类型 费别 全自费

## 日志
/// creator:郭荣勇
/// date:20170310
/// desc:一般性的通用日志
/// table:DHCDoc_Log.Common
/// input:根据主键更新或者插入(Insert/Update),调用日志类,调用日志类方法,日志描述,主键(可以"."拼接),日志记录值
/// output:
/// eg: d ##class(DHCDoc.Log.Common).General("Update","web.DHCOEDispensing","PortForDurg","批次价失败记录","321||23||1","-1^执行记录不能为空")
/// eg: d ##class(DHCDoc.Log.Common).General("Insert","web.DHCOEDispensing","PortForDurg01","批次价失败记录第二个位置","321||23||1","-1^执行记录不能为空")

## 医生叫号 已就诊患者叫号提示"11^队列信息不存在不能呼叫!"
opdoc.patient.list.csp
dhcdoc.opdoc.patient.list.js
var ret=tkMakeServerCall("web.DHCVISQueueManage","RunNextButton","","",GetCacheIPAddress());
ClassMethod CheckCalledStatus(EpisodeID As %String, UserID As %String = "") As %String
{
	s retStr=""
	q:$g(EpisodeID)="" "9^就诊信息不存在,请重新呼叫!"
    i UserID="" s UserID=%session.Get("LOGON.USERID")
    s CareID=$P($G(^SSU("SSUSR",UserID)),"^",14)
	q:$g(CareID)="" "10^用户非医护人员不能呼叫!"
	s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""))
	q:QueRowId="" "11^队列信息不存在不能呼叫!"
	s oref=##Class(User.DHCQueue).%OpenId(QueRowId)
	s called=oref.QueCompDr
	s DocDr=oref.QueDocDrGetObjectId()
    d oref.%Close()
    q:(called=1)&&(DocDr'=CareID)&&(DocDr'="") "12^该病人已被其他医生呼叫,请重新呼叫!"
    q 0
}

## 医嘱套明细添加医嘱lookup添加字段
<!--udhcfavitem.edit.newedit.csp HUI医嘱套明细维护-->

## 医嘱选择用法后不能填数量
特殊用法设置
外用用法
没有疗程和单次剂量，只应用于门急诊（即选择该用法后，自动清空疗程和单次剂量）

## 医技录入医嘱提示过滤其他子类
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

## 调整挂号病人信息模块比例
opadm.cashierreg.show.csp
opadm.app.show.csp

## 打印病理条码问题排查
scripts/nurse/nis/HandleMethod/OrderExcute.js
scripts/dhcdoc/dhcapp/PrintBarCode.js
web.DHCDocAPPBL.cls

## 病理申请单标本信息必填
dhcdoc.dhcapp.blmapshow.js
dhcdoc.dhcapp.TCTBBPanelNew.js

#TCTSpecListNew
[Code](./doc/code/TCTBBPanelNew.js.md)

病理菜单 -> HPV申请单 -> 模板维护 -> 元素维护

## 建卡登记号作为卡号报错
scripts/UDHCCardPatInfoRegExp.js
NewEmrCard()

w ##Class(DHCDoc.Interface.Outside.ElecHealthCardService.ElecHealthCardMethods).createVmcardQRcode(^temp("createVmcardQRcode"))

## 作废医嘱
/// 作废医嘱 
/// w ##Class(LISAPP.Common.BLL.HISOrderItem).UnUseMulti("402||77","22064")

## 中药审核医嘱 中药调配费
///山一大二附院对调配费用加收的特殊规则
/*
var UpNums=OrderItemObj.length
if (UpNums>15){
	var CNMedAddARCIMRowId="15963||1"
	//var CNMedAddQty=(Math.ceil(UpNums/5))-3   ///向上取整
	var CNMedAddQty=(Math.floor(UpNums/5))-3   ///向下取整
	if (CNMedAddQty>0){
		var OrderItem=CNMedAddARCIMRowId+"^"+CNMedAddQty + "^" + "" + "^" + ""+"^"+""+"^^^^^^^^^CMPTAOF"+"^"+OrderSerialNum+"^"+CalPrescNo+"^"+CalPrescSeqNo;;
			OrderItemStr=OrderItemStr+String.fromCharCode(1)+OrderItem;
	}
	}
*/
## 挂号跳转报错
[Code](./doc/code/regJump.md)
SELECT *
FROM websys.menu
--where ID = 57618;
where caption like "挂号";

select *
from websys.WorkFlowItemDefinition
--where Url like "%&%";
WHERE ID = 50001;

## 检查检验不控制数量的子类
医嘱子类扩展设定
<!--设置 dhcdoc.config.subcatcontral.csp 子类控制设置-->
scripts/dhcdocconfig/dhcdoc.config.subcatcontral.js
url : $URL+"?ClassName=DHCDoc.DHCDocConfig.SubCatContral&QueryName=FindSubCatConfigList"
w ^DHCDocConfig("HospDr_2","NotLimitQtyCat")
--
ClassMethod CheckPackQtyUpdate
w ##class(web.DHCOEOrdItem).GetItemNotLimitQtySubCatFlag("2119||1")

## 检查核实状态
select OEORI_ItemStat_DR->ostat_desc,*
from OE_OrdItem
WHERE OEORI_RowId = "1238||7";

SELECT *
FROM Ens_InterfaceMethod
WHERE method_code like "%UpdateSystemStatus%";
SELECT ES_PreStatusCode, ES_StatusCode,*
FROM SqlUser.Ens_Statuslog
where ES_ExamID like "%EKG1041%";

SELECT *
from Ens_StatusCode;

SELECT *
FROM Ens_Status
WHERE ES_ExamID like "EKG1041%";

## 诊断删除日志增加诊断类型
SELECT * FROM 
MR_Diagnos;
SELECT *
from MR_DiagType;
SELECT *
from MRC_DiagnosType;
<!--dhcdoc.deldiaglist.csp 诊断删除记录-->
url:$URL+"?ClassName=web.DHCDocDiagnosEntryV8&QueryName=GetDelDiagList&mradm="+mradm, 
//诊断类型
s DiagTypeDr=$g(^MRDelLog(mradm,"Sub",sub,"Data","TYP",1))
s DiagType=##class(User.MRCDiagnosType).%OpenId(DiagTypeDr).DTYPDesc