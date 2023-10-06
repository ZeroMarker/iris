## 修改建卡
cardreg.hui.csp

cardreg.show.hui.csp

show.csp add web element

web.DHCEntity.PCA.PATMAS.cls    add property to middle store class

CardReg.hui.js
$("#NewCard").click(NewCardclick);
function GetPatDetailByPAPMINo() {
}

web.DHCBL.CARDIF.ICardRefInfo.cls

web.DHCBL.CARD.UCardPatRegBuilder.cls

web.DHCBL.CARD.UCardPaPatMasInfo.cls
//联系人性别
Set patmas.PAPMIName7=PatObj.PAPMIName7			

//联系人职业
Set patmas.PAPMIName8=PatObj.PAPMIName8
	
Set sc = patmas.%Save()

User.PAPatMas.cls

web.DHCEntity.PCA.CardPatInfoReg.cls
建卡信息存储中间类

// 建卡信息回传
CardReg.hui.js
keypress()
function GetPatDetailByPAPMINo()
ClassName: "web.DHCBL.CARD.UCardPaPatMasInfo",
MethodName: "GetPatInfoByPANo",

Set myregobj=##class(web.DHCEntity.PCA.CardPatInfoReg).%New()
.Set PAPMIName8=$PIECE($GET(^PAPER(PapmiRowid,"ALL")),"^",24)
//联系人性别
Set myregobj.PAPMIName8=$GET(PAPMIName8)
Set myregobj=..ChangeNullValue(myregobj)
Do myregobj.XMLExportToString(.myXMLStr)


.csp -> .show.csp -> .js -> .cls -> cls.

## 医嘱录入搜索提示添加字段

oeorder.oplistcustom.new.csp

scripts/dhcdoc/UDHCOEOrder.List.Custom.new.js
field, title, text

oeorder.oplistcustom.show.csp

web.DHCDocOrderEntry.cls
Query LookUpItem(args)	// 位置决定字段值的位置
LookUpItemExecute(){
	s data = $lb()	// 位置决定字段值的位置
}

web.DHCDocOrderCommon.cls


<!--opdoc.outpatientlist.csp HISUI门诊病人列表--> 

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
```objectscript
/// d ##class(%ResultSet).RunQuery("web.DHCOPAdmReg","OPDeptList","reg","","",2)
ClassMethod OPDeptListExecute(ByRef qHandle As %Binary, UserId As %String, AdmType As %String = "", paradesc As %String = "", HospitalID As %String = "") As %Status
{
	Set repid=$INCREMENT(^CacheTemp)
	If $GET(ind)="" Set ind=1
	Kill OPDeptListArr
	Kill ^TMP($JOB,"RegCTLocLookup")
	Set UserId=$ZCONVERT(UserId,"U")
	If AdmType="" Set AdmType="O^E"
	Set Len=$LENGTH(AdmType,"^")
	Set HospitalID=##class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospitalID)
	Set SortType=##class(web.DHCOPRegConfig).GetSpecConfigNode("RegistLocSort",HospitalID)
	For i=1:1:Len  {
		Set AdmTypePut=$PIECE(AdmType,"^",i)
		Set RowId=0 For  Set RowId=$ORDER(^PAC("ADMLOC",0,"AdmType",AdmTypePut,RowId)) Quit:RowId=""  Do
		.Quit:$DATA(OPDeptListArr(RowId))
		.Quit:'$DATA(^RB("RES",0,"CTLOC",RowId))
		.Quit:..CheckLocDesc(RowId,paradesc)'=1
		.Set LocDateTo=$PIECE($GET(^CTLOC(RowId)),"^",25)
		.Quit:(LocDateTo'="")&&(LocDateTo<+$HOROLOG)
		.Set LocHospitalID=$PIECE($GET(^CTLOC(RowId)),"^",22)
		.;Q:LocHospitalID'=HospitalID
		.Quit:"N"=##class(DHCDoc.Common.Hospital).GetHospShowDataFlag("CT_Loc",RowId,HospitalID)
		.Set CTDesc=$PIECE($GET(^CTLOC(RowId)),"^",2)
		.Set CTAliasTem=""
		.If $LENGTH(CTDesc,"-")>1 Set CTAliasTem=$PIECE(CTDesc,"-",1)
		.Set CTAlias=$PIECE(^CTLOC(RowId),"^",43)
		.If CTAlias="" Set CTAlias=CTAliasTem
		.Set CTRowId=RowId
		.Set CTCode=CTRowId
		.Set CTLOCMarkNO=""
		.If SortType'="" Set CTLOCMarkNO=##class(web.DHCBL.BDP.BDPSort).GetSortNum("User.CTLoc",SortType,RowId)
		.Set CTLOCMarkNO=$CASE($LENGTH(CTLOCMarkNO),0:"999",1:"00"_CTLOCMarkNO,2:"0"_CTLOCMarkNO,:CTLOCMarkNO)
		.If $E(CTAlias, 1, $L(paradesc))=paradesc Set CTLOCMarkNO="001"
	    .Set ^TMP($JOB,"RegCTLocLookup"," "_CTLOCMarkNO,CTRowId)=CTDesc_"^"_CTAlias   //建立临时Globle
	    .Set OPDeptListArr(CTRowId)=1
		.//Do OutputRow1
	}
	//按照序号排序
	Set seq="" For {
		Set seq=$ORDER(^TMP($JOB,"RegCTLocLookup",seq))
		Quit:seq=""
		Set seq1="" For {
			Set seq1=$ORDER(^TMP($JOB,"RegCTLocLookup",seq,seq1))
			Quit:seq1=""
			Set temp=^TMP($JOB,"RegCTLocLookup",seq,seq1)
			Set CTRowId=seq1
			Set CTDesc=$PIECE(temp,"^",1)
			Set CTAlias=$PIECE(temp,"^",2)
			Do OutputRow1		
		}
	}
	
	Kill ^TMP($JOB,"RegCTLocLookup")
	Kill OPDeptListArr
 Set qHandle=$LISTBUILD(0,repid,0)
	Quit $$$OK
OutputRow1
	Set Data=$LISTBUILD(CTRowId,CTDesc,CTAlias)
	Set ^CacheTemp(repid,ind)=Data
	Set ind=ind+1
	Quit
ResetVariables1
	///set (repid)=0
	Set (CTRowId,CTCode,CTDesc,CTType)=""
	Quit
}
```
```objectscript
/// d ##class(%ResultSet).RunQuery("web.DHCRBResSession","GetClinicGroupByLocNew","","2","ck")
ClassMethod GetClinicGroupByLocNewExecute(ByRef qHandle As %Binary, LocRowId As %String = "", HospID = "", ParaDesc = "") As %Status
{
	s ^temp("GetClinicGroupByLocNew")=$lb(LocRowId, HospID, ParaDesc)
	;Q:LocRowId="" $$$OK
	If $g(ind)="" Set ind=1
	k ^TMP($J,"RegCTLocLookup")
	
	s HospID=##class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospID)
	s ID=0 for{
		s ID=$O(^DHCLocSubject(ID)) Q:ID=""
		s CLGRPRowId=$P(^DHCLocSubject(ID),"^",2)
		s CLGRPLoc=$P(^DHCLocSubject(ID),"^",1)
		continue:($p($g(^CTLOC(CLGRPLoc)),"^",22)'=HospID)
		continue:$d(ClinicGroupList(CLGRPRowId))
		continue:((LocRowId'="")&&(LocRowId'=CLGRPLoc))
		continue:(HospID'="")&&("N"=##class(DHCDoc.Common.Hospital).GetHospShowDataFlag("RBC_ClinicGroup",CLGRPRowId,HospID))
		s DateTo=$P(^RBC("CLGRP",CLGRPRowId),"^",4)
		continue:(DateTo'="")&&(DateTo<=..%SysDate())
		s DateFrom=$P(^RBC("CLGRP",CLGRPRowId),"^",3)
		continue:(DateFrom="")||(DateTo>+$H)
		s CLGRPDesc=$P(^RBC("CLGRP",CLGRPRowId),"^",2)
		s CLGRPCode=$P(^RBC("CLGRP",CLGRPRowId),"^",1)
		s ClinicGroupList(CLGRPRowId)=""
		//s CLGRPDescNew=##class(ext.util.String).ToChineseSpell(CLGRPDesc)
		s CLGRPCodeNew=$ZCVT(CLGRPCode,"U") 
        i ParaDesc'="" s ParaDesc=$ZCVT(ParaDesc,"U")
		continue:(ParaDesc'="")&&(CLGRPDesc'[ParaDesc)&&(CLGRPCodeNew'[ParaDesc)
		
		//*匹配ParaDesc前缀排序
		s CTLOCMarkNO=""
		s CTLOCMarkNO=$case($l(CTLOCMarkNO),0:"999",1:"00"_CTLOCMarkNO,2:"0"_CTLOCMarkNO,:CTLOCMarkNO)
		s:($e(CLGRPCodeNew, 1, $L(ParaDesc))=ParaDesc) CTLOCMarkNO="000"
	    s ^TMP($J,"RegCTLocLookup"," "_CTLOCMarkNO,CLGRPRowId)=CLGRPDesc_"^"_CLGRPCode   //建立临时Globle
	    //*
	    
	    //*原来代码
		//s qHandle($I(ind))=$LB(CLGRPRowId,CLGRPDesc,CLGRPCode)
	}
	//Quit $$$OK
	//*
	
	
	//*添加排序的代码
	//按照序号排序
	s seq="" for {
		s seq=$O(^TMP($J,"RegCTLocLookup",seq))
		Quit:seq=""
		s seq1="" for {
			s seq1=$O(^TMP($J,"RegCTLocLookup",seq,seq1))
			Quit:seq1=""
			s temp=^TMP($J,"RegCTLocLookup",seq,seq1)
			s CLGRPRowId=seq1
			s CLGRPDesc=$P(temp,"^",1)
			s CLGRPCode=$P(temp,"^",2)
			//b ;01
			s qHandle($I(ind))=$LB(CLGRPRowId,CLGRPDesc,CLGRPCode)		
		}
	}
	K ^TMP($J,"RegCTLocLookup")
	Quit $$$OK
	//*
}
```
## 病历浏览没有治疗记录

dhcdoc/dhcdoccure/dhcdoc.cure.applylist
q 查询科室和就诊科室不一致
```js
//查询 申请单列表
function loadCureApplyDataGrid()
{
	//EpisodeID
	var DisCancel=""
	var DisFinish=""
	var PatientID=$("#PatientID").val()
	var CancelDis=$("#CancelDis").prop("checked")
	if (CancelDis){DisCancel="Y"}
	var FinishDis=$("#FinishDis").prop("checked")
	if (FinishDis){DisFinish="Y"}
	var DocApplayNo=$('#DocApplayNo').val()
	
	var queryParams = new Object();
	queryParams.ClassName ='DHCDoc.DHCDocCure.Apply';
	queryParams.QueryName ='FindCureApplyList';
	queryParams.Arg1 ="";
	queryParams.Arg2 =PatientID;
	queryParams.Arg3 =session['LOGON.CTLOCID'];
	queryParams.Arg4 =DisCancel;
	queryParams.Arg5 =DocApplayNo;
	queryParams.Arg6 =DisFinish;
	queryParams.ArgCnt =6;
	var opts = cureApplyDataGrid.datagrid("options");
	opts.url = "./dhcdoc.cure.query.grid.easyui.csp"
	cureApplyDataGrid.datagrid('load', queryParams);
	cureApplyDataGrid.datagrid('unselectAll');
}
```
## 患者修改病人信息接口


## 卡管理卡操作查询排序
Reg.CardManagement.hui.js

```js
function RegReturnListTabDataGridLoad(){
	PageLogicObj.m_CardListTabDataGrid.datagrid("uncheckAll");
	$.cm({
	    ClassName : "web.DHCBL.CARD.CardManager",
	    QueryName : "PatientCardQuery",
	    Name:$("#Name").val(),
	    IDCardNo:"", //身份证号
	    CardNo:$("#CardNo").val(),
	    CardStatus:"N",
	    CardTypeID:$("#CardTypeRowID").val(), //GetCardTypeRowId(),
	    SupportFlag:"",
	    CredNo:$("#CredNo").val(),
	    UseStatus:"",
	    BirthDay:$("#BirthDay").val(),
	    Telphone:$("#Telphone").val(),
	    OutMedicareNo:$("#OutMedicareNo").val(),
	    InMedicareNo:$("#InMedicareNo").val(),
	    //NewOutMedicareNo:"",
	    NewInMedicareNo:"",
	    InsuranceNo:$("#InsuranceNo").val(),
	    EmMedicare:$("#EmMedicare").val(),
	    RegNo:$("#RegNo").val(),
	    Pagerows:PageLogicObj.m_CardListTabDataGrid.datagrid("options").pageSize,rows:99999
	},function(GridData){
		// Specific value to compare against
		var specificValue = $("#Name").val();
		var records = GridData.rows;
		var exact = records.filter(record => record.Name == specificValue);
		var mid = records.filter(record => record.Name.startsWith(specificValue) && record.Name !== specificValue);
		var remain = records.filter(record => !record.Name.startsWith(specificValue));

		// Sort the array based on pinyin
		mid.sort((a, b) =>
		a.Name.localeCompare(b.Name, 'zh-Hans-CN', {sensitivity: 'accent'})
		);
		
		remain.sort((a, b) =>
		a.Name.localeCompare(b.Name, 'zh-Hans-CN', {sensitivity: 'accent'})
		);
		
		GridData.rows = exact.concat(mid.concat(remain));
		//GridData.rows.sort((a, b) => a.Name.localeCompare(b.Name));
		//console.log(GridData);
		
		PageLogicObj.m_CardListTabDataGrid.datagrid({loadFilter:pagerFilter}).datagrid('loadData',GridData);
	}); 
}
```

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
## 阿帕奇评分死亡转科出院医嘱

## 就诊号到达时间
DHCQueue

DHCQueueStatus

PerState

///^PAADMi("No",$$ALPHAUP({PAADM_ADMNo}),{PAADM_RowID})
///^User.DHCQueueI("QuePaadmDrIndex",QuePaadmDr)
```objectscript
/// w ##class().GetArriveTimeByAdmNo(AdmNo)
/// "2023-09-05 17:09:10"
ClassMethod GetArriveTimeByAdmNo(AdmNo) As %String
{
	s RowId=0
    s AdmRowId=$o(^PAADMi("No",AdmNo,RowId))
    s RowId=0
    s QueDr=$o(^User.DHCQueueI("QuePaadmDrIndex",AdmRowId,RowId))

    ;s QueArriveDate=$P($G(^DHCQueueStatus(QueDr,QueChangeSub)),"^",1)
    ;s QueArriveTime=$P($G(^DHCQueueStatus(QueDr,QueChangeSub)),"^",2)
    s QueArriveTime=""
    s QueChangeSub=""
    f  {
        s QueChangeSub=$O(^DHCQueueStatus(QueDr,QueChangeSub),-1)
        Q:(QueChangeSub="")||(QueArriveTime'="")
        s QueChangeStatuDr=$P($G(^DHCQueueStatus(QueDr,QueChangeSub)),"^",4)
        continue:QueChangeStatuDr=""
        s QueChangeBeforeStatuDr=""
        //上条变化是报道且本次状态是等候
        s QueChangeBeforeSub=$O(^DHCQueueStatus(QueDr,QueChangeSub),-1)
        s QueChangeBeforeStatuDesc=""
        if (QueChangeBeforeSub'=""){
            s QueChangeBeforeStatuDr=$P($G(^DHCQueueStatus(QueDr,QueChangeBeforeSub)),"^",4)
            continue:QueChangeBeforeStatuDr=""
            s QueChangeBeforeStatuDesc=$list(^User.DHCPerStateD(QueChangeBeforeStatuDr),4)
        }
        //continue:QueChangeBeforeStatuDesc=""
        s QueChangeStatuDesc=$list(^User.DHCPerStateD(QueChangeStatuDr),4)
        //*if (QueChangeStatuDesc="等候")&&(QueChangeBeforeStatuDesc="报到"){
            s QueArriveDate=$P($G(^DHCQueueStatus(QueDr,QueChangeSub)),"^",1)
            s QueArriveTime=$P($G(^DHCQueueStatus(QueDr,QueChangeSub)),"^",2)
            s QueArriveTime = ..%ZD(QueArriveDate)_" "_..%ZT(QueArriveTime)
        //}
    }
 	q QueArriveTime
}
```
# CLASS
## 修改患者信息接口
DHCExternalService.RegInterface.Service.SelfRegService.cls

DHCExternalService.CardInterface.CardManager.cls

## 处方
web.DHCDocPrescript.cls

## 医嘱
web.DHCDocOrderEntry.cls

## 挂号
web.DHCOPAdmReg.cls

## 治疗记录
User.DHCDocCureRecode.cls
DHCDoc.DHCDocCure.Record.cls
盛楠医师2657
杨漫馨
/scripts/dhcdoc/dhcdoccure_hui/app.emr.cureapplist.js

## 生物标本库查询修改日志
doc.patientinfoupdate.hui.csp

## 草药代煎接受科室
opdoc.oeorder.cmlistcustom.csp
web.DHCDocOrderCommon

## 患者信息修改接口
dhcbill.ipbill.reg.csp

## 患者列表转出记录链接
d ##class(%ResultSet).RunQuery("web.DHCDocInPatientListNew", "GetChangeDeptPatList",16,18881,"currentLoc",66739,66745)

电子病历维护code null
