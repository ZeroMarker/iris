Class web.DHCOPAdmReg Extends DHCDoc.Util.RegisteredObject [ ClassType = "", ProcedureBlock ]
{

ClassMethod AdmRegFeeClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = AdmRegFeeExecute ]
{
	Set repid=$LIST(qHandle,2)
 Kill ^CacheTemp(repid)
 Quit $$$OK
}

/// 挂号查询
ClassMethod AdmRegFeeExecute(ByRef qHandle As %Binary, UserRowId As %String, PatientID As %String, StartDate As %Date, EndDate As %Date, InvoiceNo As %String) As %Status
{
	;d ##class(%ResultSet).RunQuery("web.DHCOPAdmReg","AdmRegFee","450","","","","")
	s ^zhou("AdmRegFee")=UserRowId_","_PatientID_","_StartDate_","_EndDate_","_InvoiceNo
	Set repid=$I(^CacheTemp)
	If $g(ind)="" Set ind=1
	
	//If $g(RegNo)'="" Set PAPMI=$o(^PAPERi("PAPMI_PatNo",$ZCVT(RegNo,"U"),""))
	i StartDate="" s StartDate=..%SysDate()
	;e  s StartDate=$ZDH(StartDate,4)
	i EndDate="" s EndDate=..%SysDate()
	;e  s EndDate=$ZDH(EndDate,4)
	
	if UserRowId="" {  
		Set qHandle=$lb(0,repid,0)
		Quit $$$OK
	}
	//PatientID As %String, StartDate As %Date, EndDate As %Date,  InvoiceNo As %String
	s UserName=$p($g(^SSU("SSUSR",UserRowId)),"^",2)
	if (InvoiceNo'=""){
		s INVNo=InvoiceNo
		s INVRowId=$O(^DHCINVPRT(0,"INV",InvoiceNo,0))
		i INVRowId="" {
			Set qHandle=$lb(0,repid,0)
			Quit $$$OK
		}
		s InitInvRowId=$O(^DHCINVPRT(0,"InitInvDR",INVRowId,0))
		s INVType=$P(^DHCINVPRT(INVRowId),"^",17)
		i INVType="R" d
			.s Adm=$$GetAdmByINV(INVRowId)
			.s PatRowId=$P(^PAADM(Adm),"^",1)
			.s PatName=$p(^PAPER(PatRowId,"ALL"),"^",1)
			.s PatientNo=""
			.;
			.s INVDate=$P(^DHCINVPRT(INVRowId),"^",5)
			.s INVPRTAcount=0.00
			.s INVDate=$P(^DHCINVPRT(INVRowId),"^",5)
			.s INVTime=$P(^DHCINVPRT(INVRowId),"^",20)
			.i INVDate'="" s INVDate=$zd(INVDate,3)
			.i INVTime'="" s INVTime=..%ZT(INVTime)
			.s INVDateTime=INVDate_" "_INVTime
			.s INVUser=$P(^DHCINVPRT(INVRowId),"^",21)
			.s INVUserName=$p($g(^SSU("SSUSR",INVUser)),"^",2)
			.;
			.s RefundDateTime="",RefundUserName=""
			.;s INVPRTAcount=$P(^DHCINVPRT(INVRowId),"^",1)
			.s PRTPatientShare=$p(^DHCINVPRT(INVRowId),"^",16)
			.s INVPRTAcount=PRTPatientShare
			.s Flag=$p(^DHCINVPRT(INVRowId),"^",8)
			.i ((InitInvRowId'="")&&((Flag="A")!(Flag="S"))) d
			..s RefundDate=$P(^DHCINVPRT(InitInvRowId),"^",5)
			..s RefundTime=$P(^DHCINVPRT(InitInvRowId),"^",20)
			..i RefundDate'="" d
			...s RefundDate=$zd(RefundDate,3)
			...i RefundTime'="" s RefundTime=..%ZT(RefundTime)
			...s RefundDateTime=RefundDate_" "_RefundTime
			..s RefundINVUser=$P(^DHCINVPRT(InitInvRowId),"^",21)
			..s RefundUserName=$p($g(^SSU("SSUSR",RefundINVUser)),"^",2)
			.;
			.s FlagDesc=""
			.i Flag="A" s FlagDesc="作废"
			.i Flag="S" s FlagDesc="退费"
			.i Flag="N" s FlagDesc="正常"
		
			.s HandIn=$p(^DHCINVPRT(INVRowId),"^",10)
			.i HandIn="Y" s HandInDesc=1
			.e  s HandInDesc=0
			.;
			.s Admi=Adm
			.S RegfeeRowId=$O(^User.DHCRegistrationFeeI("ADM",Admi,""))
			.Q:RegfeeRowId=""
			.s object=##class(User.DHCRegistrationFee).%OpenId(RegfeeRowId)
			.s QueueNo=object.RegfeeNo
			.s InvoiceId=object.Regfeetemp1.%Id()
			.s AdmDepRowId=object.RegfeeDepDr.%Id()
			.s AdmDocRowId=object.RegfeeDocDr.%Id()
			.s TRRowId=object.RegfeeTimeRangeDr.%Id()
			.s AdmDep="",AdmDoc=""
			.i AdmDepRowId'="" s AdmDep=$p($g(^CTLOC(AdmDepRowId)),"^",2)
			.i AdmDocRowId'="" s AdmDoc=$p($g(^CTPCP(AdmDocRowId,1)),"^",2)
			.i TRRowId'="" s TRDesc=$P(^DHCTimeRange(TRRowId),"^",2)
			.e  s TRDesc="其他"
			.s AdmDoc=AdmDoc_"("_TRDesc_")"
			.;
			.s AdmDate=$p($g(^PAADM(Adm)),"^",6)
			.s AdmDate=$zd(AdmDate,3)
			.s AdmTime=..%ZT($p($g(^PAADM(Adm)),"^",7))
		
			.;原诊
			.s RBASRowId=object.RegfeeRBASDr.%Id()
			.s StartTime=$P($G(^RBAS(+RBASRowId,$P(RBASRowId,"||",2))),"^",4)
			.;s TRRowId=##class(web.DHCRBResSession).GetTimeRangeByTime(StartTime)
			.;
			.;排班状态及调整原因
			.s RBASStatusDesc="",RBASStatusCode=""
			.s RBASStatusReason=""
			.i RBASRowId'="" d
			..s RBASStatusDr=$P(^RBAS(+RBASRowId,$P(RBASRowId,"||",2),"DHC"),"^",10)
			..s RBASStatusCode=$P(^DHCRBCASStatus(RBASStatusDr),"^",1)
			..s RBASStatusDesc=$P(^DHCRBCASStatus(RBASStatusDr),"^",2)
			..s RBASStatusReasonDr=$P(^RBAS(+RBASRowId,$P(RBASRowId,"||",2),"DHC"),"^",11)
			..i RBASStatusReasonDr'="" s RBASStatusReason=$P(^RBC("NA",RBASStatusReasonDr),"^",2)
			.;
			.;被替诊的挂号记录才能显示对应的替诊排班记录
			.s TRRBASRowId="",TRDoc=""
			.i (RBASStatusCode="TR") d
			..s TRRBASRowId=$P(^RBAS(+RBASRowId,$P(RBASRowId,"||",2),"DHC"),"^",12)
			..i (TRRBASRowId'="") d
			...s TRDocRowId= $P($G(^RB("RES",+TRRBASRowId)),"^",2)
			...s TRDoc=$p($g(^CTPCP(TRDocRowId,1)),"^",2)
			.
			.;是否预约
			.s regtype=0
			.s ret=##class(web.DHCRBAppointment).GetAppByAdm(Adm)
			.i ret'="" s regtype=1
			.Do OutputRow1
	}else{
		For PRTDate = StartDate:1:EndDate {
			s INVRowId=0  f  s INVRowId=$O(^DHCINVPRT(0,"UserDate",UserRowId,PRTDate,INVRowId)) q:INVRowId=""  d
			.s INVNo=$P(^DHCINVPRT(INVRowId),"^",14)
			.s INVType=$P(^DHCINVPRT(INVRowId),"^",17)
			.Q:INVType'="R"
			.s INVDate=$P(^DHCINVPRT(INVRowId),"^",5)
			.;
			.s Adm=$$GetAdmByINV(INVRowId)
			.Q:Adm=""
			.s Admi=Adm
			.;
			.s PatRowId=$P(^PAADM(Adm),"^",1)
			.s PatName=$p(^PAPER(PatRowId,"ALL"),"^",1)
			.;s PAPMIIPNo=$P(^PAPER(PatRowId,"PAT",1),"^",1)
			.;s PAPMIOPNo=$P(^PAPER(PatRowId,"PAT",1),"^",2)
			.;s PatientNo=$$CO2^at84(PAPMIIPNo,PAPMIOPNo)
			.s PatientNo=""
			.;
			.s INVPRTAcount=0.00
			.s RefundDateTime="",RefundUserName=""
			.;s INVPRTAcount=$P(^DHCINVPRT(INVRowId),"^",1)
			.s PRTPatientShare=$p(^DHCINVPRT(INVRowId),"^",16)
			.s INVPRTAcount=PRTPatientShare
			.s Flag=$p(^DHCINVPRT(INVRowId),"^",8)
			.s InitInvRowId=$p(^DHCINVPRT(INVRowId),"^",13)
			.;w InvoiceNo_"^"_INVNo_"^"_Flag,!
			.;Q:(INVNo'="")&&((Flag="A")!(Flag="S"))
			.;
			.s RefundDateTime="",RefundUserName=""
			.i ((InitInvRowId'="")&&((Flag="A")!(Flag="S"))) d
			..s INVNo=$P(^DHCINVPRT(InitInvRowId),"^",14)
			..s INVDate=$P(^DHCINVPRT(InitInvRowId),"^",5)
			..s INVTime=$P(^DHCINVPRT(InitInvRowId),"^",20)
			..i INVDate'="" s INVDate=$zd(INVDate,3)
			..i INVTime'="" s INVTime=..%ZT(INVTime)
			..s INVDateTime=INVDate_" "_INVTime
			..s INVUser=$P(^DHCINVPRT(InitInvRowId),"^",21)
			..s INVUserName=$p($g(^SSU("SSUSR",INVUser)),"^",2)
			..;
			..s RefundDate=$P(^DHCINVPRT(INVRowId),"^",5)
			..s RefundTime=$P(^DHCINVPRT(INVRowId),"^",20)
			..i RefundDate'="" d
			...s RefundDate=$zd(RefundDate,3)
			...i RefundTime'="" s RefundTime=..%ZT(RefundTime)
			...s RefundDateTime=RefundDate_" "_RefundTime
			..s RefundUserName=UserName
			.e  d
			..s INVDate=$P(^DHCINVPRT(INVRowId),"^",5)
			..s INVTime=$P(^DHCINVPRT(INVRowId),"^",20)
			..i INVDate'="" s INVDate=$zd(INVDate,3)
			..i INVTime'="" s INVTime=..%ZT(INVTime)
			..s INVDateTime=INVDate_" "_INVTime
			..s INVUserName=UserName
			.;
			.s FlagDesc=""
			.i Flag="A" s FlagDesc="作废"
			.i Flag="S" s FlagDesc="退费"
			.i Flag="N" s FlagDesc="正常"
		
			.s HandIn=$p(^DHCINVPRT(INVRowId),"^",10)
			.i HandIn="Y" s HandInDesc=1
			.e  s HandInDesc=0
			.;
			.S RegfeeRowId=$O(^User.DHCRegistrationFeeI("ADM",Admi,""))
			.Q:RegfeeRowId=""
			.s object=##class(User.DHCRegistrationFee).%OpenId(RegfeeRowId)
			.s QueueNo=object.RegfeeNo
			.s InvoiceId=object.Regfeetemp1.%Id()
			.s AdmDepRowId=object.RegfeeDepDr.%Id()
			.s AdmDocRowId=object.RegfeeDocDr.%Id()
			.s TRRowId=object.RegfeeTimeRangeDr.%Id()
			.s AdmDep="",AdmDoc=""
			.i AdmDepRowId'="" s AdmDep=$p($g(^CTLOC(AdmDepRowId)),"^",2)
			.i AdmDocRowId'="" s AdmDoc=$p($g(^CTPCP(AdmDocRowId,1)),"^",2)
			.i TRRowId'="" s TRDesc=$P(^DHCTimeRange(TRRowId),"^",2)
			.e  s TRDesc="其他"
			.s AdmDoc=AdmDoc_"("_TRDesc_")"
			.;
			.s AdmDate=$p($g(^PAADM(Adm)),"^",6)
			.s AdmDate=$zd(AdmDate,3)
			.s AdmTime=..%ZT($p($g(^PAADM(Adm)),"^",7))
		
			.;原诊
			.s RBASRowId=object.RegfeeRBASDr.%Id()
			.s StartTime=$P($G(^RBAS(+RBASRowId,$P(RBASRowId,"||",2))),"^",4)
			.;s TRRowId=##class(web.DHCRBResSession).GetTimeRangeByTime(StartTime)
			.;
			.;排班状态及调整原因
			.s RBASStatusDesc="",RBASStatusCode=""
			.s RBASStatusReason=""
			.i RBASRowId'="" d
			..s RBASStatusDr=$P(^RBAS(+RBASRowId,$P(RBASRowId,"||",2),"DHC"),"^",10)
			..s RBASStatusCode=$P(^DHCRBCASStatus(RBASStatusDr),"^",1)
			..s RBASStatusDesc=$P(^DHCRBCASStatus(RBASStatusDr),"^",2)
			..s RBASStatusReasonDr=$P(^RBAS(+RBASRowId,$P(RBASRowId,"||",2),"DHC"),"^",11)
			..i RBASStatusReasonDr'="" s RBASStatusReason=$P(^RBC("NA",RBASStatusReasonDr),"^",2)
			.;
			.;被替诊的挂号记录才能显示对应的替诊排班记录
			.s TRRBASRowId="",TRDoc=""
			.i (RBASStatusCode="TR") d
			..s TRRBASRowId=$P(^RBAS(+RBASRowId,$P(RBASRowId,"||",2),"DHC"),"^",12)
			..i (TRRBASRowId'="") d
			...s TRDocRowId= $P($G(^RB("RES",+TRRBASRowId)),"^",2)
			...s TRDoc=$p($g(^CTPCP(TRDocRowId,1)),"^",2)
			.
			.;是否预约
			.s regtype=0
			.s ret=##class(web.DHCRBAppointment).GetAppByAdm(Adm)
			.i ret'="" s regtype=1
			.Do OutputRow1
		}
	}
	
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK

OutputRow1
	set Data=$lb(INVNo,INVDateTime,INVTime,FlagDesc,HandInDesc,PatientNo,PatName,AdmDep,AdmDoc,AdmDate,RefundDateTime,INVPRTAcount,QueueNo,INVUserName,RefundUserName,Adm,INVRowId)
	 Set ^CacheTemp(repid,INVNo)=Data
	 Set ind=ind+1
	quit
ResetVariables1
	///set (repid)=0 ,Admdoccode,admdoc,Username,AdmTime
	set (INVNo,INVDateTime,INVTime,FlagDesc,HandInDesc,PatientNo,PatName,AdmDep,AdmDoc,AdmDate,RefundDateTime,INVPRTAcount,QueueNo,INVUserName,RefundUserName,Adm,INVRowId)=""
	quit
GetAdmByINV(INVRowId)
	s ConRowId=$O(^DHCBCI(0,"INV",INVRowId,0))
	Q:ConRowId="" ""
	s PBRowId=$P(^DHCBCI(ConRowId),"^",2) 
	Q:PBRowId="" ""
	s Adm=$P(^DHCPB(PBRowId),"^",1) 
	Q Adm
}

ClassMethod AdmRegFeeFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = AdmRegFeeExecute ]
{
 Set AtEnd=$LIST(qHandle,1)
 Set repid=$LIST(qHandle,2)
 Set ind=$LIST(qHandle,3)
	//
 Set ind=$o(^CacheTemp(repid,ind))
 If ind="" {				// if there are no more rows, finish fetching
 Set AtEnd=1
 Set Row=""
 }
 Else      {				// fetch row
 Set Row=^CacheTemp(repid,ind)
 }
 // Save QHandle
 s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// desc:判断当前安全组是否有强制退号的权限
/// Creator：倪康
/// CreatTime：2015-05-15
/// OutPut：1-有；0-无
/// w ##class(web.DHCOPAdmReg).CheckForceCancelReg(2)
ClassMethod CheckForceCancelReg(GroupRowId As %String, HospitalID As %String = "")
{
	s ForceCancelRegGroup=""
	s HospitalID=##class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospitalID)
	s flag=0
	Q:GroupRowId="" 0
	q:HospitalID="" 0
	/*s flag=$g(^DHCOPRegConfig("ForceCancelRegGroup",GroupRowId))
	i flag="Y" s flag=1
	e  s flag=0*/
	q ##class(web.DHCOPRegConfig).GetGroupConfig(HospitalID,GroupRowId,"ForceCancelRegGroup")
}

/// creator:郭荣勇
/// date:2016.6.15
/// desc:标准取消挂号接口,提供给东华内部系统使用
/// input:参考《HIS标准接口定义.doc》
/// output:参考《HIS标准接口定义.doc》
ClassMethod ICancelOPRegist(EpisodeID As %String = "", UserRowId As %String = "", GroupRowId As %String = "", LogonLocRowId As %String = "", ByRef NewInvoiceId As %String, ReturnMR As %String = "", ReturnReasonDr As %String = "") [ ProcedureBlock = 0 ]
{
	n (EpisodeID,UserRowId,GroupRowId,LogonLocRowId,NewInvoiceId,ReturnMR,ReturnReasonDr)
	Q:EpisodeID="" "-1001^未传入就诊RowId"
	s EpisodeID=EpisodeID
	S RegfeeRowId=$O(^User.DHCRegistrationFeeI("ADM",EpisodeID,""))
	Q:RegfeeRowId="" "-1002^通过就诊RowId未获取挂号表(DHCRegistrationFee)的ID"
	s Ret=..CancelOPRegist(RegFeeRowId,UserRowId,GroupRowId,LogonLocRowId,NewInvoiceId,ReturnMR,ReturnReasonDr)
	i Ret'=0{
		i Ret="invprt" {
			s Ret="-1003^存在收费发票"
		}elseif (Ret="diagnos") {
			s Ret="-1004^存在诊断"
		}elseif (Ret="cancel") {
			s Ret="-1005^已经退号"
		}elseif (Ret="overtime") {
			s Ret="-1006^已过时段设定退号时间"
		}elseif (Ret="-200") {
			s Ret="-1007^调用退费接口失败"
		}elseif (Ret="-204") {
			s Ret="-1008^更新挂号表失败"
		}else{
			s Ret=Ret_"^退号失败,失败代码:"_Ret
		}
	}else{
		s Ret=Ret_"^OK"
	}
	
	Q Ret
}

/// Desc:得到挂号支付时自费的支付方式
/// w ##class(web.DHCOPAdmReg).GetSelfPayMode(5614)
ClassMethod GetSelfPayMode(InvoiceId)
{
	s PayMode=""
	s InvPayModeID=""
	for{
		s InvPayModeID=$O(^DHCINVPRT(InvoiceId,"P",InvPayModeID),-1)
		Q:(InvPayModeID="")!(PayMode'="")
		s SelfPayFlag=$p(^DHCINVPRT(InvoiceId,"P",InvPayModeID),"^",12)
		continue:SelfPayFlag'="1"
		s PayMode=$p(^DHCINVPRT(InvoiceId,"P",InvPayModeID),"^",1)
	}
	if PayMode=""{
		;计费反馈无需默认现金，若无自费方式传空即可
		;s PayModeCode="CASH"
		;s PayMode=$o(^CT("CTPM",0,"Code",PayModeCode,0))
	}
	Q PayMode
}

/// 退号
ClassMethod CancelOPRegist(RegFeeRowId As %String = "", UserRowId As %String = "", GroupRowId As %String = "", LogonLocRowId As %String = "", ByRef NewInvoiceId As %String, ReturnMR As %String = "", ReturnReasonDr As %String = "", HospitalID As %String = "", PayMode As %String = "") [ ProcedureBlock = 0 ]
{
	n (RegFeeRowId,UserRowId,GroupRowId,LogonLocRowId,NewInvoiceId,ReturnMR,ReturnReasonDr,%session,HospitalID,PayMode)
	s:RegFeeRowId=5856 ^zhou("Cancel")=$lb(RegFeeRowId,UserRowId,GroupRowId,LogonLocRowId,NewInvoiceId,ReturnMR,ReturnReasonDr,HospitalID,PayMode)
	s ReturnReason=$p(ReturnReasonDr,"^",2)
	s ReturnReasonDr=$p(ReturnReasonDr,"^",1)
	;w ##class(web.DHCOPAdmReg).CancelOPRegist(2048,7,119,238,"","N","",2)
	s HospitalID=##class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospitalID)
	s ForceCancelRegFlag=..CheckForceCancelReg(GroupRowId,HospitalID)
	s ForceFlag=0
	s kid=""	
	s no=""
	s ReCode=""
	//cjb+ 存在非挂号有效医嘱时 不允许退费
	/*s mm=""
	s mm=$o(^OEORD(0,"Adm",adm,mm))
	if mm'="" d
	.s oeordcld="" f  s oeordcld=$o(^OEORD(mm,"I",oeordcld)) q:oeordcld=""  d
	..q:(oeordcld=0)
	..s paorderrow=mm_"||"_oeordcld
	..s arcimdr=$p(^OEORD(mm,"I",oeordcld,1),"^",2)
	..s subscript=$p(arcimdr,"||",1)
	..s Version=$p(arcimdr,"||",2)
	..s itemCat=$p(^ARCIM(subscript,Version,1),"^",10) 
	..s OrdCat=$p(^ARC("IC",itemCat),"^",8)
	..q:OrdCat="20"   //不判断挂号费医嘱
	..s oestatus=$p(^OEORD(mm,"I",oeordcld,1),"^",13)
	..q:((oestatus'="1")&&(oestatus'="6"))  //非核实或执行的医嘱不判断
	..s kid=+kid+1
	.if kid'="" d 
	.. set ReCode="orditem"
	..s retval=itmjs_"('"_$ZCVT(ReCode,"O","JS")_"');"
	..i itmjsex'="""" s retval=retval_itmjsex_"('"_$ZCVT(ReCode,"O","JS")_"');"
	..&javascript<#(retval)#>
	q:kid'="" 1 
	*/
 	Set $ZT="ERROR^DHCSSERR"
	&SQL(Select RegfeeAdmDr,RegfeeNo,RegfeeDoFlag,RegfeeRBASDr,Regfeetemp1,RegfeeDate,RegfeeTimeRangeDr,RegfeeDepDr
	   into :adm,:QueueNo,:doflag,:RBASRowId,:InvoiceId,:RegfeeDate,:RegfeeTimeRangeDr,:AdmDep
	   from SQLUser.DHCRegistrationFee 
	  Where %Id=:RegFeeRowId)
	;有收费发票的就诊记录不允许退号
	if 0 {
		S vFlag=$$getPrtFairType(adm)
		if (vFlag="Y") s ForceFlag=1
		q:(vFlag="Y")&&(ForceCancelRegFlag'=1) "invprt" 
	} 
	s LogHospID=$P(^CTLOC(LogonLocRowId),"^",22)
	s AdmLocID=$P($g(^PAADM(adm)),"^",4)
	s AdmLocHosp=$P(^CTLOC(AdmLocID),"^",22)
	q:AdmLocHosp'=LogHospID "NotSameHosp"

	;查找是否存在诊断
	s mradm=##Class(web.DHCPAADM).GetMRAdmID(adm)
	s Childsub=0 f  s Childsub=$o(^MR(mradm,"DIA",Childsub)) q:Childsub=""  d
	.s AddDiagnoseWay=$p($g(^MR(mradm,"DIA",Childsub,1)),"^",27)
	.q:AddDiagnoseWay="O"
	.s DiagActive=$p($g(^MR(mradm,"DIA",Childsub)),"^",34)
	.q:DiagActive'="Y"
	.s kid=mradm_"||"_Childsub
	if (kid'="") s ForceFlag=1
	q:(kid'="")&&(ForceCancelRegFlag'=1) "diagnos"
	
	if adm'="" {
		s AdmStatus=$P($g(^PAADM(adm)),"^",20)
		if AdmStatus="C" Q "cancel"
	}
	
	;判断是否在应急系统中有当天同科室无挂号费就诊记录
	s CheckBeforeCancelRegRet=##class(DHCDoc.Interface.StandAlone.Service).CheckBeforeCancelReg(adm)
	q:+CheckBeforeCancelRegRet<0 $p(CheckBeforeCancelRegRet,"^",2)

	s AdmType=$P($G(^PAADM(adm)),"^",2)
 	;替诊
	s CurrentDate=..%SysDate(),CurrentTime=..%SysTime()
	s APPTRowIdStr=""
	s TRRBASStatusCode="",AppOrderItem="",NewPay=0,ASDate=0
	if ((RBASRowId'="")&&($G(^RBAS(+RBASRowId,$P(RBASRowId,"||",2)))'="")) {
	 	s ResRowId=+RBASRowId
	 	s ASChildSub=$P(RBASRowId,"||",2)
		s ASDate=$P($G(^RBAS(ResRowId,ASChildSub)),"^",1)
	 	s TRRBASStatusDr=$P(^RBAS(ResRowId,ASChildSub,"DHC"),"^",10)
	 	s TRRBASStatusCode=$P(^DHCRBCASStatus(TRRBASStatusDr),"^",1)
	 	i (TRRBASStatusCode="N")!(TRRBASStatusCode="TR")!(TRRBASStatusCode="A")!(TRRBASStatusCode="AR") {
			s StartTime=$P($G(^RBAS(ResRowId,ASChildSub)),"^",4)
			s CancelTimePoint=CurrentTime,AllowSpaceReturnDay=""
			;根据时段设置里的时间点设置是否能够退号
			s DocDr= $P($G(^RB("RES",ResRowId)),"^",2)
			s DocDesc=$p($g(^CTPCP(DocDr,1)),"^",2)
			i DocDesc'[("便民") {
				;s TRRowId=##class(web.DHCRBResSession).GetTimeRangeByTime(StartTime)
				s TRRowId=RegfeeTimeRangeDr
				i TRRowId'="" {
					s CancelTimePoint=$P(^DHCTimeRange(TRRowId),"^",6)
					s AllowSpaceReturnDay=$P($g(^DHCTimeRange(TRRowId)),"^",11)
				}
				;如果为急诊号或者没有设置退号时间则全天可退       add by zhouzq 2009.11.02
				s EPMark=##class(web.DHCRBResource).GetEPMarkFlag(ResRowId)
				if (EPMark=1)||(CancelTimePoint="") s CancelTimePoint=85500 
				i (((CancelTimePoint<CurrentTime)&(ASDate=CurrentDate))!(((ASDate<(CurrentDate-(+AllowSpaceReturnDay)))!(AllowSpaceReturnDay=""))&(ASDate<CurrentDate))){ //&(AdmType="O")
					s ForceFlag=1
				}
				i (((CancelTimePoint<CurrentTime)&(ASDate=CurrentDate))!(((ASDate<(CurrentDate-(+AllowSpaceReturnDay)))!(AllowSpaceReturnDay=""))&(ASDate<CurrentDate)))&&(ForceCancelRegFlag'=1) { //&(AdmType="O")
					Q "overtime"
			 	}else{
					s APPTRowIdStr=##class(web.DHCRBAppointment).GetAppByAdm(adm)
					i APPTRowIdStr'="" {
						s AdmDate=$P(^PAADM(adm),"^",6)
				
						;如果预约当天就退号,则全退,否则不退预约费
						if AdmDate=CurrentDate {
							s StopItem=..GetRegINVOrderItem(InvoiceId,"App",1)
							s NewPay=..GetRegINVAppFee(InvoiceId,"App",0)
							i NewPay=0 s AppOrderItem=""
						}
					}	
			 	}
		 	}

	 	}
	}
	s OPReturnReason=##class(web.DHCOPRegConfig).GetSpecConfigNodeHosp("OPReturnReason",HospitalID)
	if ((ForceFlag=1)&&(ForceCancelRegFlag=1)&&(ReturnReasonDr="")&&(OPReturnReason=1)){
		q "NeedReason"
	}
	if (ReturnMR="Y"){
		s NewPay=..GetRegINVAppFee(InvoiceId,"App^Card",0)
		s StopItem=..GetRegINVOrderItem(InvoiceId,"App^Card",1)
	}else{
		s NewPay=..GetRegINVAppFee(InvoiceId,"App^MR^Card",0)
		s StopItem=..GetRegINVOrderItem(InvoiceId,"App^MR^Card",1)
	}
        ;生成负帐单
	TStart
	s NewInvoiceId="",APIFlag="N"
	;费用为0不会有发票,退费也就不需处理
	if InvoiceId'="" {
		s RefundStatusCode=..GetINVRefundStatus(InvoiceId,UserRowId)
		if (RefundStatusCode'="") {
			s Paymode=""
			if (PayMode=""){
				;计费需要传自费的支付方式,否则退费时的发票支付方式错误
				s Paymode=..GetSelfPayMode(InvoiceId)
				if Paymode=""{
					;s InvPayModeID=$O(^DHCINVPRT(InvoiceId,"P",""),-1)
					;s:InvPayModeID'="" Paymode=$p(^DHCINVPRT(InvoiceId,"P",InvPayModeID),"^")
				}
			}else{
				s Paymode=PayMode
			}
			;s APPMethodCode=##class(web.DHCRBAppointment).GetAPPMethodCodeByAdm(adm)
			;i APPMethodCode="TEL" d
			;ACCPINVDR为集中打印发票表关联指针
			S ACCPINVDR=$P($G(^DHCINVPRT(InvoiceId)),"^",4)
			;S AccPayCount=$P($G(^DHCINVPRT(InvoiceId)),"^",1)
			S PRTPatientShare=$P($G(^DHCINVPRT(InvoiceId)),"^",16)
			s AccPayCount=PRTPatientShare
			i NewPay=0 {
				s RebillFlag=0
				;s Refoundcode=##class(web.udhcOPRefEditIF).RefundReceipt(InvoiceId, UserRowId, RefundStatusCode, "", 0, GroupRowId,RebillFlag,LogonLocRowId,Paymode)
				If ACCPINVDR'="" {
					//s PRTOrdStr=..GetINVPRTOrdStr(InvoiceId)
					s PRTOrdStr=InvoiceId_$c(3)_StopItem_$c(3)_RebillFlag_$c(3)_AccPayCount
					s Refoundcode=##class(web.udhcOPRefEditIF).AccPayINVRefund(ACCPINVDR, PRTOrdStr,UserRowId, RefundStatusCode, GroupRowId, LogonLocRowId,Paymode,AccPayCount,RebillFlag,"")
				}Else{
					s Refoundcode=##class(web.udhcOPRefEditIF).RefundReceipt(InvoiceId, UserRowId, RefundStatusCode, StopItem, 0, GroupRowId,RebillFlag,LogonLocRowId,Paymode)
				}
			}else{
				s RebillFlag=1
				;s Refoundcode=##class(web.udhcOPRefEditIF).RefundReceipt(InvoiceId, UserRowId, RefundStatusCode, StopItem, NewPay, GroupRowId,RebillFlag,LogonLocRowId,Paymode)
				If ACCPINVDR'="" {
					s AccPayCount=AccPayCount-NewPay
					//s PRTOrdStr=..GetINVPRTOrdStr(InvoiceId)
					s PRTOrdStr=InvoiceId_$c(3)_StopItem_$c(3)_RebillFlag_$c(3)_AccPayCount
					s Refoundcode=##class(web.udhcOPRefEditIF).AccPayINVRefund(ACCPINVDR, PRTOrdStr,UserRowId, RefundStatusCode, GroupRowId, LogonLocRowId,Paymode,AccPayCount,RebillFlag,"")
				}Else{
					s Refoundcode=##class(web.udhcOPRefEditIF).RefundReceipt(InvoiceId, UserRowId, RefundStatusCode, StopItem, NewPay, GroupRowId,RebillFlag,LogonLocRowId,Paymode)
				}
			}
			;Refoundcode
			if ACCPINVDR'=""{				
				s ret=$P(Refoundcode,"^",1)  ;$c(2),1)	;计费组跟普通发票退费保持统一了
			}else {
				s ret=$P(Refoundcode,"^",1)
				
				s myPRTRowID=$P(Refoundcode,"^",2)
				s strikePrtRowID=$P(Refoundcode,"^",3)
				i (+myPRTRowID'=0) {
					//确认完成
					s AdmReasonId=$p($g(^DHCINVPRT(myPRTRowID)),"^",9)   //$P(^PAADM(adm,1),"^",7)
					s RequirINVFlag="Y"
					s FairType="R"
					s AccRowId=""
					s BillAccount=GroupRowId_"^"_AdmDep_"^"_AccRowId_"^"_RequirINVFlag_"^"_FairType
					
					//Modify 20200528 Lid 确认完成接口增加支付方式列表		
					s payList=##class(web.DHCBillConsIF).GetNewInvPayMList(InvoiceId,strikePrtRowID,myPRTRowID,"")
					s err=##class(web.DHCBillConsIF).CompleteCharge("0",UserRowId,AdmReasonId,myPRTRowID,"1",strikePrtRowID,BillAccount,payList)
					i +err'=0{
						TRollback
						s ^zhou("error","CompleteCharge")=err_",InvoiceRowid="_myPRTRowID	
						Q "-210"
					}
					//结束
				}
				s NewInvoiceId=$P(Refoundcode,"^",2)
			}
			i ret'=0 {
				TRollback
				s ^tmpgry("RefundReceipt")=ACCPINVDR_","_Refoundcode
				Q "-200"
			}
			i ACCPINVDR'="" d
			.s NewInvoiceId=$p(Refoundcode,$c(2),2)
			.s NewInvoiceId=$p(NewInvoiceId,"^",1)
			.;根据集中打印发票(dhc_accpayinv)rowid取小条表（dhc_invprt）rowid，保证DHCRegistrationFee的数据意义一致，防止统计组程序报错
			.;前提默认集中打印发票表与小条表1:1
			.if NewInvoiceId'="" d
			..s apiConPrtDr=$o(^DHCINVPRTCAPi(0,"APINVDR",NewInvoiceId,"0"))
			..i apiConPrtDr'="" s NewInvoiceId=$p(^DHCINVPRTCAP(apiConPrtDr),"^",1)
			.s APIFlag="Y"
			e  d
			.s NewInvoiceId=$P(Refoundcode,"^",2)
			.s APIFlag="N"
		}
		
		if NewInvoiceId'="" {
			&SQL(Update SQLUser.DHCRegistrationFee Set Regfeetemp1=:NewInvoiceId Where %Id=:RegFeeRowId)
			if SQLCODE {
				TRollback
				Q "-204"
			}
		}
	}else{
		Set FreeOrder=$p(##class(web.DHCOPRegConfig).GetSpecConfigNode("FreeOrder",HospitalID),"@",1)
		if (FreeOrder'="") s FreeOrder="^"_FreeOrder_"^"
		s RegLinkOrdListStr=""
		Set OEORDRowId=$o(^OEORD(0,"Adm",adm,""))
		if (OEORDRowId'="") {
			s RegSerBillSubTypeStr="^MR^Card^Reg^Check^ReCheck^App^Holi^Other^"
			s OEORIChildsub=0
			for {
				s OEORIChildsub=$o(^OEORD(OEORDRowId,"I",OEORIChildsub)) q:OEORIChildsub=""
				s ARCIMRowId=$p($g(^OEORD(OEORDRowId,"I",OEORIChildsub,1)),"^",2)
				continue:ARCIMRowId=""
				s TOrderStatusDR=$p(^OEORD(OEORDRowId,"I",OEORIChildsub,1),"^",13)
				s:+TOrderStatusDR>0 orderStatCode = $p(^OEC("OSTAT",TOrderStatusDR),"^",1)
				continue:(orderStatCode'="V")&&(orderStatCode'="E")
				s ARCIMServiceGroupDR=$p($g(^ARCIM(+ARCIMRowId,$p(ARCIMRowId,"||",2),8)),"^",7)
				continue:(ARCIMServiceGroupDR'=##class(web.DHCOPRegConfig).GetSpecConfigNode("RegServiceGroup",HospitalID)) //如果医嘱项服务组不是挂号设置-》挂号服务组，则退出
				s RegSerBillSubType=..GetRegArcimBillSubType(ARCIMRowId,HospitalID)
				s tmpRegSerBillSubType="^"_RegSerBillSubType_"^"
				i ((RegSerBillSubTypeStr[tmpRegSerBillSubType)&&(RegSerBillSubType'=""))||(FreeOrder[("^"_ARCIMRowId_"^")) {
					i RegLinkOrdListStr="" s RegLinkOrdListStr=OEORDRowId_"||"_OEORIChildsub
					e  s RegLinkOrdListStr=RegLinkOrdListStr_"^"_OEORDRowId_"||"_OEORIChildsub
				}
			}
		}
		if (RegLinkOrdListStr'="") {
			s err=##class(web.UDHCStopOrderLook).StopOrder("","",RegLinkOrdListStr,UserRowId,"","N")
			if (err'=0) {
				TRollback
				Q "-2041"
			}
		}
		
	}
		
	s vis="C",read="Y",admdate=..%SysDate(),admtime=..%SysTime()
	s UserName=""
	i UserRowId'="" s UserName=$p($g(^SSU("SSUSR",UserRowId)),"^",2)  
	b ;更新就诊表的状态
	&sql(update SQLUser.PA_Adm
		 Set PAADM_VisitStatus=:vis,	PAADM_ReadOnly=:read,
			 PAADM_UpDateDate=:admdate,	PAADM_UpDateTime=:admtime,
			 PAADM_SocialWorkerName=:UserRowId,PAADM_UpdateUser_DR=:UserRowId
		where PAADM_RowID=:adm)
	if SQLCODE {
		TRollback
		Q "-201"
	}
	;回退到可用号中
	Set StatusCode="Return"
	if ($G(^RBAS(+RBASRowId,$P(RBASRowId,"||",2)))'=""){
		if (APPTRowIdStr'=""){
			;取消预约(包括了回退号的处理)
			s APPTRowId=$P(APPTRowIdStr,"^",1)
			s err=##class(web.DHCRBAppointment).AppCancel(APPTRowId,UserRowId,StatusCode,HospitalID)
			if err {
				TRollback
				Q "-210"
			}
		}else{
			;Do ##class(web.DHCRBAppointment).RestoreSeqNo(RBASRowId, QueueNo, StatusCode,"",HospitalID)
			Do ##class(web.DHCRBAppointment).AppCancelRestoreSeqNo(RBASRowId, QueueNo, "Return",HospitalID,"")
		}
	}
	;在分诊队列中将标志改为退号
	&sql(select ID into :PersDr from SQLUser.DHCPerState where PersName='退号')
	&sql(select ID into :QueID from  SQLUser.DHCQueue where QuePaadmDr=:adm)
	if SQLCODE=0 {
		&sql(update SQLUser.DHCQueue set QueStateDr=:PersDr where QuePaadmDr=:adm )
		if SQLCODE {
			TRollback
			Q "-202"
		}
	}
	;更新退号原因
	if (ReturnReasonDr'=""){
		&sql(
			update SQLUser.PA_AdmExt
		 	Set PAADM_OPReturnReason_DR=:ReturnReasonDr, PAADM_OPReturnReason=:ReturnReason
			where PAADM_RowId=:adm
		)
		if SQLCODE {
			TRollback
			Q "-201"
		}
	}
	;分时段产生序列号，退号的时候需要回归
	s rtn= ##Class(web.DHCDocOutPatientList).CancleCreatNewQueueNo(adm)
	if rtn'=0 {
			TRollback
			Q "-215"
		}
	TCommit
	s CFIFScreenStart=##class(web.DHCOPRegConfig).GetSpecConfigNode("IFScreenStart",HospitalID)
	if (CFIFScreenStart=1)&&(ASDate=..%SysDate()){
		if ($G(^RBAS(+RBASRowId,$P(RBASRowId,"||",2)))'=""){
			s FullFlag=##class(web.DHCRBApptSchedule).CheckScheduleFull(RBASRowId)
			s err=##class(dhcinterface.DoctorApptScheClient).SetScreenDisplayMsg(RBASRowId,FullFlag)
		}
	}
	;调用平台组接口
	s rtn=##class(web.DHCENS.EnsHISService).DHCHisInterface("SENDOPRREGINFO",adm)
	Q 0_"^"_APIFlag
 //判断病人有无收费发票，如果有收费发票，则病人不能退号
getPrtFairType(adm)
   s Flag="N"
   s dhcbirowid=""
   f  s dhcbirowid=$o(^DHCBCI(0,"ADM",adm,dhcbirowid)) q:dhcbirowid=""  d
   .s invprtid=$p(^DHCBCI(dhcbirowid),"^",1)
   .s prtfairtype=$P($g(^DHCINVPRT(invprtid)),"^",34)
   .s prtflag=$P($g(^DHCINVPRT(invprtid)),"^",8)
   .i prtfairtype="F"  S Flag="Y"
   q Flag
}

ClassMethod CheckCancelOPRegist(adm, GroupRowId As %String = "", HospRowId As %String = "") As %String
{
	if (GroupRowId="")&&($d(%session)) s GroupRowId=%session.Get("LOGON.GROUPID")
	s rtn=""
	s find=0
	s ForceCancelRegFlag=..CheckForceCancelReg(GroupRowId,HospRowId)
	Q:ForceCancelRegFlag=1 ""
	;退号如果没有打印发票，则需要先打印发票
	s rtn=..CheckforCanclePrint(adm,HospRowId)
	Q:rtn'="" "1^"_rtn
	;调用新产品组接口判断就诊对应的MDT会诊是否已撤销
	s rtn=##Class(web.DHCMDTInterface).GetCsRevFlagByAdm(adm)
	Q:rtn=0 "1^不可退号,MDT会诊申请未撤销!"
	s kid=""
	
	;急诊留观患者没有下诊断或者开医嘱的也不允许退号
	s StayStatus=##class(web.DHCADMVisitStat).GetStayStatus(adm)
	i StayStatus="1" d
	.s find=1
	.s rtn="1^不可退号，急诊留观不允许退号"
	Q:find="1" rtn
	
	b ;查找是否存在诊断
	s find=..CheckAdmDiagnos(adm)
	if (find="1") {
		Q "1^不可退号，需要删除诊断"
	}
	s rtn=##class(web.DHCDocIPBookNew).checkIsExistBook(adm)
	Q:rtn'="" rtn
	
	s OrderRowId=$o(^OEORD(0,"Adm",adm,""))
	s PatientID=$P(^PAADM(adm),"^",1)
	s RegFeeID=$O(^User.DHCRegistrationFeeI("ADM",adm,0))
	s RegFeeRBASDr="",RegfeeTimeRangeDr=""
	if RegFeeID'="" {
		s RegFeeRBASDr=$List(^User.DHCRegistrationFeeD(RegFeeID),18)
		s RegfeeTimeRangeDr=$List(^User.DHCRegistrationFeeD(RegFeeID),21)
	}
	Q:OrderRowId="" ""
	;判断是否过了退号时间
	if ((RegFeeRBASDr'="")&&($G(^RBAS(+RegFeeRBASDr,$p(RegFeeRBASDr,"||",2)))'="")){
		s AdmType=$P($G(^PAADM(adm)),"^",2)
		s ASDate=$P($G(^RBAS(+RegFeeRBASDr,$p(RegFeeRBASDr,"||",2))),"^",1)
		s CurrentDate=..%SysDate(),CurrentTime=..%SysTime()
		s CancelTimePoint=CurrentTime,AllowSpaceReturnDay=""
		;根据时段设置里的时间点设置是否能够退号
		s DocDr= $P($G(^RB("RES",+RegFeeRBASDr)),"^",2)
		s DocDesc=$p($g(^CTPCP(DocDr,1)),"^",2)
		i DocDesc'[("便民") {
			s TRRowId=RegfeeTimeRangeDr
			i TRRowId'="" {
				s CancelTimePoint=$P(^DHCTimeRange(TRRowId),"^",6)
				s AllowSpaceReturnDay=$P($g(^DHCTimeRange(TRRowId)),"^",11)
			}
			;如果为急诊号或者没有设置退号时间则全天可退       add by zhouzq 2009.11.02
			s EPMark=##class(web.DHCRBResource).GetEPMarkFlag(+RegFeeRBASDr)
			if (EPMark=1)||(CancelTimePoint="") s CancelTimePoint=85500 
			i (((CancelTimePoint<CurrentTime)&(ASDate=CurrentDate))!(((ASDate<(CurrentDate-(+AllowSpaceReturnDay)))!(AllowSpaceReturnDay=""))&(ASDate<CurrentDate)))&&(ForceCancelRegFlag'=1) { //&(AdmType="O")
				Q "1^已经过了退号时间"
		 	}
		}
	}
	;判断是否有否除了挂号以外产生的医嘱  add by zhouzq 2010.09.09
	s find=..CheckAdmOrdItem(adm,HospRowId)
	Q:find="1" "1^不可退号，需要停医嘱"
	;获取安全组可用挂号支付方式串
	s RegPayModeStr=""
	s AdmHospitalId=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(adm)
	if HospRowId="" s HospRowId=AdmHospitalId
	s rset=##class(%ResultSet).%New("web.UDHCOPGSConfig:ReadGSINSPMList")
	do rset.Execute(GroupRowId,HospRowId,"REF")
	s columns = rset.GetColumnCount()
	s row=0
	While (rset.Next()) {
		s CTPMRowID=rset.GetData(1)
		continue:(CTPMRowID="")
		if (RegPayModeStr="") s RegPayModeStr=CTPMRowID
		e  s RegPayModeStr=RegPayModeStr_"^"_CTPMRowID
	}
	s InvoiceId=$List(^User.DHCRegistrationFeeD(RegFeeID),11)
	if (InvoiceId'="")&&($d(^DHCINVPRT(InvoiceId))) {
		s Paymode=""
		s InvPayModeID=$O(^DHCINVPRT(InvoiceId,"P",0))
		s:InvPayModeID'="" Paymode=$p(^DHCINVPRT(InvoiceId,"P",InvPayModeID),"^")
		if (Paymode'="") {
			Q:("^"_RegPayModeStr_"^")'[("^"_Paymode_"^") "1^不可退号，该安全组无 "_$P($g(^CT("CTPM",Paymode)),"^",2)_"退号权限！"
		}
	}
	Q ""
}

/// w ##class(web.DHCOPAdmReg).CheckAdmDiagnos(2118,119)
ClassMethod CheckAdmDiagnos(adm) As %String
{
	s findDiag=0
	s mradm=##Class(web.DHCPAADM).GetMRAdmID(adm)
	s Childsub=0 f  s Childsub=$o(^MR(mradm,"DIA",Childsub)) q:((Childsub="")!(findDiag=1))  d
	.s ActiveFlag=$p($g(^MR(mradm,"DIA",Childsub)),"^",34)
	.q:ActiveFlag'="Y"
	.s AddDiagnoseWay=$p($g(^MR(mradm,"DIA",Childsub,1)),"^",27)
	.q:AddDiagnoseWay="O"
	.s kid=mradm_"||"_Childsub
	.s findDiag=1
	Q findDiag
}

ClassMethod CheckAdmOrdItem(adm, HospRowId As %String = "") As %String
{
	s findOrd=0
	s OrderRowId=$o(^OEORD(0,"Adm",adm,""))
	Q:OrderRowId="" findOrd
	s PatientID=$P(^PAADM(adm),"^",1)
	;判断是否有否除了挂号以外产生的医嘱  add by zhouzq 2010.09.09
	s RegFeeID=$O(^User.DHCRegistrationFeeI("ADM",adm,0))
	if RegFeeID'="" {
		s RegFeeRBASDr=$List(^User.DHCRegistrationFeeD(RegFeeID),18)
	}
	s FreeOrder=$p(##class(web.DHCOPRegConfig).GetSpecConfigNode("FreeOrder",HospRowId),"@",1)
	s InvoiceId=$List(^User.DHCRegistrationFeeD(RegFeeID),11)
 	s INVOrderItems=..GetRegINVOrderItem(InvoiceId,"",1)
 	s AdmReason=$P(^PAADM(adm,1),"^",7)
	s OrderChild=0
	f  s OrderChild=$O(^OEORD(OrderRowId,"I",OrderChild)) q:((OrderChild="")!(findOrd="1"))  d
	.s oeflag=$p(^OEC("OSTAT",$p(^OEORD(OrderRowId,"I",OrderChild,1),"^",13)),"^",1)
	.Q:("^"_INVOrderItems_"^")[("^"_OrderRowId_"||"_OrderChild_"^")
	.s Arcimid=$p($g(^OEORD(OrderRowId,"I",OrderChild,1)),"^",2) 
	.s SerIdStr=..GetScheduleService(RegFeeRBASDr,AdmReason)
	.s DepRefArcimStr=..GetCustomScheduleService(PatientID,RegFeeRBASDr,SerIdStr)
	.s MRFeeArcimId=..GetMRFeeArcimId()
	.q:("^"_MRFeeArcimId_"^")[("^"_Arcimid_"^")
	.q:("^"_DepRefArcimStr_"^")[("^"_Arcimid_"^")
	.q:("^"_FreeOrder_"^")[("^"_Arcimid_"^")
	.s BindSource=$P($G(^OEORD(OrderRowId,"I",OrderChild,"DHC")),"^",41)
	.q:BindSource'=""
	.i (oeflag'="D")&&(oeflag'="U")&&(oeflag'="C")  d
	..s findOrd=1
	Q findOrd
}

/// w ##class(web.DHCOPAdmReg).CancelOPRegistBroker("","",210,639,90,131)
ClassMethod CancelOPRegistBroker(itmjs As %String = "", itmjsex As %String = "", RegFeeRowId As %Library.String = "", UserRowId As %Library.String, GroupRowId As %String, LogonLocRowId As %String, ReturnMR As %String = "", ReturnReasonDr As %String = "", PayMode As %String = "")
{
	s NewInvoiceId=""
	s ret=..CancelOPRegist(RegFeeRowId,UserRowId,GroupRowId,LogonLocRowId,.NewInvoiceId,ReturnMR,ReturnReasonDr,"",PayMode)
	s APIFlag=$p(ret,"^",2)
	s ret=$p(ret,"^",1)
	;s retval=itmjs_"('"_$ZCVT(ret,"O","JS")_"');"
	s ^zhou("NewInvoiceId")=NewInvoiceId
	s PrintData=""
	;i (ret="0")&(NewInvoiceId'="") s PrintData=..GetPrintData(RegFeeRowId,1)
	i (ret="0")&(NewInvoiceId'="") s PrintData=..GetPrintData(RegFeeRowId)
	s ret=ret_"$"_PrintData_"$"_APIFlag
	Q ret
}

/// 换号
ClassMethod ChangeOPRegist(RegFeeRowId As %String, NewRBASRowId As %String, UserRowId As %String = "", GroupRowId As %String = "", LogonLocRowId As %String = "", ByRef NewRegfeeRowId As %String) [ ProcedureBlock = 0 ]
{
	n (RegFeeRowId,NewRBASRowId,UserRowId,GroupRowId,LogonLocRowId,NewRegfeeRowId)
	s ^zhou("change")=RegFeeRowId_","_NewRBASRowId_","_UserRowId_","_GroupRowId_","_LogonLocRowId
	;Set $ZT="ERROR^DHCSSERR"
	
	&SQL(Select RegfeeAdmDr,RegfeeNo,RegfeeDoFlag,RegfeeRBASDr,Regfeetemp1,RegfeeTimeRangeDr
	   into :adm,:QueueNo,:doflag,:RBASRowId,:InvoiceId,:RegfeeTimeRangeDr
	   from SQLUser.DHCRegistrationFee 
	  Where %Id=:RegFeeRowId)
	  
	b ;查找是否存在诊断
	s kid=""
	s mm=0 f  s mm=$o(^MRi("MRADMDR",adm,mm)) q:mm=""  d
	.s Childsub=0
	.f  s Childsub=$o(^MR(mm,"DIA",Childsub)) q:Childsub=""  d
	..s kid=mm_"||"_Childsub
	//&sql(select mrdia_rowid  into :kid from SQLUser.mr_diagnos  where mrdia_mradm_parref=:mm)
	
	q:kid'="" "diagnos"
	
	TStart
	;Q:InvoiceId="" "Invoice"

	b ;生成负帐单
	s RefundStatusCode=..GetINVRefundStatus(InvoiceId,UserRowId)
	if (RefundStatusCode'="") {
		;s Paymode=$p(^DHCINVPRT(InvoiceId,"P",1),"^")
		s Paymode=""
		s InvPayModeID=$O(^DHCINVPRT(InvoiceId,"P",0))
		s:InvPayModeID'="" Paymode=$p(^DHCINVPRT(InvoiceId,"P",InvPayModeID),"^")
		
		;s APPMethodCode=##class(web.DHCRBAppointment).GetAPPMethodCodeByAdm(adm)
		;i APPMethodCode="TEL" d
		s Refoundcode=##class(web.udhcOPRefEditIF).RefundReceipt(InvoiceId, UserRowId,RefundStatusCode, "", 0, GroupRowId,0,LogonLocRowId,Paymode)
		i Refoundcode'=0 {
			TRollback
			Q:"-300"
		}
	}
	
	s vis="C",read="Y",admdate=..%SysDate(),admtime=..%SysTime()
	s UserName=""
	i UserRowId'="" s UserName=$p($g(^SSU("SSUSR",UserRowId)),"^",2)  
	b ;更新就诊表的状态
	&sql(update SQLUser.PA_Adm
		 Set PAADM_VisitStatus=:vis,	PAADM_ReadOnly=:read,
			 PAADM_UpDateDate=:admdate,	PAADM_UpDateTime=:admtime,
			 PAADM_SocialWorkerName=:UserRowId
		where PAADM_RowID=:adm)
	if SQLCODE {
		TRollback
		Q "-301"
	}
	
	b ;在分诊队列中?将标志改为?退号?
	&sql(select ID into :PersDr from SQLUser.DHCPerState where PersName='退号')
	&sql(update SQLUser.DHCQueue set QueStateDr=:PersDr where QuePaadmDr=:adm )
	if SQLCODE {
		TRollback
		Q "-302"
	}

	;插入就诊记录
	s PatientID=$P(^PAADM(adm),"^",1)
	s AdmType=$P(^PAADM(adm),"^",2)
	s AdmDate=$P(^PAADM(adm),"^",6)
	s AdmTime=$P(^PAADM(adm),"^",7)
	s AdmReason=$P(^PAADM(adm,1),"^",7)
	s Name=$p($g(^PAPER(PatientID,"ALL")),"^",1)
	s PatientNo=$p($g(^PAPER(PatientID,"PAT",1)),"^",1)
	
	s ResRowId=$P(NewRBASRowId,"||",1)
	s ASChild=$P(NewRBASRowId,"||",2)
	
	s AdmDep=$P($G(^RB("RES",ResRowId)),"^",1)
	s AdmDoc=$P($G(^RB("RES",ResRowId)),"^",2)
	s ASDate=$P($G(^RBAS(ResRowId,ASChild)),"^",1) 
	s ASStartTime=$P($G(^RBAS(ResRowId,ASChild)),"^",4) 
	s RoomDr=$P($G(^RBAS(ResRowId,ASChild,"DHC")),"^",5)
	s SessionTypeDr=$P($G(^RBAS(ResRowId,ASChild,"DHC")),"^",6)
	s user=UserRowId
	s group=GroupRowId
	;高替低不收费,低替高要退费
	s Sum=..GetScheduleFee(NewRBASRowId,AdmReason,+$H,FeeStr)
	;s OldSum=$P(^DHCINVPRT(InvoiceId),"^",1)
	s PRTPatientShare=$p(^DHCINVPRT(InvoiceId),"^",16)
	s OldSum=PRTPatientShare
	i Sum>OldSum s BillRBASRowId=RBASRowId
	e  s BillRBASRowId=NewRBASRowId
	
	s DiagnosCatRowId=""
	s InsuCoDR=""
	s PatAdmissionTp=..GetPatAdmissionTp(NewRBASRowId)
	s RegConDisIdPara=PatientID_"^"_BillRBASRowId_"^"_AdmReason_"^"_""
	s RegConDisId=..GetRegConDisId(RegConDisIdPara)
	s AdmCategory="",HospitalID=$P(^CTLOC(AdmDep),"^",22)
	if AdmType ="O" {
		s AdmCategory=##class(web.DHCOPRegConfig).GetGroupConfig(HospitalID,group,"OPRegAdmCategory")
	}
	s Para=PatientID_"^"_AdmType_"^"_AdmDate_"^"_AdmTime_"^"_AdmDep_"^"_AdmDoc_"^"_AdmReason_"^"_user_"^^^^"_PatAdmissionTp_"^"_AdmCategory_"^^"_DiagnosCatRowId_"^^^^^"_InsuCoDR_"^"_RegConDisId
	Set Re=##class(web.DHCPAADM).ADMInsert(Para)
	if ($g(Re)="") {
		TRollback
		Q "-201"
	}
	s EpisodeID=Re
	
	b ;记帐
	s InvoiceRowid=""
	s AccRowId=""
	s PayModeCode=""
	;应该从原帐单判断是否要收预约费和假日费
	s ret=##class(web.DHCRBAppointment).GetAppByAdm(adm)
	i ret'="" s FeeStr="||||0||1"
	e  s FeeStr=""
	s ret=..OPBillCharge(EpisodeID,BillRBASRowId,AccRowId,PayModeCode,FeeStr,user,group,"","",.NewInvoiceRowid)
	if ret'=0 {
		TRollback
		Q ret
	}
	
	s Fee=0,examfee=0
	b ;insert into DHCRegistrationFee
	s CurrDate=..%SysDate(),CurrTime=..%SysTime()
	;s RegfeeTimeRangeDr=##class(web.DHCRBResSession).GetTimeRangeByTime(ASStartTime)
	&SQL(insert into SQLUser.DHCRegistrationFee
		(RegfeeAdmDr,RegfeeName,RegfeeArcDr,RegfeeArcPrice,RegfeelookPrice,
		RegfeeBespFlag,RegfeeNo,RegfeeDoFlag,Regfeetemp1,RegfeeDepDr,RegfeeDocDr,
		RegfeeDate,RegfeeTime,RegfeeUserDr,RegfeeSessionTypeDr,RegfeeTimeRangeDr,
		RegfeeRoomDr,RegfeeRBASDr)
		Values(:EpisodeID,:Name,"",:Fee,:examfee,
		'No',:QueueNo,'Yes',:NewInvoiceRowid,:AdmDep,:AdmDoc,
		:CurrDate,:CurrTime,:user,:SessionTypeDr,:RegfeeTimeRangeDr,:RoomDr,:NewRBASRowId))
	if SQLCODE {
		TRollback
		Q "-211"
	}
	s NewRegfeeRowId=%ROWID
	 
	b ;插入队列 DHCQueue
	s Para=EpisodeID_"^"_RoomDr_"^"_QueueNo_"^"_user_"^^"_GroupRowId
	s ret=..QueueInsert(Para)
	if ret {
		TRollback
		Q "-212"
	}
	
	TCommit
	Q 0
}

ClassMethod ChangeOPRegistBroker(itmjs As %Library.String = "", itmjsex As %Library.String = "", RegFeeRowId As %String, NewRBASRowId As %String, UserRowId As %String, GroupRowId As %String, LogonLocRowId As %String)
{
	;w ##class(web.DHCOPAdmReg).ChangeOPRegistBroker("","",127,"34||15",6,6,1)
	s ^zhou("change")=RegFeeRowId_","_NewRBASRowId_","_UserRowId_","_GroupRowId_","_LogonLocRowId
	s ret=..ChangeOPRegist(RegFeeRowId,NewRBASRowId,UserRowId,GroupRowId, LogonLocRowId,.NewRegfeeRowId)
	s PrintData=""
	i ret="0" s PrintData=..GetPrintData(NewRegfeeRowId)
	s ret=ret_"$"_PrintData
	Q ret
}

/// Creator:      周志强
/// CreatDate:    2010.02.26
/// Description:  检查医生看特病的权限
/// Table:        DHC_RBResource
/// Input:        ASRowId:排板指针记录      DiagnosCatRowId:特病类别指针
/// Return:       0:允许   1:不允许
ClassMethod CheckASDiagnosCat(ASRowId As %String, DiagnosCatRowId As %String) As %String
{
	s ^zhou("CheckASDiagnosCat")=ASRowId_"^"_DiagnosCatRowId
	;w ##class(web.DHCOPAdmReg).CheckASDiagnosCat("3||8",51)
	Q:DiagnosCatRowId="" 0
	s ResRowId=+ASRowId
	set reource = ##Class(User.DHCRBResource).%OpenId(ResRowId)
	set RESDiagnosCatStr=reource.RESDiagnosCatStr
	Q:RESDiagnosCatStr="" 0
	Q:("!"_RESDiagnosCatStr_"!")'[("!"_DiagnosCatRowId_"!") 1
	Q 0
}

/// Creator:      周志强
/// CreatDate:    2010.02.26
/// Description:  检查医生看费别的权限
/// Table:        PAC_AdmReason,DHC_RBResource
/// Input:        ASRowId:排班记录指针      BillTypeRowId:费别指针
/// Return:       0:允许   1:不允许
ClassMethod CheckASBillType(ASRowId As %String, BillTypeRowId As %String) As %String
{
	s ^zhou("CheckASBillType")=ASRowId_"^"_BillTypeRowId
	;w ##class(web.DHCOPAdmReg).CheckASBillType("3||8",51)
	Q:BillTypeRowId="" 0
	s ResRowId=+ASRowId
	s LimitFlag=$p($G(^PAC("ADMREA",BillTypeRowId,"DHC")),"^",1)
	Q:LimitFlag'=1 0 
	set reource = ##Class(User.DHCRBResource).%OpenId(ResRowId)
	set RESFeeType=reource.RESFeeType
	Q:RESFeeType="" 1
	Q:("!"_RESFeeType_"!")'[("!"_BillTypeRowId_"!") 1
	Q 0
}

ClassMethod CheckResourceLimit(RowId As %String, AdmReason As %String, DiagnosCatRowId As %String) As %String
{
	;特病病人只能有有特病权限的医生来看
	;省企离休病人只能有相应权限的医生来看
	Q:(AdmReason="")!(AdmReason=" ") 0
	s AdmReasonStr="",RetireFlag="",DiagnosFlag=0,DocDiagnosCheck=0
	i $D(^RB("RES",RowId,"DHC")) {
		s RESDiagnosCatStr=$p(^RB("RES",RowId,"DHC"),"^",7)
		s RetireFlag=$p(^RB("RES",RowId,"DHC"),"^",12)
	} 
	;属于特病的费别应该由DiagnosCat决定   ;zhouzq
	If $D(^DHCDiagnosCatBill(AdmReason)) Set DiagnosFlag=1
	q:((DiagnosFlag=1)&(AdmReasonStr="")) 1       ;特病人员
	if (DiagnosFlag=1) Do
	.For k=1:1:$L(RESDiagnosCatStr,"!") Do
	..Set DocDiagnosRowid=$P(RESDiagnosCatStr,"!",k)
	..if DocDiagnosRowid=DiagnosCatRowId Set DocDiagnosCheck=1
	Q:(DocDiagnosCheck=0)&(DiagnosFlag=1)&(DiagnosCatRowId'="") 1

	q:((AdmReason="4")&(RetireFlag'="Y")) 1		  ;省企离休
	Q 0
}

/// Creator:     
/// CreatDate:    2010.03.22
/// Description:  检查其他补充限制,特需门诊只能挂普通
/// Table:        
/// Input:        
/// Return:       0:允许   1:不允许
ClassMethod CheckOtherLimit(deprowid As %String, BillTypeRowId As %String, temp1 As %String, temp2 As %String) As %String
{
	s CTDesc=""
	i deprowid'=""{
		s CTDesc=$p($g(^CTLOC(deprowid)),"^",2)
	}
	s PAAdmReason="",AdmSource=""
	i BillTypeRowId'=""{
		Set PAAdmReason=$P($g(^PAC("ADMREA",BillTypeRowId)),"^",2)
		
		s AdmSource=$p($g(^PAC("ADMREA",BillTypeRowId)),"^",9)
	}
	Q:((CTDesc="")!(PAAdmReason="")) 0
	Q:((CTDesc["特需门诊")&&(PAAdmReason'="自费")&&(AdmSource="2")) 1
	Q 0
}

ClassMethod CheckRegCountLimit(PatientID As %String, ASRowId As %String, HospitalID As %String = "", APPTRowId As %String = "") As %String
{
	s ^templog("CheckRegCountLimit")=$lb(PatientID,ASRowId,HospitalID,APPTRowId)
	s chkRtn=..CheckRegCountLimitStr(PatientID,ASRowId,HospitalID,APPTRowId)
	if chkRtn'=""{
		s chkMsg=$p(chkRtn,"^",2)
		s chkRtn=$p(chkRtn,"^",1)
	}
	
	Q +chkRtn
	
	;w ##class(web.DHCOPAdmReg).CheckRegCountLimit(8,"261||20")
	s AdmType="O"
	s obj=##class(User.RBApptSchedule).%OpenId(ASRowId)
	if $IsObject(obj){
		if HospitalID=""{
			i ($d(%session)){
				s HospitalID=##Class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospitalID)
			}else{
				s HospitalID=$p(..GetCurrentHosp("","",ASRowId,""),"^",1)	
			}
		}
		s AdmDate=obj.ASDate
		s AdmDep=obj.ASRESParRef.RESCTLOCDR.%Id()
		s AdmDoc=obj.ASRESParRef.RESCTPCPDR.%Id()
		s RegfeeTimeRangeDr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",17)
		s AdmCountStr=##Class(web.DHCOPAdmReg).GetPADayAdmCount(PatientID,AdmType,AdmDate,AdmDep,AdmDoc,RegfeeTimeRangeDr)
		s AdmCount=$P(AdmCountStr,"^",1)
		s AdmDocCount=$P(AdmCountStr,"^",2)
		s AppLocCount=$P(AdmCountStr,"^",3)
		s AdmTimeLocDocCount=$P(AdmCountStr,"^",4)
		s AdmCountStr=##Class(web.DHCOPAdmReg).GetPADayAdmCount(PatientID,"E",AdmDate,AdmDep,AdmDoc,RegfeeTimeRangeDr)
		s AdmCount=AdmCount+$P(AdmCountStr,"^",1)
		s AdmDocCount=AdmDocCount+$P(AdmCountStr,"^",2)
		s AppLocCount=AppLocCount+$P(AdmCountStr,"^",3)
		s AdmTimeLocDocCount=AdmTimeLocDocCount+$P(AdmCountStr,"^",4)
		s AppCountStr=##Class(web.DHCOPAdmReg).GetPADayAppCount(PatientID,ASRowId,APPTRowId)
		s AppCount=$P(AppCountStr,"^",1)
		s AppDocCount=$P(AppCountStr,"^",2)
		s AdmLocCount=$P(AppCountStr,"^",3)
		s AppTimeLocDocCount=$P(AppCountStr,"^",4)
		
		s DayRegCountLimit=##class(web.DHCOPRegConfig).GetSpecConfigNode("DayRegCountLimit",HospitalID)
		s DaySameDocRegCountLimit=##class(web.DHCOPRegConfig).GetSpecConfigNode("DaySameDocRegCountLimit",HospitalID)
		s DaySameLocRegCountLimit=##class(web.DHCOPRegConfig).GetSpecConfigNode("DaySameLocRegCountLimit",HospitalID)
		s LocRegLimitConfig=+$p(##class(web.DHCOPRegConfig).GetConfigNode1("OPRegDepExpand",AdmDep),"^",3)
		s TimeLocDocCountLimit=##class(web.DHCOPRegConfig).GetSpecConfigNode("DaySameTimeRegLimit",HospitalID)
		;超过每天挂号限额
		if ((AdmCount+AppCount)>=DayRegCountLimit)&&(DayRegCountLimit'=0) Q "-301"
		if ((AdmDocCount+AppDocCount)>=DaySameDocRegCountLimit)&&(DaySameDocRegCountLimit'=0) Q "-302"
		if (LocRegLimitConfig=1)&&((AdmLocCount+AppLocCount)>=DaySameLocRegCountLimit)&&(DaySameLocRegCountLimit'=0) Q "-303"
		if ('$d(^DHCOPRegConfig("DaySameTimeRegLimit",RegfeeTimeRangeDr,AdmDep,AdmDoc)))&&((AdmTimeLocDocCount+AppTimeLocDocCount)>=TimeLocDocCountLimit)&&(TimeLocDocCountLimit'=0) q "-304"
		;超过每天某种预约方式下挂号限额
		/*s MethodDR=$O(^RBC("APTM",0,"Code","WIN",0))
		s WINMethodCount=..GetPADayAppMethodCount(PatientID,ASRowId,MethodDR)
		;if WINMethodCount>0  Q "-301"    ;某种预约方式下已经预约数量的限定,需做设置
		*/
	}
	Q 0
}

ClassMethod ConvertDateToWeek(DateNum As %String) As %String
{
	if DateNum'="" {
		s Week=$ZD(DateNum,10)
		if Week=1 Q "周一"
		if Week=2 Q "周二"
		if Week=3 Q "周三"
		if Week=4 Q "周四"
		if Week=5 Q "周五"
		if Week=6 Q "周六"
		if Week=0 Q "周日"
	} 
	Q ""
}

ClassMethod ConvertToWeek(DateStr As %String) As %String
{
	s DateNum=..%ZDH(DateStr) //$ZDH(DateStr,3)
	Q ..ConvertDateToWeek(DateNum)
}

ClassMethod DHCDiagnosCat() As %String
{
 Set RetStr=""
 If $D(^Temp("DiagnosCat",$J)) K ^Temp("DiagnosCat",$J)
 Set CatRowid=0  For  Set CatRowid=$O(^DHCDiagnosCat(CatRowid)) Q:CatRowid=""  Do
 .Set DCBillTypeDR=$P(^DHCDiagnosCat(CatRowid),"^",3)
 .Set ^Temp("DiagnosCat",$J,DCBillTypeDR)=""
 If '$D(^Temp("DiagnosCat",$J)) Q ""
 Set BillTypeRowid="" For  Set BillTypeRowid=$O(^Temp("DiagnosCat",$J,BillTypeRowid)) Q:BillTypeRowid=""  Do
 .Set BillDesc=$P($G(^PAC("ADMREA",BillTypeRowid)),"^",2)
 .If RetStr="" Set RetStr=BillTypeRowid_$c(1)_BillDesc
 .Else  Set RetStr=RetStr_"^"_BillTypeRowid_$c(1)_BillDesc
 Q RetStr
}

ClassMethod DHCOPAdmBroker(itmjs As %Library.String = "", RegNo As %String, nday As %String, InvoiceNo As %String, PatientID As %String, UserRowId As %String, QueryCancel As %String = "") As %String
{
	;w ##class(web.DHCOPAdmReg).DHCOPAdmBroker("","","","",1)
	s desc=""
	s n=0
	Set rset=##Class(%ResultSet).%New("web.DHCOPAdmReg:DHCOPAdm")
	If rset.QueryIsValid() { 
		Set Status=rset.Execute(RegNo,nday,InvoiceNo,PatientID,UserRowId,QueryCancel)
		If 'Status Quit
		Set columns = rset.GetColumnCount()
		While (rset.Next()) {
			set ret=""
		    For col = 1:1:columns {
			   i ret="" s ret=rset.GetData(col)
		       e  s ret= ret_"^"_rset.GetData(col)
		    }
		    
	       s n=n+1
	       i (ret'="") {
		   		s retval=itmjs_"('"_$ZCVT(ret,"O","JS")_"');"
				&javascript<#(retval)#>
	       }
		}
		d rset.Close()
	}
	Q n
}

ClassMethod DHCOPAdmClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = DHCOPAdmExecute ]
{
	Set repid=$LIST(qHandle,2)
 Kill ^CacheTemp(repid)
 Quit $$$OK
}

ClassMethod DHCOPAdmExecute(ByRef qHandle As %Binary, RegNo As %String, nday As %String, InvoiceNo As %String, PatientID As %String, UserRowId As %String, QueryCancel As %String = "", RegDate As %String = "", LogonHospID = "") As %Status
{
	;d ##class(%ResultSet).RunQuery("web.DHCOPAdmReg","DHCOPAdm","","0000000018","","","18","","")
	s ^zhou("RegNo")=RegNo_","_nday_","_InvoiceNo_","_PatientID_"^"_QueryCancel_"^"_RegDate
	if (LogonHospID="")&&($d(%session)) s LogonHospID=%session.Get("LOGON.HOSPID")
	Set repid=$I(^CacheTemp)
	s n=nday
	i n="" d  s n=0
	s cdate=..%SysDate()
	s edate=..%SysDate()-n
	if (RegDate'=""){
		s RegDate=..%ZDH(RegDate) 
		s cdate=RegDate
		s edate=RegDate
	}
	s InvoiceId=""
	s Admdepcode="",admdep="",Admdoccode="",admdoc="",admdate=""
	s Arcdr="",Arcp=""
	If $g(ind)="" Set ind=1
	
    s langid = ..%LanguageID()
	s PAPMI=""
	If $g(RegNo)'="" do
	.Set PAPMI=$o(^PAPERi("PAPMI_PatNo",$ZCVT(RegNo,"U"),0))
	.i PatientID="" s PatientID=PAPMI
	i PAPMI="" s PAPMI=PatientID
	
	s AdmStr=""
	if InvoiceNo'="" {
		s PRTRowId=0  f  s PRTRowId=$O(^DHCINVPRT(0,"INV",InvoiceNo,PRTRowId)) Q:PRTRowId=""  d
		.s ConRowId=$O(^DHCBCI(0,"INV",PRTRowId,0))
		.Q:ConRowId=""
		.s PBRowId=$P(^DHCBCI(ConRowId),"^",2) 
		.Q:PBRowId=""
		.s PRTUserRowId=$P(^DHCINVPRT(PRTRowId),"^",21)
		.s myCPRTRowID=$o(^DHCINVPRT(0,"InitInvDR",PRTRowId,0))
		.s:((QueryCancel="1")&(myCPRTRowID'="")) PRTUserRowId=$P(^DHCINVPRT(myCPRTRowID),"^",21)
		.Q:(PRTUserRowId'=UserRowId)&(QueryCancel="1")
		.s Adm=$P(^DHCPB(PBRowId),"^",1) 
		.s VisitStatus=$p($g(^PAADM(Adm)),"^",20)
		.Q:(VisitStatus'="A")&(QueryCancel'="1")
		.Q:(VisitStatus'="C")&(QueryCancel="1")
		.i AdmStr="" s AdmStr=Adm
		.e  s AdmStr=AdmStr_"^"_Adm
	}else{
		If $g(PAPMI)'="" d
		.s PatName=$p(^PAPER(PAPMI,"ALL"),"^",1)
		.S Adm=0 f  Set Adm=$o(^PAPERdr(PAPMI,"ADM","O",Adm)) quit:Adm=""  d
		..s VisitStatus=$p($g(^PAADM(Adm)),"^",20)
		..Q:VisitStatus'="A"
		..i AdmStr="" s AdmStr=Adm
		..e  s AdmStr=AdmStr_"^"_Adm
		.S Adm=0 f  Set Adm=$o(^PAPERdr(PAPMI,"ADM","E",Adm)) quit:Adm=""  d
		..s VisitStatus=$p($g(^PAADM(Adm)),"^",20)
		..Q:VisitStatus'="A"
		..i AdmStr="" s AdmStr=Adm
		..e  s AdmStr=AdmStr_"^"_Adm
	}

	if AdmStr'="" {
	s m=0
	f i=1:1:$L(AdmStr,"^") d
	.s Adm=$P(AdmStr,"^",i)
	.s AdmReason=$P(^PAADM(Adm,1),"^",7)
	.s PatDr=$P(^PAADM(Adm),"^")
	.s PatRegNo=$p(^PAPER(PatDr,"PAT",1),"^",1)
	.s PatName=$p(^PAPER(PatDr,"ALL"),"^",1)
	.i RegNo="" s RegNo=$p(^PAPER(PatDr,"PAT",1),"^",1)
	.i RegNo'=PatRegNo s RegNo=PatRegNo
	.s Admi=Adm
	.S I=$O(^User.DHCRegistrationFeeI("ADM",Admi,""))
	.Q:I=""
	.s RegfeeDate=$List(^User.DHCRegistrationFeeD(I),15)
	.Q:((RegfeeDate<edate)!(RegfeeDate>cdate))&&(InvoiceNo="")
	.s TRRowId=$List(^User.DHCRegistrationFeeD(I),21)
	.s admdate=$p($g(^PAADM(Adm)),"^",6)
	.s kdate=..%ZD(admdate) //$zd(admdate,3)
	.s AdmTime=..%ZT($p($g(^PAADM(Adm)),"^",7),3)
	.s Cuserid=$p($g(^PAADM(Adm)),"^",43)
	.i Cuserid="" s Username="" 
	.e  s Username=$p($g(^SSU("SSUSR",Cuserid)),"^",2)
    .s:$g(Username)'="" Username = ##class(User.SSUser).GetTranByDesc("SSUSRName",Username,langid)
	.;s Arcdr=$List(^User.DHCRegistrationFeeD(I),3)
	.;s Arcp=$List(^User.DHCRegistrationFeeD(I),4)
	.s Arcdr=""
	.s Arcp=""
	.s ph=$List(^User.DHCRegistrationFeeD(I),8)
	.s InvoiceId=$List(^User.DHCRegistrationFeeD(I),11)
	.;
	.i QueryCancel="1" d
	..&SQL(select PRT_OldINV_DR into :oldInvoiceId From SQLUser.DHC_INVPRT where PRT_RowId=:InvoiceId)
	..if oldInvoiceId'="" s InvoiceId=oldInvoiceId
	.
	.s RegfeeRowId=I
	.s admdep="",admdoc=""
	.s Admdepcode=$List(^User.DHCRegistrationFeeD(I),13)
	.i Admdepcode'="" s admdep=$p($g(^CTLOC(Admdepcode)),"^",2),DeptHospDt=$p(^CTLOC(Admdepcode),"^",22)
    .s:$g(admdep)'="" admdep = ##class(User.CTLoc).GetTranByDesc("CTLOCDesc",admdep,langid)
	.Q:(DeptHospDt'=LogonHospID)
	.s Admdoccode=$List(^User.DHCRegistrationFeeD(I),14)
	.i Admdoccode'="" s admdoc=$p($g(^CTPCP(Admdoccode,1)),"^",2)
    .s:$g(admdoc)'="" admdoc = ##class(User.CTCareProv).GetTranByDesc("CTPCPDesc",admdoc,langid)
	.i RegfeeDate'="" s RegfeeDate=..%ZD(RegfeeDate) //$zd(RegfeeDate,3)
	.s RegfeeTime=$List(^User.DHCRegistrationFeeD(I),16)
	.i RegfeeTime'="" s RegfeeTime=..%ZT(RegfeeTime)
	.;原诊
	.s RBASRowId=$List(^User.DHCRegistrationFeeD(I),18)
	.;
	.;s StartTime=$P($G(^RBAS(+RBASRowId,$P(RBASRowId,"||",2))),"^",4)
	.;s TRRowId=##class(web.DHCRBResSession).GetTimeRangeByTime(StartTime)
	.i TRRowId'=""  d
    ..s TRDesc=$P(^DHCTimeRange(TRRowId),"^",2)
    ..s:$g(TRDesc)'="" TRDesc = ##class(User.DHCTimeRange).GetTranByDesc("TRDesc", TRDesc, langid)
	.e  d
    ..s TRDesc="其他"
    ..s TRDesc = ..%Translate("opadm.reg.hui.csp",TRDesc,langid)
	.s:ph'="" admdoc=admdoc_"("_TRDesc_")"
	.;
	.;排班状态及调整原因
	.s RBASStatusDesc="",RBASStatusCode=""
	.s RBASStatusReason=""
	.i RBASRowId'="" d
	..s RBASStatusDr=$P($g(^RBAS(+RBASRowId,$P(RBASRowId,"||",2),"DHC")),"^",10)
	..q:RBASStatusDr=""
	..s RBASStatusCode=$P(^DHCRBCASStatus(RBASStatusDr),"^",1)
	..s RBASStatusDesc=$P(^DHCRBCASStatus(RBASStatusDr),"^",2)
    ..s:$g(RBASStatusDesc)'="" RBASStatusDesc = ##class(User.DHCRBCASStatus).GetTranByDesc("ASSDesc", RBASStatusDesc, langid)
	..i (RBASStatusCode'="N") d
	...s RBASStatusReasonDr=$P(^RBAS(+RBASRowId,$P(RBASRowId,"||",2),"DHC"),"^",11)
	...i RBASStatusReasonDr'="" s RBASStatusReason=$P(^RBC("NA",RBASStatusReasonDr),"^",2)
    ...s:$g(RBASStatusReason)'="" RBASStatusReason = ##class(User.RBCReasonNotAvail).GetTranByDesc("RNAVDesc", RBASStatusReason, langid)
	.s AdmRegFeeInfo=..GetAdmRegFeeInfo(Adm,LogonHospID)
	.;Reg_"^"_Check_"^"_MR_"^"_Card_"^"_ReCheck_"^"_App_"^"_Holi_"^"_Other
	.s RegFee=$p(AdmRegFeeInfo,"^",1)
	.s CheckFee=$p(AdmRegFeeInfo,"^",2)
	.s MRFee=$p(AdmRegFeeInfo,"^",3)
	.s ReCheckFee=$p(AdmRegFeeInfo,"^",5)
	.s AppFee=$p(AdmRegFeeInfo,"^",6)
	.s HoliFee=$p(AdmRegFeeInfo,"^",7)
	.s OtherFee=$p(AdmRegFeeInfo,"^",8)
	.;是否预约
	.s regtype=0
	.s ret=##class(web.DHCRBAppointment).GetAppByAdm(Adm)
	.i ret'="" d
	..s regtype=1
	..;停诊和替诊产生的号预约费也要退
	..;如果预约当天就退号,则全退,否则不退预约费
	..i ((RBASStatusCode="N")!(RBASStatusCode="R"))&&(admdate=..%SysDate()) d
	...s AppFee=$p(AdmRegFeeInfo,"^",6)
	.;被替诊的挂号记录才能显示对应的替诊排班记录
	.s TRRBASRowId="",TRDoc=""
	.i (RBASStatusCode="TR") d
	..s TRRBASRowId=$P(^RBAS(+RBASRowId,$P(RBASRowId,"||",2),"DHC"),"^",12)
	..i (TRRBASRowId'="") d
	...s TRDocRowId= $P($G(^RB("RES",+TRRBASRowId)),"^",2)
	...s TRDoc=$p($g(^CTPCP(TRDocRowId,1)),"^",2)
	.
	.s INVPRTNo="",INVPRTAcount=0.00,INVPayMode=""
	.i InvoiceId'="",$d(^DHCINVPRT(InvoiceId)) d
	..s INVPRTNo=$P($g(^DHCINVPRT(InvoiceId)),"^",14)
	..i INVPRTNo="" d
	...s ACCPINVDR=$P($G(^DHCINVPRT(InvoiceId)),"^",4)
	...s:ACCPINVDR'="" INVPRTNo=$P($G(^DHCINVPRTAP(ACCPINVDR)),"^",6)
	..;s INVPRTAcount=$P(^DHCINVPRT(InvoiceId),"^",1)
	..s PRTPatientShare=$p($g(^DHCINVPRT(InvoiceId)),"^",16)
	..s INVPRTAcount=$j(PRTPatientShare,"",2)
	..s INVPayMode=..GetINVPayMode(InvoiceId)
	.s Acount=INVPRTAcount
	.Q:(InvoiceNo'="")&&(InvoiceNo'=INVPRTNo)&(QueryCancel'="1")
	.s TabEinvprtNo=""
	.s TabEinvprtStr=##class(BILL.EINV.BL.COM.InvUpDetailsCtl).GetEInvInfoByHisInvDr("OP",InvoiceId)
	.if TabEinvprtStr'="" s TabEinvprtNo=$P(TabEinvprtStr,"^",1)
	.;
	.s TRSum=0,FeeStr="",ChangeSum=0
	.i QueryCancel'="1" d
	..i TRRBASRowId'="" d
	...s AdmReason=$P(^PAADM(Adm,1),"^",7)
	...;如果是预约替诊,则还要算替诊医生的预约费用
	...i regtype=1 s FeeStr="||||||1"
	...s TRSum=..GetScheduleFee(TRRBASRowId,AdmReason,+$H,FeeStr)
	...i TRSum<Acount s ChangeSum=Acount-TRSum
	...i +TRSum=0 s MRFee=0
	.s m=m+1
	.s ReturnFlag=..CheckCancelOPRegist(Adm)
	.i ReturnFlag=""  s TabReturnFlag="可退"
	.e  s TabReturnFlag=$p(ReturnFlag,"^",2)
    .s TabReturnFlag = ..%Translate("opadm.return.hui.csp",TabReturnFlag,langid)
	.s InsuAdmInfoDr=##class(web.DHCOPAdm).GetINADMRowid(RegfeeRowId)
	.s AdmReasonId=$P(^PAADM(Adm,1),"^",7)
	.b   ;001
	.Do OutputRow1
	}
	/*i (RegNo="")&&(nday="")&&(InvoiceNo="")&&(PatientID="") d
	.Set ^CacheTemp(repid,ind)=$lb("")
	.Set ind=ind+1*/
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK

OutputRow1
	set Data=$lb(Admdepcode,admdep,Admdoccode,admdoc,AdmTime,Username,Adm,Acount,Arcdr,RegNo,ph,InvoiceId,kdate,RegfeeDate,RegfeeTime,RegfeeRowId,INVPRTNo,RBASRowId,TRRBASRowId,TRDoc,RBASStatusDesc,RBASStatusCode,regtype,AppFee,RBASStatusReason,PatName,TRSum,ChangeSum,INVPayMode,RegFee,CheckFee,AppFee,ReCheckFee,OtherFee,HoliFee,TabReturnFlag,PatDr,MRFee,$g(InsuAdmInfoDr),$g(AdmReasonId),$g(TabEinvprtNo))
	 Set ^CacheTemp(repid,ind)=Data
	 Set ind=ind+1
	quit
ResetVariables1
	///set (repid)=0 ,Admdoccode,admdoc,Username,AdmTime
	set (Admdepcode,admdep,Admdoccode,admdoc,AdmTime,Username,Adm,Acount,Arcdr,RegNo,ph,InvoiceId,kdate,RegfeeDate,RegfeeTime,RegfeeRowId,INVPRTNo,RBASRowId,TRRBASRowId,TRDoc,TRRBASStatusDesc,TRRBASStatusCode,regtype,AppFee,RBASStatusReason,PatName,TRSum,ChangeSum,INVPayMode,RegFee,CheckFee,AppFee,ReCheckFee,OtherFee,HoliFee,TabReturnFlag,PatDr,MRFee,InsuAdmInfoDr,AdmReasonId,TabEinvprtNo)=""
	quit
}

ClassMethod DHCOPAdmFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = DHCOPAdmExecute ]
{
 Set AtEnd=$LIST(qHandle,1)
 Set repid=$LIST(qHandle,2)
 Set ind=$LIST(qHandle,3)
	//
 Set ind=$o(^CacheTemp(repid,ind))
 If ind="" {				// if there are no more rows, finish fetching
 Set AtEnd=1
 Set Row=""
 }
 Else      {				// fetch row
 Set Row=^CacheTemp(repid,ind)
 }
 // Save QHandle
 s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

ClassMethod DocListBroker(itmjs As %Library.String = "", itmjsex As %Library.String = "", val As %Library.String = "")
{
	;w ##class(web.DHCOPAdmReg).DocListBroker("","","14^6^^431967^8^^6")
 Set Status=0
 Set value=""

 Set rs=##Class(%ResultSet).%New("web.DHCOPAdmReg:OPDocList")
 If rs.QueryIsValid() { 
	 Set Status=rs.Execute(val)
	 Set columns = rs.GetColumnCount()

	 If 'Status Quit
	 While rs.Next() {
		s rowvalue=""
		For col = 1:1:columns {
			;Write rset.GetColumnName(col),":"
			if col=1 set rowvalue=rs.GetData(col)
			e  s rowvalue=rowvalue_"^"_rs.GetData(col)
		}
		if value="" s value=rowvalue
		else  s value=value_"!"_rowvalue
	 }
 }
 if value'="" {
	 ;s retval=itmjs_"('"_value_"');"
	 s retval=itmjs_"('"_$ZCVT(value,"O","JS")_"');"
	 i itmjsex'="" s retval=retval_itmjsex_"('"_$ZCVT(value,"O","JS")_"');"
	 &javascript<#(retval)#>
 }
 q 1
}

ClassMethod DoclikeMark(doc As %String, Markdoc As %String) As %String
{
 Set Flag=0	
 If '$d(^User.DHCMarkDocI("MarkdDocMarkIndex",Markdoc)) Q "0"
 Set Markrowid="" F  s Markrowid=$O(^User.DHCMarkDocI("MarkdDocMarkIndex",Markdoc,Markrowid)) q:Markrowid=""  d
 .If Markrowid=doc Set Flag=1
 Q Flag
}

ClassMethod FormatPatientNo(str As %String) As %String
{
	s len=$l(str)
	For i = 1:1:(8-len) {
		s str="0"_str
	}
	Q str
}

/// 得到服务项所对应的挂号费用类型
ClassMethod GeRegSerBillSubType(SerId) As %String
{
	;w ##class(web.DHCOPAdmReg).GeRegSerBillSubType("")
	s ArcimId=$p(^RBC("SER",SerId),"^",1)
	Q ..GetRegArcimBillSubType(ArcimId)
}

ClassMethod GetINVPayMode(InvoiceId As %String) As %String
{
	;n (InvoiceId)
    s langid = ..%LanguageID()
	s Num=0
	s PayMode="",PayModeStr=""
	s InitInvoiceId=$o(^DHCINVPRT(0,"InitInvDR",InvoiceId,""))
	s IPMSub=0
	for {
		s IPMSub=$O(^DHCINVPRT(InvoiceId,"P",IPMSub))
		Q:IPMSub=""
		s IPMPayModeDR=$p($g(^DHCINVPRT(InvoiceId,"P",IPMSub)),"^",1)
		s IPMAmt=$p($g(^DHCINVPRT(InvoiceId,"P",IPMSub)),"^",3)
		if (InitInvoiceId'=""){
			if ($d(^DHCINVPRT(InitInvoiceId,"P",IPMSub))) {
				s refIPMAmt=$p($g(^DHCINVPRT(InitInvoiceId,"P",IPMSub)),"^",3)
				s IPMAmt=IPMAmt+refIPMAmt
			}
		}
		continue:IPMAmt=0
		if IPMPayModeDR'="" {
			s PayMode=$P($g(^CT("CTPM",IPMPayModeDR)),"^",2)
            s:$g(PayMode)'="" PayMode=##class(User.CTPayMode).GetTranByDesc("CTPMDesc",PayMode,langid)
			if PayModeStr="" s PayModeStr=PayMode_":"_$j(IPMAmt,"",2)
			else  s PayModeStr=PayModeStr_","_PayMode_":"_$j(IPMAmt,"",2)
			s Num=Num+1
		}
	}
	Q PayModeStr
	/*if Num>1 {
		Q PayModeStr
	}else{
		Q PayMode
	}*/
}

ClassMethod GetAdmRecord(PatientID As %String) As %String
{
 ;w ##class(web.DHCOPAdmReg).GetAdmRecord("00000013")
    s flag=0
    If $g(PatientID)'="" {
	    s AdmTypeStr="O^E"
	    for i=1:1:$l(AdmTypeStr,"^"){
		    Q:flag=1
		    s AdmType=$p(AdmTypeStr,"^",i)
		    s Adm="" 
			for {
				s Adm=$o(^PAPERdr(PatientID,"ADM",AdmType,Adm)) quit:Adm=""
				s VisitStatus=$p($g(^PAADM(Adm)),"^",20)
				continue:VisitStatus'="A"
				s admdate=$p($g(^PAADM(Adm)),"^",6)
				s flag=1
				Q
			}
		}
	}
	Q flag
}

ClassMethod GetAdmTimeRange(ASRowId, SeqNo) As %String
{
	;w ##class(web.DHCOPAdmReg).GetAdmTimeRange("91||1",1)
	s TimePeriod=##class(web.DHCOPRegConfig).GetSpecConfigNode("AdmTimeRangeCount")
	if TimePeriod="" s TimePeriod=3
	s ASStartTime=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2))),"^",4) 
	s Load=+$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2))),"^",8)
	;s TRRowId=##class(web.DHCRBResSession).GetTimeRangeByTime(ASStartTime)
	s TRRowId=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",17)
	Q:TRRowId="" ""
	Q:+Load=0 ""
	s StartTime=$P(^DHCTimeRange(TRRowId),"^",3)
	s EndTime=$P(^DHCTimeRange(TRRowId),"^",4)
	/*
	i $e(SeqNo,1)="+"{
		s SessStartTime=EndTime+1800
		Q ..%ZT(SessStartTime,2)_"之前"
	}
	*/
	i $e(SeqNo,1)="+"{
		if (EndTime<=84599){
			s SessStartTime=EndTime+1800
		}else{
			s SessStartTime=EndTime
		}
		Q ..%ZT(SessStartTime,2)_"之前"
	}
	;w Load_"-"_..%ZT(StartTime)_"-"_..%ZT(EndTime),!
	f i=1:1:TimePeriod  {
		if (SeqNo/Load)<=(i/TimePeriod) {
			Quit
		}
	}
	s SingleTime=(EndTime-StartTime)/TimePeriod
	s SingleTime=$fn(SingleTime,"",0)
	s SessStartTime=StartTime+(SingleTime*(i-1))
	s SessEndTime=StartTime+(SingleTime*i)
	Q ..%ZT(SessStartTime,2)_"-"_..%ZT(SessEndTime,2)
}

ClassMethod GetBillSubStr(UserId As %String) As %String
{
	s ret1=""
	
	Q ret1
}

ClassMethod GetBillTypeListBroker(JSFunName As %String = "", ListName As %String = "", PatientID As %String, HospID As %String = "") As %String
{
	s langid = ..%LanguageID()
    ;w ##class(web.UDHCOPOtherLB).GetPacListBroker("GetBillTypeToHUIJson","","21")
	s myBMRowid=""
	s mydes=""
	s myval=""
	s mySelFlag=0
	s myIdx=0
	s PatDr=PatientID
	s json="["
	;s PatientNo=..FormatPatientNo(PatientNo)
	;Set PatDr=$o(^PAPERi("PAPMI_PatNo",$ZCVT(PatientNo,"U"),""))
	Quit:PatDr="" 0
	s HospID=##class(DHCDoc.Common.Hospital).GetDefHospIdByTableName("DHC_PACADM",HospID)
	if $D(^PAPER(PatDr,"PER",1)) d
 	.Set PAPERStateCodeDR=$p(^PAPER(PatDr,"PER",1),"^",10)
 	f  s myBMRowid=$o(^DHCPACADM(0,"Social",PAPERStateCodeDR,myBMRowid),-1) q:(myBMRowid="")  d
	.if $D(^DHCPACADM(myBMRowid)) d
	..s PACAdmReasonDr=$p(^DHCPACADM(myBMRowid),"^",2)
	..s PACHospDr=$p(^DHCPACADM(myBMRowid),"^",5)
	.Q:PACHospDr'=HospID
	.s StDate=$p($g(^PAC("ADMREA",PACAdmReasonDr)),"^",3)
	.Q:(StDate>+$H)&&(StDate'="")
	.s EndDate=$p($g(^PAC("ADMREA",PACAdmReasonDr)),"^",4)
	.Q:(EndDate<+$H)&&(EndDate'="")
	.s mydes=$p($g(^PAC("ADMREA",PACAdmReasonDr)),"^",2)
    .s:$g(mydes)'="" mydes=##class(User.PACAdmReason).GetTranByDesc("READesc",mydes,langid)
	.s myval=PACAdmReasonDr
	.;s myval=myval_"^"_$p(^PAC("ADMREA",PACAdmReasonDr),"^",2)
	.s myIdx=myIdx+1
	.i myIdx=1 d 
	..s mySelFlag=1
	.e  d
	..s mySelFlag=0
	.;前台维护界面增加了是否默认的勾选
	.s PACDefault=$p($g(^DHCPACADM(myBMRowid)),"^",6)
	.if (PACDefault="Y") s mySelFlag=1
	.i JSFunName="GetBillTypeToHUIJson" d
	..s OneJsonData="{""text"":"""_$g(mydes)_""",""id"":"""_$g(myval)_""""
	..i mySelFlag=1 s OneJsonData=OneJsonData_",""selected"":true"
	..s OneJsonData=OneJsonData_"}"
	..i myIdx=1 d
	...s json=json_OneJsonData
	..e  d
	...s json=json_","_OneJsonData
	.e  d
	..s rtnval=JSFunName_"('"_ListName_"','"_$ZCVT($g(mydes),"O","JS")_"','"_$ZCVT($g(myval),"O","JS")_"','"_$ZCVT($g(myIdx),"O","JS")
	..s rtnval=rtnval_"','"_$ZCVT("","O","JS")_"');"
	..&javascript<#(rtnval)#>
	.s myIdx=myIdx+1
	s json=json_"]"   
	i JSFunName="GetBillTypeToHUIJson" {
		q json
	}
	q 0
}

/// 得到费别
ClassMethod GetBillTypeStr() As %String
{
	;w ##class(web.DHCOPAdmReg)GetSexStr()
	s ret1=""
	s RowId=0 f  Set RowId=$o(^PAC("ADMREA",RowId)) Quit:RowId=""  d
	.s Desc=$p(^PAC("ADMREA",RowId),"^",2)
	.s ret=RowId_$C(1)_Desc
	.i ret1="" s ret1=ret
	.e  s ret1=ret_"^"_ret1
 Q ret1
}

ClassMethod GetBoroughByMark(MarkDr As %String) As %String
{
	
	// w ##class(web.DHCOPAdmReg).GetBoroughByMark("500")
	s BoroughDesc=""
	s MarkStr=" "_MarkDr
	s BoroughMarkDr=$o(^User.DHCDepMarkI("DepmMarkDrIndex",MarkStr,0))
	q:BoroughMarkDr="" BoroughDesc 
	s BoroughDr=$list($g(^User.DHCDepMarkD(BoroughMarkDr)),7)
	q:BoroughDr="" BoroughDr 
	s BoroughDesc=$list($g(^User.DHCExaBoroughD(BoroughDr)),5)
	q BoroughDesc
}

ClassMethod GetCardFee() As %String
{
	s ArcimId=..GetCardFeeArcimId()
	Q:ArcimId="" 0
	s BillPrice=$p(##Class(web.UDHCJFPRICE).GetOrderPrice("","",ArcimId,+$H,"","","",""),"^",4)
	Q BillPrice
}

ClassMethod GetCardFeeArcimId(HospId As %String = "") As %String
{
	Q $p(##class(web.DHCOPRegConfig).GetSpecConfigNode("NeedBillCardFeeOrder",HospId),"@",1)
	/*
	s HospitalCode=..GetHospitalCode()
	
	if HospitalCode="YKDYY" {
		s ARCIMSubscript=$O(^ARCIM(0,"Code","GHYXXXTFWF",""))
		s ARCIMVersion=$O(^ARCIM(0,"Code","GHYXXXTFWF",ARCIMSubscript,""))
		Q ARCIMSubscript_"||"_ARCIMVersion
	}elseif(HospitalCode="SHSDFYY"){
		s ARCIMCode="CKF001"
		s ARCIMSubscript=$O(^ARCIM(0,"Code",ARCIMCode,""))
		s ARCIMVersion=$O(^ARCIM(0,"Code",ARCIMCode,ARCIMSubscript,""))
		Q ARCIMSubscript_"||"_ARCIMVersion
		 
	}elseif(HospitalCode="JSXZZXYY"){
		s ARCIMCode="CKF001"
		s ARCIMSubscript=$O(^ARCIM(0,"Code",ARCIMCode,""))
		s ARCIMVersion=$O(^ARCIM(0,"Code",ARCIMCode,ARCIMSubscript,""))
		Q ARCIMSubscript_"||"_ARCIMVersion
		 
	}else{
		
		Q $p(##class(web.DHCOPRegConfig).GetSpecConfigNode("NeedBillCardFeeOrder"),"@",1)
	}
	*/
}

ClassMethod GetCatCode(CatBillType As %String) As %String
{
 if CatBillType="" Q ""
 Set Flag=0
 if '$D(^DHCDiagnosCatBill(CatBillType)) Q ""
 Set ret=""
 Set RowId=0 f  s RowId=$O(^DHCDiagnosCat(RowId)) Q:RowId=""  d
 .Set DCBillType=$P($G(^DHCDiagnosCat(RowId)),"^",3)
 .Q:DCBillType'=CatBillType
 .b ;cwg-1
 .Set DCAdmType=$P($G(^DHCDiagnosCat(RowId)),"^",2)
 .Set DCType=$P($G(^DHCDiagnosCat(RowId)),"^",5)
 .Set DCQuick=$P($G(^DHCDiagnosCat(RowId)),"^",6)
 .Set Desc=$P($G(^DHCDiagnosCat(RowId)),"^",1)
 .Q:(DCType'="S")
 .If ret="" Set ret=RowId_"!"_Desc_"!"_DCQuick_$C(1)_Desc_"-"_$g(DCQuick)
 .Else  Set ret=ret_"^"_RowId_"!"_Desc_"!"_DCQuick_$C(1)_Desc_"-"_$g(DCQuick)
 b ;
 Q ret
}

/// desc 获取公共卡设置的公共卡ID串以^分割，公共卡是以&分割
ClassMethod GetCommonPatientID(ChoseCommonCardNo As %String = "", HospitalID As %String = "") As %String
{
	//判断是否有公共卡
	s CommonPatientID=""
	s CommonCardNoStr=##class(web.DHCOPRegConfig).GetSpecConfigNode("CommonCardNo",HospitalID)
	i (CommonCardNoStr'="") {
		s CardStrLong=$L(CommonCardNoStr,"&")
		for i=1:1:CardStrLong{
		s CommonCardNo=$P(CommonCardNoStr,"&",i)
		continue:CommonCardNo=""
		s ExpStr=""_$c(2)_""_$C(2)_"PatInfo"_$C(2)_HospitalID
		s ret=##class(web.UDHCAccManageCLSIF).getaccinfofromcardno(CommonCardNo,"",ExpStr)
		s retcode=$P(ret,"^",1)
		//if (retcode="-201")!(retcode="0"){
		s CommonPatientIDGet=$P(ret,"^",8)
		///防止公共卡号维护多种卡类型
		if (CommonPatientIDGet=""){
			s ExpStr=""_$c(2)_1_$C(2)_"PatInfo"_$C(2)_HospitalID
			s ret=##class(web.UDHCAccManageCLSIF).getaccinfofromcardno(CommonCardNo,"",ExpStr)
			s CommonPatientIDGet=$P(ret,"^",8)
		}
		if CommonPatientID="" s CommonPatientID=CommonPatientIDGet
		else  s CommonPatientID=CommonPatientID_"^"_CommonPatientIDGet
		//}
		}
	}
	Q CommonPatientID
}

ClassMethod GetCurrentTimeRange() As %String
{
	;w ##class(web.DHCOPAdmReg).GetCurrentTimeRange()
	Q ##class(web.DHCRBResSession).GetTimeRangeByTime()
}

/// 本地化关联的服务医嘱项
/// Creator:zhou
/// date:2010-08-04
/// desc:本地化关联的服务医嘱项
/// Modify:guorongyong
/// Modify Desc:根据医院代码使用不同的封装函数,统一到设置上
ClassMethod GetCustomScheduleService(PatientID As %String, ASRowId As %String, SerIdStr As %String, SearchType As %String = "Search") As %String
{
	;n (PatientID,ASRowId,AdmReason,SerIdStr)
	;w ##class(web.DHCOPAdmReg).GetCustomScheduleService(2,"251||2","4248||1^4251||1")
	;s ^gry("GetCustomScheduleService",ASRowId)=PatientID_","_ASRowId_","_SerIdStr
	s HospitalCode=##class(web.DHCDocOrderCommon).GetCurrentHospitalCode()
	s HospitalCode=$ZCVT(HospitalCode,"U")
	s CommonPatientID=..GetCommonPatientID()
	s HospId=$p(##class(web.DHCOPAdmReg).GetCurrentHosp("","",ASRowId,""),"^",1)
	if HospitalCode="YKDYY" {
		s SerIdStr=..CustomScheduleServiceSY(PatientID,ASRowId,SerIdStr)	
	}elseif HospitalCode="XZSZXYY" {
		;老年人免费 1为70岁以上老人免费,2为老年证免费,徐州全免
		 s OldManFree=##class(web.DHCOPRegConfig).GetSpecConfigNode("OldManFree")
		 if (OldManFree=1){
			 if PatientID'="" {
				 Set Age=+$p(^PAPER(PatientID,"ALL"),"^",6)
				 Set Age=$p(((+$H-Age)/365)+0.5,".")
				 if Age>=70 Set SerIdStr=$p(##class(web.DHCOPRegConfig).GetSpecConfigNode("FreeOrder"),"@",1)
			 }
		 }
		 if (OldManFree=2){
			 s OldManCardNo=""
			 if PatientID'="" {
			 	&sql(select DHCPCN_CardNo into :OldManCardNo from SqlUser.DHC_PaperCardNum where DHCPCN_Papmi_DR=:PatientID and (DHCPCN_CardType_DR->CARD_Desc like '%老年证%'))
			 	if OldManCardNo'="" s SerIdStr=$p(##class(web.DHCOPRegConfig).GetSpecConfigNode("FreeOrder"),"@",1)
			 }
		 }
		s SerIdStr=..CustomScheduleServiceXZ(PatientID,ASRowId,SerIdStr)	
	}elseif HospitalCode="HYD" {
		s AdmissionTpCode=""
		s AdmissionTp=..GetPatAdmissionTp(ASRowId)
		if (AdmissionTp'="") s AdmissionTpCode=$P($g(^PAC(AdmissionTp,"IPAT")),"^",1)
        if AdmissionTpCode'="T" {
			;老年人免费 1为70岁以上老人免费,2为老年证免费,哈医大只免挂号费
			 s OldManFree=##class(web.DHCOPRegConfig).GetSpecConfigNode("OldManFree")
			 if (OldManFree=1){
				 if PatientID'="" {
					 Set Age=+$p(^PAPER(PatientID,"ALL"),"^",6)
					 Set Age=$p(((+$H-Age)/365)+0.5,".")
					 if Age>=70 Set SerIdStr=..UpdateSerIdStrFree("Reg^",SerIdStr)
				 }
			 }
			 if (OldManFree=2){
				 s OldManCardNo=""
				 if PatientID'="" {
				 	&sql(select DHCPCN_CardNo into :OldManCardNo from SqlUser.DHC_PaperCardNum where DHCPCN_Papmi_DR=:PatientID and (DHCPCN_CardType_DR->CARD_Desc like '%老年证%'))
				 	if OldManCardNo'="" Set SerIdStr=..UpdateSerIdStrFree("Reg^",SerIdStr)
				 }
			 }
        }
		;s SerIdStr=..CustomScheduleServiceHYD(PatientID,ASRowId,SerIdStr)	
	}
	
	;有设置的部分统一到走设置
	;
	;验证医嘱项上的性别、年龄控制
	s (PatDOB,SexId)=""
	if (PatientID'=""){
		s PatDOB=$P($G(^PAPER(PatientID,"ALL")),"^",6)
		s SexId=$P($G(^PAPER(PatientID,"ALL")),"^",7)
	}elseif (CommonPatientID'=""){
		s PatDOB=$P($G(^PAPER(+CommonPatientID,"ALL")),"^",6)
		s SexId=$P($G(^PAPER(+CommonPatientID,"ALL")),"^",7)
	}
	if (PatDOB'="")||(SexId'=""){
		s SerIdStrTemp=""
		f i=1:1:$l(SerIdStr,"^") {
			s ArcimId=$P(SerIdStr,"^",i)
			i (ArcimId="") {continue}
			s ASCheckStr=##Class(web.DHCDocOrderCommon).GetItemAgeSexRestriction(ArcimId,PatientID,HospId)
			if (+ASCheckStr=1){
				continue
			}
			If SerIdStrTemp="" {
				Set SerIdStrTemp=ArcimId
			}else{
				Set SerIdStrTemp=SerIdStrTemp_"^"_ArcimId 
			}
		}
		Set SerIdStr=SerIdStrTemp
	}
	///--------------保证有医嘱可以结算
	///------免费医嘱在InsertRegOrder最后有判断，此处返回会导致挂免费号收病历本,计费组调用更新流水表发票ID时传入的医嘱串只有病历本，但实际医嘱却有两条导致失败
	/*if (SerIdStr=""){
		s SerIdStr=$p(##class(web.DHCOPRegConfig).GetSpecConfigNode("FreeOrder"),"@",1)
	}*/
	///挂号设置，条件医嘱设置
	s AdmDepID=$P(^RB("RES",+ASRowId),"^",1)
	s AdmDocID=$P(^RB("RES",+ASRowId),"^",2)
	s SerIdStr=##class(DHCDoc.OPAdm.DHCOPRegArcimConfig).CheckForOtherARCIM(AdmDepID,AdmDocID,PatientID,SerIdStr)
	Q SerIdStr
}

ClassMethod CustomScheduleServiceXZ(PatientID As %String, ASRowId As %String, SerIdStr As %String, SearchType As %String = "Search") As %String
{
	;1、走DHCRegConFree表判断是否满足免费的条件,根据设置拼服务串
	;2、挂号时附加的费用(eg:妇科 银光检查费)
    ;1
    
    ;2
    ;s DepRefArcimStr=..findDepRefArcimStr(AdmDepID)
    Q:ASRowId="" SerIdStr
    s AdmDepID=$P(^RB("RES",+ASRowId),"^",1)
    s AdmDep=""
    if AdmDepID'="" {
	    s AdmDep=$p(^CTLOC(AdmDepID),"^",2)
    }
    b ;1
    s SexCode=""
    if PatientID'="" {
	    s SexID=$p(^PAPER(PatientID,"ALL"),"^",7)
	    if SexID'="" s SexCode=$p(^CT("SEX",SexID),"^",1)
    }
    if (SexCode="F")&&(AdmDep["生殖医学中心门诊") {
	    s AddARCIMRowid=##class(web.DHCDocOrderEntry).GetARCIMByCode("8239")
	    if AddARCIMRowid'="" {
	    	if SerIdStr="" s SerIdStr=AddARCIMRowid
	    	s SerIdStr=SerIdStr_"^"_AddARCIMRowid
	    }
    }
    
    if AdmDep["肛肠科门诊" {
	    s AddARCIMRowid=##class(web.DHCDocOrderEntry).GetARCIMByCode("8132")
	    if AddARCIMRowid'="" {
	    	if SerIdStr="" s SerIdStr=AddARCIMRowid
	    	s SerIdStr=SerIdStr_"^"_AddARCIMRowid
	    }
    }
    
     if AdmDep["妇科门诊" {
	    s AddARCIMRowid=##class(web.DHCDocOrderEntry).GetARCIMByCode("8239")
	    if AddARCIMRowid'="" {
	    	if SerIdStr="" s SerIdStr=AddARCIMRowid
	    	s SerIdStr=SerIdStr_"^"_AddARCIMRowid
	    }
    }
    
    if AdmDep["产科门诊" {
	    s AddARCIMRowid=##class(web.DHCDocOrderEntry).GetARCIMByCode("8261")
	    if AddARCIMRowid'="" {
	    	if SerIdStr="" s SerIdStr=AddARCIMRowid
	    	s SerIdStr=SerIdStr_"^"_AddARCIMRowid
	    }
    }
    
    Q SerIdStr
}

ClassMethod CustomScheduleServiceSY(PatientID As %String, ASRowId As %String, SerIdStr As %String, SearchType As %String = "Search") As %String
{
	s PAPERRowid=PatientID
	s AdmDep=$P(^RB("RES",+ASRowId),"^",1)
	s SocialStatus=$P(^PAPER(PAPERRowid,"PER",1),"^",10)
	s OldManCardId=$p(^PAPER(PAPERRowid,"ALL"),"^",20)
	set MentalityFristFlag=0
	 ;下面的处理原来太乱,临时整理了一下     ;zhouzq
	 i AdmDep="184" {
		 s MentalityFristFlag=$$MentalityFrist(PAPERRowid)
	 	 i MentalityFristFlag=1 s SerIdStr=SerIdStr_"^"_"3116||1"
	 } 
	 i AdmDep="144" s SerIdStr=SerIdStr_"^"_"2142||1"
	 i AdmDep="229" {
		 s MentalityFristFlag=$$MentalityFristXN(PAPERRowid,ASRowId) //add
		 i (MentalityFristFlag>1)&($L(SerIdStr,"3116||1")>1) {
		 	 set SerIdStrTemp=""
			 f j=1:1:$L(SerIdStr,"^") d 
			 .Q:($P(SerIdStr,"^",j)="3116||1")
			 .s ArcimId=$P(SerIdStr,"^",j)
			 .s RegSerBillSubType=..GetRegArcimBillSubType(ArcimId)
			 .If SerIdStrTemp'="" Set SerIdStrTemp=SerIdStrTemp_"^"_ArcimId
			 .If SerIdStrTemp="" Set SerIdStrTemp=ArcimId
			 Set SerIdStr=SerIdStrTemp
		 }
	 }
	 //add by guorongyong  20090526  老干门诊2%挂号费?诊察费全免
	 if (OldManCardId'="")&&((SocialStatus="26")||(SocialStatus="27")) {
	     set SerIdStrTemp=""
	     f i=1:1:$l(SerIdStr,"^") {
		     s ArcimId=$P(SerIdStr,"^",i)
		     i (ArcimId="") {continue}
		     s RegSerBillSubType=..GetRegArcimBillSubType(ArcimId)
		     i (RegSerBillSubType="Check") s ArcimId="6336||1"
		     If SerIdStrTemp="" Set SerIdStrTemp=ArcimId
		     If SerIdStrTemp'="" Set SerIdStrTemp=SerIdStrTemp_"^"_ArcimId 
	     }
	     Set SerIdStr=SerIdStrTemp
	 }
	 
	 Q SerIdStr
	 
MentalityFrist(PAPERRowid)
	 ;心理门诊首诊判断	
	 s Flag=0
	 s PAADMRowID="" F  s PAADMRowID=$O(^PAPERdr(PatientID,"ADM","O",PAADMRowID)) Q:PAADMRowID=""  d
	 .Q:PAADMRowID=""
	 .s VisitStatus=$p($g(^PAADM(PAADMRowID)),"^",20)  //Edited  By ChenWenGang,2009.08.16
	 .Q:VisitStatus'="A"    //Edited  By ChenWenGang,2009.08.16
	 .Q:'$D(^PAADM(PAADMRowID))
	 .s DepDr=$P(^PAADM(PAADMRowID),"^",4)
	 .s AdmDocDr=$P(^PAADM(PAADMRowID),"^",9)
	 .i DepDr="184" s Flag=Flag+1
	 .;i DepDr="229" s Flag=Flag+1
	 Q Flag
MentalityFristXN(PAPERRowid,ASRowId)
	 ;心理门诊首诊判断	
	 s Flag=0
	 q:$g(PatientID)="" Flag  //Edited  By ChenWenGang,2009.08.16
	 s PAADMRowID="" F  s PAADMRowID=$O(^PAPERdr(PatientID,"ADM","O",PAADMRowID)) Q:PAADMRowID=""  d
	 .Q:PAADMRowID=""
	 .s VisitStatus=$p($g(^PAADM(PAADMRowID)),"^",20)  //Edited  By ChenWenGang,2009.08.16
	 .Q:VisitStatus'="A"    //Edited  By ChenWenGang,2009.08.16
	 .Q:'$D(^PAADM(PAADMRowID))
	 .s DepDr=$P(^PAADM(PAADMRowID),"^",4)
	 .s AdmDocDr=$P(^PAADM(PAADMRowID),"^",9)
	 .s LocAdmDocDr="",SessType=""
	 .s RESDeptDr=""
	 .if (ASRowId'="") d
	 ..s LocAdmDocDr=$P(^RB("RES",+ASRowId),"^",2)
	 ..S RESDeptDr=$p(^RB("RES",+ASRowId),"^",1)
	 ..s SessTypeDr=$p(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC"),"^",6)
	 ..if SessTypeDr'="" s SessType=$p(^RBC("SESS",SessTypeDr),"^",1)
	 .i (DepDr="229")&&(LocAdmDocDr=AdmDocDr) d
	 ..if (SessType="12") s Flag=Flag+1
	 .;q:RESDeptDr="229"
	 .i DepDr="184" s Flag=Flag+1
	 Q Flag
}

ClassMethod GetDHCDiagnosIcdCat()
{
 Set RetStr=""
 Set CatRowid=0  For  Set CatRowid=$O(^DHCDiagnosCat(CatRowid)) Q:CatRowid=""  Do
 .Set BillTypeDR=$P(^DHCDiagnosCat(CatRowid),"^",3)
 .Set CatDesc=$P(^DHCDiagnosCat(CatRowid),"^",1)
 .Set DiagnosCode=$P(^DHCDiagnosCat(CatRowid),"^",6)
 .Set CatDesc=CatDesc_" "_DiagnosCode
 .If RetStr="" Set RetStr=BillTypeDR_$c(1)_CatRowid_$c(1)_CatDesc
 .Else  Set RetStr=RetStr_"^"_BillTypeDR_$c(1)_CatRowid_$c(1)_CatDesc
 Q RetStr
}

/// w ##class(web.DHCOPAdmReg).GetDefaultBillType("22","2")
ClassMethod GetDefaultBillType(PatCatDr As %String, HospID As %String = "") As %String
{
	set AdmReason=""
	q:PatCatDr="" AdmReason
	s HospID=##Class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospID)
	s DefHospId=##class(DHCDoc.Common.Hospital).GetDefHospIdByTableName("DHC_PACADM",HospID)
	/*i PatCatDr'="" set DHCPACADMDr=$o(^DHCPACADM(0,"Social",PatCatDr,""))
	i $g(DHCPACADMDr)'="" set AdmReason=$p(^DHCPACADM(DHCPACADMDr),"^",2)*/
	s DefaultAdmReason=""
	s DHCPACADMDr=""
	for {
		set DHCPACADMDr=$o(^DHCPACADM(0,"Social",PatCatDr,DHCPACADMDr))
		q:DHCPACADMDr=""
		s DHCPACHosp=$p(^DHCPACADM(DHCPACADMDr),"^",5)
		continue:((DHCPACHosp'="")&&(DefHospId'="")&&(DHCPACHosp'=DefHospId))
		s StDate=$p($g(^PAC("ADMREA",DHCPACADMDr)),"^",3)
		continue:(StDate>+$H)&&(StDate'="")
		s EndDate=$p($g(^PAC("ADMREA",DHCPACADMDr)),"^",4)
		continue:(EndDate<+$H)&&(EndDate'="")
		set AdmReason=$p(^DHCPACADM(DHCPACADMDr),"^",2)
		;病人类别与费别的对照支持维护是否默认,与挂号界面一致,取第一条默认数据
		set PACDefault=$p($g(^DHCPACADM(DHCPACADMDr)),"^",6)
		if ((PACDefault="Y")&&(DefaultAdmReason="")) s DefaultAdmReason=AdmReason
	}
	if (DefaultAdmReason'="") s AdmReason=DefaultAdmReason
	Q AdmReason
}

ClassMethod GetExcludeFeeStr(PatientID As %String) As %String
{
	Q:'$d(^PAPER(PatientID,"PER",1)) ""
	s PACCATRowId=$P(^PAPER(PatientID,"PER",1),"^",10)
	Q:'$d(^CT("SS",PACCATRowId,"DHC")) ""
	s ExcludeRegFee=$P(^CT("SS",PACCATRowId,"DHC"),"^",1)
	s ExcludeCheckFee=$P(^CT("SS",PACCATRowId,"DHC"),"^",2)
	Q ExcludeRegFee_"^"_ExcludeCheckFee
}

ClassMethod GetFeeType() As %String
{
 Set RetStr=""
 Set myBMRowid=""
 For  Set myBMRowid=$O(^PAC("ADMREA",myBMRowid)) q:(myBMRowid="")  d
 .Set mydes=$p(^PAC("ADMREA",myBMRowid),"^", 2)
 .If RetStr="" Set RetStr=myBMRowid_$c(1)_mydes
 .Else  Set RetStr=RetStr_"^"_myBMRowid_$c(1)_mydes
 Q RetStr

	s ret1=""
	s RowId=0 f  Set RowId=$o(^PAC("ADMREA",RowId)) Quit:RowId=""  d
	.s Desc=$p(^PAC("ADMREA",RowId),"^",2)
	.s ret=RowId_$C(1)_Desc
	.i ret1="" s ret1=ret
	.e  s ret1=ret_"^"_ret1
 Q ret1
}

ClassMethod GetHospitalCode()
{
	s HospitalRowId=$O(^CT("HOSP",0))
	Q:HospitalRowId="" ""
	s HospitalNationalCode=$P(^CT("HOSP",HospitalRowId),"^",7)
	Q HospitalNationalCode
}

ClassMethod GetINVPRTOrdStr(InvoiceId As %String) As %String
{
	s PRTOrdStr=""
	Q:InvoiceId="" PRTOrdStr
	S ACCPINVDR=$P($G(^DHCINVPRT(InvoiceId)),"^",4)	
	;S AccPayCount=$P($G(^DHCINVPRT(InvoiceId)),"^",1)
	s PRTPatientShare=$p(^DHCINVPRT(InvoiceId),"^",16)
	s AccPayCount=PRTPatientShare
	If ACCPINVDR'="" Do
	.Set OEORDStr=""
	.Set BCIRowid=$O(^DHCBCI(0,"INV",InvoiceId,-1))
	.Q:BCIRowid=""
	.Set BillRowid=$P($G(^DHCBCI(BCIRowid)),"^",2)
	.Q:BillRowid=""
	.Set PBOChild=0 For  Set PBOChild=$O(^DHCPB(+BillRowid,"O",PBOChild)) Q:PBOChild=""  Do
	..Set PBOOEORIDR=$P($G(^DHCPB(+BillRowid,"O",PBOChild)),"^",4)
	..Q:PBOOEORIDR=""
	..If OEORDStr=""  Set OEORDStr=PBOOEORIDR
	..Else  Set OEORDStr=OEORDStr_"^"_PBOOEORIDR
	.Set PRTOrdStr=InvoiceId_$c(3)_OEORDStr_$c(3)_0_$c(3)_AccPayCount
	Q PRTOrdStr
}

/// 得到发票退费时的状态
ClassMethod GetINVRefundStatus(InvoiceId As %String, UserRowId As %String)
{
	;w Class(web.DHCOPAdmReg).GetINVRefundStatus(967)
	;发票状态
	s Flag=$p(^DHCINVPRT(InvoiceId),"^",8)
	s PrtFlag=$p(^DHCINVPRT(InvoiceId),"^",3)
	s InvNo=$p(^DHCINVPRT(InvoiceId),"^",14)
	s HandIn=$p(^DHCINVPRT(InvoiceId),"^",10)
	s accPINVDR=$P($G(^DHCINVPRT(InvoiceId)),"^",4)	
	s User=$p(^DHCINVPRT(InvoiceId),"^",21)
	s Status=""
	;w InvNo_"^"_Flag_"^"_PrtFlag
	if ((InvNo="")&(Flag="N")&(PrtFlag'="P")) ! ((InvNo'="")&(Flag="N")&(PrtFlag="P")) ! ((InvNo="")&(Flag="N")&(accPINVDR'="")) {
		if (User'=UserRowId) {
			s Status="S"
		}else {
			if (HandIn="Y"){
				s Status="S"
			}else {
				s Status="A"
			}
		}
	}
	Q Status
}

/// Creator:      周志强
/// CreatDate:    2009.02.26
/// Description:  得到与费别对应的医保医疗类别
/// Table:        DHC_BillTypeInsurEPType,INSU_DicData
/// Input:        BillTypeRowId:费别      EpisodeType:诊别
/// Return:       返回医保医疗类别串(代码,名称,默认标志)
ClassMethod GetInsurEPTypeStr(BillTypeRowId As %String, EpisodeType As %String) As %String
{
	;w ##class(web.DHCOPAdmReg).GetInsurEPTypeStr(20,"O")
	s ret1=""
	s Childsub=0 f  Set Childsub=$o(^PAC("ADMREA",BillTypeRowId,"INSUR",Childsub)) Quit:Childsub=""  d
	.s str=$G(^PAC("ADMREA",BillTypeRowId,"INSUR",Childsub))
	.s BIEpisodType=$P(str,"^",1)
	.Q:BIEpisodType'=EpisodeType
	.s InsurEPTypeRowId=$P(str,"^",2)
	.s default=$P(str,"^",3)
	.s DicCode=$P(^DHCINDID(InsurEPTypeRowId),"^",2)
	.s DicDesc=$P(^DHCINDID(InsurEPTypeRowId),"^",3)
	.s ret=DicCode_$C(1)_DicDesc_$C(1)_default
	.i ret1="" s ret1=ret
	.e  s ret1=ret1_"^"_ret
 	Q ret1
}

ClassMethod GetMRFee(HospId As %String = "") As %String
{
	i ($g(HospId)="")&&($d(%session)) s HospId=%session.Get("LOGON.HOSPID")
	s ArcimId=..GetMRFeeArcimId(HospId)
	Q:ArcimId="" 0
	s BillPrice=$p(##Class(web.UDHCJFPRICE).GetOrderPrice("","",ArcimId,+$H,"","","","",HospId),"^",4)
	Q BillPrice
}

ClassMethod GetMRFeeArcimId(HospId As %String = "") As %String
{
	Q $p(##class(web.DHCOPRegConfig).GetSpecConfigNode("MRArcimId",HospId),"@",1)
	/*
	s HospitalCode=..GetHospitalCode()
	if HospitalCode="YKDYY" {
		s ARCIMSubscript=$O(^ARCIM(0,"Code","CZJBLSC",""))
		s ARCIMVersion=$O(^ARCIM(0,"Code","CZJBLSC",ARCIMSubscript,""))
		Q ARCIMSubscript_"||"_ARCIMVersion
	}elseif(HospitalCode="SZZYY") {
		s ARCIMSubscript=$O(^ARCIM(0,"Code","11010000102",""))
		s ARCIMVersion=$O(^ARCIM(0,"Code","11010000102",ARCIMSubscript,""))
		Q ARCIMSubscript_"||"_ARCIMVersion
	}else{
		
		Q $p(##class(web.DHCOPRegConfig).GetSpecConfigNode("MRArcimId"),"@",1)
	}
	*/
}

/// 根据排班id+患者信息,获取排班相关信息
/// w ##class(web.DHCOPAdmReg).GetMarkRegFee("226||48","4","67","","","","")
ClassMethod GetMarkRegFee(ASRowId As %String, BillTypeDR As %String, PatientID As %String = "", AppMethodCode As %String = "", RegConDisId As %String = "", GroupID As %String = "", ClinicGroupId As %String = "") As %String
{
	s ^zhou("GetMarkRegFee")=$lb(ASRowId,BillTypeDR,PatientID,AppMethodCode,RegConDisId,GroupID,ClinicGroupId)
	s langid=..%LanguageID()
	Q:ASRowId="" ""
	
	s ResRowId=$p(ASRowId,"||",1)
	s ASChildSub=$p(ASRowId,"||",2)
	;不排除排班被删除的可能,需先判断排班是否存在
	Q:'$d(^RBAS(+ResRowId,ASChildSub)) ""
	;根据释放时间自动释放锁表锁号
	d ##Class(web.DHCLockSchedule).UnLockSchedule(ASRowId)
	;过时段号源不能挂出并增号(增加到最后一个时段)
	s HospId=$p(..GetCurrentHosp("","",ASRowId,""),"^",1)
	d ##class(web.DHCRBAppointment).SeqNoOverRangeTimeAdd(ASRowId,HospId)
	;排班日期
	s ASDate=$p($g(^RBAS(ResRowId,ASChildSub)),"^",1)
	s ASDateWeek=""
	if (ASDate'="") {
		s ASDateWeek=..ConvertDateToWeek(ASDate)
		s:ASDateWeek'="" ASDateWeek = ..%Translate("opadm.reg.hui.csp",ASDateWeek,langid)
		s ASDate=..%ZD(ASDate)
	}
	if (AppMethodCode="") s AppMethodCode="WIN"
	s AppMethodCodeDR=$o(^RBC("APTM",0,"Code",AppMethodCode,0))
	s NoLimitLoadFlag=##class(web.DHCRBApptSchedule).GetASNoLimitLoadFlag(ASRowId)	//便捷排班标志
	;正号限额、预约限额、加号限额
	s Load=$p($g(^RBAS(ResRowId,ASChildSub)),"^",8)
	if (NoLimitLoadFlag="Y") {
		s AppLoad=Load	 
	}else{
		s AppLoad=$p($g(^RBAS(ResRowId,ASChildSub)),"^",2) 
		s WinMethodAppLoad=##class(web.DHCRBAppointment).GetAppSeqNo(ASRowId,AppMethodCode,"")	//##class(web.DHCRBAppointment).GetAvailableNum(ASRowId,"APP",AppMethodCode,"")  //##class(web.DHCRBApptScheduleAppQty).GetAPPMethodQty(ASRowId,"WIN")
		s AppLoad=WinMethodAppLoad
	}
	s AddLoad=$p($g(^RBAS(ResRowId,ASChildSub,"DHC")),"^",3)
	if (AddLoad="") s AddLoad=0
	;剩号数、预约数、现场剩号数、加号数
	s AvailSeqNoStr=##class(web.DHCRBAppointment).GetAvailableNum(ASRowId,"NOR",AppMethodCode,"","","","",ClinicGroupId)	//##class(web.DHCRBApptSchedule).GetAvailSeqNoStr(ASRowId,"NOR")
	s AvailAppSeqNo=##class(web.DHCRBAppointment).GetAvailableNum(ASRowId,"APP",AppMethodCode,"","","","",ClinicGroupId)	//##class(web.DHCRBApptSchedule).GetAvailSeqNoStr(ASRowId,"APP",AppMethodCodeDR)
	;由于修改了号源获取规则,旧版本现场剩号的计算方式不再试用,此处改为返回当日可挂数量(NORN -> NOR)
	s AvailNorSeqNo=##class(web.DHCRBAppointment).GetAvailableNum(ASRowId,"NOR",AppMethodCode,"","","","",ClinicGroupId)	//##class(web.DHCRBApptSchedule).GetAvailSeqNoStr(ASRowId,"NORN")
	s AvailAddSeqNo=##class(web.DHCRBApptSchedule).GetAvailSeqNoStr(ASRowId,"ADD")
	;诊室,亚专业,出诊级别
	s RoomDesc=""
	s RoomDr=$p($g(^RBAS(ResRowId,ASChildSub,"DHC")),"^",5)
	if (RoomDr'="") s RoomDesc=$p($g(^CTLOC(RoomDr)),"^",2)
	s ClinicGroupDesc=""
	s ClinicGroupDr=$p($g(^RBAS(ResRowId,ASChildSub,"DHC")),"^",7)
	if (ClinicGroupDr'="") s ClinicGroupDesc=$p($g(^RBC("CLGRP",ClinicGroupDr)),"^",2)
	if ($g(ClinicGroupDesc)'="") s ClinicGroupDesc=##class(User.RBCClinicGroup).GetTranByDesc("CLGRPDesc",ClinicGroupDesc,langid)
	s SessionClinicGroupDrStr=""
	s ClinicGroupStr=##class(web.DHCApptScheduleNew).GetClinicGroupDrStr(ASRowId)
	if ClinicGroupStr'=""{
		s SessionClinicGroupDrStr=$p(ClinicGroupStr,"^",1)
		s ClinicGroupDesc=$p(ClinicGroupStr,"^",2)
	}
	s SessionTypeDesc=""
	s SessionTypeDr=$p($g(^RBAS(ResRowId,ASChildSub,"DHC")),"^",6)
	if (SessionTypeDr'="") s SessionTypeDesc=$p($g(^RBC("SESS",SessionTypeDr)),"^",2)
	if ($g(SessionTypeDesc)'="") s SessionTypeDesc=##class(User.RBCSessionType).GetTranByDesc("SESSDesc",SessionTypeDesc,langid)
	;出诊开始时间、时段
	s StartTime=$p($g(^RBAS(ResRowId,ASChildSub)),"^",4)
	s TRDesc="其他"
	s TRRowId=$p($g(^RBAS(ResRowId,ASChildSub,"DHC")),"^",17)
	if (TRRowId'="") s TRDesc=$p($g(^DHCTimeRange(TRRowId)),"^",2)
	if ($g(TRDesc)'="") s TRDesc=##class(User.DHCTimeRange).GetTranByDesc("TRDesc",TRDesc,langid)
	;出诊状态
	s statuscode="",statusDesc=""
	s status=$p($g(^RBAS(ResRowId,ASChildSub,"DHC")),"^",10)
	if (status'="") {
		s statuscode=$P(^DHCRBCASStatus(status),"^",1)
		s statusDesc=$P(^DHCRBCASStatus(status),"^",2)
		if ($g(statusDesc)'="") s statusDesc=##class(User.DHCRBCASStatus).GetTranByDesc("ASSDesc",statusDesc,langid)
	}
	s statusreason=$P($G(^RBAS(ResRowId,ASChildSub,"DHC")),"^",11)
	;号源使用情况(1.当日挂号数(包括正号、加号)+取号数,2.预约未取号数+预约已取号数,3.预约已取号数,4.加号使用数(包括挂号、预约、取号))
	s UsedSeqNoCount=##class(web.DHCRBApptSchedule).GetUsedSeqNoCount(ASRowId)
	s RegedCount=$P(UsedSeqNoCount,"^",1)
	s AppedCount=$P(UsedSeqNoCount,"^",2)
	s AddedCount=$P(UsedSeqNoCount,"^",3)
	s AppedArriveCount=$P(UsedSeqNoCount,"^",4)
	/*s AppedCount=(+AppedCount)-(+AppedArriveCount)
	if (AppedCount>=AppLoad){s AvailAppSeqNo="" }*/
	;取价格
	s Price=0,chrhfee=0,holi=0,AppFee=0,OtherFee=0,ReCheckFee=0
	s PriceArcId="",chrhfeeArcId="",holiId="",AppFeeId="",OtherFeeId=""
	s AdmReason=BillTypeDR
	s HospId=$p(..GetCurrentHosp("","",ASRowId,""),"^",1)
	s AdmDate=$p($g(^RBAS(+ASRowId,$p(ASRowId,"||",2))),"^",1)
	;取挂号费和诊查费和节假日挂号费信息
	s SerIdStr=..GetScheduleService(ASRowId,AdmReason,HospId)
	;取附加费用信息(挂号设置->挂号附加医嘱设置)
	s SerIdStr=..GetCustomScheduleService(PatientID,ASRowId,SerIdStr)
	if (RegConDisId=""){
		s RegConDisIdPara=PatientID_"^"_ASRowId_"^"_AdmReason_"^"_""
		s RegConDisId=..GetRegConDisId(RegConDisIdPara)
	}
	s AdmLoc=$p($g(^RB("RES",+ASRowId)),"^",1)
	s AdmType="O"
	if (AdmType'="E") {
		s IsEmergency=..IsEmergency(AdmLoc)
		if IsEmergency="1" s AdmType="E"
	}
	/*if (GroupID'=""){
		s OPRegInsertOrder=##class(web.DHCOPRegConfig).GetGroupConfig(HospId,GroupID,"OPRegInsertOrder")
		if (OPRegInsertOrder=1) s SerIdStr=""
	}*/
	s PriceExpStr=RegConDisId_"^^^^^^^^"_PatientID_"^"_AdmType
	s ReAdmFeeFlag=##class(web.DHCOPAdmReg).GetReAdmFeeFlag(PatientID,ASRowId)
	if (SerIdStr'="") {
		for i=1:1:$l(SerIdStr,"^") {
			;s SerId=$p(SerIdStr,"^",i)
			;s ArcimId=$p($g(^RBC("SER",SerId)),"^",1)
			s ArcimId=$P(SerIdStr,"^",i)
			s BillPrice=$p(##class(web.UDHCJFPRICE).GetOrderPrice("",AdmReason,ArcimId,AdmDate,"","","","",HospId,PriceExpStr),"^",4)
			;s RegSerBillSubType=..GeRegSerBillSubType(SerId)
			s RegSerBillSubType=..GetRegArcimBillSubType(ArcimId,HospId)
			if (RegSerBillSubType="Reg") {	//挂号费
				;s PriceArcId=PriceArcId_"$"_ArcimId
				s Price=BillPrice+Price
			}
			if ((RegSerBillSubType="Check")&&(ReAdmFeeFlag=0)) {	//诊查费
				;s chrhfeeArcId=chrhfeeArcId_"$"_ArcimId
				s chrhfee=BillPrice+chrhfee
			}
			if (RegSerBillSubType="Holi") {	//假日费
				;s holiId=holiId_"$"_ArcimId
				s holi=BillPrice+holi
			}
			if (RegSerBillSubType="App") {	//预约费
				;s AppFeeId=AppFeeId_"$"_ArcimId
				s AppFee=BillPrice+AppFee
			}
			if ((RegSerBillSubType="ReCheck")&&(ReAdmFeeFlag=1)) {	//复诊费
				;s OtherFeeId=OtherFeeId_"$"_ArcimId
				s ReCheckFee=BillPrice+ReCheckFee
			}
			;在出诊级别设置界面进行限制,防止出现职称绑定后,修改了账单子组价格计算不一致的问题
			if ((RegSerBillSubType="Other")||(RegSerBillSubType="NotRegFee")) {	//其它费
				;s OtherFeeId=OtherFeeId_"$"_ArcimId
				s OtherFee=BillPrice+OtherFee
			}
		}
	}
	s re=Load_"^"_AppLoad_"^"_AddLoad_"^"_AvailSeqNoStr_"^"_AvailAddSeqNo_"^"_RoomDesc_"^"_RoomDr	//1-7
	s re=re_"^"_ClinicGroupDesc_"^"_ClinicGroupDr_"^"_SessionTypeDesc_"^"_SessionTypeDr		//8-11
	s re=re_"^"_$fn(Price,"-")_"^"_$g(PriceArcId)_"^"_$fn(chrhfee,"-")_"^"_$fn(ReCheckFee,"-")	//12-15
	s re=re_"^"_$fn(holi,"-")_"^"_holiId_"^"_$fn(AppFee,"-")_"^"_AppFeeId_"^"_$fn(OtherFee,"-")	//16-20
	s re=re_"^"_TRDesc_"^"_RegedCount_"^"_AppedCount_"^"_AddedCount_"^"_AvailAppSeqNo		//21-25
	s re=re_"^"_AvailNorSeqNo_"^"_statusDesc_"^"_ASDate_"^"_ASDateWeek_"^"_AppedArriveCount	//26-30
	s re=re_"^"_NoLimitLoadFlag		//31-
	Q re
}

ClassMethod GetMenuIDByName(name As %String) As %String
{
	&SQL(SELECT ID Into :MenuID FROM websys.Menu WHERE Name = :name)
	if 'SQLCODE Q MenuID
	Q ""
}

ClassMethod GetMultiDateAvailRA(RowId As %String, DateStr As %String, AdmTime As %String, TimeRangeRowId As %String, SelectTRQuery As %String = "", ShowStopFlag As %String = "") As %String
{
	s Str=""
	F i=1:1:$L(DateStr,"^") {
		s AdmDate=$P(DateStr,"^",i)
		s ASRowIdStr=##Class(web.DHCRBApptSchedule).GetAvailRA(RowId,AdmDate,AdmTime,TimeRangeRowId,SelectTRQuery,"",ShowStopFlag)
		if ASRowIdStr'="" {
			i Str="" s Str=ASRowIdStr
			e  s Str=Str_"^"_ASRowIdStr
		}
	}
	Q Str
}

ClassMethod GetMultiPrintMarkCodeStr() As %String
{
	;w ##class(web.DHCOPAdmReg).GetMultiPrintMarkCodeStr()
	s ret1=""
	s loc=0 f  Set loc=$o(^RB("RES",0,"CTLOC",loc)) quit:loc=""  d
	.s RowId=0 f  Set RowId=$o(^RB("RES",0,"CTLOC",loc,RowId)) quit:RowId=""  d
	..s CTPCPRowId=$P(^RB("RES",RowId),"^",2)
	..s CTLocRowId=$P(^RB("RES",RowId),"^",1)
	..;如果非医生则退出
	..Q:(CTPCPRowId="")!(CTLocRowId="")
	..;判断是否需要排班
	..s ScheSt=$p(^RB("RES",RowId),"^",6)
	..Q:(ScheSt'="Y")
	..s CTPCPDesc=$p(^CTPCP(CTPCPRowId,1),"^",2)
	..s CTLocDesc=$p($g(^CTLOC(CTLocRowId)),"^",2)
	..Q:CTPCPDesc'[("便民")
	..set ret=RowId_$C(1)_CTPCPDesc
 ..i ret1="" s ret1=ret
 ..e  s ret1=ret_"^"_ret1
 Q ret1
}

ClassMethod GetNotAvailDate()
{
	;w ##class(web.DHCOPAdmReg).GetNotAvailDate()
	s ret=""
	&sql(DECLARE MyCursor CURSOR FOR  SELECT FESTDate FROM SQLUser.DHC_OPRegFestivalSet)
	&sql(OPEN MyCursor)
	For  &sql(FETCH MyCursor  INTO :FESTDate) q:SQLCODE  d
	.if ret="" s ret=FESTDate
	.e  s ret=ret_"^"_FESTDate
	&sql(CLOSE MyCursor)
	Q ret
}

ClassMethod GetOPDeptStr(UserId As %String, AdmType As %String, Group As %String = "") As %String
{
	;w ##class(web.DHCOPAdmReg).GetOPDeptStr(272,"O")
	s ret1=""
	s AllRegDepString=..GetAllRegDepString(Group)
	Set rset=##class(%ResultSet).%New("web.DHCOPAdmReg:OPDeptList")
	do rset.Execute(UserId,AdmType)
	Set columns = rset.GetColumnCount()
	set row=0
	While (rset.Next()) {
		set RowId=rset.GetData(1)
		continue:(AllRegDepString'="")&&(AllRegDepString'[("^"_RowId_"^"))     //兼容如果科室里面没有可以挂号的医生，那么不显示
		s DepGroupDR=""
		;set DepGroupDR=$P(^CTLOC(RowId),"^",19)
		if (DepGroupDR'="") {
			i '$d(CacheTemp($J,"OPRegDepGroup",DepGroupDR)) {
				s CacheTemp($J,"OPRegDepGroup",DepGroupDR)=RowId
			}else{
				s CacheTemp($J,"OPRegDepGroup",DepGroupDR)=CacheTemp($J,"OPRegDepGroup",DepGroupDR)_$C(2)_RowId
			}
		}else {
			set Deptdesc=rset.GetData(2) //$p(rset.GetData(2),"-",2)
			if $l(Deptdesc,"-")>1,$p(Deptdesc,"-",2)'="" set Deptdesc=$p(Deptdesc,"-",2)
			set Alias=rset.GetData(3)
			if Alias="" Set Alias=$p(rset.GetData(2),"-",1)
			set ret=rset.GetData(1)_$C(1)_Deptdesc_"-"_Alias  //guorongyong 2008-03-20
			;set ret=rset.GetData(1)_$C(1)_rset.GetData(2)_"-"_rset.GetData(3)
		    i ret1="" s ret1=ret
		    e  s ret1=ret_"^"_ret1
		}
	}
	
	i $d(CacheTemp($J,"OPRegDepGroup")) {
		s DepGroupDR=0  f  s DepGroupDR=$O(CacheTemp($J,"OPRegDepGroup",DepGroupDR)) Q:DepGroupDR=""  d
		.Q:'$D(^RBC("DEP",DepGroupDR))
		.s DepGroupDesc=$P(^RBC("DEP",DepGroupDR),"^",2)
		.s LocRowIdStr=CacheTemp($J,"OPRegDepGroup",DepGroupDR)
		.s FirstLocRowId=$P(LocRowIdStr,$C(2),1)
		.s CTAlias=$P(^CTLOC(FirstLocRowId),"^",43)
		.s DepGroupData=LocRowIdStr_$C(1)_DepGroupDesc_"-"_CTAlias
		.i ret1="" s ret1=DepGroupData
		.e  s ret1=ret1_"^"_DepGroupData
	}
	
	d rset.Close()
	Q ret1
}

ClassMethod GetOldDoc(itmjs As %Library.String = "", itmjsex As %Library.String = "", RegNo As %Library.String = "", nday As %Library.String = "")
{
	s desc=0
	//Set repid=$I(^CacheTemp)
	s n=nday
	i n="" d  s n=0
	s cdate=..%SysDate()
	s edate=..%SysDate()-n

	s InvoiceId=""
	s Admdepcode="",admdep="",Admdoccode="",admdoc="",admdate=""
	s Arcdr="",Arcp="",ph=""
	If $g(ind)="" Set ind=1
	Set Adm=0,i=0
	If $g(RegNo)'="" do
	.Set PAPMI=$o(^PAPERi("PAPMI_PatNo",$ZCVT(RegNo,"U"),0))
	.If $g(PAPMI)="" Quit
	.f  Set Adm=$o(^PAPERdr(PAPMI,"ADM","O",Adm)) quit:Adm=""  d
	..s VisitStatus=$p($g(^PAADM(Adm)),"^",20)
	..i VisitStatus'="A" d  q 
	..s admdate=$p($g(^PAADM(Adm)),"^",6)
	..f k=edate:1:cdate d
	...i admdate'=k d  q 
	...s kdate=$zd(admdate,1)
	...s Admdepcode=$p($g(^PAADM(Adm)),"^",4)
	...s admdep=$p($g(^CTLOC(Admdepcode)),"^",2)
	...s Admdoccode=$p($g(^PAADM(Adm)),"^",9) 
	...i Admdoccode="" s admdoc="aa" 
	...e  s admdoc=$p($g(^CTPCP(Admdoccode,1)),"^",2)
	...s AdmTime=..%ZT($p($g(^PAADM(Adm)),"^",7),3)
	
	...s Cuserid=$p($g(^PAADM(Adm)),"^",43)
	...i Cuserid="" s Username="bb" 
	...s Admi=Adm
	...e  s Username=$p($g(^SSU("SSUSR",Cuserid)),"^",2)
	...S I=$O(^User.DHCRegistrationFeeI("ADM",Admi,""))
	...if I'="" d
	....s Arcdr=$List(^User.DHCRegistrationFeeD(I),3)
	....s Arcp=$List(^User.DHCRegistrationFeeD(I),4)
	....s ph=$List(^User.DHCRegistrationFeeD(I),8)
	....s InvoiceId=$List(^User.DHCRegistrationFeeD(I),11)
	....s i=i+1
	...if (desc=0) d
	....s desc=Admdepcode_"^"_admdep_"^"_Admdoccode_"^"_admdoc_"^"_AdmTime_"^"_Username_"^"_Adm_"^"_Arcp_"^"_Arcdr_"^"_RegNo_"^"_ph_"^"_InvoiceId_"^"_kdate
	...e  d
	....s desc=desc_"!"_Admdepcode_"^"_admdep_"^"_Admdoccode_"^"_admdoc_"^"_AdmTime_"^"_Username_"^"_Adm_"^"_Arcp_"^"_Arcdr_"^"_RegNo_"^"_ph_"^"_InvoiceId_"^"_kdate
	if itmjs'="" 
	.s retval=itmjs_"('"_$ZCVT(desc,"O","JS")_"');"
	.&javascript<#(retval)#>
	q desc
}

ClassMethod GetPADayAdmCount(PARowId As %String, AdmType As %String, FindDate As %String, FindDep As %String, FindDoc As %String, TimeRangeID As %String = "")
{
	s ^tempqujian("GetPADayAdmCount")=PARowId_","_AdmType_","_FindDate_","_FindDep_","_FindDoc_","_TimeRangeID
	s FindDepHospDr=$p(^CTLOC(FindDep),"^",22)
	s Count=0,AdmDocCount=0,AdmLocCount=0,AdmTimeDocLoc=0
	s AdmRowId=0 f  s AdmRowId=$O(^PAPERdr(PARowId,"ADM",AdmType,AdmRowId)) Q:AdmRowId=""  d
	.s AdmHospitalId=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(AdmRowId)
	.Q:AdmHospitalId'=FindDepHospDr
	.s AdmDate=$p($g(^PAADM(AdmRowId)),"^",6)
	.s AdmDep=$P($g(^PAADM(AdmRowId)),"^",4)
	.s AdmDoc=$P($g(^PAADM(AdmRowId)),"^",9)
	.s AdmStatus=$P($g(^PAADM(AdmRowId)),"^",20)
	.Q:AdmStatus'="A"
	.s TRRowid=""
	.s Admi=AdmRowId
	.S RegfeeRowId=$O(^User.DHCRegistrationFeeI("ADM",Admi,""))
	.if RegfeeRowId'="" d
	..s object=##class(User.DHCRegistrationFee).%OpenId(RegfeeRowId)
	..s TRRowid=object.RegfeeTimeRangeDr.%Id()
	.i FindDate=AdmDate s Count=Count+1
	.i ((FindDep=AdmDep)&(AdmDoc=FindDoc)&(FindDate=AdmDate)) s AdmDocCount=AdmDocCount+1
	.i ((FindDep=AdmDep)&(FindDate=AdmDate)) s AdmLocCount=AdmLocCount+1
	.i ((FindDep=AdmDep)&(AdmDoc=FindDoc)&(FindDate=AdmDate)&(TimeRangeID=TRRowid)) s AdmTimeDocLoc=AdmTimeDocLoc+1
	Q Count_"^"_AdmDocCount_"^"_AdmLocCount_"^"_AdmTimeDocLoc
}

ClassMethod GetPADayAppCount(PARowId As %String, FindASRowId As %String, APPTRowId As %String = "") As %String
{
	;w ##class(web.DHCOPAdmReg).GetPADayAppCount(186421,"299||2")
	s AppCount=0,AppDocCount=0,AppLocCount=0,AppTimeDocLoc=0
	s statuscode="I"
	s FindASDate=$P($G(^RBAS(+FindASRowId,$P(FindASRowId,"||",2))),"^",1)
	s TimeRangeDr=$P($G(^RBAS(+FindASRowId,$P(FindASRowId,"||",2),"DHC")),"^",17)
	s FindASLoc=$P($G(^RB("RES",+FindASRowId)),"^",1)
	s ASDoc=$p(^RB("RES",+FindASRowId),"^",2)
	s ResRowId=0 f  s ResRowId=$O(^PAPERDR(PARowId,"RB_Appt",statuscode,ResRowId)) Q:ResRowId=""  d
	.s ASChild=0 f  s ASChild=$O(^PAPERDR(PARowId,"RB_Appt",statuscode,ResRowId,ASChild)) Q:ASChild=""  d
	..s APPTChild=0 f  s APPTChild=$O(^PAPERDR(PARowId,"RB_Appt",statuscode,ResRowId,ASChild,APPTChild)) Q:APPTChild=""  d
	...//APPTRowId-预约取号时的预约ID,预约取号时本条预约记录不计算在内,否则挂号限额设置为1，能预约/加号成功但不能取号
	...s ASRowId=ResRowId_"||"_ASChild
	...Q:((ASRowId_"||"_APPTChild)=APPTRowId)
	...s ASDate=$P($G(^RBAS(ResRowId,ASChild)),"^",1)
	...i FindASDate=ASDate s AppCount=AppCount+1
	...s APPDoc=$p(^RB("RES",ResRowId),"^",2)
	...s ASLoc=$P($G(^RB("RES",ResRowId)),"^",1)
	...i ((APPDoc=ASDoc)&(ASLoc=FindASLoc)&(FindASDate=ASDate)) s AppDocCount=AppDocCount+1
	...i (FindASDate=ASDate)&&(ASLoc=FindASLoc) s AppLocCount=AppLocCount+1
	...s ASTimeRange=$P($G(^RBAS(ResRowId,ASChild,"DHC")),"^",17)
	...i (FindASDate=ASDate)&&(ASLoc=FindASLoc)&&(ASRowId=FindASRowId)&&(ASTimeRange=TimeRangeDr) s AppTimeDocLoc=AppTimeDocLoc+1
	Q AppCount_"^"_AppDocCount_"^"_AppLocCount_"^"_AppTimeDocLoc
}

ClassMethod GetPaAdmType(EpisodeID As %String) As %String
{
 s AdmType=$P(^PAADM(EpisodeID,1),"^",7)
 q AdmType
}

ClassMethod GetPaperInfo(PAADMRowid As %String) As %String
{
	s PaperRowid=$P(^PAADM(PAADMRowid),"^",1)
	s Ret=##class(web.DHCDocOrderEntry).GetPatientByRowid(PaperRowid)
	q Ret
}

ClassMethod GetPatDetailBroker(itmjs As %Library.String = "", itmjsex As %Library.String = "", val As %Library.String = "")
{
	;n id,code,desc
    s langid = ..%LanguageID()
	Set (id,code,desc)=""
	s logonHospID=%session.Get("LOGON.HOSPID")
	;
	s PatientNo=..FormatPatientNo(val)
	Set PatDr=$o(^PAPERi("PAPMI_PatNo",$ZCVT(val,"U"),""))
	Quit:PatDr="" 0
	Set Name=$p(^PAPER(PatDr,"ALL"),"^",1)
	set RIDCardNo=$p($g(^PAPER(PatDr,"ALL")),"^",9)
	set PatYBCode=$p($g(^PAPER(PatDr,"PAT",3)),"^",12) //$p($g(^PAPER(PatDr,"ALL")),"^",19) //医保号
	set (CardNo,CardTypeID,IsTempCard)=""
	set CardRowid=""
	f  s CardRowid=$o(^DHCCARDi("CF",0,"PAPMIDR",PatDr,CardRowid)) q:(CardRowid="")||(CardNo'="")  d
	.s ActiveFlag=$P(^DHCCARD("CF",CardRowid),"^",10) 
	.q:ActiveFlag'="N"
	.s CardNo=$P(^DHCCARD("CF",CardRowid),"^",2)       //卡号
	.s CardTypeID=$p($g(^DHCCARD("CF",CardRowid)),"^",16)	//卡类型
	.s IsTempCard=##class(web.DHCBL.CARD.UCardRefInfo).GetTemporaryCardFlag(CardTypeID, CardNo)
	Set DOB=+$p(^PAPER(PatDr,"ALL"),"^",6)
	Set AgeStr=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.reg.GetPapmiAge",PatDr,"",logonHospID,"","","",1)
    Set Age=$p(AgeStr,"||",1)
    Set AgeYear=+$p(AgeStr,"||",2)
	Set Sex=$p(^CT("SEX",$p(^PAPER(PatDr,"ALL"),"^",7)),"^",2)
    Set:$g(Sex)'="" Sex=##class(User.CTSex).GetTranByDesc("CTSEXDesc",Sex,langid)
	Set OPMRN="",IPMRN="",RAddress="",YBType=""
	if $D(^PAPER(PatDr,"PER",4)) {
	    set RAddress=$p(^PAPER(PatDr,"PER",4),"^",18)
	}
	Set OPMRN=##class(web.DHCDocOrderCommon).GetMrNo("",PatDr,"O",$g(%session.Data("LOGON.HOSPID"))) ;门诊病案号
	Set PatCat="",PatCatDesc=""
	if $D(^PAPER(PatDr,"PER",1)) {
		set IPMRN=##class(web.DHCDocOrderCommon).GetMrNo("",PatDr,"I",$g(%session.Data("LOGON.HOSPID"))) ;住院病案号
		Set PatCatDr=$p(^PAPER(PatDr,"PER",1),"^",10)
		i $g(PatCatDr)'="" {
			set PatCatDesc=$p($g(^CT("SS",PatCatDr)),"^",2)   //病人类型描述
            Set PatCatDesc=##class(User.CTSocialStatus).GetTranByDesc("SSDesc",PatCatDesc,langid)
			Set PatCat=$p($g(^CT("SS",PatCatDr)),"^",1)_"."_$p($g(^CT("SS",PatCatDr)),"^",2)
		}
	}

	s PAPERSGMedicareCode1="",PAPERSGMedicareCode2=""
	Set DHCPerRowId=$o(^DHCPERSON(0,"PAPERSON",PatDr,""))
	if DHCPerRowId'="" {
    	Set PAPERSGMedicareCode1=$p(^DHCPERSON(DHCPerRowId),"^",5) //门诊病历号1(妇产西院)
    	Set PAPERSGMedicareCode2=$p(^DHCPERSON(DHCPerRowId),"^",6) //住院病历号1(妇产西院)
	}
	
	s AppBreakCount=##class(web.DHCRBAppointment).GetAppBreakCount(PatDr)
	
	;老年证号,可以根据这个属性用来减免某些费用
	Set OldMan=""
	if $D(^PAPER(PatDr,"ALL")) Set OldMan=$p(^PAPER(PatDr,"ALL"),"^",20)
	
	;在医院是否就诊过
	s GetReAdmParams=##class(%ArrayOfDataTypes).%New()
	d GetReAdmParams.SetAt(PatDr,"PatientID")
	s ReAdmFlag=##class(DHCDoc.DHCDocConfig.ReAdmRules).GetReAdmFlag(GetReAdmParams)
	s EmployeeFunction="",SecretLevel=""
	s PatEncryptLevel=##class(web.DHCBL.CARD.UCardPaPatMasInfo).GetPatEncryptLevel(PatDr,.ErrMsg)
	i PatEncryptLevel'="" {
		s EmployeeFunction=$p(PatEncryptLevel,"^",2)
		s SecretLevel=$p(PatEncryptLevel,"^",4)
	}
	set TelHome=$p($g(^PAPER(PatDr,"PER",1)),"^",11)
	Set PAPERCountry = $s(+$p($g(^PAPER(PatDr,"PER",1)),"^",8)'=0:$p($g(^CT("COU",$p($g(^PAPER(PatDr,"PER",1)),"^",8))),"^",2),1:"")
    Set:$g(PAPERCountry)'="" PAPERCountry=##class(User.CTCountry).GetTranByDesc("CTCOUDesc",PAPERCountry,langid)
	set PAPERForeignAddress = $G(^PAPER(PatDr,"PER","ADD",1))
	s CredType=""
	s myCredTypeID=$p($g(^PAPER(PatDr,"PAT",3)),"^",7)
	s:myCredTypeID'="" CredType=$p($g(^PAC("CARD",myCredTypeID)),"^",2)
    s:$g(CredType)'="" CredType = ##class(User.DHCCredType).GetTranByDesc("CRTDesc",CredType,langid)
	s CredNo=$p($g(^PAPER(PatDr,"PAT",3)),"^",6)
	s PatInIPAdmission=##class(web.DHCDocOrderCommon).CheckPatInIPAdmission(PatDr,logonHospID)
	;死亡标志
	s HospCodeNode="HospDr_"_$g(%session.Data("LOGON.HOSPID"))
	s ForeignInfoByAge=$g(^DHCDocCardConfig(HospCodeNode,"ForeignInfoByAge"))
	s AgeLimitInfo=""		;应该和发卡界面保持一个判断
	if (IsTempCard'="Y")&&(AgeYear<ForeignInfoByAge)&&(AgeYear'=..%Translate("Bill.Com.Age", "未知", langid)){
        s foreignPhoneTrans = ..%Translate("opadm.reg.hui.csp", "联系人电话", langid)
		s foreignNameTrans = ..%Translate("opadm.reg.hui.csp", "联系人姓名", langid)
		s foreignIDCardTrans = ..%Translate("opadm.reg.hui.csp", "联系人证件号码", langid)
		s LimitStr=""
		s ForeignPhone=$p($g(^PAPER(PatDr,"ALL")),"^",4)
		if ForeignPhone="" d
		.s LimitStr=$case(LimitStr,"":foreignPhoneTrans,:foreignPhoneTrans_"、"_LimitStr)
		s ForeignName=$p($g(^PAPER(PatDr,"PER",2)),"^",13)
		if ForeignName="" d
		.s LimitStr=$case(LimitStr,"":foreignNameTrans,:foreignNameTrans_"、"_LimitStr)
		s ForeignIDCard=$p($g(^PAPER(PatDr,"PER",2)),"^",4)
		if ForeignIDCard="" d
		.s LimitStr=$case(LimitStr,"":foreignIDCardTrans,:foreignIDCardTrans_"、"_LimitStr)
		s:LimitStr'="" AgeLimitInfo=..%Translate("opadm.reg.hui.csp","患者年龄小于",langid)_ForeignInfoByAge_..%Translate("opadm.reg.hui.csp","岁",langid)_LimitStr_..%Translate("opadm.reg.hui.csp","不能为空！",langid)
	}
	if PatCat=""{
		s AgeLimitInfo=AgeLimitInfo_" "_..%Translate("opadm.reg.hui.csp","请补录患者类型！",langid)
	}
	
	s IsDeceased=##Class(web.PAPerson).CheckDeceased(PatDr)
	//是否有未补交的先诊疗后付费费用
	s HasPendPayOrdFlag=##class(BILL.Interface.Inside.Service).IHasPendPayOrdByPAPMI(PatDr, logonHospID, 1)
	//患者留观状态
	s StayStatus=##class(web.DHCOPAdmReg).GetInHospOrStayStatus(PatDr) 
	//患者信息不完善时，控制患者信息必填项不能为空时做出提示
	s NeedAddPatInfo=""
	s AllowAgeNoCreadCard=$g(^DHCDocCardConfig(HospCodeNode,"AllowAgeNoCreadCard"))
	if (IsTempCard'="Y"){
        s cardNoTrans = ..%Translate("opadm.reg.hui.csp", "证件号码", langid)
		s telHomeTrans = ..%Translate("opadm.reg.hui.csp", "联系电话", langid)
		s CardNoRequired=##class(web.DHCBL.CARD.UCardRefInfo).CheckCardNoRequired(myCredTypeID)
		i (CardNoRequired="Y")&&(CredNo="")&&((AllowAgeNoCreadCard="")||((AllowAgeNoCreadCard'="")&&(AllowAgeNoCreadCard<AgeYear))){
			s NeedAddPatInfo=$case(NeedAddPatInfo,"":cardNoTrans,:cardNoTrans_"、"_NeedAddPatInfo)
		}
		i (TelHome=""){
			s NeedAddPatInfo=$case(NeedAddPatInfo,"":telHomeTrans,:telHomeTrans_"、"_NeedAddPatInfo)
		}
		i AgeLimitInfo'=""{
			s NeedAddPatInfo=$case(NeedAddPatInfo,"":AgeLimitInfo,:AgeLimitInfo_"、"_NeedAddPatInfo)	
		}
	}
	Set desc=Name_"^"_Age_"^"_Sex_"^"_OPMRN_"^"_IPMRN_"^"_PatCat_"^"_PatDr_"^"_RIDCardNo_"^"_RAddress_"^"_PatientNo_"^"_AppBreakCount_"^"_PatYBCode_"^"_PatCatDesc_"^"_PAPERSGMedicareCode1_"^"_PAPERSGMedicareCode2_"^"_OldMan_"^"_PatCatDr_"^"_ReAdmFlag_"^"_CardNo_"^"_EmployeeFunction_"^"_SecretLevel
	s desc=desc_"^"_TelHome_"^"_PAPERCountry_"^"_PAPERForeignAddress_"^"_CredType_"^"_CredNo_"^"_PatInIPAdmission_"^"_IsDeceased_"^"_AgeLimitInfo_"^"_HasPendPayOrdFlag_"^"_myCredTypeID_"^"_StayStatus_"^"_NeedAddPatInfo
    if (itmjsex'=""){
	    q desc
	}else{
		set retval=itmjs_"('"_$ZCVT(desc,"O","JS")_"');"
		i itmjsex'="""" s retval=retval_itmjsex_"('"_$ZCVT(desc,"O","JS")_"^"_id_"^"_$ZCVT(code,"O","JS")_"');"
		&javascript<#(retval)#>
		q 1
	}
}

ClassMethod GetPatientIDByCardNo(CardNo As %String)
{
	s NewPatientID=""
	i (CardNo'="") {
		s ExpStr=""_$c(2)_""_$C(2)_"PatInfo"
		s ret=##class(web.UDHCAccManageCLSIF).getaccinfofromcardno(CardNo,"",ExpStr)
		s retcode=$P(ret,"^",1)
		if (retcode="-201")!(retcode="0"){
			s NewPatientID=$P(ret,"^",8)
		}
	}
	Q NewPatientID
}

ClassMethod GetPatientIDByNo(PatientNo As %String)
{
	s PatientID=""
	i (PatientNo'="") {
		s PatientID=$O(^PAPERi("PAPMI_PatNo",PatientNo,0))
	}
	Q PatientID
}

ClassMethod GetPrintData(RegfeeRowId As %String, AppFlag As %String = "", RePrintFlag = "N", HospId As %String = "") As %String
{
	;s ^RP("GetPrintData")=RegfeeRowId_"^"_AppFlag
	;w ##class(web.DHCOPAdmReg).GetPrintData(1250,"","Y",2)
	i ($g(HospId)="")&&($d(%session)) s HospId=%session.Get("LOGON.HOSPID")
	s ret=""
	s obj=##class(User.DHCRegistrationFee).%OpenId(RegfeeRowId)
	if $IsObject(obj){
		s SessionType="",TimeRange="",Room="",RoomAddress="",ExabMemo="",InvoiceId="",RBASDr=""
		s AdmDr=obj.RegfeeAdmDr.%Id()
		s DepDr=obj.RegfeeDepDr.%Id()
		if (DepDr'="")&&(HospId=""){
			s HospId=$P(^CTLOC(DepDr),"^",22)
		}
		s DocDr=obj.RegfeeDocDr.%Id()
		s UserDr=obj.RegfeeUserDr.%Id()
		s RegDate=obj.RegfeeDate
		s RegTime=..%ZT(obj.RegfeeTime,1)
		if $IsObject(obj.RegfeeSessionTypeDr) s SessionTypeDr=obj.RegfeeSessionTypeDr.%Id()
		if $IsObject(obj.RegfeeTimeRangeDr) s TimeRangeDr=obj.RegfeeTimeRangeDr.%Id()
		s SeqNo=obj.RegfeeNo
		s RoomDr=""
		if $IsObject(obj.RegfeeRoomDr) s RoomDr=obj.RegfeeRoomDr.%Id()
		if $IsObject(obj.Regfeetemp1) s InvoiceId=obj.Regfeetemp1.%Id()
		if $IsObject(obj.RegfeeRBASDr) s RBASDr=obj.RegfeeRBASDr.%Id()
		;取医保的结算信息
		s InsuPayCash="",InsuPayCount="",InsuPayFund="",InsuPayOverallPlanning="",InsuPayOther=""
		s InsuPayCash=obj.RegfeeInsuCash
		s InsuPayCash=$P(InsuPayCash,"!",2)
		s InsuPayCount=obj.RegfeeInsuCount
		s InsuPayCount=$P(InsuPayCount,"!",2)
		s InsuPayFund=obj.RegfeeInsuFund
		s InsuPayFund=$P(InsuPayFund,"!",2)
		s InsuPayOverallPlanning=obj.RegfeeInsuOverallPlanning
		s InsuPayOther=obj.RegfeeInsuOther
		s ClinicGroupCode=""
		s ASLoad="0"
		i RBASDr'="" {
			;code代表打印出的亚专业的描述
			 s ClinicGroupDr=$P($G(^RBAS(+RBASDr,$P(RBASDr,"||",2),"DHC")),"^",7)
			 i ClinicGroupDr'="" s ClinicGroupCode=$P($G(^RBC("CLGRP",ClinicGroupDr)),"^",1)
			 //取出号别正号限额
			 s ASLoad=$p($g(^RBAS(+RBASDr,$p(RBASDr,"||",2))),"^",8)
		}
		
		s DepDesc="",DocDesc="",UserCode="",User="",HospitalDesc=""
		i DepDr'=""{
			s HospitalDesc=$p($g(^CTLOC(DepDr)),"^",22)
			s:HospitalDesc'="" HospitalDesc=$P(^CT("HOSP",HospitalDesc),"^",2)
			s HospitalDesc=HospitalDesc //_"门诊挂号凭证"
			s DepDesc=$p($g(^CTLOC(DepDr)),"^",2)
		}
		i DocDr'="" s DocDesc=$p($g(^CTPCP(DocDr,1)),"^",2)
		s DepDesc1=$P(DepDesc,"-",2)
		i DepDesc1'="" s DepDesc=DepDesc1
		s User=""
		i InvoiceId'="" {
			s:UserDr="" UserDr=$P(^DHCINVPRT(InvoiceId),"^",21)
		}
		i UserDr'="" s UserCode=$p($g(^SSU("SSUSR",UserDr)),"^",1) 
		i UserDr'="" s User=$p($g(^SSU("SSUSR",UserDr)),"^",2)		
		s RoomNo="", RoomFloor=""
		/*
		s WaitingAddressInfo=..GetWaitingAddressInfo(AdmDr)
		s RoomFloor=$p(WaitingAddressInfo,"^",1)
		s RoomNo=$p(WaitingAddressInfo,"^",2)
		*/
		s ExabMemo=##Class(web.DHCOPAdmReg).GetScheduleAddressInfo(RBASDr)
		s RoomNo=$P(ExabMemo,",",2)
		s WaitingAddress=$P(ExabMemo,",",1)
		/*
		s AdmQueueID=$o(^User.DHCQueueI("QuePaadmDrIndex",AdmDr,""))
		i AdmQueueID'="" {
			s myQueExabDr=$list($g(^User.DHCQueueD(AdmQueueID)),6)
			i myQueExabDr'=""{
				s ExabMemo=$list($g(^User.DHCExaBoroughD(myQueExabDr)),4)		
			}
		}
		*/
		i SessionTypeDr'="" s SessionType=$P($g(^RBC("SESS",SessionTypeDr)),"^",2)
		s RegDate=$ZD(RegDate,3)
		s RegDateYear=$P(RegDate,"-",1)
		s RegDateMonth=$P(RegDate,"-",2)
		s RegDateDay=$P(RegDate,"-",3)
		s TimeRangeDesc=""
		i TimeRangeDr'="" s TimeRangeDesc=$P(^DHCTimeRange(TimeRangeDr),"^",2)
		s TimeRange=..GetAdmTimeRange(RBASDr,SeqNo)
		s TimeRange=TimeRangeDesc
		if DocDesc[("便民") s TimeRange=""
		;i $e(SeqNo)="+" s SeqNo=ASLoad_"加"_$e(SeqNo,2,$L(SeqNo))
		i RePrintFlag="Y" s SeqNo=SeqNo_"      (补打)"
		/*退号不释放原号,加一标志
		s RegisterFeeId=""
		s SeqNoFlag=0
		s exit=0
		f  s RegisterFeeId=$o(^User.DHCRegistrationFeeD(RegisterFeeId)) q:(RegisterFeeId="")||(exit=1)  d
		.s NewadmDR=$List(^User.DHCRegistrationFeeD(RegisterFeeId),2)
		.s NewRegDate=$List(^User.DHCRegistrationFeeD(RegisterFeeId),15)
		.s NewDocDR=$List(^User.DHCRegistrationFeeD(RegisterFeeId),14)
		.S NewDepDR=$List(^User.DHCRegistrationFeeD(RegisterFeeId),13)
		.s NewRegNo=$List(^User.DHCRegistrationFeeD(RegisterFeeId),8)
		.q:NewRegDate'=$zdh(RegDate,3)
		.q:(NewDocDR'=DocDr)&&(NewDocDR'="")
		.q:(NewDepDR'=DepDr)&&(NewDepDR'="")
		.q:NewRegNo'=SeqNo
		.s admvisitstatus=$p(^PAADM(NewadmDR),"^",20)
		.i (admvisitstatus="C")||(admvisitstatus="Cancel") d
		..s SeqNoFlag=1
		.s exit=1
		.;q:(admvisitstatus="C")||(admvisitstatus="Cancel") 
		if SeqNoFlag=1 s SeqNo=SeqNo_"     (释放号)"
		s ^guo("Print")=SeqNoFlag_"^"_SeqNo
		*/   // End
		s (CardNo,INVPRTNo)=""
		s PayModeStr=""
		if (InvoiceId'="") {
			//预交金:0,医保账户支付:11
			s INVPRTNo=$P(^DHCINVPRT(InvoiceId),"^",14)
			s PayModeStr=##class(web.DHCOPAdmReg).GetINVPayMode(InvoiceId)
		}
		//如果支付方式不为空,超过20个字节换行,因为考虑到第三方调用,则分为PayModeStr1和PayModeStr2
		s PayModeStr1=""
		s PayModeStr2=""
		if (PayModeStr'=""){
			if ($l(PayModeStr)>20) {s PayModeStr1=$e(PayModeStr,1,20),PayModeStr2=$e(PayModeStr,21,$l(PayModeStr))}
			else{s PayModeStr1=PayModeStr}
		}
		i AdmDr'="" {
			S AdmReason=$P($g(^PAADM(AdmDr,1)),"^",7)
			s PatDr=$P(^PAADM(AdmDr),"^")
			;s InMedical=$p($g(^PAPER(PatDr,"PAT",1)),"^",22)
			s InMedical=##Class(DHCWMR.IO.OutService).IGetMrNoByPatientID(PatDr,"",HospId)
			i InMedical["-"  s InMedical=""
			s OPMedcare=##Class(DHCWMR.IO.OutService).IGetMrNoByPatientID(PatDr,"O",HospId)
		    s IPMedcare=##Class(DHCWMR.IO.OutService).IGetMrNoByPatientID(PatDr,"I",HospId)
			s PatName=$p(^PAPER(PatDr,"ALL"),"^",1)
			;取登记号
			s PatNo=$p(^PAPER(PatDr,"PAT",1),"^",2)
			s AdmDate=$p($g(^PAADM(AdmDr)),"^",6)
			s AdmDateStr=$ZD(AdmDate,3)
			;s AdmDateStr=$e(AdmDateStr,3,10)
			s TransactionNo=$ZD(+$H,8)_" "_UserCode_" "_INVPRTNo
			s TPatCardNo=##class(DHCDoc.Common.pa).GetAdmRegCard(AdmDr)
   			s:TPatCardNo'="" CardNo=$p(TPatCardNo,"^",1)
		}
		
		s BillSum=0,ConRowId="",PBRowId=""
		s AppFee=0,RegFee=0,CheckFee=0,OtherFee=0,Total=0
		if (InvoiceId'="")	s ConRowId=$O(^DHCBCI(0,"INV",InvoiceId,0))
		;打印挂号费和诊疗费(包括附属的其他费用)
		s TotalRMBDX=""
		i ConRowId'="" 	s PBRowId=$P(^DHCBCI(ConRowId),"^",2) 
		if PBRowId'="" {
			s PBOChild=0 f  s PBOChild=$O(^DHCPB(PBRowId,"O",PBOChild)) Q:PBOChild=""  d
			.s ArcimId=$P(^DHCPB(PBRowId,"O",PBOChild),"^",3)
			.Q:ArcimId=""
			.s type=..GetRegArcimBillSubType(ArcimId,HospId)
			.s BillSum=$P(^DHCPB(PBRowId,"O",PBOChild),"^",11)
			.i type="App" s AppFee=AppFee+BillSum
			.e  d
			..;i (type="Reg")!(type="Check") s RegFee=RegFee+BillSum
			..;i (type="Check") s CheckFee=CheckFee+BillSum
			..i (type="Reg") s RegFee=RegFee+BillSum
			..e  s OtherFee=OtherFee+BillSum
			s Total=AppFee+RegFee+OtherFee
			s TotalRMBDX=..RMBDXXZH("","",Total)
		}
		;得到收费项目
		s Regitems=..GetRegitems(AdmDr)
		if AppFlag=1 {
			s DepDesc=""
			s DocDesc=""
			s SessionType=""
			s TimeRange=""
			s RoomFloor=""
			s SeqNo=""
		}
		;支付方式相关的金额全部统一到支付方式信息中PayModeStr1,PayModeStr2
		;如果需要自费金额与医保金额的分别汇总,可以在【医生站设置->本地化参数配置】中设置:^CF.DOC("LocalConfig","OPAdm","InsuPayMode")=医保支付方式^医保基金支付!医保账户支付^^
		s InsuPayMode=##class(DHCDoc.DHCDocConfig.LocalConfig).GetLocalConfigValue("OPAdm","ZFPayMode")
		for i=1:1:$l(PayModeStr,",") {
			s PayModeDesc=$p($p(PayModeStr,",",i),":",1)
			s PayModeAmt=$p($p(PayModeStr,",",i),":",2)
			continue:PayModeDesc=""
			if ("!"_InsuPayMode_"!")[("!"_PayModeDesc_"!") s InsuPayFund=InsuPayFund+PayModeAmt
		}
		s YBPay=InsuPayFund,PersonPay=Total-YBPay
		s YBPay=$j(YBPay,6,2)_"元",PersonPay=$j(PersonPay,6,2)_"元"
		s Total=$j(Total,6,2)_"元"
		//得到分时段信息
		s TimeRangeInfo=##class(web.DHCRBApptSchedule).GetTimeRangeRegInfo(RBASDr,SeqNo,TimeRangeDesc)
		
		;得到账户余额
		s AccBalance=##class(web.DHCOPChargeAddByOther).GetAccLeftByRegNo("",PatDr)
		if +AccBalance'=0 s AccBalance=""
		else  s AccBalance=$p(AccBalance,"^",2)
		s EmployeeFunction="",SecretLevel=""
		s PatEncryptLevel=##class(web.DHCBL.CARD.UCardPaPatMasInfo).GetPatEncryptLevel(PatDr,.ErrMsg)
		i PatEncryptLevel'="" {
			s EmployeeFunction=$p(PatEncryptLevel,"^",2)
			s SecretLevel=$p(PatEncryptLevel,"^",1)
		}
		
		s ret=AdmDr_"^"_PatName_"^"_DepDesc_"^"_DocDesc_"^"_SessionType_"^"_AdmDateStr_"^"_TimeRange_"^"_SeqNo
		s ret=ret_"^"_RoomNo_"^"_RoomFloor_"^"_UserCode_"^"_User_"^"_RegDateYear_"^"_RegDateMonth_"^"_RegDateDay
		s ret=ret_"^"_TransactionNo_"^"_Total_"^"_RegFee_"^"_AppFee_"^"_OtherFee_"^"_ClinicGroupCode_"^"_RegTime_"^"_RBASDr_"^"_ExabMemo
		s ret=ret_"^"_InsuPayCash_"^"_InsuPayCount_"^"_InsuPayFund_"^"_InsuPayOverallPlanning_"^"_InsuPayOther
		s ret=ret_"^"_TotalRMBDX_"^"_INVPRTNo_"^"_CardNo_"^"_Room_"^"_AdmReason_"^"_Regitems_"^"_AccBalance
		s ret=ret_"^"_PatNo_"^"_TimeRangeInfo_"^"_HospitalDesc_"^"_PersonPay_"^"_YBPay_"^"_InMedical_"^"_RegfeeRowId
		s ret=ret_"^"_EmployeeFunction_"^"_OPMedcare_"^"_IPMedcare_"^"_PayModeStr1_"^"_PayModeStr2
		;s ^gry("PrintDate")=ret
	}
	Q ret
}

/// 得到候诊地址信息,如果有诊室直接获取诊室位置/如果没有诊室则获取科室所在位置
/// w ##class(web.DHCOPAdmReg).GetWaitingAddressInfo(270)
ClassMethod GetWaitingAddressInfo(AdmId As %String) As %String
{
	s WaitingAddress="",RoomNo=""
	q:AdmId="" ""
	s RegID=$O(^User.DHCRegistrationFeeI("ADM",AdmId,0))
	q:RegID="" ""
	s ASRowID=$LIST(^User.DHCRegistrationFeeD(RegID),18)
	s AddressInfo=##Class(web.DHCOPAdmReg).GetScheduleAddressInfo(ASRowID)
	s RoomNo=$P(AddressInfo,",",2)
	s WaitingAddress=$P(AddressInfo,",",1)
	Q WaitingAddress_"^"_RoomNo
}

/*
1.排班记录扩展设置维护位置信息; Add 20230921
2.排班记录上有维护诊室，取诊室。
3.排班记录没有维护，取科室与诊区关联关系，取诊区。
4.若是上述都没维护，取科室地址。
*/
/// w ##Class(web.DHCOPAdmReg).GetScheduleAddressInfo("2179||35")
ClassMethod GetScheduleAddressInfo(ASRowID As %String) As %String
{
	s AddressInfo=""
	;排班扩展项-Address
	s ASExtendConfig=##class(DHCDoc.OPAdm.ScheduleTemplateConfig).ShowASScheduleExtendConfig(ASRowID,"Address")
	if ASExtendConfig'=""{
		s ConfigAryObj={}.%FromJSON(ASExtendConfig)	
		if (ConfigAryObj.%Size()>0){
			s AddressObj=ConfigAryObj.%Get(0)
			s AddressInfo=AddressObj.Value
		}
		if AddressInfo'=""{
			q AddressInfo
		}
	}
	s ASRoomDR=$P($G(^RBAS(+ASRowID,$P(ASRowID,"||",2),"DHC")),"^",5)
	if (ASRoomDR'=""){
		s AddressInfo=$g(^CTLOC(ASRoomDR,"ADDR",1)) //$p($g(^CTLOC(ASRoomDR)),"^",16)
		if AddressInfo'=""{
			q AddressInfo
		}
	}
	
	S LocID=$p(^RB("RES",+ASRowID),"^",1)
	s DOCID=$p(^RB("RES",+ASRowID),"^",2)
	s ExabDr=""
	&sql(SELECT depmbordr into :ExabDr FROM sqluser.DHCDepMark
             where depmdepdr=:LocID and depmmarkdr=:DOCID)
	if (ExabDr'=""){
		s ExabMemo=""
		if ($G(^User.DHCExaBoroughD(ExabDr))'="") s ExabMemo=$lg(^User.DHCExaBoroughD(ExabDr),4)
		if (ExabMemo'=""){
			q ExabMemo
		}
	}
	s AddressInfo=$g(^CTLOC(LocID,"ADDR",1)) //$p($g(^CTLOC(LocID)),"^",16)
	q AddressInfo
}

/// 重打
ClassMethod GetRePrintData(RegfeeRowId As %String) As %String
{
	;w ##class(web.DHCOPAdmReg).GetPrintData(3345)
	s ret=""
	s obj=##class(User.DHCRegistrationFee).%OpenId(RegfeeRowId)
	if $IsObject(obj){
		s SessionType="",TimeRange="",Room="",RoomAddress=""
		s AdmDr=obj.RegfeeAdmDr.%Id()
		s DepDr=obj.RegfeeDepDr.%Id()
		s DocDr=obj.RegfeeDocDr.%Id()
		;s UserDr=obj.RegfeeUserDr.%Id()
		s RegDate=obj.RegfeeDate
		s RegTime=..%ZT(obj.RegfeeTime,1)
		s SessionTypeDr=obj.RegfeeSessionTypeDr.%Id()
		s TimeRangeDr=obj.RegfeeTimeRangeDr.%Id()
		s SeqNo=obj.RegfeeNo
		s RoomDr=obj.RegfeeRoomDr.%Id()
		s InvoiceId=obj.Regfeetemp1.%Id()
		s RBASDr=obj.RegfeeRBASDr.%Id()
		s ClinicGroupCode=""
		i RBASDr'="" {
			;code代表打印出的亚专业的描述
			 s ClinicGroupDr=$P($G(^RBAS(+RBASDr,$P(RBASDr,"||",2),"DHC")),"^",7)
			 i ClinicGroupDr'="" s ClinicGroupCode=$P($G(^RBC("CLGRP",ClinicGroupDr)),"^",1)
		}
		
		s DepDesc="",DocDesc="",UserCode="",User=""
		i DepDr'="" s DepDesc=$p($g(^CTLOC(DepDr)),"^",2)
		i DocDr'="" s DocDesc=$p($g(^CTPCP(DocDr,1)),"^",2)
		s DepDesc1=$P(DepDesc,"-",2)
		i DepDesc1'="" s DepDesc=DepDesc1
		s UserCode=""
		i InvoiceId'="" {
			s UserDr=$P(^DHCINVPRT(InvoiceId),"^",21)
			i UserDr'="" s UserCode=$p($g(^SSU("SSUSR",UserDr)),"^",1) 
			i UserDr'="" s User=$p($g(^SSU("SSUSR",UserDr)),"^",2)
		} 
		s RoomNo="", RoomFloor=""
		i RoomDr'="" { 
			s Room=$p($g(^CTLOC(RoomDr)),"^",2)
			;地址
			s RoomFloor=$p($g(^CTLOC(RoomDr)),"^",16)
			s RoomNo=$P(RoomFloor,",",2)
			;i RoomNo'="" s Room=RoomNo
			;取地址必须放在取诊室号后面
			s RoomFloor=$P(RoomFloor,",",1)
		}
		
		i SessionTypeDr'="" s SessionType=$P(^RBC("SESS",SessionTypeDr),"^",2)
		s RegDate=$ZD(RegDate,3)
		s RegDateYear=$P(RegDate,"-",1)
		s RegDateMonth=$P(RegDate,"-",2)
		s RegDateDay=$P(RegDate,"-",3)
		s TimeRangeDesc=""
		i TimeRangeDr'="" s TimeRangeDesc=$P(^DHCTimeRange(TimeRangeDr),"^",2)
		s TimeRange=..GetAdmTimeRange(RBASDr,SeqNo)
		s TimeRange=TimeRangeDesc_TimeRange
		if DocDesc[("便民") s TimeRange=""
		i $e(SeqNo)="+" s SeqNo="加"_$e(SeqNo,2,$L(SeqNo))
		s SeqNo=SeqNo_"    (补打)"
		s INVPRTNo=""
		if (InvoiceId'="") s INVPRTNo=$P(^DHCINVPRT(InvoiceId),"^",14)
		s MrNo=""
		i AdmDr'="" {
			s PatDr=$P(^PAADM(AdmDr),"^")
			s PatName=$p(^PAPER(PatDr,"ALL"),"^",1)
			s PatNo=$p(^PAPER(PatDr,"PAT",1),"^",2)
			s AdmDate=$p($g(^PAADM(AdmDr)),"^",6)
			s AdmDateStr=$ZD(AdmDate,3)
			;s AdmDateStr=$e(AdmDateStr,3,10)
			s TransactionNo=$ZD(+$H,8)_" "_UserCode_" "_INVPRTNo
			i PatDr'=""{
				s CFRowID=$o(^DHCCARDi("CF",0,"PAPMIDR",PatDr,0))
				i CFRowID'=""{
					s CardNo=$p($g(^DHCCARD("CF",CFRowID)),"^",2)
				}
			}
			s AdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(AdmDr)
			s ErrMsg=""
			s MrNo=##Class(DHCWMR.IO.OutService).IGetMrNoByEpisodeID(AdmDr,AdmType,.ErrMsg)
			i MrNo["-"  s MrNo=""
		}
		
		s BillSum=0,ConRowId="",PBRowId=""
		s AppFee=0,RegFee=0,OtherFee=0,Total=0
		if (InvoiceId'="")	s ConRowId=$O(^DHCBCI(0,"INV",InvoiceId,0))
		
		i ConRowId'="" 	s PBRowId=$P(^DHCBCI(ConRowId),"^",2) 
		if PBRowId'="" {
			s PBOChild=0 f  s PBOChild=$O(^DHCPB(PBRowId,"O",PBOChild)) Q:PBOChild=""  d
			.s ArcimId=$P(^DHCPB(PBRowId,"O",PBOChild),"^",3)
			.Q:ArcimId=""
			.s type=..GetRegArcimBillSubType(ArcimId)
			.s BillSum=$P(^DHCPB(PBRowId,"O",PBOChild),"^",11)
			.i type="App" s AppFee=AppFee+BillSum
			.e  d
			..i (type="Reg")!(type="Check") s RegFee=RegFee+BillSum
			..e  s OtherFee=OtherFee+BillSum
			s Total=AppFee+RegFee+OtherFee
		}
		if (InvoiceId'="") s INVPRTNo=$P(^DHCINVPRT(InvoiceId),"^",14)
		s ret=AdmDr_"^"_PatName_"^"_DepDesc_"^"_DocDesc_"^"_SessionType_"^"_AdmDateStr_"^"_TimeRange_"^"_SeqNo_"^"_RoomNo_"^"_RoomFloor_"^"_UserCode_"^"_User_"^"_RegDateYear_"^"_RegDateMonth_"^"_RegDateDay_"^"_TransactionNo_"^"_Total_"^"_RegFee_"^"_AppFee_"^"_OtherFee_"^"_ClinicGroupCode_"^"_RegTime_"^"_INVPRTNo_"^"_PatNo_"^"_CardNo_"^^^"_MrNo
	}
	Q ret
}

// 4001||152||1

/// 打印预约条
ClassMethod GetAppPrintData(AppARowid As %String) As %String
{
	s ret="",PatName="",CardNo="",TRDesc="",PatSexDR="",PatSex="",APPTTransUserDR="",APPTMethodDR="",APPTLastStatusChangeUserDR=""
	s PatNo="",TimeRangeInfo="",APPTTransUser="",APPTMethod=""
	s object=##class(User.RBAppointment).%OpenId(AppARowid)
	if $IsObject(object){
		if $IsObject(object.APPTPAPMIDR) s PAPMIDR=object.APPTPAPMIDR.%Id()
		S APPTStatus=object.APPTStatus
		s APPTQueueNo=object.APPTQueueNo     //诊号
		s APPTAdmDR=object.APPTAdmDR //.%Id
		if $ISOBJECT(APPTAdmDR) {
			s APPTAdmDR=APPTAdmDR.%Id()
		}
		s APPTETA=object.APPTETA
		s APPTTransDate=..%ZD(object.APPTTransDate)   //预约日期
		;s APPTTransDate=$zd(APPTTransDate,3)
		s APPTTransTime=object.APPTTransTime
		if $IsObject(object.APPTTransUserDR) s APPTTransUserDR=object.APPTTransUserDR.%Id()
		if $IsObject(object.APPTMethodDR) s APPTMethodDR=object.APPTMethodDR.%Id()
		s APPTDateComp=..%ZD(object.APPTDateComp)
		s APPTTimeComp=object.APPTTimeComp
		if $IsObject(object.APPTLastStatusChangeUserDR) s APPTLastStatusChangeUserDR=object.APPTLastStatusChangeUserDR.%Id()
		s APPTLastStatusChangeDate=..%ZD(object.APPTLastStatusChangeDate)
		s APPTLastStatusChangeTime=object.APPTLastStatusChangeTime
		if APPTTransUserDR'=""  s APPTTransUser=$p($g(^SSU("SSUSR",APPTTransUserDR)),"^",2)
		if APPTMethodDR'="" s APPTMethod=$p($g(^RBC("APTM",APPTMethodDR)),"^",2)
		
		//预约医生
		//s ASRowId=(+AppARowid)_"||"_$p(AppARowid,"||",2)
		s RESRowid=(+AppARowid)
		s ASChild=$p(AppARowid,"||",2)
		s AdmDate=$P($g(^RBAS(RESRowid,ASChild)),"^",1)
		s AdmDate=..%ZD(AdmDate)
		;s AdmDate=$zd(AdmDate,3)
		s StartTime=$P($G(^RBAS(RESRowid,ASChild)),"^",4)
	    //s TRRowId=##class(web.DHCRBResSession).GetTimeRangeByTime(StartTime)
	    //if TRRowId'="" s TRDesc=$P(^DHCTimeRange(TRRowId),"^",2)
	    //e  s TRDesc="其他"
	    s RegfeeTimeRangeDr=$P($G(^RBAS(+AppARowid,$p(AppARowid,"||",2),"DHC")),"^",17)
	    i RegfeeTimeRangeDr'="" s TRDesc=$P(^DHCTimeRange(RegfeeTimeRangeDr),"^",2) 
	    e  s TRDesc="其他" 
	    s SeqNo=APPTQueueNo_" 号("_TRDesc_")"
		
		s Locdesc="",Docdesc=""
		S LocID=$p(^RB("RES",RESRowid),"^",1)
		i LocID'="" s Locdesc=$p(^CTLOC(LocID),"^",2)
		s DOCID=$p(^RB("RES",RESRowid),"^",2)
		i DOCID'="" s Docdesc=$p(^CTPCP(DOCID,1),"^",2)
		
		//建议就诊时间
		s TimeRangeInfo=##class(web.DHCRBApptSchedule).GetTimeRangeRegInfo(RESRowid_"||"_ASChild,APPTQueueNo,"")
		
		//病人信息
		if (PAPMIDR'=""){
			//s CardNoID=$O(^DHCCARDi("CF",0,"PAPMIDR",PAPMIDR,""))
			//i CardNoID'="" s CardNo=$p(^DHCCARD("CF",CardNoID),"^",2)
		    s CardNoID="",StopFlag="false"
			f  s CardNoID=$O(^DHCCARDi("CF",0,"PAPMIDR",PAPMIDR,CardNoID)) q:(CardNoID="")!(StopFlag="true")  d
			.s ArriveFlag=$p(^DHCCARD("CF",CardNoID),"^",10)
			.Q:ArriveFlag'="N"
			.s CardNo=$p(^DHCCARD("CF",CardNoID),"^",2)
			.s StopFlag="true"
			s PatName=$p($g(^PAPER(PAPMIDR,"ALL")),"^",1)
			s PatSexDR=$p($g(^PAPER(PAPMIDR,"ALL")),"^",7)
			i PatSexDR'="" s PatSex=$p(^CT("SEX",PatSexDR),"^",2)
			s PatNo=$p(^PAPER(PAPMIDR,"PAT",1),"^",2) //登记号
		}
		s CommonPatientID=..GetCommonPatientID()
		i (("^"_CommonPatientID_"^")[("^"_PAPMIDR_"^")){
			s PatName=$p($g(^RBAS(RESRowid,ASChild,"APPT",$p(AppARowid,"||",3),"DHC")),"^",1)
		}
		s PatCatDr=$p(^PAPER(PAPMIDR,"PER",1),"^",10)
		s AdmReason=..GetDefaultBillType(PatCatDr)
		s RtnMes=##class(web.DHCOPAdmReg).GetMarkRegFee(RESRowid_"||"_ASChild,AdmReason,PAPMIDR)
		s SessionTypeDesc=$P(RtnMes,"^",10) //级别
		s ASDateWeek=$P(RtnMes,"^",29) //星期
		s RegFee=$P(RtnMes,"^",12)
		s CheckFee=$P(RtnMes,"^",14)
		s ReCheckFee=$P(RtnMes,"^",15)
		s HoliFee=$P(RtnMes,"^",16)
		s AppFee=$P(RtnMes,"^",18)
		s OtherFee=$P(RtnMes,"^",20)
		s Price=RegFee+CheckFee+ReCheckFee+HoliFee+AppFee+OtherFee
		//s Price=$P(RtnMes,"^",30) //总金额
		s:APPTTransTime'="" APPTTransTime=..%ZT(APPTTransTime,1)
		s listitem1=""
		s APPPattype=$P($g(^RBAS(RESRowid,ASChild,"APPT",$p(AppARowid,"||",3),"DHC")),"^",15) 
		if ((APPPattype'="")&&(APPPattype'=1)){
			s listitem1="请联系人为父母或者其他关系的患者卡号取号！"
			}
	 
		s ret=CardNo_"^"_PAPMIDR_"^"_PatName_"^"_PatSex_"^"_SeqNo_"^"_APPTQueueNo_"^"_Locdesc_"^"_Docdesc
		s ret=ret_"^"_APPTTransDate_"^"_APPTTransTime_"^"_AdmDate_"^"_APPTLastStatusChangeDate_"^"_APPTLastStatusChangeTime

		s ret=ret_"^"_PatNo_"^"_TimeRangeInfo_"^"_APPTTransUser_"^"_APPTMethod_"^"_Price_"^"_SessionTypeDesc_"^"_ASDateWeek_"^^^"_listitem1
	}
	Q ret
}

/// Creator：yjy
/// Createdate:2010-08-11
/// Medify:gry
/// desc:得到病人就诊收费项目明细
ClassMethod GetRegitems(PaadmRowid As %String) As %String
{
 Q:PaadmRowid="" ""
 S Str=""
 s OEORDRowId=$O(^OEORD(0,"Adm",PaadmRowid,""))
 Q:OEORDRowId="" ""
 s OEORIChildsub="0" F  s OEORIChildsub=$O(^OEORD(OEORDRowId,"I",OEORIChildsub)) Q:OEORIChildsub=""  d
 .S OEORIItmMastDR=$P(^OEORD(OEORDRowId,"I",OEORIChildsub,1),"^",2)
 .s ARCIMSubscript=$P(OEORIItmMastDR,"||",1)
 .S ARCIMVersion=$P(OEORIItmMastDR,"||",2)
 .q:$P($G(^OEORD(OEORDRowId,"I",OEORIChildsub,1)),"^",13)=4
 .S ARCIMDesc=$P(^ARCIM(ARCIMSubscript,ARCIMVersion,1),"^",2)
 .s UnitPrice=##class(web.DHCDocOrderEntry).GetOrderPrice("", "",OEORIItmMastDR, "", "", "", "", "") 
 .s UnitPrice=$j($P(UnitPrice,"^",1),3,2)
 .S Str=Str_ARCIMDesc_"["_UnitPrice_"!"
 Q Str
}

/// 判断是否需要受取复诊收费
ClassMethod GetReAdmFeeFlag(PatientID As %String, ASRowId As %String) As %String
{
	;w ##class(web.DHCOPAdmReg).GetReAdmFeeFlag(5,"1||28")
	s ResRowId=+ASRowId
	s flag=0,PreAdmDocDr=""
	Q:PatientID="" flag
	set obj = ##Class(User.DHCRBResource).%OpenId(ResRowId)
	set RESReAdmFeeFlag=obj.RESReAdmFeeFlag
	d obj.%Close()
	Q:RESReAdmFeeFlag'="Y" flag
	Set DocDr=$p(^RB("RES",ResRowId),"^",2)
	Set DeptDr=$p(^RB("RES",ResRowId),"^",1)
	s Adm="" f  Set Adm=$o(^PAPERdr(PatientID,"ADM","O",Adm),-1) Quit:(Adm="")!(PreAdmDocDr'="")  d
	.s VisitStatus=$p($g(^PAADM(Adm)),"^",20)
	.Q:VisitStatus'="A"
	.s AdmDepDr=$p($g(^PAADM(Adm)),"^",4)
	.Q:AdmDepDr'=DeptDr
	.s PreAdmDocDr=$p($g(^PAADM(Adm)),"^",9)
	Q:PreAdmDocDr'=DocDr 0
	Q 1
}

/// 得到科室便民号排班记录
ClassMethod GetRapidASRowId(loc As %String, user As %String, MarkType As %String = "", SecheduleDate As %String = "", TimeRangeId As %String = "", DocId As %String = "") As %String
{
	;w ##class(web.DHCOPAdmReg).GetRapidASRowId(63,600,"","2013-05-20",4,"")
	s ^zhou("GetRapidASRowId")=loc_","_user_","_MarkType_","_SecheduleDate_","_TimeRangeId_","_DocId
	if SecheduleDate="" {
		s SecheduleDate=..%SysDate()
	}else {
		i $l(SecheduleDate,"-")=3 s SecheduleDate=$zdh(SecheduleDate,3)
		i $l(SecheduleDate,"/")=3 s SecheduleDate=$zdh(SecheduleDate,4)
	}
	if TimeRangeId="" {
		s TRTime=..%SysTime()
		s TimeRangeId=..GetTimeRangeByTime(TRTime)
	}
	if (MarkType="BM") {
		s ret=..GetRapidMarkCodeStr(loc)
		if ret'="" {
			s ret1=$P(ret,"^",1)
			s RapidMarkRowId=$P(ret1,$C(1),1)
			if RapidMarkRowId'="" {
				s RapidASRowId=##class(web.DHCRBApptSchedule).GetAvailRA(RapidMarkRowId,+$H,"",TimeRangeId)
				i RapidASRowId'="" {
					s RapidASRowId=$P(RapidASRowId,"^",1)
					Q RapidASRowId
				}
			}
		}
	}else{
		s doc=""
		i DocId'="" {
			s doc=DocId
		}elseif user'=""{
			s doc=##class(web.SSUser).GetDefaultCareProvider(user)
		}
		if $g(doc)'=""{
			Q ..GetTodayASRowIdByRes(loc,doc,"",SecheduleDate,"") //TimeRangeId
		}
	}
	Q ""
}

/// 得到科室便民号资源
ClassMethod GetRapidMarkCodeStr(loc As %String) As %String
{
	; w ##class(web.DHCOPAdmReg).GetRapidMarkCodeStr(153)
	s ret1=""
	s RowId=0 f  Set RowId=$o(^RB("RES",0,"CTLOC",loc,RowId)) quit:RowId=""  d
	.s CTPCPRowId=$P(^RB("RES",RowId),"^",2)
	.s CTLocRowId=$P(^RB("RES",RowId),"^",1)
	.Q:(CTPCPRowId="")!(CTLocRowId="")
	.;B ;判断是否需要排班
	.s ScheSt=$p(^RB("RES",RowId),"^",6)
	.Q:(ScheSt'="Y")
	.s CTPCPDesc=$p(^CTPCP(CTPCPRowId,1),"^",2)
	.s CTLocDesc=$p($g(^CTLOC(CTLocRowId)),"^",2)
	.q:(CTPCPDesc'[("便民"))
	.set ret=RowId_$C(1)_CTPCPDesc
 	.i ret1="" s ret1=ret
 	.e  s ret1=ret_"^"_ret1
 	Q ret1
}

/// 取登记号
ClassMethod GetRapidPatientNo() As %String
{
	;w ##class(web.DHCOPAdmReg).GetRapidPatientNo()
	;如果超过延时则返回为空
	if ('$d(^DHCDocConfig("StartRapidRegCardNo")))!(^DHCDocConfig("StartRapidRegCardNo")="") Q ""
	if ('$d(^DHCDocConfig("EndRapidRegCardNo")))!(^DHCDocConfig("EndRapidRegCardNo")="") Q ""
	s StartCardNo=^DHCDocConfig("StartRapidRegCardNo")
	s EndCardNo=^DHCDocConfig("EndRapidRegCardNo")
	if '$d(^DHCDocConfig("CurrentRapidRegCardNo")) {
		s ^DHCDocConfig("CurrentRapidRegCardNo")=StartCardNo
	}
	
	lock +^DHCDocConfig("CurrentRapidRegCardNo"):30
	i $TEST {
		s CurrentCardNo=^DHCDocConfig("CurrentRapidRegCardNo")
		if CurrentCardNo'=""  {
			s NextCardNo=CurrentCardNo+1
			if (NextCardNo>EndCardNo)!(NextCardNo<StartCardNo) s NextCardNo=StartCardNo
		}else{
			s NextCardNo=StartCardNo
		}
		s ^DHCDocConfig("CurrentRapidRegCardNo")=NextCardNo
	}
	lock -^DHCDocConfig("CurrentRapidRegCardNo")
	
	f i=1:1:(10-$l(NextCardNo)) d
	.s NextCardNo="0"_NextCardNo

	Q NextCardNo
}

ClassMethod GetReceiptStr(RegDate As %Date, UserRowId As %String) As %String
{
	if (RegDate="") s RegDate=..%SysDate()
	s Count=0,Sum=0
	s RowId=0  f  s RowId=$O(^DHCINVPRT(0,"UserDate",UserRowId,RegDate,RowId)) Q:RowId=""  d
	.s INVPRTNo=$P(^DHCINVPRT(RowId),"^",14)
	.s INVFireType=$P(^DHCINVPRT(RowId),"^",34)
	.q:INVFireType'="R"
	.i INVPRTNo'="" s Count=Count+1
	.;s INVPRTAcount=$P(^DHCINVPRT(RowId),"^",1)
	.s PRTPatientShare=$P(^DHCINVPRT(RowId),"^",16)
	.s INVPRTAcount=PRTPatientShare
	.s Sum=Sum+INVPRTAcount
	Q Count_"^"_Sum
}

ClassMethod GetRegArcimBillSubType(ArcimId, HospId As %String = "") As %String
{
	s BillSubRowId=$P($G(^ARCIM(+ArcimId,$P(ArcimId,"||",2),1)),"^",9)
	s CardFeeArcimId=..GetCardFeeArcimId(HospId)
	s MRFeeArcimId=..GetMRFeeArcimId(HospId)
	;病历本
	Q:ArcimId=MRFeeArcimId "MR"
	;卡费
	Q:ArcimId=CardFeeArcimId "Card"
	;挂号费
	s RegFeeBillSub=##class(web.DHCOPRegConfig).GetSpecConfigNode("RegFeeBillSub",HospId)
	Q:RegFeeBillSub=BillSubRowId "Reg"
	;诊查费
	s CheckFeeBillSub=##class(web.DHCOPRegConfig).GetSpecConfigNode("CheckFeeBillSub",HospId)
	Q:CheckFeeBillSub=BillSubRowId "Check"
	;复诊费
	s CheckFeeBillSub=##class(web.DHCOPRegConfig).GetSpecConfigNode("ReCheckFeeBillSub",HospId)
	Q:CheckFeeBillSub=BillSubRowId "ReCheck"
	s AppFeeBillSub=##class(web.DHCOPRegConfig).GetSpecConfigNode("AppFeeBillSub",HospId)
	Q:AppFeeBillSub=BillSubRowId "App"
	;假日费
	s HoliFeeBillSub=##class(web.DHCOPRegConfig).GetSpecConfigNode("HoliFeeBillSub",HospId)
	Q:HoliFeeBillSub=BillSubRowId "Holi"
	;不能把所有其他医嘱都归类到其他，不然门诊收费处那边无法单独账单挂号费
	s OhterFeeBillSub=##class(web.DHCOPRegConfig).GetSpecConfigNode("OtherFeeBillSub",HospId)
	Q:OhterFeeBillSub=BillSubRowId "Other"
	Q "NotRegFee"
}

ClassMethod GetRegINVAppFee(InvoiceRowId As %String, RegFeeType As %String, ExcludeFlag As %String) As %String
{
	;w ##class(web.DHCOPAdmReg).GetINVAppFee(568)
	s BillSum=0
	Q:InvoiceRowId="" 0
	s ConRowId=$O(^DHCBCI(0,"INV",InvoiceRowId,0))
	Q:ConRowId="" 0
	s PBRowId=$P(^DHCBCI(ConRowId),"^",2) 
	Q:PBRowId="" 0
	s AdmRowId=$P(^DHCPB(PBRowId),"^",1)
	s AdmDate=$P(^DHCPB(PBRowId),"^",2)
	s AdmReason=$P(^DHCPB(PBRowId),"^",4)
	s HospId=$p(..GetCurrentHosp(AdmRowId,"","",""),"^",1)
	s PatientID=$p(^PAADM(AdmRowId),"^",1)
	s RegFeeRBASDr=""
	s Admi=AdmRowId
	s RegfeeRowId=$O(^User.DHCRegistrationFeeI("ADM",Admi,""))
	i RegfeeRowId'="" s RegFeeRBASDr=$List(^User.DHCRegistrationFeeD(RegfeeRowId),18)
	s RegConDisIdPara=PatientID_"^"_RegFeeRBASDr_"^"_AdmReason_"^"_""
	s RegConDisId=..GetRegConDisId(RegConDisIdPara)
	
	s PBOChild=0 f  s PBOChild=$O(^DHCPB(PBRowId,"O",PBOChild)) Q:PBOChild=""  d
	.q:($d(^DHCPB(PBRowId,"O",PBOChild))=10)
	.s ArcimId=$P(^DHCPB(PBRowId,"O",PBOChild),"^",3)
	.Q:ArcimId=""
	.s type=..GetRegArcimBillSubType(ArcimId,HospId)
	.Q:(ExcludeFlag=1)&(("^"_RegFeeType_"^")[("^"_type_"^"))
	.Q:(ExcludeFlag=0)&(("^"_RegFeeType_"^")'[("^"_type_"^"))
	.//s OrdItemRowId=$P(^DHCPB(PBRowId,"O",PBOChild),"^",4)
	.s BillPatShareAmt=$P(^DHCPB(PBRowId,"O",PBOChild),"^",11)
	.s BillSum=BillSum+BillPatShareAmt
	.//s BillQty=$P(^DHCPB(PBRowId,"O",PBOChild),"^",5)
	.//s BillPrice=$p(##Class(web.UDHCJFPRICE).GetOrderPrice("",AdmReason,ArcimId,AdmDate,"","","","",HospId,RegConDisId),"^",4)
	.//s BillSum=BillSum+$fn(BillPrice*BillQty,"",2)
	Q BillSum
}

ClassMethod GetRegINVOrderItem(InvoiceRowId As %String, RegFeeType As %String, ExcludeFlag As %String) As %String
{
	s ret=""
	q:InvoiceRowId="" 0
	s ConRowId=$O(^DHCBCI(0,"INV",InvoiceRowId,0))
	Q:ConRowId="" 0
	s PBRowId=$P(^DHCBCI(ConRowId),"^",2) 
	Q:PBRowId="" 0
	s AdmRowId=$P(^DHCPB(PBRowId),"^",1)
	s HospId=$p(..GetCurrentHosp(AdmRowId,"","",""),"^",1)
	s PBOChild=0 f  s PBOChild=$O(^DHCPB(PBRowId,"O",PBOChild)) Q:PBOChild=""  d
	.s ArcimId=$P(^DHCPB(PBRowId,"O",PBOChild),"^",3)
	.Q:ArcimId=""
	.s type=..GetRegArcimBillSubType(ArcimId,HospId)
	.s OrdItemRowId=$P(^DHCPB(PBRowId,"O",PBOChild),"^",4)
	.Q:(ExcludeFlag=1)&(("^"_RegFeeType_"^")[("^"_type_"^"))
	.Q:(ExcludeFlag=0)&(("^"_RegFeeType_"^")'[("^"_type_"^"))
	.i ret="" s ret=OrdItemRowId
	.e  s ret=ret_"^"_OrdItemRowId
	Q ret
}

ClassMethod GetResDocByLocId(val As %Library.String = "")
{
	s desc=""
	s retstr=""
	Set rs=##Class(%ResultSet).%New("web.DHCRBResSession:FindResDoc")
	If rs.QueryIsValid() { 
		 Set Status=rs.Execute(val)
		 If 'Status Quit
		 While rs.Next() {
			 Set DocCode=rs.GetData(2)
			 Set DocRowid=rs.GetData(3)
			 Set DocDesc=rs.GetData(1)
			 Set ResRowid=rs.GetData(4)
			 If retstr="" Set retstr=ResRowid_$c(2)_DocRowid_$c(1)_DocDesc
			 Else  Set retstr=retstr_"^"_ResRowid_$c(2)_DocRowid_$c(1)_DocDesc
		 }
	}
	Q retstr
}

ClassMethod GetResRowIdStr(FindDeptRowIdStr As %String, FindDocDr As %String) As %String
{
	s ResRowIdStr=""
	if (FindDeptRowIdStr'=""){
		f i=1:1:$l(FindDeptRowIdStr,$C(2)) {
			s FindDeptDr=$P(FindDeptRowIdStr,$C(2),i)
			Set RowId=0 f  Set RowId=$O(^RB("RES",0,"CTLOC",FindDeptDr,RowId)) Quit:RowId=""  d
			.s DocDr=$P(^RB("RES",RowId),"^",2)
			.Q:(FindDocDr'="")&(FindDocDr'=DocDr)
			.i ResRowIdStr="" s ResRowIdStr=RowId
			.e  s ResRowIdStr=ResRowIdStr_"^"_RowId
		}
	}else{
		Set LocDr=0 f  Set LocDr=$O(^RB("RES",0,"CTPCP",FindDocDr,LocDr)) Quit:LocDr=""  d
		.Set RowId=0 f  Set RowId=$O(^RB("RES",0,"CTPCP",FindDocDr,LocDr,RowId)) Quit:RowId=""  d
		..i ResRowIdStr="" s ResRowIdStr=RowId
		..e  s ResRowIdStr=ResRowIdStr_"^"_RowId
	}
	Q ResRowIdStr
}

/// 查找相符的就诊记录
ClassMethod GetSameAdm(PatientID As %String, AdmDep As %String, AdmDoc As %String, AdmDate As %Date) As %String
{
	s ^zhou("GetSameAdm")=PatientID_","_AdmDep_","_AdmDoc_","_AdmDate
	;w ##class(web.DHCOPAdmReg).GetSameAdm(93,43,862,61046)
	;lxz 按照就诊两种类型来看，来分别检测就诊更合理
	s AdmType="O"
	if AdmType'="E" {
		s IsEmergency=..IsEmergency(AdmDep)
		if IsEmergency="1" s AdmType="E"
	}
	s FindAdmRowId=""
	s AdmRowId=0  f  s AdmRowId=$O(^PAPERdr(PatientID,"ADM",AdmType,AdmRowId)) Q:AdmRowId=""  d
	.s CurrAdmDep=$P(^PAADM(AdmRowId),"^",4)
	.s CurrAdmDoc=$P(^PAADM(AdmRowId),"^",9)
	.s CurrAdmStatus=$P($g(^PAADM(AdmRowId)),"^",20)
	.s CurrAdmDate=$P($g(^PAADM(AdmRowId)),"^",6)
	.Q:(CurrAdmDep'=AdmDep)!(CurrAdmDoc'=AdmDoc)!(CurrAdmDate'=AdmDate)
	.Q:(CurrAdmStatus="C")||(CurrAdmStatus="D")
	.s FindAdmRowId=AdmRowId
	Q FindAdmRowId
}

/// 得到排班记录对应的费用总额
ClassMethod GetSchedulOtherFee(ASRowId As %String) As %String
{
	;w ##class(web.DHCOPAdmReg).GetScheduleFee(ASRowId,"",+$H,"||||||1")
	s HospId=$p(..GetCurrentHosp("","",ASRowId,""),"^",1)
	s RegConDisIdPara=""_"^"_ASRowId_"^"_""_"^"_""
	s RegConDisId=..GetRegConDisId(RegConDisIdPara)
	set Price=0
	;取挂号费和诊查费和节假日挂号费信息
	s SerIdStr=..GetScheduleService(ASRowId)
	i SerIdStr'="" {
	 f i=1:1:$l(SerIdStr,"^") {
		 ;s SerId=$P(SerIdStr,"^",i)
		 ;s ArcimId=$p(^RBC("SER",SerId),"^",1)
		 s ArcimId=$P(SerIdStr,"^",i)
		 i (ArcimId="") {continue}
		 ;判断挂号所涉及的费用分类性质并插入医嘱表
		 ;s RegSerBillSubType=..GeRegSerBillSubType(SerId)
		 s RegSerBillSubType=..GetRegArcimBillSubType(ArcimId)
		 i (RegSerBillSubType="Other"){
		 	s Price=$p(##Class(web.UDHCJFPRICE).GetOrderPrice("","",ArcimId,+$h,"","","","",HospId,RegConDisId),"^",4)
		 }
	 }
	}
	Q Price
}

/// 得到排班记录对应的费用总额
ClassMethod GetScheduleFee(ASRowId As %String, AdmReason As %String, AdmDate As %String, FeeStr As %String, PatientID As %String = "") As %String
{
	;w ##class(web.DHCOPAdmReg).GetScheduleFee(ASRowId,"",+$H,"||||||1")
	s Fee=$P(FeeStr,"||",1)
	s checkfee=$P(FeeStr,"||",2)
	s holi=$P(FeeStr,"||",3)
	s appfee=$P(FeeStr,"||",4)
	s recheckfee=$P(FeeStr,"||",6)
	;w "examfee:"_examfee_",holi:"_holi_",appfee:"_appfee
	
	s HospId=$p(..GetCurrentHosp("","",ASRowId,""),"^",1)
	s RegConDisIdPara=PatientID_"^"_ASRowId_"^"_AdmReason_"^"_""
	s RegConDisId=..GetRegConDisId(RegConDisIdPara)
	set Price=0
	;取挂号费和诊查费和节假日挂号费信息
	s SerIdStr=..GetScheduleService(ASRowId,AdmReason)
	i SerIdStr'="" {
	 f i=1:1:$l(SerIdStr,"^") {
		 ;s SerId=$P(SerIdStr,"^",i)
		 ;s ArcimId=$p(^RBC("SER",SerId),"^",1)
		 s ArcimId=$P(SerIdStr,"^",i)
		 i (ArcimId="") {continue}
		 ;判断挂号所涉及的费用分类性质并插入医嘱表
		 ;s RegSerBillSubType=..GeRegSerBillSubType(SerId)
		 s RegSerBillSubType=..GetRegArcimBillSubType(ArcimId)
		 ;诊查费
		 i (RegSerBillSubType="Check")&&((checkfee=0)!(checkfee="")) {continue}
		 ;复诊诊查费
		 i (RegSerBillSubType="ReCheck")&&((recheckfee=0)!(recheckfee="")) {continue}
		 ;收复诊费则不收诊查费
		 i (RegSerBillSubType="Check")&&((recheckfee'=0)&&(recheckfee'="")) {continue}
		 i (RegSerBillSubType="App")&&((appfee=0)!(appfee="")) {continue}
		 i (RegSerBillSubType="Holi")&&((holi=0)!(holi="")) {continue}
		 s BillPrice=$p(##Class(web.UDHCJFPRICE).GetOrderPrice("",AdmReason,ArcimId,AdmDate,"","","","",HospId,RegConDisId),"^",4)
		 ;w RegSerBillSubType_"^"_BillPrice
		 s Price=Price+BillPrice
	 }
	}
	Q Price
}

/// creator:guorongyong
/// date:2010-08-24
/// desc:免费挂号某些设置子类 eg "Reg^Check"
/// Input:免费设置的设置串,需要修改的医嘱串
/// OutPut:修改后的医嘱串
ClassMethod UpdateSerIdStrFree(FreeStr As %String, SerIdStr As %String) As %String
{
	s UpdatedSerIdStr=""
	for i=1:1:$length(SerIdStr,"^") {
		s TmpSerId=$P(SerIdStr,"^",i)
		if TmpSerId="" continue
		s RegSerBillSubType=..GetRegArcimBillSubType(TmpSerId)
		if (RegSerBillSubType'="")&&(("^"_FreeStr_"^")[("^"_RegSerBillSubType_"^")) continue
		
		if UpdatedSerIdStr="" s UpdatedSerIdStr=TmpSerId
		else  s UpdatedSerIdStr=UpdatedSerIdStr_"^"_TmpSerId
	}
	
	Q UpdatedSerIdStr
}

/// 得到排班记录对应的服务串,如果模板上未定义服务则去找医生上所定义的服务
ClassMethod GetScheduleService(ASRowId As %String, AdmReason As %String = "", HospId As %String = "") As %String
{
	 s HospId=##class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospId)
	 if HospId=""{
	 	s LocID=$P(^RB("RES",+ASRowId),"^",1)
	 	s HospId=$P(^CTLOC(LocID),"^",22)
	 }
	 ;取挂号费和诊查费和节假日挂号费信息,利用SER_ReminderDays来区分
	 s SerIdStr="",ArcimIdStr=""
	 s ResRowId=+ASRowId
	 s ASChildSub=$P(ASRowId,"||",2)
	 /*s FromRessRowId=$P($G(^RBAS(ResRowId,ASChildSub)),"^",12)
	 i FromRessRowId'="" {
		s DateRowId=$P(FromRessRowId,"||",2)
		s SessRowId=$P(FromRessRowId,"||",3)
		if $d(^RB("RES",ResRowId,"DATE",DateRowId,"SESS",SessRowId)) {
			Set SessSerRowId=0 f  s SessSerRowId=$O(^RB("RES",ResRowId,"DATE",DateRowId,"SESS",SessRowId,"SER",SessSerRowId)) q:(SessSerRowId="")  d
			.s SerId=$p($G(^RB("RES",ResRowId,"DATE",DateRowId,"SESS",SessRowId,"SER",SessSerRowId)),"^",1)
			.;RegId=RB_ResEffDateSessServices.SER_ReminderDays
			.s RegId=$p($G(^RB("RES",ResRowId,"DATE",DateRowId,"SESS",SessRowId,"SER",SessSerRowId)),"^",6)
			.s ArcimId=$p($G(^RBC("SER",SerId)),"^",1)
			.Q:+ArcimId=0
			.Q:##class(DHCDoc.Common.Hospital).GetHospShowDataFlag("ARC_ItmMast",ArcimId,HospId)="N"
			.i ArcimIdStr="" s ArcimIdStr=ArcimId
			.e  s ArcimIdStr=ArcimIdStr_"^"_ArcimId
			.i SerIdStr="" s SerIdStr=SerId
			.e  s SerIdStr=SerIdStr_"^"_SerId
		}
	 }
	 ;w "ArcimIdStr:"_ArcimIdStr
	 if SerIdStr="" {
		Set DocDr=$p(^RB("RES",ResRowId),"^",2)
		s SerId=0  f  s SerId=$O(^RBC("SER",0,"CTCP",DocDr,SerId)) q:SerId=""  d
		.s ArcimId=$p($G(^RBC("SER",SerId)),"^",1)
		.Q:+ArcimId=0
		.Q:##class(DHCDoc.Common.Hospital).GetHospShowDataFlag("ARC_ItmMast",ArcimId,HospId)="N"
		.i SerIdStr="" s SerIdStr=SerId
		.e  s SerIdStr=SerIdStr_"^"_SerId
		.i ArcimIdStr="" s ArcimIdStr=ArcimId
		.e  s ArcimIdStr=ArcimIdStr_"^"_ArcimId
	 }*/
	 ;w "ArcimIdStr:"_ArcimIdStr
	 if ArcimIdStr="" {
		s SessionTypeRowId=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",6)
		i SessionTypeRowId'="" {
			s Child=0 f  s Child=$O(^RBC("SESS",SessionTypeRowId,"SER",Child)) q:(Child="")  d
			.s ArcimId=$p($G(^RBC("SESS",SessionTypeRowId,"SER",Child)),"^",1)
			.Q:+ArcimId=0
			.s HospDr=$p($G(^RBC("SESS",SessionTypeRowId,"SER",Child)),"^",2)
			.q:(HospDr'="")&&(HospDr'=HospId)
			.s SESSType=$p(^RBC("SESS",SessionTypeRowId,"SER",Child),"^",3)
			.q:((SESSType="OrderPre")||(SESSType="OrderDiag"))
			.Q:##class(DHCDoc.Common.Hospital).GetHospShowDataFlag("ARC_ItmMast",ArcimId,HospId)="N"
			.s EXCludeAdmReasonList=##Class(web.DHCRBResource).GetEXCludeAdmReasonList(SessionTypeRowId_"||"_Child)
			.q:(AdmReason'="")&&(EXCludeAdmReasonList[("^"_AdmReason_"^"))
			.i ArcimIdStr="" s ArcimIdStr=ArcimId
			.e  s ArcimIdStr=ArcimIdStr_"^"_ArcimId
		}
	 }
	 Q ArcimIdStr
}

/// 得到性别
ClassMethod GetSexStr() As %String
{
	;w ##class(web.DHCOPAdmReg)GetSexStr()
	s ret1=""
	s RowId=0 f  Set RowId=$o(^CT("SEX",RowId)) Quit:RowId=""  d
	.s Desc=$p(^CT("SEX",RowId),"^",2)
	.s ret=RowId_$C(1)_Desc
 .i ret1="" s ret1=ret
 .e  s ret1=ret_"^"_ret1
 Q ret1
}

ClassMethod GetTimeRangeByTime(SessTime As %String) As %String
{
	;根据传入时间得到最符合此时间的时段，逻辑：按此时间与时段时间间隔最短
	Q ##class(web.DHCRBResSession).GetTimeRangeByTime(SessTime)
	/*
	s find=0,ret=""
	s TRRowId=0  f  s TRRowId=$O(^DHCTimeRange(TRRowId)) Q:(TRRowId="")!(find=1)  d
	.s StartTime=$P(^DHCTimeRange(TRRowId),"^",3)
	.s EndTime=$P(^DHCTimeRange(TRRowId),"^",4)
	.i (SessTime'<StartTime)&&(SessTime'>EndTime) d
	..s find=1
	..s ret=TRRowId
	.Q:find=1
	if ret="" {
		s TRRowId=0  f  s TRRowId=$O(^DHCTimeRange(TRRowId)) Q:(TRRowId="")  d
		.s StartTime=$P(^DHCTimeRange(TRRowId),"^",3)
		.s EndTime=$P(^DHCTimeRange(TRRowId),"^",4)
		.i (SessTime>EndTime) s ret=TRRowId
	}
	Q ret
	*/
}

ClassMethod GetTimeRangeStr(Flag As %String, HospId As %String = "") As %String
{
	;Flag=0 按照当前时间点得到时段串
    s langid = ..%LanguageID()
	s ret=""
	s HospId=##class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospId)
	s SessTime=..%SysTime()
	s TRRowId=0  f  s TRRowId=$O(^DHCTimeRange(TRRowId)) Q:(TRRowId="")  d
	.s TRDesc=$P(^DHCTimeRange(TRRowId),"^",2)
    .s TRDesc = ##class(User.DHCTimeRange).GetTranByDesc("TRDesc",TRDesc,langid)
	.s TRCode=$P(^DHCTimeRange(TRRowId),"^",1)
	.Q:##class(DHCDoc.Common.Hospital).GetHospShowDataFlag("DHC_TimeRange",TRRowId,HospId)="N"
	.s StartTime=$P(^DHCTimeRange(TRRowId),"^",3)
	.s EndTime=$P(^DHCTimeRange(TRRowId),"^",4)
	.s UseStDate=$P(^DHCTimeRange(TRRowId),"^",7)
	.Q:(UseStDate>+$H)&&(UseStDate'="")
	.s UseEndDate=$P(^DHCTimeRange(TRRowId),"^",8)
	.Q:(UseEndDate<+$H)&&(UseEndDate'="")
	.Q:(SessTime>EndTime)&&(Flag=0)
	.s TRData=TRRowId_$C(1)_TRDesc_$C(2)_TRCode
	.i ret="" s ret=TRData
	.e  s ret=ret_"^"_TRData
	Q ret
}

/// 得到所传入的科室loc号别doc的排班记录注：doc实际指的是选择的号别MarkID
ClassMethod GetTodayASRowIdByRes(loc As %String, doc As %String, NeedAllFlag As %String = "", SecheduleDate As %String = "", TimeRangeId As %String = "") As %String
{
	;s ^gry("GetTodayASRowIdByRes")=loc_","_doc_","_NeedAllFlag_","_SecheduleDate_","_TimeRangeId
	;w ##class(web.DHCOPAdmReg).GetTodayASRowIdByRes(63,838)
	if SecheduleDate="" {
		s SecheduleDate=..%SysDate()
	}else {
		i $l(SecheduleDate,"-")=3 s SecheduleDate=$zdh(SecheduleDate,3)
		i $l(SecheduleDate,"/")=3 s SecheduleDate=$zdh(SecheduleDate,4)
	}
	Q:doc="" ""
	s ResRowId=$O(^RB("RES",0,"CTPCP",doc,loc,0))
	if ResRowId="" Q ""
	s TRRowId=TimeRangeId
	s DefaultASRowId=""
	s AvailAS=##class(web.DHCRBApptSchedule).GetAvailRA(ResRowId,SecheduleDate,"",TRRowId,"","N")
	i AvailAS'="" {
		s DefaultTimeRangeRowId=##class(web.DHCRBResSession).GetTimeRangeByTime(..%SysTime())
		if (DefaultTimeRangeRowId'="") {
			for i=1:1:$l(AvailAS,"^") {
				s ASRowId=$P(AvailAS,"^",i)
				//停止挂号（医生坐诊信息开启停止挂号后，不允许挂号及取号）
			    s StopRegFlag=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",30)
			    continue:StopRegFlag="Y"
				s ASTimeRangeDr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",17)
				if (DefaultTimeRangeRowId=ASTimeRangeDr) {
					s DefaultASRowId=ASRowId
					Q
				}
			}
		}
		//如果获取非当前时段排班就诊登记时，需要重新生成排班
		if DefaultASRowId="" s DefaultASRowId=$P(AvailAS,"^",1)
	}
	Q DefaultASRowId
}

/// 得到医生doc所在科室对应的所有号别的排班记录
ClassMethod GetTodayAllASRowIdByRes(loc As %String, doc As %String, NeedAllFlag As %String = "", SecheduleDate As %String = "", TimeRangeId As %String = "") As %String
{
	;s ^gry("GetTodayAllASRowIdByRes")=loc_","_doc_","_NeedAllFlag_","_SecheduleDate_","_TimeRangeId
	;w ##class(web.DHCOPAdmReg).GetTodayAllASRowIdByRes(63,920,"","2014-03-27","")
	if SecheduleDate="" {
		s SecheduleDate=..%SysDate()
	}else {
		i $l(SecheduleDate,"-")=3 s SecheduleDate=$zdh(SecheduleDate,3)
		i $l(SecheduleDate,"/")=3 s SecheduleDate=$zdh(SecheduleDate,4)
	}
	Q:doc="" ""
	s TRRowId=TimeRangeId
	;查找指定日期时段的医生所对应的所有好别的所有的排班记录
	Set FindASRowId=""
	Set Markid=0
	f  s Markid=$O(^User.DHCMarkDocI("MarkdDocMarkIndex",doc,Markid)) Q:Markid=""  d
	.q:Markid=""
	.s ResRowId=$O(^RB("RES",0,"CTPCP",Markid,loc,0))
	.Q:ResRowId="" 
	.s AvailAS=##class(web.DHCRBApptSchedule).GetAvailRA(ResRowId,SecheduleDate,"",TRRowId,"")
	.i AvailAS'=""  d
	..if FindASRowId'="" s FindASRowId=FindASRowId_"^"_AvailAS
	..else  s FindASRowId=AvailAS	
	Q FindASRowId
}

/// Creator:      lixiangzong
/// Description:  根据用户ID和登录科室ID获取用户所对应的号别
/// Input:		  UserID用户ID,LocID科室ID,DisType=1 使用JSON返回数据
/// Return:       返回MarkDocDesc_"^"_MarkDocID 对应号别的描述和ID
/// w ##class(web.DHCOPAdmReg).FindDocMarkStr(600,63)
ClassMethod FindDocMarkStr(UserID As %String, LocID As %String, DisType As %String = "") As %String
{
	s ^Tempzong("FindMarkStr")=UserID_","_LocID
	Q:((UserID="")||(LocID="")) ""
	s DocID=$P(^SSU("SSUSR",UserID),"^",14)
	Q:DocID="" ""
	s Ret=""
	s DHCMarkRowID=0 
	f  s DHCMarkRowID=$O(^User.DHCMarkDocI("MarkdDocMarkIndex",DocID,DHCMarkRowID))  Q:DHCMarkRowID=""  d
	.s FindFlag=0
	.s ID="" f  s ID=$O(^User.DHCMarkDocI("MarkdDocMarkIndex",DocID,DHCMarkRowID,ID)) Q:(ID="")||(FindFlag=1)  d
	..s MarkDepId=$list(^User.DHCMarkDocD(ID),4)
	..i MarkDepId=LocID s FindFlag=1
	..b ;34
	.Q:FindFlag=0
	.s ResRowID=$O(^RB("RES",0,"CTPCP",DHCMarkRowID,LocID,0))
	.Q:ResRowID=""
	.s ScheSt=$p(^RB("RES",ResRowID),"^",6)
	.Q:ScheSt'="Y"
	.s MarkDesc=$p($g(^CTPCP(DHCMarkRowID,1)),"^",2)
	.i DisType=1 d
	..if Ret=""  s Ret="["_"'"_DHCMarkRowID_"'"_","_"'"_MarkDesc_"'"_"]"
	..else  s Ret=Ret_","_"["_"'"_DHCMarkRowID_"'"_","_"'"_MarkDesc_"'"_"]"
	.e  d
	..if Ret=""  s Ret=DHCMarkRowID_$C(1)_MarkDesc
	..else  s Ret=Ret_"^"_DHCMarkRowID_$C(1)_MarkDesc
	
	if Ret=""{
		if DisType=1{
			//s Ret="["_"'"_INTIM_bz_"'"_","_"'"_$p($g(^CTPCP(DocID,1)),"^",2)_"'"_"]"
		}else{
			s Ret=DocID_$c(1)_$p($g(^CTPCP(DocID,1)),"^",2)
		}
	}
	Q Ret
}

/// 插入挂号医嘱
/// w ##class(web.DHCOPAdmReg).InsertRegOrder(1927,"426||30","0||0||0||0||0||0||0",7,119,"","","","",98)
ClassMethod InsertRegOrder(AdmRowId As %String, ASRowId As %String, FeeStr As %String, user As %String, group As %String, FreeRegFlag As %String, FreeCheckFlag As %String, ByRef Price As %String, ByRef DiscountFactor As %String, RegConDisId As %String = "") As %String
{
	s Re=AdmRowId
	s ResRowId=$P(ASRowId,"||",1)
	s ASChild=$P(ASRowId,"||",2)
	s AdmReason=$P(^PAADM(AdmRowId,1),"^",7)
	s AdmDep=$P(^PAADM(AdmRowId),"^",4)
	s AdmDate=$P(^PAADM(AdmRowId),"^",6)
	s AdmTime=$P(^PAADM(AdmRowId),"^",7)

	s Fee=$P(FeeStr,"||",1)
	s checkfee=$P(FeeStr,"||",2)
	s holi=$P(FeeStr,"||",3)
	s appfee=$P(FeeStr,"||",4)
	s mrfee=$P(FeeStr,"||",5)
	s recheckfee=$P(FeeStr,"||",6)
	s cardfee=$P(FeeStr,"||",7)
	;w "examfee:"_examfee_",holi:"_holi_",regfee:"_regfee
    
    s PatientID=$P(^PAADM(AdmRowId),"^",1)
    s HospId=$p(..GetCurrentHosp(AdmRowId,"","",""),"^",1)
    if (RegConDisId=""){
		s RegConDisIdPara=PatientID_"^"_ASRowId_"^"_AdmReason_"^"_""_"^"_HospId
		s RegConDisId=..GetRegConDisId(RegConDisIdPara)
	}
	s OrdSeqNo=0
	TStart
	set err=0
	set Price=0
	;取挂号费和诊查费和节假日挂号费信息
	s SerIdStr=..GetScheduleService(ASRowId,AdmReason,HospId)
	s SerIdStr=..GetCustomScheduleService(PatientID,ASRowId,SerIdStr)
	i cardfee=1  {
	 	s CardFeeArcimId=..GetCardFeeArcimId()
	 	if CardFeeArcimId'="" {
		 	if SerIdStr="" s SerIdStr=CardFeeArcimId
		 	else  s SerIdStr=SerIdStr_"^"_CardFeeArcimId
	 	}
	}
	i mrfee=1  {
	 	s MRFeeArcimId=..GetMRFeeArcimId(HospId)
	 	if MRFeeArcimId'="" {
		 	if SerIdStr="" s SerIdStr=MRFeeArcimId
		 	else  s SerIdStr=SerIdStr_"^"_MRFeeArcimId
	 	}
	}
	s InsertOrdFlag=0
	;如果没有医嘱，则取挂号设置的免费医嘱
	Set FreeOrder=$p(##class(web.DHCOPRegConfig).GetSpecConfigNode("FreeOrder",HospId),"@",1)
	if SerIdStr="" s SerIdStr=FreeOrder
	S AdmLoc=$p(^RB("RES",+ASRowId),"^",1)
	 s AdmType="O"
	 if AdmType'="E" {
		s IsEmergency=..IsEmergency(AdmLoc)
		if IsEmergency="1" s AdmType="E"
	 }
	  s OPRegInsertOrder=##class(web.DHCOPRegConfig).GetGroupConfig(HospId,group,"OPRegInsertOrder")
	s PriceExpStr=RegConDisId_"^^^^^^^^"_PatientID_"^"_AdmType
	i SerIdStr'="" {
	 	f i=1:1:$l(SerIdStr,"^") {
			 ;s SerId=$P(SerIdStr,"^",i)
			 ;s ArcimId=$p(^RBC("SER",SerId),"^",1)
			 s ArcimId=$P(SerIdStr,"^",i)
			 i (ArcimId="") {continue}
			 ;判断挂号所涉及的费用分类性质并插入医嘱表
			 ;s RegSerBillSubType=..GeRegSerBillSubType(SerId)
			 s RegSerBillSubType=..GetRegArcimBillSubType(ArcimId,HospId)
			 s BillPrice=$p(##Class(web.UDHCJFPRICE).GetOrderPrice("",AdmReason,ArcimId,AdmDate,"","","","",HospId,PriceExpStr),"^",4)
			 if (OPRegInsertOrder'=1){
				i (RegSerBillSubType="Check")&&((checkfee=0)!(checkfee=""))&&(+BillPrice'=0) {continue}
				i (RegSerBillSubType="ReCheck")&&((recheckfee=0)!(recheckfee=""))&&(+BillPrice'=0) {continue}
				i (RegSerBillSubType="Check")&&((recheckfee'=0)&&(recheckfee'="")) {continue}
				i (RegSerBillSubType="App")&&((appfee=0)!(appfee=""))&&(+BillPrice'=0) {continue}
				i (RegSerBillSubType="Holi")&&((holi=0)!(appfee=""))&&(+BillPrice'=0) {continue}
				i ((RegSerBillSubType="Reg")&&(FreeRegFlag="Y"))  {continue}
				i ((RegSerBillSubType="Check")&&(FreeCheckFlag="Y"))  {continue}
			 }
			 
			 ;w ##Class(web.UDHCJFPRICE).GetOrderPrice("","","1||1",60971,"","","","")
			 
			 s Price=Price+BillPrice
			 s err=$$insertitem()
			 s InsertOrdFlag=1
			 Q:err=100
	 	}
	}else{
		TRollback
		Q "-405"
	}
	i err=100 {
		TRollback
		Q err
	}
	//修复挂号医嘱不为空(且不是免费医嘱),但挂号费、诊查费的折扣系数为1,导致未插入任何挂号医嘱,计费错误
	if (InsertOrdFlag=0)&&(Price=0)&&(FreeOrder'="") {
		s ArcimId=FreeOrder
		s err=$$insertitem()
	}
	TC
	Q 0
insertitem()
	s OrdSeqNo=+OrdSeqNo+1
	s ordstr=ArcimId_"^"_"1"_"^"_AdmDep_"^"_0_"^"_""_"^"_AdmReason_"^"_AdmDate_"^"_AdmTime
	i DiscountFactor'=""{
		s ordstr=ArcimId_"^"_DiscountFactor_"^"_AdmDep_"^"_0_"^"_""_"^"_AdmReason_"^"_AdmDate_"^"_AdmTime
	}
	s AddDoctor=$p(^SSU("SSUSR",user),"^",14)
	s ordcat=$p(^ARCIM(+ArcimId,1,1),"^",10)
	s ordtype=$p(^ARC("IC",ordcat),"^",7)
	s priority=$o(^OECPR(0,"Code","NORM",""))
	i priority="" Set priority=$o(^OECPR(0))
	s PackQty=$p(ordstr,"^",2)
	if +PackQty=0 Set PackQty=1
	s NewOrdstr=ArcimId_"^"_ordtype_"^"_priority_"^"_..%ZD(AdmDate)_"^"_..%ZT(AdmTime,1)_"^"_PackQty_"^0^"_AdmDep_"^"_AdmReason
	s $p(NewOrdstr,"^",20)=OrdSeqNo
	s $p(NewOrdstr,"^",58)="RTO"
	s ResValue=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.ord.SaveOrderItems",Re,NewOrdstr,user,AdmDep,AddDoctor)
	//s ResValue=##Class(web.DHCOPCashier).Insert(Re,ordstr,user,AdmDep,"","")
	s d=$p(ResValue,"^",1)
	i (d'=0)&&(d'=100) s d=0
	b ;Insert PriceArcId
	if d'=0{
		Q "100"
	}
	Q 0
}

ClassMethod GetregisterFee(EpisodeID) As %String
{
	
	if EpisodeID="" quit
	s OEORDRowId=$O(^OEORD(0,"Adm",EpisodeID,""))
	quit:'$D(^OEORD(OEORDRowId))
	s rtn=EpisodeID_"!"
	s OEORIChildsub="0" f  s OEORIChildsub=$O(^OEORD(OEORDRowId,"I",OEORIChildsub)) q:OEORIChildsub=""  d
	.q:'$D(^OEORD(OEORDRowId,"I",OEORIChildsub))
	.S ItmMastDR=$P($G(^OEORD(OEORDRowId,"I",OEORIChildsub,1)),"^",2)
	.S ARCIMSubscript=$P(ItmMastDR,"||",1) S ARCIMVersion=$P(ItmMastDR,"||",2)
	.S ARCIMDesc=$p($G(^ARCIM(ARCIMSubscript,ARCIMVersion,1)),"^",2)
	.S ItemCat=$p($G(^ARCIM(ARCIMSubscript,ARCIMVersion,1)),"^",10)
	.S ItemStat=$P($G(^OEORD(OEORDRowId,"I",OEORIChildsub,1)),"^",13)
	.q:ItemStat'=1
	.s PhQtyOrd=$P($G(^OEORD(OEORDRowId,"I",OEORIChildsub,1)),"^",12)
	.s UnitPrice=##class(web.DHCDocOrderEntry).GetOrderPrice("", "", ItmMastDR, "", "", "", "", "")
	.s UnitPrice=$p(UnitPrice,"^",1)
	.s rtn=rtn_OEORDRowId_"||"_OEORIChildsub_"^"_ItmMastDR_"^"_ARCIMDesc_"^"_ItemCat_"^"_PhQtyOrd_"^"_UnitPrice_"!"
	q rtn
}

ClassMethod IsEmergency(AdmDep As %String)
{
	s AdmType=""
	set LinkLocDr=0
	Set LinkLocDr=$o(^CTLOC(AdmDep,"LINK",0,"Loc",0))
	if LinkLocDr'="" d
	.s LinkLocType=$p(^CTLOC(LinkLocDr),"^",13)
	.i LinkLocType="EM" Set AdmType="E"
	i AdmType="E" Q 1
	Q 0
}

ClassMethod IsEmergencyByRBAS(AsRowId As %String)
{
	s RBRowId=+AsRowId
	s DeptDr=$p(^RB("RES",RBRowId),"^",1)
	q ..IsEmergency(DeptDr)
}

/// 预约取号
ClassMethod OPAppArrive(APPTRowId As %String, UserRowId As %String, GroupRowId As %String = "", ByRef RegfeeRowId As %String, PayModeCode As %String, AccRowId As %String, AdmReason As %String = "", FeeStr As %String = "")
{
	s ^zhou("OPArrive")=APPTRowId_","_UserRowId_","_GroupRowId
	;w ##class(web.DHCOPAdmReg).OPAppArrive("1876||281||1",639,89)
	Set object =##class(User.RBAppointment).%OpenId(APPTRowId)
	i $IsObject(object) {
		s RBASRowId=object.APPTASParRef.%Id()
		s APPTStatus=object.APPTStatus
		;已经取号
		i APPTStatus="A" {
			d object.%Close()
			Q "-221"
		}
		i APPTStatus="X" {
			d object.%Close()
			Q "-220"
		}
		s QueueNo=object.APPTQueueNo
		s MethodCode=""
		s MethodDr=object.APPTMethodDR.%Id()
		i MethodDr'="" {s MethodCode=$P(^RBC("APTM",MethodDr),"^",1)}

		s PatientID=object.APPTPAPMIDR.%Id()
		s AdmDate=$p($g(^RBAS(+APPTRowId,+$p(APPTRowId,"||",2))),"^")
		s AdmTime=..%SysTime() ;$p($g(^RBAS(+APPTRowId,+$p(APPTRowId,"||",2))),"^",4)
		d object.%Close()

 		if (AdmDate'=..%SysDate()){
			;Q "-230"
		}

		s PatCatDr=$p(^PAPER(PatientID,"PER",1),"^",10)
		i AdmReason="" s AdmReason=..GetDefaultBillType(PatCatDr)
		s Name=$p($g(^PAPER(PatientID,"ALL")),"^",1)
		s PatientNo=$p($g(^PAPER(PatientID,"PAT",1)),"^",1)
		;s ResRowId=$P(APPTRowId,"||",1)
		
		s TRRBASRowId=""
	  	s RBASStatusDr=$P(^RBAS(+RBASRowId,$P(RBASRowId,"||",2),"DHC"),"^",10)
	 	s RBASStatusCode=$P(^DHCRBCASStatus(RBASStatusDr),"^",1)
	 	if (RBASStatusCode="S") {
		 	Q "-224"
	 	}
	 	i (RBASStatusCode="TR") d
	 	.s TRRBASRowId=$P(^RBAS(+RBASRowId,$P(RBASRowId,"||",2),"DHC"),"^",12)
	 	
		i $G(TRRBASRowId)'="" s RBASRowId=TRRBASRowId
		;如果有替诊则取替诊的信息
		s ResRowId=+RBASRowId
		s ASChild=$P(RBASRowId,"||",2)
		s AdmDep=$P($G(^RB("RES",ResRowId)),"^",1)
		s AdmDoc=$P($G(^RB("RES",ResRowId)),"^",2)
		s ASStartTime=$P($G(^RBAS(ResRowId,ASChild)),"^",4) 
		s RoomDr=$P($G(^RBAS(ResRowId,ASChild,"DHC")),"^",5)
		s SessionTypeDr=$P($G(^RBAS(ResRowId,ASChild,"DHC")),"^",6)
		s RegfeeTimeRangeDr=$P($G(^RBAS(ResRowId,ASChild,"DHC")),"^",17)

		s user=UserRowId
		s group=GroupRowId
		s CreateUser=UserRowId
		s AdmType="O"
		if AdmType'="E" {
			s IsEmergency=..IsEmergency(AdmDep)
			if IsEmergency="1" s AdmType="E"
		}
		
		s DiagnosCatRowId=""
		s InsuCoDR=""
		s PatAdmissionTp=..GetPatAdmissionTp(RBASRowId)
		s RegConDisIdPara=PatientID_"^"_RBASRowId_"^"_AdmReason_"^"_""
		s RegConDisId=..GetRegConDisId(RegConDisIdPara)
		s AdmCategory="",HospitalID=$P(^CTLOC(AdmDep),"^",22)
		if AdmType ="O" {
			s AdmCategory=##class(web.DHCOPRegConfig).GetGroupConfig(HospitalID,group,"OPRegAdmCategory")
		}
		s Para=PatientID_"^"_AdmType_"^"_AdmDate_"^"_AdmTime_"^"_AdmDep_"^"_AdmDoc_"^"_AdmReason_"^"_CreateUser_"^^^^"_PatAdmissionTp_"^"_AdmCategory_"^^"_DiagnosCatRowId_"^^^^^"_InsuCoDR_"^"_RegConDisId
		TStart
		s EpisodeID=##class(web.DHCPAADM).ADMInsert(Para)
		i EpisodeID'="" {
		    s err=##Class(web.DHCRBAppointment).AppArrive(APPTRowId,EpisodeID,UserRowId)
		    i err'=0 {
			    TRollback
				Q "-222"
		    }
	    }
	    
		b ;记帐,取号要算预约费
		s InvoiceRowid=""
		;s PayModeCode=""
		;s AccRowId=""
		s NeedAppFee=##class(web.DHCRBAppointment).NeedAppFee(APPTRowId)
		if FeeStr=""   s FeeStr="1||1||0||||0||0"                    ;s FeeStr="||0||0||||0||0"
		i NeedAppFee="1" s $P(FeeStr,"||",4)=1
		
		i MethodCode="TEL" {}
		s ret=..OPBillCharge(EpisodeID,RBASRowId,AccRowId,PayModeCode,FeeStr,user,group,"","",.InvoiceRowid)
		if ret'=0 {
			TRollback
			Q ret
		}
		
		s examfee=0,Fee=0
		i InvoiceRowid'="" d
		.;s Fee=$P(^DHCINVPRT(InvoiceRowid),"^",1)
		.s PRTPatientShare=$P(^DHCINVPRT(InvoiceRowid),"^",16)
		.s Fee=PRTPatientShare
		

		b ;insert into DHCRegistrationFee
		s CurrDate=..%SysDate(),CurrTime=..%SysTime()
		;s RegfeeTimeRangeDr=##class(web.DHCRBResSession).GetTimeRangeByTime(ASStartTime)
		;插入挂号表 DHCRegistrationFee
		&SQL(insert into SQLUser.DHCRegistrationFee
			(RegfeeAdmDr,RegfeeName,RegfeeArcDr,RegfeeArcPrice,RegfeelookPrice,
			RegfeeBespFlag,RegfeeNo,RegfeeDoFlag,Regfeetemp1,RegfeeDepDr,RegfeeDocDr,
			RegfeeDate,RegfeeTime,RegfeeUserDr,RegfeeSessionTypeDr,RegfeeTimeRangeDr,
			RegfeeRoomDr,RegfeeRBASDr)
			Values(:EpisodeID,:Name,"",:Fee,:examfee,
			'No',:QueueNo,'Yes',:InvoiceRowid,:AdmDep,:AdmDoc,
			:CurrDate,:CurrTime,:user,:SessionTypeDr,:RegfeeTimeRangeDr,:RoomDr,:RBASRowId))
		if SQLCODE {
			TRollback
			Q "-211"
		}
		s RegfeeRowId=%ROWID
		 
		b ;插入队列 DHCQueue
		s Para=EpisodeID_"^"_RoomDr_"^"_QueueNo_"^"_user_"^^"_group
		s ret=..QueueInsert(Para)
		if ret {
			TRollback
			Q "-212"
		}

		TC
		
		//调用114停诊接口
		if (MethodCode="TEL"){
			s CFIFTeleAppStart=##class(web.DHCOPRegConfig).GetSpecConfigNode("IFTeleAppStart")
			if (CFIFTeleAppStart=1){
				set err=##class(dhcinterface.TeleClient).notifyGetNumber(APPTRowId)
				If err'=0 {
					Do $System.Status.DisplayError()
					;Trollback
					;Quit 100
				}
			}
		}
		;调用平台组接口
		s rtn=##class(web.DHCENS.EnsHISService).DHCHisInterface("SENDOPREGINFO",EpisodeID)
		Q 0
	}
	
	Q "-223"
}

ClassMethod OPAppArriveBroker(itmjs As %Library.String = "", itmjsex As %Library.String = "", APPTRowId As %String, UserRowId As %String = "", GroupRowId As %String = "", PayModeCode As %String = "", AccRowId As %String = "")
{
	;w ##class(web.DHCOPAdmReg).OPAppArriveBroker("","","1876||281||1",639,89)
	s ^zhou("arrive")=APPTRowId_","_UserRowId_","_GroupRowId_","_PayModeCode_","_AccRowId
	s RegfeeRowId=""
	s ret=..OPAppArrive(APPTRowId,UserRowId,GroupRowId,.RegfeeRowId,PayModeCode,AccRowId)
	s PrintData=""
	i ret="0" s PrintData=..GetPrintData(RegfeeRowId)
	s ret=ret_"$"_PrintData
	i itmjs'="" {
		s retval=itmjs_"('"_$ZCVT(ret,"O","JS")_"');"
		i itmjsex'="" s retval=retval_itmjsex_"('"_$ZCVT(ret,"O","JS")_"');"
		&javascript<#(retval)#>
	}
	q ret
}

/// 转预约取号
ClassMethod OPAppArriveTransfer(APPTRowId As %String, NewCardNo As %String, UserRowId As %String = "", GroupRowId As %String = "", ByRef RegfeeRowId As %String, PayModeCode As %String, AccRowId As %String)
{
	;w ##class(web.DHCOPAdmReg).OPAppArriveBroker("","","250||14||2",6,6)
	s ^zhou("OPAppArriveTransferBroker")=APPTRowId_","_NewCardNo_","_UserRowId_","_GroupRowId
	s NewPatientID=##class(web.DHCOPAdmReg).GetPatientIDByCardNo(NewCardNo)
	if NewPatientID="" Q "-201"
	Ts
	s ret=##class(web.DHCRBAppointment).TransferAppoint(APPTRowId,NewPatientID,UserRowId)
	s retcode=$P(ret,"^",1)
	i retcode=0 {
		s NewAPPTRowId=$P(ret,"^",2)
		s RegfeeRowId=""
		s ret=..OPAppArrive(NewAPPTRowId,UserRowId,GroupRowId,.RegfeeRowId,PayModeCode,AccRowId)
		s retcode=$P(ret,"^",1)
		if retcode'=0 {
			Tro
			Q "-202"
		}
	}else{
		Q "-203"
		tro
	}
	tc
	q 0
}

ClassMethod OPAppArriveTransferBroker(itmjs As %Library.String = "", itmjsex As %Library.String = "", APPTRowId As %String, NewCardNo As %String, UserRowId As %String = "", GroupRowId As %String = "", PayModeCode As %String, AccRowId As %String)
{
	;d ##class(web.DHCOPAdmReg).OPAppArriveTransferBroker("","","51||1||1","000100000000001",6,6)
	s RegfeeRowId=""
	s ret=..OPAppArriveTransfer(APPTRowId,NewCardNo,UserRowId,GroupRowId,.RegfeeRowId,PayModeCode,AccRowId)     ;原代码参数RegfeeRowId带点“.”
	s PrintData=""
	s ^tempshp("regfeerowid")=RegfeeRowId
	i ret="0" s PrintData=..GetPrintData(RegfeeRowId)
	s ret=ret_"$"_PrintData
	i itmjs'="" {
		s retval=itmjs_"('"_$ZCVT(ret,"O","JS")_"');"
		i itmjsex'="" s retval=retval_itmjsex_"('"_$ZCVT(ret,"O","JS")_"');"
		&javascript<#(retval)#>
	}
	q ret
}

/// 窗口预约预约号(医院电话预约,非现场预约,不出票)
/// w ##class("web.DHCOPAdmReg").OPAppBroker("","",18,559||2185,"",600)
ClassMethod OPAppBroker(itmjs As %Library.String = "", itmjsex As %Library.String = "", PatientID As %String, ASRowId As %Library.String = "", QueueNo As %Library.String = "", UserRowId As %Library.String = "", AppPatInfo As %Library.String = "", MethodCode As %String = "", TimeRangeStr As %String = "", HospitalID As %String = "", ClinicGroupId As %String = "", ExpStr As %String = "")
{
	//判断是否有公共卡
	;s ^tempshp("appp")=PatientID_"^"_ASRowId_"^"_QueueNo_"^"_UserRowId   ;18^559||2185^^600
	s CommonPatientID=..GetCommonPatientID("",HospitalID)
	s ResRowId=(+ASRowId)
	s AdmDep=$P($G(^RB("RES",ResRowId)),"^",1)
	s AdmDoc=$P($G(^RB("RES",ResRowId)),"^",2)
	s AdmDate=$P(^RBAS(+ASRowId,$p(ASRowId,"||",2)),"^",1)
	//公共卡不做限制
	i (("^"_CommonPatientID_"^")'[("^"_PatientID_"^")){
		s ret=..CheckRegCountLimit(PatientID,ASRowId,HospitalID)
		if ret'=0 Q ret
		///排版扩展设置限制
		s ret=##class(DHCDoc.OPAdm.ScheduleTemplateConfig).CheckOPRegExpandConfig(PatientID,ASRowId,"")
		if ret'=0 Q $p(ret,"^",2)
		///亚专业限制
		s ret=##class(web.DHCRBCClinicGroup).CheckClinicGroupLimitConfig(PatientID,ClinicGroupId,HospitalID)
		if ret'=0 Q $p(ret,"^",2)
	}
	s ApptTypeCode=$p(ExpStr,"^",1)
	s MethodDR=""
	i MethodCode'="" s MethodDR=$O(^RBC("APTM",0,"Code",MethodCode,0))	
	i MethodDR="" s MethodDR=$O(^RBC("APTM",0,"Code","WIN",0))
	s Para=PatientID_"^"_ASRowId_"^"_MethodDR_"^"_"O"_"^"_UserRowId
	s Para=Para_"^"_QueueNo_"^^"_AppPatInfo_"^^"_TimeRangeStr
	s Para=Para_"^"_ClinicGroupId_"^"_ApptTypeCode
	s ^tmplog("OPApp")=Para
	
	s ret=##class(web.DHCRBAppointment).Insert(Para,"",HospitalID)
	s retcode=$P(ret,"^",1)
	Q ret
}

/// 爱康预约 预约号   guorongyong 2008-03-26
ClassMethod OPAppAiKangBroker(itmjs As %Library.String = "", itmjsex As %Library.String = "", PatientID As %String, ASRowId As %Library.String = "", QueueNo As %Library.String = "", UserRowId As %Library.String = "")
{
	s MethodDR=$O(^RBC("APTM",0,"Code","AIKANG",0))	
	s Para=PatientID_"^"_ASRowId_"^"_MethodDR_"^"_"O"_"^"_UserRowId_"^"_QueueNo
	;s ^gry("OPAppAiKang")=Para
	s ret=##class(web.DHCRBAppointment).Insert(Para)
	s retcode=$P(ret,"^",1)
	Q ret
}

/// 电话预约
/// 预约方式业务 可能按方式是分开操作的，所以功能也分离出来
ClassMethod OPAppTelBroker(itmjs As %Library.String = "", itmjsex As %Library.String = "", PatientID As %String, ASRowId As %Library.String = "", QueueNo As %Library.String = "", UserRowId As %Library.String = "", AppPatInfo As %Library.String = "")
{
	s MethodDR=$O(^RBC("APTM",0,"Code","TEL",0))	
	s Para=PatientID_"^"_ASRowId_"^"_MethodDR_"^"_"O"_"^"_UserRowId_"^"_QueueNo_"^^"_AppPatInfo
	;s ^gry("OPAppTel")=Para
	s ret=##class(web.DHCRBAppointment).Insert(Para)
	s retcode=$P(ret,"^",1)
	Q ret
}

/// 窗口预约现场号(医院电话预约,非现场预约挂号,不出票)
ClassMethod OPAppNormalBroker(itmjs As %Library.String = "", itmjsex As %Library.String = "", PatientID As %String, ASRowId As %Library.String = "", QueueNo As %Library.String = "", UserRowId As %Library.String = "")
{
	s MethodDR=$O(^RBC("APTM",0,"Code","WIN",0))	
	s Para=PatientID_"^"_ASRowId_"^"_MethodDR_"^"_"O"_"^"_UserRowId_"^"_QueueNo_"^"_"NORN"
	s ^zhou("OPAppNormal")=Para
	s ret=##class(web.DHCRBAppointment).Insert(Para)
	s retcode=$P(ret,"^",1)
	Q ret
}

/// 收费
ClassMethod OPBillCharge(AdmRowId As %String, ASRowId As %String, AccRowId As %String, PayModeCode As %String, FeeStr As %String, user As %String, group As %String, FreeRegFlag As %Library.String = "", FreeCheckFlag As %Library.String = "", ByRef InvoiceRowid As %String, InsuCoStr As %String = "", DiscountFactor As %String = "", InsuJoinStr As %String = "", UnBillFlag As %String = "", RegConDisId As %String = "", HospitalID As %String = "", ETPRowID As %String = "", LoginLoc As %String = "") As %String
{
	s CFNotNeedNotFeeBill=##class(web.DHCOPRegConfig).GetSpecConfigNode("NotNeedNotFeeBill",HospitalID)
    s langid = ..%LanguageID()
	
	s Re=AdmRowId
	s ResRowId=$P(ASRowId,"||",1)
	s ASChild=$P(ASRowId,"||",2)
	s AdmReason=$P(^PAADM(AdmRowId,1),"^",7)
	s AdmDep=$P(^PAADM(AdmRowId),"^",4)
	s AdmDate=$P(^PAADM(AdmRowId),"^",6)
	s AdmTime=$P(^PAADM(AdmRowId),"^",7)
	s Fee=$p(FeeStr,"||",1)
	s TabMRFee=$p(FeeStr,"||",5)
	s TabReCheckFee=$p(FeeStr,"||",6)
	s TabCardFee=$p(FeeStr,"||",7)
	;界面上的勾选要判断
	//Q:(+Fee=0)&(+TabMRFee=0)&(+TabReCheckFee=0)&(+TabCardFee=0)&(CFNotNeedNotFeeBill=1) 0
	TStart
	set err=..InsertRegOrder(AdmRowId,ASRowId,FeeStr,user,group,FreeRegFlag,FreeCheckFlag,.Price,DiscountFactor,RegConDisId)
	i (err=100)||(err="-405") {
		TRollback
		Q $CASE(err,"-405":"-405",:"-206")
	}
	if (group'=""){
		s OPRegInsertOrder=##class(web.DHCOPRegConfig).GetGroupConfig(HospitalID,group,"OPRegInsertOrder")
		if (OPRegInsertOrder=1) {
			TC
			Q 0
		}
	}
	//因为在换号时传入的FeeStr="",为保证帐单成功,做如下处理	 
	s Fee=Price
	i DiscountFactor'=""{
		s Fee=Fee*DiscountFactor
	}
	;billing then insert into invoice
	s InvoiceRowid=""
	//Q:UnBillFlag="Y" 0 //不记账标志
	//If (Fee'=0)  {
	  If (UnBillFlag'="Y") {
		s OEOrdRowid=$o(^OEORD(0,"Adm",AdmRowId,""))
		if (OEOrdRowid="")||($O(^OEORD(OEOrdRowid,"I",0))=""){
			q "-214"
		}
		;如果没有传入支付方式 ,默认为现金 2020-08-20 去掉
		;i PayModeCode="" s PayModeCode="CASH"
		s PayModeid=$o(^CT("CTPM",0,"Code",PayModeCode,0))
		;获取扫码付返回的支付方式
		s PayModeidNew=##class(DHCBILL.Common.DHCBILLCommon).GetETPPayModeID(ETPRowID)
		i PayModeidNew'="" s PayModeid=PayModeidNew
		s PayMode=PayModeid_"^^^^^^^^"
		s RequirINVFlag="Y"
		//若费用为0,,挂号设置配置"无费用不走发票",则修改参数RequirINVFlag(是否需要发票)为N,只进行结算不产生发票号
		if (+Fee=0)&(+TabMRFee=0)&(+TabReCheckFee=0)&(+TabCardFee=0)&(CFNotNeedNotFeeBill=1) s RequirINVFlag="N"
		s FairType="R"
		s BillAccount=group_"^"_LoginLoc_"^"_AccRowId_"^"_RequirINVFlag_"^"_FairType
		s Value=##Class(web.DHCOPINVCons).OPBillCharge(Re,user,"",AdmReason,Fee,PayMode,group,"0","","0",BillAccount)
		b ;bill over
		s d=$p(Value,"^",1)
		s InvoiceRowid=$P(Value,"^",2)
		i d'=0 {
			TRollback
			s ^zhou("error")=d_"@1"_$g(^guo("OPBillCharge"))_"^"_Fee_"^"_DiscountFactor
			d ##class(DHCDoc.Log.Common).General("Insert","web.DHCOPAdmReg","OPBillCharge","计费预结算接口调用失败",Re,$tr(Value,"^",","))
			s BillChargeErrMsg=""
			s ExistFlag=##class(%Dictionary.MethodDefinition).%ExistsId("DHCBILL.SelfPay.BLL.DHCOPBillPayLogic"_"||"_"GetPreChargeErrMsg")
 			if (ExistFlag=1){
				s BillChargeErrMsg=##class(DHCBILL.SelfPay.BLL.DHCOPBillPayLogic).GetPreChargeErrMsg(d)
 			}
			s ErrMsg="-210"_","_..%Translate("opadm.reg.hui.csp","计费失败!请咨询计费组,计费错误代码",langid)_":["   // _Value_"]"
            s ErrMsg=ErrMsg_d_"^"_..%Translate("opadm.reg.hui.csp", $p(Value, "^", 2, $l(Value, "^")))_"]"
			if BillChargeErrMsg'=""{
				s ErrMsg=ErrMsg_","_..%Translate("opadm.reg.hui.csp","错误描述",langid)_":"_..%Translate("opadm.reg.hui.csp",BillChargeErrMsg,langid)
			}
			Q ErrMsg
		}
		
		set patSelfPayAmt=Fee  //患者自费金额，先默认全部自费
		;实时医保挂号调用计费接口,更新支付方式表(DHC_INVPayMode)
		if InsuJoinStr'="" {
			s InsuPayStr=$p(InsuJoinStr,"!",1)
			s InsuPayModeDetailStr=$p(InsuJoinStr,"!",2)
			s PatPayModeDR=$p(InsuPayStr,"^",4)
			if (PatPayModeDR'=""){
				for i=1:1:$l(InsuPayModeDetailStr,$c(2)) {
					s OneInsuPayModeStr=$p(InsuPayModeDetailStr,$c(2),i)
					s OneInsuPayModeId=$p(OneInsuPayModeStr,"^",1)
					s OneInsuPayModeAmount=$p(OneInsuPayModeStr,"^",2)
					if (OneInsuPayModeId=PatPayModeDR){
						s patSelfPayAmt=OneInsuPayModeAmount  //20200228 Lid 取患者自费金额
						s $p(OneInsuPayModeStr,"^",1)=PayModeid
						s $p(InsuPayModeDetailStr,$c(2),i)=OneInsuPayModeStr
					}
				}
				s $p(InsuPayStr,"^",4)=PayModeid
				s InsuJoinStr=InsuPayStr_"!"_InsuPayModeDetailStr
			}
			s err=##class(web.DHCOPAdm).UpdateINVPRTYBInfo(InsuJoinStr,InvoiceRowid)
			i +err'="0"{
				TRollback
				s ^zhou("error","UpdateINVPRTYBInfo")=err_"@InsuJoinStr="_InsuJoinStr_",InvoiceRowid="_InvoiceRowid
				d ##class(DHCDoc.Log.Common).General("Insert","web.DHCOPAdmReg","OPBillCharge","调用计费结算接口后更新医保支付方式失败",Re,$tr(err,"^",","))
				;Q "-2101"_",计费结算接口后更新医保支付方式失败,计费错误代码:"_err
				s BillChargeErrMsg=""
				s ExistFlag=##class(%Dictionary.MethodDefinition).%ExistsId("DHCBILL.SelfPay.BLL.DHCOPBillPayLogic"_"||"_"GetPreChargeErrMsg")
	 			if (ExistFlag=1){
					s BillChargeErrMsg=##class(DHCBILL.SelfPay.BLL.DHCOPBillPayLogic).GetPreChargeErrMsg(err)
	 			}
				s ErrMsg="-2101"_","_..%Translate("opadm.reg.hui.csp","计费结算接口后更新医保支付方式失败,计费错误代码",langid)_":" // _err
                s ErrMsg = ErrMsg_(+err)_"^"_..%Translate("opadm.reg.hui.csp",$p(err, "^", 2, $l(err, "^")))
				if BillChargeErrMsg'=""{
					s ErrMsg=ErrMsg_","_..%Translate("opadm.reg.hui.csp","错误描述",langid)_":"_..%Translate("opadm.reg.hui.csp",BillChargeErrMsg,langid)
				}
				Q ErrMsg
			}
		}
		
		//Modify 2020526 Lid 确认完成接口增加支付方式列表参数,注意：selfPayAmtRound包含一个^
		s selfPayAmtRound=##class(web.DHCBillConsIF).GetManyInvRoundErrAmt(InvoiceRowid,patSelfPayAmt,PayModeid)	
		//ETPRowID:订单ID
		s payList=PayModeid_"^^^^^^^"_selfPayAmtRound_"^^^"_ETPRowID
		s err=##class(web.DHCBillConsIF).CompleteCharge("0",user,AdmReason,InvoiceRowid,"0","",BillAccount,payList)
		i +err'=0{
			TRollback
			s ^zhou("error","CompleteCharge")=err_"@InsuPayDetailStr="_InsuJoinStr_",InvoiceRowid="_InvoiceRowid_",payList="_payList
			d ##class(DHCDoc.Log.Common).General("Insert","web.DHCOPAdmReg","OPBillCharge","计费结算提交接口调用失败",Re,$tr(err,"^",","))
			;Q "-2102"_",计费结算提交接口调用失败,计费错误代码:"_err
			s BillChargeErrMsg=""
			s ExistFlag=##class(%Dictionary.MethodDefinition).%ExistsId("DHCBILL.SelfPay.BLL.DHCOPBillPayLogic"_"||"_"GetPreChargeErrMsg")
 			if (ExistFlag=1){
				s BillChargeErrMsg=##class(DHCBILL.SelfPay.BLL.DHCOPBillPayLogic).GetPreChargeErrMsg(err)
 			}
			s ErrMsg="-2102"_","_..%Translate("opadm.reg.hui.csp","计费结算提交接口调用失败,计费错误代码",langid)_":" // _err
            s ErrMsg = ErrMsg_(+err)_"^"_..%Translate("opadm.reg.hui.csp",$p(err, "^", 2, $l(err, "^")))
			if BillChargeErrMsg'=""{
				s ErrMsg=ErrMsg_","_..%Translate("opadm.reg.hui.csp","错误描述",langid)_":"_..%Translate("opadm.reg.hui.csp",BillChargeErrMsg,langid)
			}
			Q ErrMsg
		}
		
	}
	TC
	Q 0
}

ClassMethod OPDeptListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = OPDeptListExecute ]
{
	Set repid=$LIST(qHandle,2)
	Kill ^CacheTemp(repid)
	Quit $$$OK
}

/// d ##class(%ResultSet).RunQuery("web.DHCOPAdmReg","OPDeptList","reg","","",2)
ClassMethod OPDeptListExecute(ByRef qHandle As %Binary, UserId As %String, AdmType As %String = "", paradesc As %String = "", HospitalID As %String = "") As %Status
{
	Set repid=$I(^CacheTemp)
	If $g(ind)="" Set ind=1
	k OPDeptListArr
	k ^TMP($J,"RegCTLocLookup")
	s UserId=$ZCVT(UserId,"U")
	i AdmType="" s AdmType="O^E"
	s Len=$L(AdmType,"^")
	s HospitalID=##class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospitalID)
	s SortType=##class(web.DHCOPRegConfig).GetSpecConfigNode("RegistLocSort",HospitalID)
	Set langid=..%LanguageID()
	for i=1:1:Len  {
		s AdmTypePut=$P(AdmType,"^",i)
		s RowId=0 f  s RowId=$O(^PAC("ADMLOC",0,"AdmType",AdmTypePut,RowId)) Q:RowId=""  d
		.Q:$d(OPDeptListArr(RowId))
		.Q:'$d(^RB("RES",0,"CTLOC",RowId))
		.Q:..CheckLocDesc(RowId,paradesc)'=1
		.s LocDateTo=$p($g(^CTLOC(RowId)),"^",25)
		.Q:(LocDateTo'="")&&(LocDateTo<+$H)
		.s LocHospitalID=$p($g(^CTLOC(RowId)),"^",22)
		.;Q:LocHospitalID'=HospitalID
		.;q:"N"=##class(DHCDoc.Common.Hospital).GetHospShowDataFlag("CT_Loc",RowId,HospitalID)
		.q:##class(DHCDoc.Common.Hospital).GetMultiHospConfigLoc(HospitalID,RowId)="N"
		.q:($P(^CTLOC(RowId),"^",14)'="Y")
		.s CTDesc=$p($g(^CTLOC(RowId)),"^",2)
		.s CTDesc=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",CTDesc,langid)
		.s CTAliasTem=""
		.i $l(CTDesc,"-")>1 s CTAliasTem=$P(CTDesc,"-",1)
		.s CTAlias=$P(^CTLOC(RowId),"^",43)
		.i CTAlias="" s CTAlias=CTAliasTem
		.s CTRowId=RowId
		.s CTCode=CTRowId
		.s CTLOCMarkNO=""
		.i SortType'="" s CTLOCMarkNO=##class(web.DHCBL.BDP.BDPSort).GetSortNum("User.CTLoc",SortType,RowId)
		.s CTLOCMarkNO=$case($l(CTLOCMarkNO),0:"999",1:"00"_CTLOCMarkNO,2:"0"_CTLOCMarkNO,:CTLOCMarkNO)
	    .s ^TMP($J,"RegCTLocLookup"," "_CTLOCMarkNO,CTRowId)=CTDesc_"^"_CTAlias   //建立临时Globle
	    .s OPDeptListArr(CTRowId)=1
		.//Do OutputRow1
	}
	//按照序号排序
	s seq="" for {
		s seq=$O(^TMP($j,"RegCTLocLookup",seq))
		Quit:seq=""
		s seq1="" for {
			s seq1=$O(^TMP($J,"RegCTLocLookup",seq,seq1))
			Quit:seq1=""
			s temp=^TMP($j,"RegCTLocLookup",seq,seq1)
			s CTRowId=seq1
			s CTDesc=$P(temp,"^",1)
			s CTAlias=$P(temp,"^",2)
			d OutputRow1		
		}
	}

	K ^TMP($J,"RegCTLocLookup")
	k OPDeptListArr
 Set qHandle=$lb(0,repid,0)
	Quit $$$OK
OutputRow1
	set Data=$lb(CTRowId,CTDesc,CTAlias)
	Set ^CacheTemp(repid,ind)=Data
	Set ind=ind+1
	quit
ResetVariables1
	///set (repid)=0
	set (CTRowId,CTCode,CTDesc,CTType)=""
	quit
}

ClassMethod OPDeptListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = OPDeptListExecute ]
{
	Set AtEnd=$LIST(qHandle,1)
	Set repid=$LIST(qHandle,2)
	Set ind=$LIST(qHandle,3)
	//
	Set ind=$o(^CacheTemp(repid,ind))
	If ind="" {				// if there are no more rows, finish fetching
		Set AtEnd=1
		Set Row=""
	}
	Else      {				// fetch row
		Set Row=^CacheTemp(repid,ind)
	}
	// Save QHandle
	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// 医生站直接挂号(无排班记录)
ClassMethod OPDocFastRegist(PatientID As %Library.String, AdmDep As %Library.String, AdmDoc As %Library.String, AdmReason As %String, user As %Library.String = "", group As %Library.String = "", ByRef EpisodeID As %String = "") As %String [ ProcedureBlock = 0 ]
{
	;w ##class(web.DHCOPAdmReg).OPDocRapidRegist(1,"405||27","","",590,37)
	s ^zhou("OPDocFastRegist")=PatientID_","_AdmDep_","_AdmDoc_","_AdmReason_","_user_","_group
	
	Set $ZT="ERROR^DHCSSERR"
	Q:($g(user)="")!($g(group)="") ""
	Q:($g(PatientID)="")!($g(AdmDep)="")!($g(AdmDoc)="") ""
	
	s EpisodeID=..GetSameAdm(PatientID,AdmDep,AdmDoc,+$H)
	i EpisodeID'=""  Q 0
	
	s Name=$p($g(^PAPER(PatientID,"ALL")),"^",1)
	s PatientNo=$p($g(^PAPER(PatientID,"PAT",1)),"^",1)
	
	s AdmType="O"
	if AdmType'="E" {
		s IsEmergency=..IsEmergency(AdmDep)
		if IsEmergency="1" s AdmType="E"
	}
	s AdmDate=..%SysDate(),AdmTime=..%SysTime()
	
	if (AdmReason=""){
		s PatCatDr=$p(^PAPER(PatientID,"PER",1),"^",10)
		s AdmReason=..GetDefaultBillType(PatCatDr)
	}
	TStart
	s AdmCategory="",HospitalID=$P(^CTLOC(AdmDep),"^",22)
	if AdmType ="O" {
		s AdmCategory=##class(web.DHCOPRegConfig).GetGroupConfig(HospitalID,group,"OPRegAdmCategory")
	}
	;插入就诊记录
	s Para=PatientID_"^"_AdmType_"^"_AdmDate_"^"_AdmTime_"^"_AdmDep_"^"_AdmDoc_"^"_AdmReason_"^"_user_"^^^^^"_AdmCategory
	Set EpisodeID=##class(web.DHCPAADM).ADMInsert(Para)
	if ($g(EpisodeID)="") {
		TRollback
		Q "-201"
	}

	TC
	Q "0"
}

/// 医生站直接挂号(无排班记录)
ClassMethod OPDocFastRegistBroker(PatientID As %String, AdmReason As %String, AdmDep As %String, user As %String, group As %String) As %String [ ProcedureBlock = 0 ]
{
	s EpisodeID=""
	s mradm=""
	s AdmDoc=##class(web.SSUser).GetDefaultCareProvider(user)
	s ret=..OPDocFastRegist(PatientID,AdmDep,AdmDoc,AdmReason,user,group,.EpisodeID )
	if EpisodeID'="" {
		s mradm=##Class(web.DHCPAADM).GetMRAdmID(EpisodeID)
	}
	b ;OPRegist OK
	s ret=ret_"^"_EpisodeID_"^"_mradm
	q ret
}

ClassMethod OPDocListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = OPDocListExecute ]
{
	Set repid=$LIST(qHandle,2)
	Kill ^CacheTemp(repid)
	Quit $$$OK
}

ClassMethod OPDocListExecute(ByRef qHandle As %Binary, Dept As %String = "") As %Status
{
	s ^zhou("OPDoc")=Dept
	;d ##class(%ResultSet).RunQuery("web.DHCOPAdmReg","OPDocList","60^1^^^CUR^^1^^^CUR^^^^2")
	Set repid=$I(^CacheTemp)	
	If $g(ind)="" Set ind=1
    s langid = ..%LanguageID()
	Set DeptDr=""
	//挂号界面按专业组查询排班
	set QryScheduleByClinicGroup=##class(web.DHCOPRegConfig).GetSpecConfigNode("QryScheduleByClinicGroup")
	set UserId=$p($g(Dept),"^",2)
	;如果不为空则代表是是预约的日期
	set AppDate=$p($g(Dept),"^",3)
	;PAPER_RowId
	set nid = $p($g(Dept),"^",4)
	set TimeRangeRowId=$p($g(Dept),"^",5)
	Set FindDocDr=$p($g(Dept),"^",6)
	Set GroupRowId=$p($g(Dept),"^",7)
	set FindDeptDr=$p($g(Dept),"^",1)
	set AdmReason=$p($g(Dept),"^",8)
	set PatientID=$p($g(Dept),"^",4)
	Set DiagnosCatRowId=$p($g(Dept),"^",9)
	;上下午
	Set SelectTRQuery=$p($g(Dept),"^",10)
	;服务组
	Set ClinicServiceGroupRowId=$p($g(Dept),"^",11)
	;是否显示停诊
	Set ShowStopFlag=$p($g(Dept),"^",12)
	;优惠类型
	Set RegConDisId=$p($g(Dept),"^",13)
	;登录医院
	Set LogonHospId=$p($g(Dept),"^",14)
	;预约方式代码
	Set AppMothodCode=$p($g(Dept),"^",15)
	;是否显示无可预约号源的排班，对外接口传入
	Set ShowNoAppLoadFlag=$p($g(Dept),"^",16)
	
	if DiagnosCatRowId'="" Set DiagnosCatRowId=$P(DiagnosCatRowId,"!",1)
	s SocialStatus="",OldManCardId=""
	//i PatientID'="" s SocialStatus=$P(^PAPER(PatientID,"PER",1),"^",10)
	 //add by guorongyong  20090526
	i PatientID'="" d
	.s SocialStatus=$P(^PAPER(PatientID,"PER",1),"^",10)
	.s OldManCardId=$p(^PAPER(PatientID,"ALL"),"^",20)
	 //add by guorongyong  20090526	
	s NotAvailDateStr="" ;..GetNotAvailDate()
	s AppDaysLimit=##class(web.DHCOPRegConfig).GetSpecConfigNode("AppDaysLimit",LogonHospId)
	if AppDate'=0 {
		i AppDate="" d
		.Set AdmDate=..%SysDate(),AdmTime=..%SysTime(),AdmWeek=$ZD(+$H,10)
		e  d
		.;Set AdmDate=$ZDH(AppDate,4) ,AdmTime=..%SysTime(),AdmWeek=$ZD(AppDate,10)
		.;$ZDH(AppDate,3)
		.if AppDate["||" s AdmDate=AppDate,AdmTime=..%SysTime(),AdmWeek=$ZD($P(AppDate,"||",1),10)
		.e  Set AdmDate=..%ZDH(AppDate) ,AdmTime=..%SysTime(),AdmWeek=$ZD(AppDate,10)
		;确定是否在预约周期限定内
		;如果传入的是带"||"的日期则分开判断挂号限制日期和时间
		s AllowFind=1
		if (AdmDate'["||") {
			i (AppDaysLimit'=""){
				s AppLimitDate=AppDaysLimit+(+$H)
				i (AppLimitDate<AdmDate) s AllowFind=0
			}
			if (NotAvailDateStr'=""){
				if ("^"_NotAvailDateStr_"^")[("^"_AdmDate_"^") s AllowFind=0
			}
		}else{
			s StartAppDate=$P(AdmDate,"||",1)
			s EndAppDate=$P(AdmDate,"||",2)
			s AdmDateStr=""
			for i=StartAppDate:1:EndAppDate d
			.s allfind=1
			.if AppDaysLimit'="" d
			..s AppLimitDate=AppDaysLimit+(+$H)
			..i (AppLimitDate<i) s allfind=0 
			.q:allfind=0
			.q:(NotAvailDateStr'="")&&(("^"_NotAvailDateStr_"^")[("^"_AdmDate_"^"))
			.if AdmDateStr="" s AdmDateStr=i
			.e  s AdmDateStr=AdmDateStr_"^"_i
			if AdmDateStr="" s AllowFind=0
			else  s AdmDate=AdmDateStr
		}
	}else{
		s AdmDate=""
		s AdmTime=..%SysTime()
		s AllowFind=1
		i (AppDaysLimit=""){s AppDaysLimit=60} //默认60天，和诊间预约保持一致
		s StartDate=..%SysDate()+1
		F i=StartDate:1:(StartDate+AppDaysLimit-1) {
			if (NotAvailDateStr'=""){
				if ("^"_NotAvailDateStr_"^")[("^"_i_"^") continue
			}
			i AdmDate="" s AdmDate=i
			e  s AdmDate=AdmDate_"^"_i
			
		}
	}
	s FindClinic=""
	if AdmDate="" s AllowFind=0
	//若服务组不为空,按照服务组查询维护的科室串
	if (ClinicServiceGroupRowId'=""){
		;-QryScheduleByClinicGroup=1 则按亚专业查询
		s NodeName="CGS"
		if (QryScheduleByClinicGroup="1"){
			s NodeName="CG"
			s FindClinic=ClinicServiceGroupRowId
		}
		if (FindDeptDr=""){
			s id=0
			f {
				s id=$o(^DHCLocSubjecti(NodeName,ClinicServiceGroupRowId,id)) Q:id=""
				i FindDeptDr="" s FindDeptDr=id
				else  s FindDeptDr=FindDeptDr_$C(2)_id
			}
		}else{
			//如科室不为空,判断科室与该服务组是否对照,无对照直接退出
			if ('$d(^DHCLocSubjecti(NodeName,ClinicServiceGroupRowId,FindDeptDr))){
				s FindDeptDr="",FindDocDr=""
			}
		}
	}
	if (FindDeptDr="")&(FindDocDr="") s AllowFind=0

	If (AllowFind'=1) {
		Do ResetVariables2
		Do OutputNullRow 	
		Set qHandle=$lb(0,repid,0)
		Quit $$$OK
	}
	;取安全组对应的资源和诊室
	s GroupRes=##class(web.DHCOPRegConfig).GetGroupRes(GroupRowId,LogonHospId)
	s GroupRegRoom=##class(web.DHCOPRegConfig).GetGroupRegRoom(GroupRowId,LogonHospId)
	;FindDeptDr是包含多个科室Rowid的串
	s ResRowIdStr=..GetResRowIdStr(FindDeptDr,FindDocDr)
	i ResRowIdStr="" {
		Do ResetVariables2
		Do OutputNullRow 	
		Set qHandle=$lb(0,repid,0)
		Quit $$$OK
	}
	;是否校验排班授权(按排班人员)
	s QryScheduleCheckUserPower=##class(web.DHCOPRegConfig).GetSpecConfigNode("QryScheduleCheckUserPower",LogonHospId)
	;得到与病人类别对应的默认费别
	i AdmReason="" s AdmReason=$$DefaultBillType(nid)
	s AdmDateStr=AdmDate
	f m=1:1:$L(AdmDateStr,"^") d
	.s AdmDate=$P(AdmDateStr,"^",m)
	.;s RowId=0 f  Set RowId=$O(^RB("RES",0,node1,node2,RowId)) Quit:RowId=""  d
	.f j=1:1:$L(ResRowIdStr,"^") d
	..s RowId=$P(ResRowIdStr,"^",j)
	..Q:'$D(^RB("RES",RowId))
	..Set DocDr=$p(^RB("RES",RowId),"^",2)
	..Set DeptDr=$p(^RB("RES",RowId),"^",1)
	..s RESDateActiveFrom=$p($g(^RB("RES",RowId)),"^",22)
	..s RESDateActiveTo=$p($g(^RB("RES",RowId)),"^",23)
	..s RESScheduleRequired=$p($g(^RB("RES",RowId)),"^",6)
	..Q:$g(RESScheduleRequired)="N" 
	..Q:(RESDateActiveFrom'="")&&(RESDateActiveFrom>+$h)
	..Q:(RESDateActiveTo'="")&&(RESDateActiveTo<+$h)
	..;Q:(LogonHospId'="")&&(LogonHospId'=$p($g(^CTLOC(DeptDr)),"^",22))
	..q:##class(DHCDoc.Common.Hospital).GetMultiHospConfigLoc(LogonHospId,DeptDr)="N"
	..;Q:(FindDocDr'="")&&(DocDr'=FindDocDr)
	..;Q:(FindDeptDr'="")&&(DeptDr'=FindDeptDr)
	..;号别标志
	..set ScheSt=$p(^RB("RES",RowId),"^",6)
	..Quit:(ScheSt'="Y")
	..Quit:(DocDr="")
	..Q:(GroupRes'="")&&(("!"_GroupRes_"!")'[("!"_RowId_"!"))
	..s UserActive="Y"
	..set Userdr=$O(^SSU("SSUSR",0,"CTPCP",DocDr,"0"))
	..if Userdr'="" d
	...s UserActive=$P(^SSU("SSUSR",Userdr),"^",19)
	..q:UserActive'="Y"
	..;判断排班授权(按排班人员)的权限,如果没有设定权限就可以看所有号别
	..s FindStatus=""
	..s UGRowId=$o(^User.DHCUserGroupI("UserNamedr"," "_UserId,0))
	..if (UGRowId'="") s FindStatus=$$UserMark(UserId,DocDr)
	..Q:(QryScheduleCheckUserPower=1)&&(UGRowId'="")&&(FindStatus="")
	..;获取该号别的缩写,以便界面操作快速定位
	..s AbbDoc=$$GetAbbDoc(DeptDr,DocDr)
	..;获取提示信息
	..;s BorghAlertInfo=..GetAlertInfo(RowId)
	..;
	..;查找可用排班记录
	..;w RowId_"^"_AdmDate_"^"_TimeRangeRowId,!
	..;s ASRowIdStr=##Class(web.DHCRBApptSchedule).GetAvailRA(RowId,AdmDate,AdmTime,TimeRangeRowId)
	..s ASRowIdStr=..GetMultiDateAvailRA(RowId,AdmDate,AdmTime,TimeRangeRowId,SelectTRQuery,ShowStopFlag)
	..;w ASRowIdStr
	..Quit:ASRowIdStr=""
	..s len=$L(ASRowIdStr,"^")
	..For i=1:1:len d
	...s ASRowId=$P(ASRowIdStr,"^",i)
	...s RoomDR=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",5)
	...Q:(GroupRegRoom'="")&&(("!"_GroupRegRoom_"!"_""_"!")'[("!"_RoomDR_"!"))
	...s ClinicGroupStr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",29)
	...s TRFlag=$p(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC"),"^",19)	
	...if TRFlag'="Y" s ClinicGroupStr=""  ///不分时段，不需要分亚专业挂号，只显示亚专业
	...i ClinicGroupStr'="" s ClinicGroupStr=ClinicGroupStr_","
	...for n=1:1:$l(ClinicGroupStr,",") d
	....s ClinicGroupId=$p(ClinicGroupStr,",",n)
	....q:(FindClinic'="")&&(FindClinic'=ClinicGroupId)
	....;返回指定日期排班记录的信息串
	....s DocResValue=..GetMarkRegFee(ASRowId,AdmReason,PatientID,AppMothodCode,RegConDisId,GroupRowId,ClinicGroupId)
	....Q:(DocResValue=0)!(DocResValue="")
	....;
	....s SessionTypeDr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",6)
	....//guorongyong 2008-04-20 start
	....s SessionTypeCode="",SESSConv=""
	....i SessionTypeDr'="" s SessionTypeCode=$P($G(^RBC("SESS",SessionTypeDr)),"^",1)
	....if SessionTypeDr'="" s SESSConv=$p($g(^RBC("SESS",SessionTypeDr)),"^",9)
	....if SESSConv="" s SESSConv="15"
    ....//guorongyong 2008-04-20 end
	....s ASDate=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2))),"^",1) 
	....s Load=$p(DocResValue,"^",1)
	....s AppLoad=$p(DocResValue,"^",2)
	....s AddLoad=$p(DocResValue,"^",3)
	....s AvailSeqNoStr=$p(DocResValue,"^",4)
	....s AvailSeqNoCount=AvailSeqNoStr ;$l(AvailSeqNoStr,",")
	....s AvailAddSeqNoStr=$p(DocResValue,"^",5)
	....s RoomDesc=$p(DocResValue,"^",6)
	....s RoomDr=$p(DocResValue,"^",7)
	....;s ClinicGroupDesc=$p(DocResValue,"^",8)
	....;s ClinicGroupDr=$p(DocResValue,"^",9)
	....s ClinicGroupDesc=""	;$p(DocResValue,"^",8)
	....s ClinicGroupDr=$select(ClinicGroupId="null":"",1:ClinicGroupId)	;$p(DocResValue,"^",9)
	....s:ClinicGroupDr'="" ClinicGroupDesc=$p(^RBC("CLGRP",ClinicGroupDr),"^",2)
    ....s:$g(ClinicGroupDesc)'="" ClinicGroupDesc = ##class(User.RBCClinicGroup).GetTranByDesc("CLGRPDesc", ClinicGroupDesc, langid)
	....if TRFlag'="Y" s ClinicGroupDesc=$p(DocResValue,"^",8)
	....//Q:(ClinicGroupRowId'="")&&(ClinicGroupDr'=ClinicGroupRowId)
	....s SessionTypeDesc=$p(DocResValue,"^",10)
	....;s SessionTypeDr=$p(DocResValue,"^",11)
	....;如果没能维护服务价格应该就不能挂号,这个逻辑在替诊时一样
	....s RegFeeDr="",ExamFeeDr="",HoliFeeDr="",AppFeeDr=""
	....s RegFee=$p(DocResValue,"^",12)
	....s CheckFee=$p(DocResValue,"^",14)
	....s HoliFee=$p(DocResValue,"^",16)
	....s AppFee=$p(DocResValue,"^",18)
	....;s RegFeeDr=$p(DocResValue,"^",13)
	....s ReCheckFee=$p(DocResValue,"^",15)
	....;s HoliFeeDr=$p(DocResValue,"^",17)
	....;s AppFeeDr=$p(DocResValue,"^",19)
	....s OtherFee=$p(DocResValue,"^",20)
	....s TRDesc=$p(DocResValue,"^",21)
	....;
	....s RegedCount=$p(DocResValue,"^",22)
	....s AppedCount=$p(DocResValue,"^",23)
	....s AddedCount=$p(DocResValue,"^",24)
	....s AppedArriveCount=$p(DocResValue,"^",30)
	....s AvailAppSeqNo=$p(DocResValue,"^",25)
	....s StopRegNoFlag=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",27) //停正号标识则可用号数为0
	....//if StopRegNoFlag="Y" s AvailSeqNoStr="" 
	....i (ASDate>+$H) s AvailSeqNoStr=AvailAppSeqNo
	....q:((AvailSeqNoStr="0")||(AvailSeqNoStr=""))&&(ASDate>+$H)&&(ShowNoAppLoadFlag'="Y")
	....s AvailNorSeqNoStr=$p(DocResValue,"^",26)
	....;
	....s ScheduleStatus=$p(DocResValue,"^",27)
	....s ScheduleStatusF=0
	....i ScheduleStatus="停诊" s ScheduleStatusF=1
	....s ScheduleDate=$p(DocResValue,"^",28)
	....s ScheduleDateWeek=$p(DocResValue,"^",29)
	....s NoLimitLoadFlag=$p(DocResValue,"^",31)
	....S MarkDesc=$p(^CTPCP(DocDr,1),"^",2)
	....;i TRDesc'="" s MarkDesc=MarkDesc_"("_TRDesc_")"
	....s RoomCode=""
	....i RoomDr'="" s RoomCode=$P(^CTLOC(RoomDr),"^",43)
	....;
	....s DepDesc=$P(^CTLOC(DeptDr),"^",2)
    ....s:$g(DepDesc)'="" DepDesc = ##class(User.CTLoc).GetTranByDesc("CTLOCDesc",DepDesc,langid)
	....s StopRegFlag=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",30)
	....;获取提示信息
	....s BorghAlertInfo=..GetAlertInfo(ASRowId)
	....;得到挂号设置的排队顺序(在日期和时段后)
	....s SessSort=..GetDefaultSortType(ASRowId,AvailSeqNoStr)
	....s TimeRangeDr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",17)
	....s TimeRangeSort=9999 
	....s TimeRangeSortType=##class(web.DHCOPRegConfig).GetSpecConfigNode("TimeRangeSort",LogonHospId)
	....if TimeRangeSortType'="" d
	.....s TimeRangeSort=##class(web.DHCBL.BDP.BDPSort).GetSortNum("User.DHCTimeRange",TimeRangeSortType,TimeRangeDr)
	.....if (TimeRangeSort="") s TimeRangeSort=9999
	....e  s TimeRangeSort=TimeRangeDr
	....s TimeRangeSort=$E("0000",1,4-$L(TimeRangeSort))_TimeRangeSort
	....s AdmWaitSum=##class(web.DHCAlloc).GetAdmWaitSum(ASRowId)
	....Do OutputRow2
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
OutputRow2
	;号别,诊室,职称,正号,预约限额,加号限额,加号,剩号,挂号费,诊查费,假日费 
	s ID=ASRowId_"||"_ClinicGroupDr
    s:$g(MarkDesc)'="" MarkDesc = ##class(User.CTCareProv).GetTranByDesc("CTPCPDesc",MarkDesc,langid)
    s:$g(SessionTypeDesc)'="" SessionTypeDesc = ##class(User.RBCSessionType).GetTranByDesc("SESSDesc",SessionTypeDesc,langid)
	set Data=$lb(ASRowId,MarkDesc,Load,AppLoad,AddLoad,AvailSeqNoStr,AvailAddSeqNoStr,RoomDesc,ClinicGroupDesc,SessionTypeDesc,RegFee,RegFeeDr,CheckFee,ReCheckFee,HoliFee,HoliFeeDr,AppFee,OtherFee,RoomCode,DepDesc,RegedCount,AppedCount,AddedCount,AvailNorSeqNoStr,ScheduleStatus,ScheduleDate,ScheduleDateWeek,TRDesc,AppedArriveCount,BorghAlertInfo,StopRegFlag,AdmWaitSum,NoLimitLoadFlag,ClinicGroupDr,ID)
	set ind=AdmDate_TimeRangeSort_SessSort_ScheduleStatusF_($E("0000000000",1,10-$L(RowId))_RowId)_($E("0000000000",1,10-$L(ClinicGroupDr))_ClinicGroupDr)
	s ^tempqujian("OutputRow2",ind)=Data
	Set ^CacheTemp(repid,ind)=Data
	;如果不按日期+时段来排序需要把下面的代码放开
	;Set ind=ind+1
	quit
OutputNullRow
	Set DocCode="",DocDesc=""
	set Data=$lb(ASRowId,MarkDesc,Load,AppLoad,AddLoad,AvailSeqNoStr,AvailAddSeqNoStr,RoomDesc,ClinicGroupDesc,SessionTypeDesc,RegFee,RegFeeDr,CheckFee,ReCheckFee,HoliFee,HoliFeeDr,AppFee,OtherFee,RoomCode,DepDesc,RegedCount,AppedCount,AddedCount,AvailNorSeqNoStr,ScheduleStatus,ScheduleDate,ScheduleDateWeek,TRDesc,AppedArriveCount,BorghAlertInfo,StopRegFlag,AdmWaitSum,NoLimitLoadFlag,ClinicGroupDr,ID)
	set ind=1
	Set ^CacheTemp(repid,ind)=Data
	;Do OutputRow2
	Quit
ResetVariables2
	///set (repid)=0
	set (ASRowId,MarkDesc,Load,AppLoad,AddLoad,AvailSeqNoStr,AvailAddSeqNoStr,RoomDesc,ClinicGroupDesc,SessionTypeDesc,RegFee,RegFeeDr,CheckFee,ReCheckFee,HoliFee,HoliFeeDr,AppFee,OtherFee,RoomCode,DepDesc,RegedCount,AppedCount,AddedCount,ScheduleStatusCode,ScheduleStatus,ScheduleDate,ScheduleDateWeek,TRDesc,AppedArriveCount,BorghAlertInfo,StopRegFlag,AdmWaitSum,NoLimitLoadFlag,ClinicGroupDr,ID)=""
	quit
GetAbbDoc(DeptDr,DocDr)
	s AbbDoc=""
	s RegKingRowid=$o(^User.DHCRegKindI("RegDeptDocIndex"," "_DeptDr," "_DocDr,0))
	if RegKingRowid'="" s AbbDoc=$LIST(^User.DHCRegKindD(RegKingRowid),4)
	s AbbDoc=$ZCVT(AbbDoc,"U")
	Q AbbDoc
DefaultBillType(PatientID)
	if PatientID="" Q ""
	set PatCatDr=$p(^PAPER(nid,"PER",1),"^",10)
	i PatCatDr'="" set DHCPACADMDr=$O(^DHCPACADM(0,"Social",PatCatDr,""))
	set AdmReason=""
	if $g(DHCPACADMDr)'="" set AdmReason=$p(^DHCPACADM(DHCPACADMDr),"^",2)
	Q AdmReason
UserMark(UserId,DocDr)
	s FindStatus=""
	s UserRowId=0 f  Set UserRowId=$o(^User.DHCUserGroupI("UserNamedr"," "_UserId,UserRowId)) quit:(UserRowId="")!(FindStatus'="")  d
	.s UserDocDr=$list(^User.DHCUserGroupD(UserRowId),2)
	.if (UserDocDr=DocDr) S FindStatus=UserDocDr
	Quit FindStatus
}

ClassMethod OPDocListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = OPDocListExecute ]
{
 Set AtEnd=$LIST(qHandle,1)
 Set repid=$LIST(qHandle,2)
 Set ind=$LIST(qHandle,3)
	//
 Set ind=$o(^CacheTemp(repid,ind))
 If ind="" {				// if there are no more rows, finish fetching
 Set AtEnd=1
 Set Row=""
 }
 Else      {				// fetch row
 Set Row=^CacheTemp(repid,ind)
 }
 // Save QHandle
 s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// 医生站修改病人信息并直接挂号(无排班记录)
ClassMethod OPDocNewFastRegist(PaInfo As %String, AdmReason As %String, AdmDep As %String, user As %Library.String, group As %Library.String) As %String
{
	s ^zhou("OPDocNewRapidRegist")=PaInfo_","_AdmReason_","_AdmDep_","_user_","_group
	;w ##class(web.DHCOPAdmReg).OPDocNewFastRegist("zhou^3^10","",7,590,37)
	
	s CurrentPatientNo=..GetRapidPatientNo()
	if CurrentPatientNo="" Q "-405"
	
	s PatientID=..GetPatientIDByNo(CurrentPatientNo)
	if (PatientID="") Q "-405"
	
	s PaInfo=PatientID_"^"_PaInfo
	s ret=..SavePatient(PaInfo)
	if ret'=0 Q "406"
	
	s AdmDoc=##class(web.SSUser).GetDefaultCareProvider(user)
	s EpisodeID=""
	s mradm=""
	s ret=..OPDocFastRegist(PatientID,AdmDep,AdmDoc,AdmReason,user,group,.EpisodeID )
	if EpisodeID'="" {
		s mradm=##Class(web.DHCPAADM).GetMRAdmID(EpisodeID)
	}
	b ;OPRegist OK
	s ret=ret_"^"_PatientID_"^"_EpisodeID_"^"_mradm_"^"_CurrentPatientNo
	q ret
}

/// 医生站直接挂号接口
ClassMethod OPDocRapidRegistBroker(PatientID As %Library.String = "", ASRowId As %Library.String = "", AdmReason As %String, FeeStr As %String = "", user As %Library.String = "", group As %Library.String = "", LocID As %String = "", DocRowId As %String = "", TimeRangeRowId As %String = "", PayModeCode As %Library.String = "", AccRowId As %Library.String = "", RegConDisId As %String = "", InsuJoinStr As %String = "", ETPRowID As %String = "", DocOPRegistBill As %String = "", RegExpStr As %String = "") As %String
{
	;w ##class(web.DHCOPAdmReg).OPDocRapidRegistBroker(22,"2||180","","1||1||0||0",12175,28,115,1,"","CPP",2637,"","","")
	s ^TMPGRY("OPDocRapidRegistBroker")=PatientID_","_ASRowId_","_AdmReason_","_FeeStr_","_user_","_group_","_LocID_","_DocRowId_","_TimeRangeRowId_","_PayModeCode_","_AccRowId_","_RegConDisId_","_InsuJoinStr_","_ETPRowID
	s EpisodeID=""
	s mradm=""
	;如果查找排班记录为空的话那么新增一条非规则出诊记录
	if ASRowId="" {
		s NowDate=..%SysDate()
		s NowTime=..%SysTime()
		i TimeRangeRowId="" s TimeRangeRowId=##class(web.DHCRBResSession).GetTimeRangeByTime(NowTime)
		s Rtn=##class(web.DHCRBApptSchedule).InsertOneIrrSchedule(LocID,DocRowId,NowDate,TimeRangeRowId)
		s RtnFlag=$P(Rtn,"^",1)
		if RtnFlag=0 {
			s ASRowId=$P(Rtn,"^",2)
		}
	}
	Q:ASRowId="" "-101"
	s HospId=$p(..GetCurrentHosp("","",ASRowId,""),"^",1)
	;排版扩展设置限制
	if (AdmReason=""){
		s PatCatDr=$p(^PAPER(PatientID,"PER",1),"^",10)
		s AdmReason=..GetDefaultBillType(PatCatDr)
	}
	if (AdmReason="") q "费别为空，请去挂号收费处维护费别！"
	s ret=##class(DHCDoc.OPAdm.ScheduleTemplateConfig).CheckOPRegExpandConfig(PatientID,ASRowId,AdmReason)
	if ret'=0 Q $p(ret,"^",2)
	s:DocOPRegistBill="" DocOPRegistBill=##class(web.DHCOPRegConfig).GetSpecConfigNodeHosp("DocOPRegistBill",HospId)
	;如果是卡消费直接调用便民挂号程序
	if (PayModeCode'="")&&(DocOPRegistBill=1) {
		s RegfeeRowId=""
		s ret=..OPRapidRegist(PatientID,ASRowId,AdmReason,PayModeCode,AccRowId,user,group,.RegfeeRowId,RegConDisId,FeeStr,InsuJoinStr,ETPRowID,RegExpStr)
		i RegfeeRowId'="" s EpisodeID=$List(^User.DHCRegistrationFeeD(RegfeeRowId),2)
	}else{
		s ret=..OPDocRapidRegist(PatientID,ASRowId,AdmReason,FeeStr,user,group,.EpisodeID,RegConDisId,RegExpStr)
	}
	if ret {
		TRollback
		Q ret
	}
	b ;插入缴费医嘱及诊断
	s ret=..InsertPreOrderAndDiag(ASRowId,EpisodeID,user,HospId)
	if ret {
		TRollback
		Q "-215"
	}
	if EpisodeID'="" {
		s mradm=##Class(web.DHCPAADM).GetMRAdmID(EpisodeID)
		;调用平台组接口
		s rtn=##class(web.DHCENS.EnsHISService).DHCHisInterface("SENDOPREGINFO",EpisodeID)
	}
	b ;OPRegist OK
	s ret=ret_"^"_EpisodeID_"^"_mradm
	q ret
}

/// 医生站直接挂号
ClassMethod OPDocRapidRegist(PatientID As %Library.String = "", ASRowId As %Library.String = "", AdmReason As %String, FeeStr As %String = "", user As %Library.String = "", group As %Library.String = "", ByRef EpisodeID As %String = "", RegConDisId As %String = "", RegExpStr As %String = "") As %String [ ProcedureBlock = 0 ]
{
	;w ##class(web.DHCOPAdmReg).OPDocRapidRegist(42,546||228,,1||1||0||0,600,99)
	s ^zhou("OPDocRapidRegist")=PatientID_","_ASRowId_","_AdmReason_","_FeeStr_","_user_","_group
	
	s PayModeCode = "", AccRowId = ""	
	
	Set $ZT="ERROR^DHCSSERR"
	Q:($g(user)="")!($g(group)="") ""
	Q:($g(ASRowId)="")!($g(PatientID)="") ""
	
	s ResRowId=$P(ASRowId,"||",1)
	s ASChild=$P(ASRowId,"||",2)
	s AdmDep=$P($G(^RB("RES",ResRowId)),"^",1)
	s AdmDoc=$P($G(^RB("RES",ResRowId)),"^",2)
	s (RegCardType,RegCardNo,RegSource,TabPCLRowID)=""
	if RegExpStr'=""{
		s RegCardType=$p(RegExpStr,"^",1)
		s RegCardNo=$p(RegExpStr,"^",2)	
		s RegSource=$p(RegExpStr,"^",3)	
		if RegSource="" s RegSource="OPDOC"
		s TabPCLRowID=$p(RegExpStr,"^",4)	
		s LoginLoc=$p(RegExpStr,"^",5)
		i ($d(%session)'=0)&&(LoginLoc="") d
	 	.s LoginLoc=%session.Get("LOGON.CTLOCID")
	}
	
	s EpisodeID=..GetSameAdm(PatientID,AdmDep,AdmDoc,+$H)
	i EpisodeID'=""  Q "-102"
	
	s ASDate=$P($G(^RBAS(ResRowId,ASChild)),"^",1) 
	s ASStartTime=$P($G(^RBAS(ResRowId,ASChild)),"^",4) 
	Q:($g(AdmDep)="")!($g(AdmDoc)="") ""
	s Name=$p($g(^PAPER(PatientID,"ALL")),"^",1)
	s PatientNo=$p($g(^PAPER(PatientID,"PAT",1)),"^",1)
	s RoomDr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",5)
	s SessionTypeDr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",6)
	s RegfeeTimeRangeDr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",17)
	
	s AdmType="O"
	if AdmType'="E" {
		s IsEmergency=..IsEmergency(AdmDep)
		if IsEmergency="1" s AdmType="E"
	}
	s CurrDate=..%SysDate()
	s CurrTime=..%SysTime()

	;如果调用的不是当日的提班记录,则为预约
	s AdmDate=ASDate,AdmTime=..%SysTime()
	
	if (AdmReason=""){
		s PatCatDr=$p(^PAPER(PatientID,"PER",1),"^",10)
		s AdmReason=..GetDefaultBillType(PatCatDr)
	}
	TStart
	
	s DiagnosCatRowId=""
	s InsuCoDR=""
	s PatAdmissionTp=..GetPatAdmissionTp(ASRowId)
	if RegConDisId="" {
		s RegConDisIdPara=PatientID_"^"_ASRowId_"^"_AdmReason_"^"_""
		s RegConDisId=..GetRegConDisId(RegConDisIdPara)
	}
	;插入就诊记录
	s BRegType=..GetRegType(RegSource)
	s AdmCategory="",HospitalID=$P(^CTLOC(AdmDep),"^",22)
	if AdmType ="O" {
		s AdmCategory=##class(web.DHCOPRegConfig).GetGroupConfig(HospitalID,group,"OPRegAdmCategory")
	}
	s Para=PatientID_"^"_AdmType_"^"_AdmDate_"^"_AdmTime_"^"_AdmDep_"^"_AdmDoc_"^"_AdmReason_"^"_user_"^^^^"_PatAdmissionTp_"^"_AdmCategory_"^^"_DiagnosCatRowId_"^^^^^"_InsuCoDR_"^"_RegConDisId ;21
	s Para=Para_"^^^^^^^^"_BRegType_"^"_RegCardType_"^"_RegCardNo
	Set Re=##class(web.DHCPAADM).ADMInsert(Para)
	if ($g(Re)="") {
		TRollback
		Q "-201"
	}

	s EpisodeID=Re
	if (TabPCLRowID'=""){
	    s rtn=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.opadm.UpdateEmChk",TabPCLRowID,EpisodeID,+ASRowId)
	    if (rtn'=0){
		    TRollback
			Q "-2011"
		}
	}
	b ;插入挂号医嘱
	s Price=0
	if FeeStr'="" {
		b  ;s FeeStr="||||0||0"
		s DiscountFactor=""
		s ret=..InsertRegOrder(EpisodeID,ASRowId,FeeStr,user,group,"N","N",.Price,DiscountFactor,RegConDisId)
		if ret'=0 {
			TRollback
			Q $CASE(ret,"-405":"-405",:"-206")
			//Q "-206"
		}
	}
	
	;此时未结帐
	s InvoiceRowid=""
	s QueueNo=""
	s Fee=Price
	s examfee=""
	
	b ;insert into DHCRegistrationFee
	s CurrDate=..%SysDate(),CurrTime=..%SysTime()
	;s RegfeeTimeRangeDr=##class(web.DHCRBResSession).GetTimeRangeByTime(ASStartTime)
	&SQL(insert into SQLUser.DHCRegistrationFee
		(RegfeeAdmDr,RegfeeName,RegfeeArcDr,RegfeeArcPrice,RegfeelookPrice,
		RegfeeBespFlag,RegfeeNo,RegfeeDoFlag,Regfeetemp1,RegfeeDepDr,RegfeeDocDr,
		RegfeeDate,RegfeeTime,RegfeeUserDr,RegfeeSessionTypeDr,RegfeeTimeRangeDr,
		RegfeeRoomDr,RegfeeRBASDr)
		Values(:EpisodeID,:Name,"",:Fee,:examfee,
		'No',:QueueNo,'Yes',:InvoiceRowid,:AdmDep,:AdmDoc,
		:CurrDate,:CurrTime,:user,:SessionTypeDr,:RegfeeTimeRangeDr,:RoomDr,:ASRowId))
	if SQLCODE {
		TRollback
		Q "-211"
	}
	s RegfeeRowId=%ROWID
	
	
	b ;插入队列 DHCQueue
	s Para=EpisodeID_"^"_RoomDr_"^"_QueueNo_"^"_user_"^^"_group
	&sql(select ID into :PersDr from  SQLUser.DHCPerState where PersName='等候')
	s Expstr="^^^^"_PersDr
	s ret=..QueueInsert(Para,Expstr)
	//如果先插入队列表,在更新队列状态，队列表状态变化表会有两条同样的记录
	/*;如果是报到状态,直接置为等候状态
	s PersDr=""
	&sql(select ID into :PersDr from  SQLUser.DHCPerState where PersName='等候')
	s QueRowId=$o(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,0))
	i QueRowId'="" {
		&sql(Update SQLUser.DHCQueue set QueStateDr=:PersDr where ID=:QueRowId)
		s ret=SQLCODE
	}*/
	if ret {
		TRollback
		Q "-212"
	}

	TC
	Q "0"
}

/// 便民挂号
ClassMethod OPRapidRegist(PatientID As %Library.String = "", ASRowId As %Library.String = "", AdmReason As %String, PayModeCode As %Library.String = "", AccRowId As %Library.String = "", user As %Library.String = "", group As %Library.String = "", ByRef RegfeeRowId As %String = "", RegConDisId As %String = "", FeeStr As %String = "1||1||0||0", InsuJoinStr As %String = "", ETPRowID As %String = "", RegExpStr As %String = "") As %String [ ProcedureBlock = 0 ]
{
	;w ##class(web.DHCOPAdmReg).OPRapidRegist(431967,"67||1","","","",512,53,"")
	s ^zhou("OPRapidRegist")=PatientID_","_ASRowId_","_AdmReason_","_PayModeCode_","_AccRowId_","_user_","_group_","_RegConDisId

	Set $ZT="ERROR^DHCSSERR"
	Q:($g(user)="")!($g(group)="") ""
	Q:($g(ASRowId)="")!($g(PatientID)="") ""
	s ResRowId=$P(ASRowId,"||",1)
	s ASChild=$P(ASRowId,"||",2)
	s AdmDep=$P($G(^RB("RES",ResRowId)),"^",1)
	s AdmDoc=$P($G(^RB("RES",ResRowId)),"^",2)
	s ASDate=$P($G(^RBAS(ResRowId,ASChild)),"^",1) 
	s ASStartTime=$P($G(^RBAS(ResRowId,ASChild)),"^",4) 
	Q:($g(AdmDep)="")!($g(AdmDoc)="") ""
	s Name=$p($g(^PAPER(PatientID,"ALL")),"^",1)
	s PatientNo=$p($g(^PAPER(PatientID,"PAT",1)),"^",1)
	s RoomDr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",5)
	s SessionTypeDr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",6)
	s RegfeeTimeRangeDr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",17)
	s (RegCardType,RegCardNo,RegSource,TabPCLRowID)=""
	if RegExpStr'=""{
		s RegCardType=$p(RegExpStr,"^",1)
		s RegCardNo=$p(RegExpStr,"^",2)	
		s RegSource=$p(RegExpStr,"^",3)	
		if RegSource="" s RegSource="OPDOC"
		s TabPCLRowID=$p(RegExpStr,"^",4)	
		s LoginLoc=$p(RegExpStr,"^",5)
		i ($d(%session)'=0)&&(LoginLoc="") d
	 	.s LoginLoc=%session.Get("LOGON.CTLOCID")
	}
	s EpisodeID=..GetSameAdm(PatientID,AdmDep,AdmDoc,+$H)
	i EpisodeID'=""  Q "-102"
	s AdmType="O"
	if AdmType'="E" {
		s IsEmergency=..IsEmergency(AdmDep)
		if IsEmergency="1" s AdmType="E"
	}
	s CurrDate=..%SysDate()
	s CurrTime=..%SysTime()

	;如果调用的不是当日的提班记录,则为预约
	s AdmDate=ASDate,AdmTime=..%SysTime()
	
	if (AdmReason=""){
		s PatCatDr=$p(^PAPER(PatientID,"PER",1),"^",10)
		s AdmReason=..GetDefaultBillType(PatCatDr)
	}
	
	;医保支付方式明细
	s InsuAdmRowid="",InsuDivRowid=""
	s InsuPayModeDetailStr=""
	s InsuPayCash="",InsuPayCount="",InsuPayFund=""
	;此处做字符兼容,支持$C(2)和@两种符号的分割
	i (InsuJoinStr'="") {
		if (InsuJoinStr["@") s InsuJoinStr=$tr(InsuJoinStr,"@",$c(2))
		s InsuPayStr=$p(InsuJoinStr,"!",1)
		;医保返回信息中的支付方式串,其中包括:现金支付,帐户支付,统筹支付;
		s InsuPayModeDetailStr=$p(InsuJoinStr,"!",2)
		s InsuAdmRowid=$p(InsuPayStr,"^",2)
		s InsuDivRowid=$p(InsuPayStr,"^",3)
		for i=1:1:$l(InsuPayModeDetailStr,$c(2)) {
			s OneInsuPayModeStr=$p(InsuPayModeDetailStr,$c(2),i)
			s OneInsuPayModeId=$p(OneInsuPayModeStr,"^",1)
			s OneInsuPayModeAmount=$p(OneInsuPayModeStr,"^",2)
		}	
	}
	TStart
	
	s DiagnosCatRowId=""
	s InsuCoDR=""
	s PatAdmissionTp=..GetPatAdmissionTp(ASRowId)
	if RegConDisId="" {
		s RegConDisIdPara=PatientID_"^"_ASRowId_"^"_AdmReason_"^"_""
		s RegConDisId=..GetRegConDisId(RegConDisIdPara)
	}
	;插入就诊记录
	s BRegType=..GetRegType(RegSource)
	s AdmCategory="",HospitalID=$P(^CTLOC(AdmDep),"^",22)
	if AdmType ="O" {
		s AdmCategory=##class(web.DHCOPRegConfig).GetGroupConfig(HospitalID,group,"OPRegAdmCategory")
	}
	s Para=PatientID_"^"_AdmType_"^"_AdmDate_"^"_AdmTime_"^"_AdmDep_"^"_AdmDoc_"^"_AdmReason_"^"_user_"^^^^"_PatAdmissionTp_"^"_AdmCategory_"^^"_DiagnosCatRowId_"^^^^^"_InsuCoDR_"^"_RegConDisId ;21
	s Para=Para_"^^^^^^^^"_BRegType_"^"_RegCardType_"^"_RegCardNo
	Set Re=##class(web.DHCPAADM).ADMInsert(Para)
	if ($g(Re)="") {
		TRollback
		Q "-201"
	}

	s EpisodeID=Re
	if (TabPCLRowID'=""){
	    s rtn=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.opadm.UpdateEmChk",TabPCLRowID,EpisodeID,+ASRowId)
	    if (rtn'=0){
		    TRollback
			Q "-2011"
		}
	}
	b ;记帐
	s InvoiceRowid=""
	s ret=..OPBillCharge(EpisodeID,ASRowId,AccRowId,PayModeCode,FeeStr,user,group,"","",.InvoiceRowid,"","",InsuJoinStr,"",RegConDisId,"",ETPRowID,LoginLoc)
	if ret'=0 {
		TRollback
		Q ret
	}
	
	s QueueNo=""
	
	b ;insert into DHCRegistrationFee
	s CurrDate=..%SysDate(),CurrTime=..%SysTime()
	;s RegfeeTimeRangeDr=##class(web.DHCRBResSession).GetTimeRangeByTime(ASStartTime)
	&SQL(insert into SQLUser.DHCRegistrationFee
		(RegfeeAdmDr,RegfeeName,RegfeeArcDr,RegfeeArcPrice,RegfeelookPrice,
		RegfeeBespFlag,RegfeeNo,RegfeeDoFlag,Regfeetemp1,RegfeeDepDr,RegfeeDocDr,
		RegfeeDate,RegfeeTime,RegfeeUserDr,RegfeeSessionTypeDr,RegfeeTimeRangeDr,
		RegfeeRoomDr,RegfeeRBASDr)
		Values(:EpisodeID,:Name,"",:Fee,:examfee,
		'No',:QueueNo,'Yes',:InvoiceRowid,:AdmDep,:AdmDoc,
		:CurrDate,:CurrTime,:user,:SessionTypeDr,:RegfeeTimeRangeDr,:RoomDr,:ASRowId))
	if SQLCODE {
		TRollback
		Q "-211"
	}
	s RegfeeRowId=%ROWID
	b ;更新医保相关信息,医保组提供接口
	if InsuAdmRowid'="" {
		s InsuRet=##class(web.DHCINSUPort).UpdateInsuAdm(InsuAdmRowid,EpisodeID,InvoiceRowid,InsuDivRowid)
		if InsuRet'=0 {
			TRollback
			Q "-2010"
		}
	}
	b ;插入队列 DHCQueue
	s Para=EpisodeID_"^"_RoomDr_"^"_QueueNo_"^"_user_"^^"_group
	&sql(select ID into :PersDr from  SQLUser.DHCPerState where PersName='等候')
	s Expstr="^^^^"_PersDr

	s ret=..QueueInsert(Para,Expstr)
	if ret {
		TRollback
		Q "-212"
	}
	TC
	Q "0"
}

ClassMethod OPRapidRegistBroker(PatientID As %String, ASRowId As %Library.String = "", AdmReason As %String, PayModeCode As %Library.String = "", AccRowId As %Library.String = "", user As %Library.String = "", group As %Library.String = "")
{
	;w ##class(web.DHCOPAdmReg).OPRapidRegistBroker(431967,"67||1","","","",512,53)
	s RegfeeRowId=""
	s ret=..OPRapidRegist(PatientID,ASRowId,AdmReason,PayModeCode,AccRowId,user,group,.RegfeeRowId)
	b ;OPRegist OK
	s PrintData=""
	i ret="0" {
		s InvoiceId=$List(^User.DHCRegistrationFeeD(RegfeeRowId),11)
		i InvoiceId="" {
			s PrintData=""
		}else{
			s PrintData=..GetPrintData(RegfeeRowId)
		}
	}
	s ret=ret_"$"_PrintData
	q ret
}

/// 重新帐单
ClassMethod OPReBillCharge(RegFeeRowId As %String, UserRowId As %String, GroupRowId, LogonLocRowId As %String) As %String
{
	&SQL(Select RegfeeAdmDr,RegfeeNo,RegfeeDoFlag,RegfeeRBASDr,Regfeetemp1
	   into :adm,:QueueNo,:doflag,:RBASRowId,:InvoiceId
	   from SQLUser.DHCRegistrationFee 
	  Where %Id=:RegFeeRowId)
	s InvoiceUserDr=$p(^DHCINVPRT(InvoiceId),"^",21)
	if (InvoiceUserDr'=UserRowId) {
		Q "-200"
	} 

	s INVPRTNo=$P(^DHCINVPRT(InvoiceId),"^",14)
	;s INVPRTAcount=$P(^DHCINVPRT(InvoiceId),"^",1)
	s PRTPatientShare=$P(^DHCINVPRT(InvoiceId),"^",16)
	s INVPRTAcount=PRTPatientShare
	;s Paymode=$p(^DHCINVPRT(InvoiceId,"P",1),"^")
	s Paymode=""
	s InvPayModeID=$O(^DHCINVPRT(InvoiceId,"P",0))
	s:InvPayModeID'="" Paymode=$p(^DHCINVPRT(InvoiceId,"P",InvPayModeID),"^")
	
	Ts
	s rtn=##class(web.udhcOPRefEditIF).RefundReceipt(InvoiceId, UserRowId, "A", "", INVPRTAcount, GroupRowId,1,LogonLocRowId,Paymode)
	b  ;RefundReceipt
	s Refundcode=$P(rtn,"^",1)
	i Refundcode'=0 {
		TRo
		Q "-201"
	}
	s NewInvoiceId=$P(rtn,"^",2)

	&SQL(Update SQLUser.DHCRegistrationFee set Regfeetemp1=:NewInvoiceId where %Id=:RegFeeRowId)
	if SQLCODE {
		TRo
		Q "-201"
	}
	Tc
	Q 0
}

/// creator:郭荣勇
/// date:2014-01-15
/// desc:得到病人就诊类型,存储在PA_Adm上,标识主要提供给计费组使用
ClassMethod GetPatAdmissionTp(ASRowId As %String) As %String
{
	
	;1.按医院区分
	s PatAdmissionTp=""
	s HospitalCode=##class(web.DHCDocOrderCommon).GetCurrentHospitalCode()
	s HospitalCode=$ZCVT(HospitalCode,"U")
	i HospitalCode="HYD" {
		Q:ASRowId="" ""
		s ZId="",YId="",TId=""
		s ZId=$O(^PAC("IPAT",0,"Code","Z",""))
		s YId=$O(^PAC("IPAT",0,"Code","Y",""))
		s TId=$O(^PAC("IPAT",0,"Code","T",""))
		s PatAdmissionTp="",ASDate="",SessionTypeDesc=""
		s ResRowId=$P(ASRowId,"||",1)
		s ASChildSub=$P(ASRowId,"||",2)
		s SessionTypeDr=$P($G(^RBAS(ResRowId,ASChildSub,"DHC")),"^",6)
		i SessionTypeDr'="" s SessionTypeDesc=$P($G(^RBC("SESS",SessionTypeDr)),"^",2)
	
		s ASDate=$P($G(^RBAS(ResRowId,ASChildSub)),"^",1) 
		;i (SessionTypeDesc["初诊")!(SessionTypeDesc["复诊") {
		i (SessionTypeDesc["特需") {
			s PatAdmissionTp=TId
		;}elseif (($ZD(ASDate,10)=6)!($ZD(ASDate,10)=0))&&(SessionTypeDesc["周末"){
		}elseif (($ZD(ASDate,10)=6)!($ZD(ASDate,10)=0)){
			s PatAdmissionTp=YId
		}else{
			s PatAdmissionTp=ZId
		}
	}
	Q PatAdmissionTp
}

/// creator:郭荣勇
/// date:2014-01-15
/// desc:得到满足的挂号优惠设置的RowId,存储在PA_AdmExt上,标识主要提供给计费组使用
ClassMethod GetRegConDisId(Para As %String) As %String
{
	
	s PatientID=$p(Para,"^",1)
	s ASRowId=$p(Para,"^",2)
	s AdmReason=$p(Para,"^",3)
	s IsHaveOldCred=$p(Para,"^",4)
	s HospID=$p(Para,"^",5)
	i HospID="" {
		s HospID=$p(..GetCurrentHosp("","",ASRowId,""),"^",1)
	}
	s RegConDisId=##class(web.DHCRegConDisCount).CheckDHCRegConDisCount(PatientID,ASRowId,AdmReason,IsHaveOldCred,HospID)
	Q RegConDisId
}

/// CreateDate:2021-04-20
/// Desc:统一判定挂号渠道方式,目前
ClassMethod GetRegType(RegSource As %String = "", APPTRowId As %String = "")
{
	//MDT 	MDT会诊
	//SERV 	外部预约挂号接口
	//WIN	窗口挂号
	//OPDOC	就诊登记
	//APPREG预约取号	
	if RegSource="" s RegSource="WIN"
	if (RegSource="WIN")&&(APPTRowId'=""){
		s RegSource="APPREG"	
	}
	s ApptTypeRowId=##class(web.DHCRBAppointment).GetApptTypeByCode(RegSource)
	Q ApptTypeRowId
}

/// 挂号
/// Input:	RegSource 挂号渠道
/// 		RegExpStr 扩展信息 挂号就诊卡卡类型^就诊卡号
/// w ##class(web.DHCOPAdmReg).OPRegist("2","5||1","1","","0||0||0||0||0||0||0","CASH","","7","119","","","","","","","","","","","","","","","","上午","","1^0000060001")
ClassMethod OPRegist(PatientID As %Library.String = "", ASRowId As %Library.String = "", AdmReason As %String, QueueNo As %Library.String = "", FeeStr As %Library.String = "", PayModeCode As %Library.String = "", AccRowId As %Library.String = "", user As %Library.String = "", group As %Library.String = "", AdmType As %Library.String = "", DiagnosCatRowId As %Library.String = "", FreeRegFlag As %Library.String = "", FreeCheckFlag As %Library.String = "", ByRef RegfeeRowId As %String = "", ByRef InsuJoinStr As %String = "", ByRef DiscountFactor As %String = "", ByRef APPTRowId As %String = "", UnBillFlag As %String = "", TabPCLRowID As %String = "", ApptMethodCode As %String = "", SourceType As %String = "", RegConDisId As %String = "", HospitalID As %String = "", ETPRowID As %String = "", TimeRangeStr As %String = "", RegSource As %String = "", RegExpStr As %String = "") As %String [ ProcedureBlock = 0 ]
{
	;1,379||5,,,10||0||0||0||0||0,CASH,,5,93,,,,,,*6*1^"
	;w ##class(web.DHCOPAdmReg).OPRegist(3,"1638||65","","","10||7||0||0||0||0||0","CASH","","5","93","","","","","","*6*1^")
	s ^zhou("OPRegist")="w ##class(web.DHCOPAdmReg).OPRegist("""_PatientID_""","""_ASRowId_""","""_AdmReason_""","""_QueueNo_""","""_FeeStr_""","""_PayModeCode_""","""_AccRowId_""","""_user_""","""_group_""","""_AdmType_""","""_DiagnosCatRowId_""","""_RegfeeRowId_""","""_InsuJoinStr_""","""_DiscountFactor_""","""_TabPCLRowID_""","""_ApptMethodCode_""","""_SourceType_""","""_RegConDisId_""")"
	s ^CacheTemp("OPRegist1")=$lb(PatientID , ASRowId, AdmReason , QueueNo, FeeStr, PayModeCode , AccRowId , user , group , AdmType , DiagnosCatRowId , FreeRegFlag , FreeCheckFlag ,  RegfeeRowId,  InsuJoinStr,  DiscountFactor,  APPTRowId , UnBillFlag , TabPCLRowID , ApptMethodCode , SourceType, RegConDisId , HospitalID,ETPRowID ,TimeRangeStr,RegSource,RegExpStr)
	;Set $ZT="ERROR^DHCSSERR"
	Q:($g(user)="")!($g(group)="") ""
	Q:($g(ASRowId)="")!($g(PatientID)="") ""
	
	s (RegCardType,RegCardNo,ClinicGroupId,ApptTypeCode,notCheckFlag)=""
	if RegExpStr'=""{
		s RegCardType=$p(RegExpStr,"^",1)
		s RegCardNo=$p(RegExpStr,"^",2)	
		s ClinicGroupId=$p(RegExpStr,"^",3)	
		s ApptTypeCode=$p(RegExpStr,"^",4)	
		s LoginLoc=$p(RegExpStr,"^",5)
		s notCheckFlag=$p(RegExpStr,"^",6)
		i ($d(%session)'=0)&&(LoginLoc=""){
	 		s LoginLoc=%session.Get("LOGON.CTLOCID")
		}
	}
	s ResRowId=$P(ASRowId,"||",1)
	s ASChild=$P(ASRowId,"||",2)
	s AdmDep=$P($G(^RB("RES",ResRowId)),"^",1)
	s AdmDoc=$P($G(^RB("RES",ResRowId)),"^",2)
	s ASDate=$P($G(^RBAS(ResRowId,ASChild)),"^",1) 
	s ASStartTime=$P($G(^RBAS(ResRowId,ASChild)),"^",4) 
	Q:($g(AdmDep)="")!($g(AdmDoc)="") ""
	s Name=$p($g(^PAPER(PatientID,"ALL")),"^",1)
	s PatientNo=$p($g(^PAPER(PatientID,"PAT",1)),"^",1)
	s RoomDr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",5)
	s SessionTypeDr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",6)
	s RegfeeTimeRangeDr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",17)
	s NoLimitLoadFlag=$p(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC"),"^",31)
	s HospitalID=##class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospitalID)
	if AdmType="" s AdmType="O"
	if AdmType'="E" {
		s IsEmergency=..IsEmergency(AdmDep)
		if IsEmergency="1" s AdmType="E"
	}
	s SessionStr=user_"^"_group_"^"_LoginLoc_"^"_HospitalID
	;将挂号检测入口统一
	if notCheckFlag'="Y"{
		s chkRtn=..CheckBeforeReg(ASRowId, PatientID, APPTRowId, RegCardType,RegCardNo, HospitalID, "", RegSource, SessionStr)
		if chkRtn'=""{
			s chkCode=$p(chkRtn,"^",1)
			s chkMsg=$p(chkRtn,"^",2)
			Q chkCode_","_chkMsg
		}
	}

	s EPMark=##class(web.DHCRBResource).GetEPMarkFlag(ResRowId)
	s AddStartTime=##class(web.DHCOPRegConfig).GetSpecConfigNode("AddStartTime",HospitalID)
	s CurrDate=..%SysDate()
	s CurrTime=..%SysTime()
	if APPTRowId'="" {
	    s GetSeqNoMode="APP"
		s AdmDate=ASDate
		if AdmDate=CurrDate {
			s AdmTime=..%SysTime()
		}else{
			i ASStartTime'="" s AdmTime=ASStartTime
			e  s AdmTime=$p($H,",",2)
		}
	}else{
		;如果调用的不是当日的提班记录,则为预约
		if ASDate=CurrDate {
			s GetSeqNoMode="NOR"
			s AdmDate=..%SysDate(),AdmTime=..%SysTime()
		}else{
			s GetSeqNoMode="APP"
			s AdmDate=ASDate
			i ASStartTime'="" s AdmTime=ASStartTime
			e  s AdmTime=$p($H,",",2)
		}
	}
	
	;外部预约挂号,判断是否允许加号
	s AllowAddRegFlag="Y"		
	if (RegSource="SERV"){
		s AllowAddRegFlag=+(##class(DHCDoc.Interface.Outside.Config).GetConfigNode(group,"AllowAddReg",HospitalID))
		if AllowAddRegFlag'="1"{
			s AllowAddRegFlag="N"	
		}	
	}
	if (AdmReason=""){
		s PatCatDr=$p(^PAPER(PatientID,"PER",1),"^",10)
		s AdmReason=..GetDefaultBillType(PatCatDr)
	}
	
	//判断是否有公共卡
	s CommonPatientID=..GetCommonPatientID("",HospitalID)
	//公共卡不做限制
	/*i (("^"_CommonPatientID_"^")'[("^"_PatientID_"^"))&&(EPMark'=1){
		s ret=..CheckRegCountLimit(PatientID,ASRowId,HospitalID,APPTRowId)
		if ret'=0 Q ret
	}*/
	///排版扩展设置限制
	s ret=##class(DHCDoc.OPAdm.ScheduleTemplateConfig).CheckOPRegExpandConfig(PatientID,ASRowId,AdmReason)
	if ret'=0 Q $p(ret,"^",2)
	///亚专业限制
	s ret=##class(web.DHCRBCClinicGroup).CheckClinicGroupLimitConfig(PatientID,ClinicGroupId,HospitalID)
	if ret'=0 Q $p(ret,"^",2)
	;保险支付明细
	s InsuCoStr=""
	s InsuCoDR="",InsuCoProDR="",InsuCoPatPay=""
	
	;医保支付方式明细
	s InsuAdmRowid="",InsuDivRowid=""
	s InsuPayModeDetailStr=""
	s InsuPayCash="",InsuPayCount="",InsuPayFund=""
	;此处做字符兼容,支持$C(2)和@两种符号的分割
	i (InsuJoinStr'="") {
		if (InsuJoinStr["@") s InsuJoinStr=$tr(InsuJoinStr,"@",$c(2))
		s InsuPayStr=$p(InsuJoinStr,"!",1)
		;医保返回信息中的支付方式串,其中包括:现金支付,帐户支付,统筹支付;
		s InsuPayModeDetailStr=$p(InsuJoinStr,"!",2)
		s InsuAdmRowid=$p(InsuPayStr,"^",2)
		s InsuDivRowid=$p(InsuPayStr,"^",3)
		for i=1:1:$l(InsuPayModeDetailStr,$c(2)) {
			s OneInsuPayModeStr=$p(InsuPayModeDetailStr,$c(2),i)
			s OneInsuPayModeId=$p(OneInsuPayModeStr,"^",1)
			s OneInsuPayModeAmount=$p(OneInsuPayModeStr,"^",2)
		}	
	}
	
	TStart
	
	b ;QueueNo
	;s RESRowId=+ASRowId
	;s GetReAdmFeeFlag=..GetReAdmFeeFlag(PatientID,RESRowId)
	
	s PatAdmissionTp=..GetPatAdmissionTp(ASRowId)
	if (RegConDisId=""){
		s RegConDisIdPara=PatientID_"^"_ASRowId_"^"_AdmReason_"^^"_HospitalID
		s RegConDisId=..GetRegConDisId(RegConDisIdPara)
	}
	s AdmCategory=""
	if AdmType ="O" {
		s AdmCategory=##class(web.DHCOPRegConfig).GetGroupConfig(HospitalID,group,"OPRegAdmCategory")
	}
	;插入就诊记录
	s tmpRegSource=RegSource
	s:ApptTypeCode'="" tmpRegSource=ApptTypeCode
	s BRegType=..GetRegType(tmpRegSource,APPTRowId)
	s Para=PatientID_"^"_AdmType_"^"_AdmDate_"^"_AdmTime_"^"_AdmDep_"^"_AdmDoc_"^"_AdmReason_"^"_user_"^^^^"_PatAdmissionTp_"^"_AdmCategory_"^^"_DiagnosCatRowId_"^^^^^"_InsuCoDR_"^"_RegConDisId ;21
	s Para=Para_"^^^^^^^^"_BRegType_"^"_RegCardType_"^"_RegCardNo
	Set Re=##class(web.DHCPAADM).ADMInsert(Para)
	if ($g(Re)="") {
		TRollback
		Q "-201"
	}
	s EpisodeID=Re
	//先分诊患者，挂号成功后处理分诊记录与adm关联，同步就诊记录里的绿色通道标识
    //入参:EmPCLvID-分级ID, EpisodeID-就诊ID，RbResourceId-资源号别
    //返回值：0-成功，其他-失败
   if AdmType ="E" {
	    //如果分级ID为空，则寻找改患者24小时之内，第一条分级信息的分级ID
	    if (TabPCLRowID=""){
		    s PatChkLvCareInfo=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.opadm.GetPatChkLvCareInfo",PatientID,0)
		    if (PatChkLvCareInfo'=""){
			    s FirstPatChkLvCareInfo=$p(PatChkLvCareInfo,"||",1)
			    if (FirstPatChkLvCareInfo'=""){
				    s FirstPatChkLv=$p(FirstPatChkLvCareInfo,"^",3)
			        i FirstPatChkLv'="" s TabPCLRowID=FirstPatChkLv
				}
			}
		}
	}
    if (TabPCLRowID'=""){
	    s rtn=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.opadm.UpdateEmChk",TabPCLRowID,EpisodeID,+ASRowId)
	    if (rtn'=0){
		    TRollback
			Q "-2011"
		}
	}
    
	///将对号别的获得等处理提到事务的前部。将对号别时间的限定在处理完号别后进行。
	s EPMark=""
	if (EPMark'=1){
		if (GetSeqNoMode="APP"){
			if APPTRowId="" {
				;生成预约记录需要写固定代码,"W" 代表窗口预约
				if ApptMethodCode'="" s MethodDR=$O(^RBC("APTM",0,"Code",ApptMethodCode,0))
				else  s MethodDR=$O(^RBC("APTM",0,"Code","WIN",0))
				if MethodDR="" Q "-2020"
				s Para=PatientID_"^"_ASRowId_"^"_MethodDR_"^"_AdmType_"^"_user
				s Para=Para_"^"_QueueNo_"^^^^"_TimeRangeStr
				s Para=Para_"^"_ClinicGroupId_"^"_ApptTypeCode
				s rtn=##Class(web.DHCRBAppointment).Insert(Para,SourceType,HospitalID)
				i $p(rtn,"^",1)'=0 {
					TRollback
					Q "-234"_",插入预约记录失败."
				}
			}else{
				s RBASRowId=$p(APPTRowId,"||",1,2)
				s APPTData=$g(^RBAS(+APPTRowId,$p(APPTRowId,"||",2),"APPT",$p(APPTRowId,"||",3)))
				s ApptPatientID=$p(APPTData,"^",2)
				;无卡预约取号关联当前病人
				if (ApptPatientID="")||(("^"_CommonPatientID_"^")[("^"_ApptPatientID_"^")) {
					&sql(Update SQLUser.RB_Appointment Set APPT_PAPMI_DR=:PatientID Where APPT_RowId=:APPTRowId)
					if SQLCODE {
						TRollback
						Q "-233"_",更新预约记录的病人关联失败."
					}
				}
				s TRRBASRowId=""
			  	s RBASStatusDr=$P($G(^RBAS(+RBASRowId,$P(RBASRowId,"||",2),"DHC")),"^",10)
			 	s:RBASStatusDr'="" RBASStatusCode=$P(^DHCRBCASStatus(RBASStatusDr),"^",1)
			 	if (RBASStatusCode="S")||(RBASStatusCode="PS") {
				 	TRollback
				 	Q "-224,医生已经停诊."
			 	}
			 	i (RBASStatusCode="TR") s TRRBASRowId=$P(^RBAS(+RBASRowId,$P(RBASRowId,"||",2),"DHC"),"^",12)
				i $G(TRRBASRowId)'="" s ASRowId=TRRBASRowId	
				s MethodDR=$p(APPTData,"^",12)
				if MethodDR="" Q "-2020"
				s QueueNo=$p(APPTData,"^",5)
				s rtn="0^"_APPTRowId_"^"_QueueNo
			}
			s Flag=$P(rtn,"^",1)
			i Flag=0 {
			    s ResultCode=0
			    s APPTRowId=$P(rtn,"^",2)
			    s QueueNo=$P(rtn,"^",3)
			    s ErrorMsg=""
			    ;更新取号状态
			    s err=##Class(web.DHCRBAppointment).AppArrive(APPTRowId,EpisodeID,user,HospitalID)
			    i err'=0 {
				    TRollback
				    Q "-2021"
			    }
			}else{
			   s err=$P(rtn,"^",1)
			   ;"系统忙,请稍后重试"
			   i Flag=-200 s err="-2022"
			   ;"无可用预约号"
			   i Flag=-201 s err="-202"
			   ;"无此排班记录"
			   i Flag=-202 s err="-202"
			   ;预约渠道为空
			   i Flag=-204 s err="-204"
			   TRollback
			   q err
			}
		}else{
			b //根据取号模式取排号
			if (TimeRangeStr'["-") s TimeRangeStr=""
			if (+QueueNo'=0)&&(SourceType="LOCK"){
				;由于锁号时直接改变号序状态,若走锁号模式,则直接返回传入号序
				s QueueNo=QueueNo
			}else{
				s StartTime="",EndTime=""
				if (TimeRangeStr'=""){
					if (TimeRangeStr'["-") {s TimeRangeStr=""}else{
					s StartTime=$P(TimeRangeStr,"-",1)
					s EndTime=$P(TimeRangeStr,"-",2)}
				}
				s QueueNo=##class(web.DHCRBAppointment).GetSeqNo(ASRowId,GetSeqNoMode,"","",HospitalID,AllowAddRegFlag,ClinicGroupId,QueueNo,StartTime,EndTime)
			}
		}
		if ((NoLimitLoadFlag'="Y")&&(QueueNo=""))!(QueueNo="0")!(QueueNo="-1") {
			TRollback
			Q "-202"
		}
	}else{
		s QueueNo=""
	}
	
	;回归的预约号需要改变预约记录
	;--若勾选了预约回归不释放号源并增号配置,这里将调用不到爽约，因为根本取不到回归的预约号
	;--会在web.DHCRBApptSchedule.GetAvailSeqNoStr方法中调用
	if (GetSeqNoMode'="APP"){
		s IsApptRowid=..getApptRowidByQueNo(ASRowId,QueueNo)
		if IsApptRowid'="" {
			//s err=##Class(web.DHCRBAppointment).AppArrive(IsApptRowid,EpisodeID,user)
			s err=##Class(web.DHCRBAppointment).AddAppBreak(IsApptRowid,user,HospitalID)
			i err'=0 {
			    TRollback
			    Q "-2021"
		    }
		}
	}
	if ASDate=CurrDate {
		if (AddStartTime'="")&(CurrTime<AddStartTime)&&(QueueNo["+"){
			TRollback
			Q "-403"
		}
	}

	b ;记帐
	s InvoiceRowid=""
	s ret=..OPBillCharge(EpisodeID,ASRowId,AccRowId,PayModeCode,FeeStr,user,group,FreeRegFlag,FreeCheckFlag,.InvoiceRowid,InsuCoStr,DiscountFactor,InsuJoinStr,UnBillFlag,RegConDisId,HospitalID,ETPRowID,LoginLoc)
	if ret'=0 {
		TRollback
		Q ret
	}
	b ;insert into DHCRegistrationFee
	s CurrDate=..%SysDate(),CurrTime=..%SysTime()
	i FeeStr'="" d   
	.s Fee=$p(FeeStr,"||",1)
	.s examfee=$p(FeeStr,"||",2)
	s RegfeeAPPRangeTime=##class(web.DHCDocOutPatientList).GetAPPTimeRangeReg(ASRowId,QueueNo)
	;s RegfeeTimeRangeDr=##class(web.DHCRBResSession).GetTimeRangeByTime(ASStartTime)
	&SQL(insert into SQLUser.DHCRegistrationFee
		(RegfeeAdmDr,RegfeeName,RegfeeArcDr,RegfeeArcPrice,RegfeelookPrice,
		RegfeeBespFlag,RegfeeNo,RegfeeDoFlag,Regfeetemp1,RegfeeDepDr,RegfeeDocDr,
		RegfeeDate,RegfeeTime,RegfeeUserDr,RegfeeSessionTypeDr,RegfeeTimeRangeDr,
		RegfeeRoomDr,RegfeeRBASDr,RegTransferFlag,RegTransferReDoc,
		RegfeeInsuAdmDr,RegfeeInsuCash,RegfeeInsuCount,RegfeeInsuFund,RegfeeInsuOverallPlanning,RegfeeInsuOther,
		RegfeeInsuCoDR,RegfeeInsuCoProDR,RegfeeInsuCoPatPay,RegfeeAPPRangeTime,RegfeeClinicGroupDR)
		Values(:EpisodeID,:Name,"",:Fee,:examfee,
		'No',:QueueNo,'Yes',:InvoiceRowid,:AdmDep,:AdmDoc,
		:CurrDate,:CurrTime,:user,:SessionTypeDr,:RegfeeTimeRangeDr,:RoomDr,:ASRowId,"","",
		:InsuAdmRowid,:InsuPayCash,:InsuPayCount,:InsuPayFund,:InsuPayOverall,:InsuPayInsuOther,
		:InsuCoDR,:InsuCoProDR,:InsuCoPatPay,:RegfeeAPPRangeTime,:ClinicGroupId))
	if SQLCODE {
		TRollback
		Q "-211"
	}
	s RegfeeRowId=%ROWID
	b ;更新医保相关信息,医保组提供接口
	if InsuAdmRowid'="" {
		s InsuRet=##class(web.DHCINSUPort).UpdateInsuAdm(InsuAdmRowid,EpisodeID,InvoiceRowid,InsuDivRowid)
		if InsuRet'=0 {
			TRollback
			Q "-2010"
		}
	}
	
	b ;插入队列 DHCQueue
	s Para=EpisodeID_"^"_RoomDr_"^"_QueueNo_"^"_user_"^"_ASRowId_"^"_group
	s ret=..QueueInsert(Para)
	if ret {
		TRollback
		Q "-212"
	}
	b ;插入缴费医嘱及诊断
	s ret=..InsertPreOrderAndDiag(ASRowId,EpisodeID,user,HospitalID)
	if ret {
		TRollback
		Q "-215"
	}
	TC
	
	;大屏号别状态服务
	s CFIFScreenStart=##class(web.DHCOPRegConfig).GetSpecConfigNode("IFScreenStart",HospitalID)
	if (CFIFScreenStart=1)&&(ASDate=..%SysDate()){
		s FullFlag=##class(web.DHCRBApptSchedule).CheckScheduleFull(ASRowId)
		s err=##class(dhcinterface.DoctorApptScheClient).SetScreenDisplayMsg(ASRowId,FullFlag)
	}
	;调用平台组接口
	s rtn=##class(web.DHCENS.EnsHISService).DHCHisInterface("SENDOPREGINFO",EpisodeID)
	;DTS埋点
	s UserCode=$p($g(^SSU("SSUSR",user)),"^",1) 
	s rtn=##class(DHCDoc.Log.BizLogDTS).BizLogDTSInsert("1635895928927948800", PatientID, EpisodeID, "", UserCode, "", "")
	Q "0"
}

ClassMethod OPRegistBroker(PatientID As %String, ASRowId As %Library.String = "", AdmReason As %String, QueueNo As %Library.String = "", FeeStr As %Library.String = "", PayModeCode As %Library.String = "", AccRowId As %Library.String = "", user As %Library.String = "", group As %Library.String = "", AdmType As %Library.String = "", DiagnosCatRowId As %Library.String = "", FreeRegFlag As %Library.String = "", FreeCheckFlag As %Library.String = "", ByRef RegfeeRowId As %String = "", InsuJoinStr As %String = "", DiscountFactor As %String = "", TAPPTRowID As %String = "", UnBillFlag As %String = "", TabPCLRowID As %String = "", ApptMethodCode As %String = "", SourceType As %String = "", RegConDisId As %String = "", HospitalID As %String = "", ETPRowID As %String = "", TimeRangeStr As %String = "", RegSource As %String = "", RegExpStr As %String = "")
{
	s ^tempscl("ggg")=PatientID_","_ASRowId_","_AdmReason_","_QueueNo_","_FeeStr_","_PayModeCode_","_AccRowId_","_ user_","_group_","_AdmType_","_DiagnosCatRowId_","_FreeRegFlag_","_FreeCheckFlag_","_RegfeeRowId_","_InsuJoinStr_","_DiscountFactor_","_TAPPTRowID_","_UnBillFlag_","_TabPCLRowID_","_ApptMethodCode_","_ SourceType_","_RegConDisId
	;w ##class(web.DHCOPAdmReg).OPRegistBroker(1,"3022||314","1","","0||0||0||0||0||0||0","CPP","39963",7,119,"","","","")
	s CFNotNeedNotFeeBill=##class(web.DHCOPRegConfig).GetSpecConfigNode("NotNeedNotFeeBill",HospitalID)
	s RegfeeRowId=""
	s ret=..OPRegist(PatientID,ASRowId,AdmReason,QueueNo,FeeStr,PayModeCode,AccRowId,user,group,AdmType,DiagnosCatRowId,FreeRegFlag,FreeCheckFlag,.RegfeeRowId,InsuJoinStr,DiscountFactor,TAPPTRowID,UnBillFlag,TabPCLRowID,ApptMethodCode,SourceType,RegConDisId,HospitalID,ETPRowID,TimeRangeStr,RegSource,RegExpStr)
	b ;OPRegist OK
	s PrintData=""
	i ret="0" {
		s InvoiceId=$List(^User.DHCRegistrationFeeD(RegfeeRowId),11)
		i InvoiceId="" {
			s PrintData=""
			s PrintData=##class(DHCDoc.Common.pa).GetOPPrintData(RegfeeRowId) //i CFNotNeedNotFeeBill=1 
		}else{
			s PrintData=##class(DHCDoc.Common.pa).GetOPPrintData(RegfeeRowId)
		}
	}
	s ret=ret_"$"_PrintData
	q ret
}

ClassMethod getApptRowidByQueNo(RBASRowid As %String, QueNo As %String) As %String
{
	Q:RBASRowid="" ""
	s myAPPTRowid=""
	s APPTRowid=0
	for {
		s APPTRowid=$O(^RBAS("APPT_Status","I",+RBASRowid,$P(RBASRowid,"||",2),APPTRowid))
		Q:APPTRowid=""
		s APPTQueueNo=$P($g(^RBAS(+RBASRowid,$P(RBASRowid,"||",2),"APPT",APPTRowid)),"^",5)
		if (APPTQueueNo'="")&&(APPTQueueNo=QueNo) {
			s myAPPTRowid=RBASRowid_"||"_APPTRowid
			quit
		}
	}
	
	Q myAPPTRowid
}

/// 得到加号预约医生
ClassMethod GetDOCADDDocDR(EpisodeID As %String)
{
	Q:EpisodeID="" ""
	s DOCADDDocDR=""
    s resRowid=$o(^RBAS("PAADM_DR",EpisodeID,""))
    if resRowid'="" {
	    s asChildsub=$o(^RBAS("PAADM_DR",EpisodeID,resRowid,""))
	    s apptChildsub=$o(^RBAS("PAADM_DR",EpisodeID,resRowid,asChildsub,""))
	    if $d(^RBAS(resRowid,asChildsub,"APPT",apptChildsub)) {
	    	s APPTTransUserDR=$p($g(^RBAS(resRowid,asChildsub,"APPT",apptChildsub)),"^",11)
	    	if APPTTransUserDR'="" {
				s ctpcpDr=$p($g(^SSU("SSUSR",APPTTransUserDR)),"^",14)
				if ctpcpDr'="" {
					s CarPrvTpDR=$p($g(^CTPCP(+$g(ctpcpDr),1)),"^",4)
					s DoctorType=$p($g(^CT("CPT",+$g(CarPrvTpDR))),"^",4)
					if DoctorType="DOCTOR" s DOCADDDocDR=ctpcpDr
				}
			}
	    }
    }
    
    Q DOCADDDocDR
}

ClassMethod QueueInsert(Para As %String, ExpStr As %String = "")
{
	;s ^RP("queue")=Para
	//insert into DHC_Queue 插入分诊排队记录表
	s EpisodeID=$P(Para,"^",1)
	s Room=$P(Para,"^",2)
	s QueueNo=$P(Para,"^",3)
	s UserID=$P(Para,"^",4)
	s ASRowId=$P(Para,"^",5)
	s group=$P(Para,"^",6)
	s HospId=$p(..GetCurrentHosp(EpisodeID,"","",""),"^",1)
	s PatientID=$P(^PAADM(EpisodeID),"^",1)
	s Name=$p($g(^PAPER(PatientID,"ALL")),"^",1)
	s PatientNo=$p($g(^PAPER(PatientID,"PAT",1)),"^",1)
	
	s AdmDate=$P(^PAADM(EpisodeID),"^",6)
	s AdmTime=$P(^PAADM(EpisodeID),"^",7)
	s AdmDep=$P(^PAADM(EpisodeID),"^",4)
	s AdmDoc=$P(^PAADM(EpisodeID),"^",9)
	s StatusDate=..%SysDate()
	s StatusTime=..%SysTime()
	
	s ConsultLocID="",ConsultDocID="",ConsultFlag="",ConsultUserID="",ParaPersDr=""
	if ExpStr'="" {
		s ConsultLocID=$p(ExpStr,"^",1)
		s ConsultDocID=$p(ExpStr,"^",2)
		s ConsultFlag=$p(ExpStr,"^",3)
		s ConsultUserID=$p(ExpStr,"^",4)
		if (ConsultFlag="Y"){
			s AdmDep=ConsultLocID
			s AdmDoc=ConsultDocID
		}
		s ParaPersDr=$p(ExpStr,"^",5)
	}
	s DOCADDDocDR="" ;..GetDOCADDDocDR(EpisodeID)    
	//"等候"状态rowid
	&sql(select ID into :PersDr from  SQLUser.DHCPerState where PersName='等候')
	&sql(select ID into :FirstDr from SQLUser.DHCFirstCode where firstcname='正常')
	i ParaPersDr'="" s PersDr=ParaPersDr
	set ExabDr=""
	set MarkRowid=0
	set SQLCODE=0
	s RoomDr=""
	if RoomDr="" {
             s ExabInfo=..GetExabInfo(AdmDep,AdmDoc)
             s ExabDr=$p(ExabInfo,"^",1)
             s MarkRowid=$p(ExabInfo,"^",3)

			 if (ExabDr'="") {
				;根据挂号设置-》授权管理-》功能设置-》挂号不报道
				s OPNotReportGroup=0 ;挂号强制置已报到状态
				s OPAllocReport=0 ;挂号强制置报到状态
				if (group'=""){
					s OPNotReportGroup=##class(web.DHCOPRegConfig).GetGroupConfig(HospId,group,"OPNotReportGroup")
					s OPAllocReport=##class(web.DHCOPRegConfig).GetGroupConfig(HospId,group,"OPAllocReport")
				}
				if OPNotReportGroup=1 {
					s Checkin="N"
				}elseif (OPAllocReport=1){
					s Checkin="Y"
				}else{
					&sql(select ExabTem into :Checkin from SQLUser.DHCExaBorough where ID=:ExabDr)
					if Checkin'="Y"{
					   s Checkin=$list(^User.DHCDepMarkD(MarkRowid),10)
					   if Checkin'="Y" {
					      s Checkin=..CheckCheckinBySched(ASRowId)
					   }
					}
				}
				if Checkin="Y"{
					&sql(select ID into :PersDr from  SQLUser.DHCPerState where PersName='报到')
				}else{
					&sql(select ID into :PersDr from  SQLUser.DHCPerState where PersName='等候')
				}
				i ParaPersDr'="" s PersDr=ParaPersDr
				//zhaolj2008-02-27 update end
				&SQL(Insert into SQLUser.DHCQueue
				(QueDate,QueTime,QuePersonId,QueName,QueExabDr,QueDepDr,QueMarkDr,QueNo,QuePaadmDr,QueStateDr,QueFirstDr,QueConsultFlag,QueStateDate,QueStateTime,Operuserid,QueDocDr,QueRoomDr)
				values(:AdmDate,:AdmTime,:PatientNo,:Name,:ExabDr,:AdmDep,:AdmDoc,:QueueNo,:EpisodeID,:PersDr,:FirstDr,:ConsultFlag,:StatusDate,:StatusTime,:UserID,:DOCADDDocDR,:Room))
			 }else{
				&SQL(Insert into SQLUser.DHCQueue
				(QueDate,QueTime,QuePersonId,QueName,QueExabDr,QueDepDr,QueMarkDr,QueNo,QuePaadmDr,QueStateDr,QueFirstDr,QueConsultFlag,QueStateDate,QueStateTime,Operuserid,QueDocDr,QueRoomDr)
				values(:AdmDate,:AdmTime,:PatientNo,:Name,:ExabDr,:AdmDep,:AdmDoc,:QueueNo,:EpisodeID,:PersDr,:FirstDr,:ConsultFlag,:StatusDate,:StatusTime,:UserID,:DOCADDDocDR,:Room))
			 }
	}else{
		;通过诊室与诊区的关系去得到诊区RowId
		//&SQL(Select ExarBorDr Into :ExabDr From DHCExaRoom Where %Id=:RoomDr )
		&SQL(Insert into SQLUser.DHCQueue
		(QueDate,QueTime,QuePersonId,QueName,QueExabDr,QueDepDr,QueMarkDr,QueNo,QuePaadmDr,QueStateDr,QueFirstDr,QueConsultFlag,QueStateDate,QueStateTime,Operuserid,QueDocDr)
		values(:AdmDate,:AdmTime,:PatientNo,:Name,:ExabDr,:AdmDep,:AdmDoc,:QueueNo,:EpisodeID,:PersDr,:FirstDr,:ConsultFlag,:StatusDate,:StatusTime,:UserID,:DOCADDDocDR))
	}
	Q SQLCODE
}

/// 重打
ClassMethod RePrintBroker(itmjs As %Library.String = "", itmjsex As %Library.String = "", RegFeeRowId As %String, UserRowId As %String, GroupRowId As %String, LogonLocRowId As %String)
{
	;w ##class(web.DHCOPAdmReg).RePrintBroker("","",226,12173,239,49)
	s ^zhou("RePrint")=RegFeeRowId_","_UserRowId_","_GroupRowId_","_LogonLocRowId
	s PrintData=""
	s InvoiceId=$List(^User.DHCRegistrationFeeD(RegFeeRowId),11)
	s oldReceipRowid=InvoiceId
	i InvoiceId="" {
		s ret="-300"
		s PrintData=""
	}else{
		s InvUserRowId=$P($g(^DHCINVPRT(InvoiceId)),"^",21)
		s InvHandin=$P($g(^DHCINVPRT(InvoiceId)),"^",10)
		if (InvHandin="Y")||(InvUserRowId'=UserRowId){
			Q "-200"
		}
		TS
		s ret=..OPReBillCharge(RegFeeRowId,UserRowId,GroupRowId, LogonLocRowId)
		i ret="0" {
			s myPRTRowID=$List(^User.DHCRegistrationFeeD(RegFeeRowId),11)
			s PRTFairType=$P($g(^DHCINVPRT(myPRTRowID)),"^",34)
			//新发票rowid不为空时，要确认完成
			if (myPRTRowID'=""){ //&&(PRTFairType="R")
				s EpisodeID=$List(^User.DHCRegistrationFeeD(RegFeeRowId),2)
				s PatientID=$P(^PAADM(EpisodeID),"^",1)
				s PatCatDr=$p(^PAPER(PatientID,"PER",1),"^",10)
		        s AdmReason=..GetDefaultBillType(PatCatDr)
				s TMPExpStr=GroupRowId_"^"_LogonLocRowId_"^"_""_"^"_""
				s TMPExpStr=TMPExpStr_"^"_"R"
				s TMPExpStr=TMPExpStr_ "^"_""_"^"_""_"^"_""
				s TMPExpStr=TMPExpStr_ "^"_AdmReason
				
				;Modify 20200528 Lid 确认完成接口增加支付方式列表参数
				s strikePrtRowID=$o(^DHCINVPRT(0,"InitInvDR",InvoiceId,""))
				s insuDivDR=$p(^DHCINVPRT(InvoiceId),"^",30)    //PRT_InsDiv_DR
				if (+insuDivDR'=0) {
					s retValue=##class(web.udhcOPRefEdit1).UpdateRepInvPayM(InvoiceId, myPRTRowID)
					s ret=$p(retValue,"^",1)
				}
				if (ret'=0) {
					TRO
					Q "-201$"
				}
				s payList=##class(web.DHCBillConsIF).GetNewInvPayMList(InvoiceId, strikePrtRowID, myPRTRowID, "")
				s ret=##class(web.DHCBillConsIF).CompleteCharge("3", UserRowId, AdmReason, myPRTRowID, "1", InvoiceId, TMPExpStr, payList) 
				if (ret'=0) {
					TRO
					Q "-201$"
				}
				//Q:ret'="0" "-201$"
			}
			if (ret="0"){
				s PrintData=..GetPrintData(RegFeeRowId,"","Y") ;..GetRePrintData(RegFeeRowId)
			}
		}else{
			b //55
			Tro
		}
	}
	if (ret=0) TC
	s ret=ret_"$"_PrintData
	Q ret
}

ClassMethod RegedMarkTabClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = RegedMarkTabExecute ]
{
	Set repid=$LIST(qHandle,2)
	Kill ^CacheTemp(repid)
	Quit $$$OK
}

ClassMethod RegedMarkTabExecute(ByRef qHandle As %Binary) As %Status
{
	Set repid=$I(^CacheTemp)	
	If $g(ind)="" Set ind=1

	set Data=$lb(DocCode,DocDesc)
	Set ^CacheTemp(repid,ind)=Data
	Set ind=ind+1
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
}

ClassMethod RegedMarkTabFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = RegedMarkTabExecute ]
{
 Set AtEnd=$LIST(qHandle,1)
 Set repid=$LIST(qHandle,2)
 Set ind=$LIST(qHandle,3)
	//
 Set ind=$o(^CacheTemp(repid,ind))
 If ind="" {				// if there are no more rows, finish fetching
 Set AtEnd=1
 Set Row=""
 }
 Else      {				// fetch row
 Set Row=^CacheTemp(repid,ind)
 }
 // Save QHandle
 s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// 撤消退号
ClassMethod RestoreOPRegist(RegFeeRowId As %String = "", UserRowId As %String = "", GroupRowId As %String = "", LogonLocRowId As %String = "") [ ProcedureBlock = 0 ]
{
	n (RegFeeRowId,UserRowId,GroupRowId,LogonLocRowId,%session)
	;w ##Class(web.DHCOPAdmReg).RestoreOPRegist(25440,809,55,101)
	s ^zhou("RestoreOPRegist")=RegFeeRowId_","_UserRowId_","_GroupRowId_","_LogonLocRowId

	;Set $ZT="ERROR^DHCSSERR"
	
	&SQL(Select RegfeeAdmDr,RegfeeNo,RegfeeDoFlag,RegfeeRBASDr,Regfeetemp1,RegfeeDate
	   into :adm,:QueueNo,:doflag,:RBASRowId,:InvoiceId,:RegfeeDate
	   from SQLUser.DHCRegistrationFee 
	  Where %Id=:RegFeeRowId)
	
	if adm'="" {
		s AdmStatus=$P($g(^PAADM(adm)),"^",20)
		if AdmStatus="A" Q "-211"
	}
	
	s RestoreInvoiceId=""  
	&SQL(select PRT_OldINV_DR into :oldInvoiceId From SQLUser.DHC_INVPRT where PRT_RowId=:InvoiceId)
	if oldInvoiceId'="" {s RestoreInvoiceId=oldInvoiceId}
	else {s RestoreInvoiceId=InvoiceId}
	
	TStart
	s ret=##class(web.udhcOPRefEditIF).CancleRefundINVPRT(RestoreInvoiceId, UserRowId, GroupRowId, LogonLocRowId)
 if (ret'=0)	{
	    Tro
	    Q "-200"
 }
	b ;restore recipt	
	if RestoreInvoiceId'="" {
		&SQL(Update SQLUser.DHCRegistrationFee Set Regfeetemp1=:RestoreInvoiceId Where %Id=:RegFeeRowId)
		if SQLCODE {
			TRollback
			Q "-204"
		}
	}
	
	s vis="A",read="Y",admdate=..%SysDate(),admtime=..%SysTime()
	s UserName=""
	i UserRowId'="" s UserName=$p($g(^SSU("SSUSR",UserRowId)),"^",2)  
	
	b ;更新就诊表的状态
	&sql(update SQLUser.PA_Adm
		 Set PAADM_VisitStatus=:vis,	PAADM_ReadOnly=:read,
			 PAADM_UpDateDate=:admdate,	PAADM_UpDateTime=:admtime,
			 PAADM_SocialWorkerName=:UserRowId
		where PAADM_RowID=:adm)
	if SQLCODE {
		TRollback
		Q "-201"
	}
	
	b ;判断是否为预约
	s APPTRowIdStr=##class(web.DHCRBAppointment).GetAppByAdm(adm)
	if (APPTRowIdStr'=""){
		;取消预约(包括了回退号的处理)
		s APPTRowId=$P(APPTRowIdStr,"^",1)
		s err=##class(web.DHCRBAppointment).AppRestore(APPTRowId,UserRowId)
		if err {
			TRollback
			Q "-210"
		}
	}else{
		Set StatusCode=1
		set APPMethodRowId=""
		d ##class(web.DHCRBAppointment).RestoreSeqNo(RBASRowId,QueueNo, StatusCode,"")
	}
	
	b ;在分诊队列中将标志改为"正常"
	&sql(select ID into :PersDr from SQLUser.DHCPerState where PersName='正常')
	&sql(update SQLUser.DHCQueue set QueStateDr=:PersDr where QuePaadmDr=:adm )
	if SQLCODE {
		TRollback
		Q "-202"
	}
	TCommit
	if RBASRowId'="" {
		s ASDate=$P($G(^RBAS(+RBASRowId,$P(RBASRowId,"||",2))),"^",1) 
		s CFIFScreenStart=##class(web.DHCOPRegConfig).GetSpecConfigNode("IFScreenStart")
		if (CFIFScreenStart=1)&&(ASDate=..%SysDate()){
			s FullFlag=##class(web.DHCRBApptSchedule).CheckScheduleFull(RBASRowId)
			s err=##class(dhcinterface.DoctorApptScheClient).SetScreenDisplayMsg(RBASRowId,FullFlag)
		}
	}
	Q 0
}

/// 转号
ClassMethod TransferOPRegist(RegFeeRowId As %String, NewPatientID As %String, UserRowId As %String = "", GroupRowId As %String = "", LogonLocRowId As %String = "", ByRef NewRegfeeRowId As %String, PayModeCode As %String, AccRowId As %String) [ ProcedureBlock = 0 ]
{
	n (RegFeeRowId,NewPatientID,UserRowId,GroupRowId,LogonLocRowId,NewRegfeeRowId)
	s ^zhou("TransferOPRegist")=RegFeeRowId_","_NewPatientID_","_UserRowId_","_GroupRowId_","_LogonLocRowId
	;Set $ZT="ERROR^DHCSSERR"
	
	&SQL(Select RegfeeAdmDr,RegfeeNo,RegfeeDoFlag,RegfeeRBASDr,Regfeetemp1
	   into :adm,:QueueNo,:doflag,:RBASRowId,:InvoiceId
	   from SQLUser.DHCRegistrationFee 
	  Where %Id=:RegFeeRowId)
	b ;查找是否存在诊断
	s kid=""
	s mm=0 f  s mm=$o(^MRi("MRADMDR",adm,mm)) q:mm=""  d
	.s Childsub=0
	.f  s Childsub=$o(^MR(mm,"DIA",Childsub)) q:Childsub=""  d
	..s kid=mm_"||"_Childsub
	//&sql(select mrdia_rowid  into :kid from SQLUser.mr_diagnos  where mrdia_mradm_parref=:mm)
	
	q:kid'="" "diagnos"
	
	TStart
	;Q:InvoiceId="" "Invoice"

	b ;生成负帐单
	s RefundStatusCode=..GetINVRefundStatus(InvoiceId,UserRowId)
	if (RefundStatusCode'="") {
		;s Paymode=$p(^DHCINVPRT(InvoiceId,"P",1),"^")
		s Paymode=""
		s InvPayModeID=$O(^DHCINVPRT(InvoiceId,"P",0))
		s:InvPayModeID'="" Paymode=$p(^DHCINVPRT(InvoiceId,"P",InvPayModeID),"^")
		
		;s APPMethodCode=##class(web.DHCRBAppointment).GetAPPMethodCodeByAdm(adm)
		;i APPMethodCode="TEL" d
		s Refoundcode=##class(web.udhcOPRefEditIF).RefundReceipt(InvoiceId, UserRowId,RefundStatusCode, "", 0, GroupRowId,0,LogonLocRowId,Paymode)
		i Refoundcode'=0 {
			TRollback
			Q:"-300"
		}
	}
	
	s vis="C",read="Y",admdate=..%SysDate(),admtime=..%SysTime()
	s UserName=""
	i UserRowId'="" s UserName=$p($g(^SSU("SSUSR",UserRowId)),"^",2)  
	b ;更新就诊表的状态
	&sql(update SQLUser.PA_Adm
		 Set PAADM_VisitStatus=:vis,	PAADM_ReadOnly=:read,
			 PAADM_UpDateDate=:admdate,	PAADM_UpDateTime=:admtime,
			 PAADM_SocialWorkerName=:UserRowId
		where PAADM_RowID=:adm)
	if SQLCODE {
		TRollback
		Q "-301"
	}
	
	b ;在分诊队列中?将标志改为?退号?
	&sql(select ID into :PersDr from SQLUser.DHCPerState where PersName='退号')
	&sql(update SQLUser.DHCQueue set QueStateDr=:PersDr where QuePaadmDr=:adm )
	if SQLCODE {
		TRollback
		Q "-302"
	}

	;插入就诊记录
	s AdmType=$P(^PAADM(adm),"^",2)
	s AdmDate=$P(^PAADM(adm),"^",6)
	s AdmTime=$P(^PAADM(adm),"^",7)
	s AdmReason=$P(^PAADM(adm,1),"^",7)
	s Name=$p($g(^PAPER(NewPatientID,"ALL")),"^",1)
	s PatientNo=$p($g(^PAPER(NewPatientID,"PAT",1)),"^",1)
	
	s ResRowId=$P(RBASRowId,"||",1)
	s ASChild=$P(RBASRowId,"||",2)
	
	s AdmDep=$P($G(^RB("RES",ResRowId)),"^",1)
	s AdmDoc=$P($G(^RB("RES",ResRowId)),"^",2)
	s ASDate=$P($G(^RBAS(ResRowId,ASChild)),"^",1) 
	s ASStartTime=$P($G(^RBAS(ResRowId,ASChild)),"^",4) 
	s RoomDr=$P($G(^RBAS(ResRowId,ASChild,"DHC")),"^",5)
	s SessionTypeDr=$P($G(^RBAS(ResRowId,ASChild,"DHC")),"^",6)
	s RegfeeTimeRangeDr=$P($G(^RBAS(ResRowId,ASChild,"DHC")),"^",17)
	
	s user=UserRowId
	s group=GroupRowId
	
	s DiagnosCatRowId=""
	s InsuCoDR=""
	s PatAdmissionTp=..GetPatAdmissionTp(RBASRowId)
	s RegConDisIdPara=NewPatientID_"^"_RBASRowId_"^"_AdmReason_"^"_""
	s RegConDisId=..GetRegConDisId(RegConDisIdPara)
	s AdmCategory="",HospitalID=$P(^CTLOC(AdmDep),"^",22)
	if AdmType ="O" {
		s AdmCategory=##class(web.DHCOPRegConfig).GetGroupConfig(HospitalID,group,"OPRegAdmCategory")
	}
	s Para=NewPatientID_"^"_AdmType_"^"_AdmDate_"^"_AdmTime_"^"_AdmDep_"^"_AdmDoc_"^"_AdmReason_"^"_user_"^^^^"_PatAdmissionTp_"^"_AdmCategory_"^^"_DiagnosCatRowId_"^^^^^"_InsuCoDR_"^"_RegConDisId
	Set Re=##class(web.DHCPAADM).ADMInsert(Para)
	if ($g(Re)="") {
		TRollback
		Q "-201"
	}
	s EpisodeID=Re
	
	b ;记帐
	s InvoiceRowid=""
	;s AccRowId=""
	;s PayModeCode=""
	
	;应该从原帐单判断是否要收预约费和假日费
	s ret=##class(web.DHCRBAppointment).GetAppByAdm(adm)
	i ret'="" s FeeStr="||||||1"
	e  s FeeStr=""
	
	s ret=..OPBillCharge(EpisodeID,RBASRowId,AccRowId,PayModeCode,FeeStr,user,group,"","",.NewInvoiceRowid)
	if ret'=0 {
		TRollback
		Q ret
	}
	
	s Fee=0,examfee=0
	b ;insert into DHCRegistrationFee
	s CurrDate=..%SysDate(),CurrTime=..%SysTime()
	;s RegfeeTimeRangeDr=##class(web.DHCRBResSession).GetTimeRangeByTime(ASStartTime)
	&SQL(insert into SQLUser.DHCRegistrationFee
		(RegfeeAdmDr,RegfeeName,RegfeeArcDr,RegfeeArcPrice,RegfeelookPrice,
		RegfeeBespFlag,RegfeeNo,RegfeeDoFlag,Regfeetemp1,RegfeeDepDr,RegfeeDocDr,
		RegfeeDate,RegfeeTime,RegfeeUserDr,RegfeeSessionTypeDr,RegfeeTimeRangeDr,
		RegfeeRoomDr,RegfeeRBASDr)
		Values(:EpisodeID,:Name,"",:Fee,:examfee,
		'No',:QueueNo,'Yes',:NewInvoiceRowid,:AdmDep,:AdmDoc,
		:CurrDate,:CurrTime,:user,:SessionTypeDr,:RegfeeTimeRangeDr,:RoomDr,:RBASRowId))
	if SQLCODE {
		TRollback
		Q "-211"
	}
	s NewRegfeeRowId=%ROWID
	 
	b ;插入队列 DHCQueue
	s Para=EpisodeID_"^"_RoomDr_"^"_QueueNo_"^"_user_"^^"_group
	s ret=..QueueInsert(Para)
	if ret {
		TRollback
		Q "-212"
	}
	
	TCommit
	Q 0
}

ClassMethod SaveCatBillType() As %String
{
 Set RetStr=""
 If $D(^DHCDiagnosCatBill) K ^DHCDiagnosCatBill
 Set CatRowid=""  For  Set CatRowid=$O(^DHCDiagnosCat(CatRowid)) Q:CatRowid=""  Do
 .Set DCBillTypeDR=$P(^DHCDiagnosCat(CatRowid),"^",3)
 .Set ^DHCDiagnosCatBill(DCBillTypeDR)=""
 Q 0
}

// 保存医生的可看特病和费别，维护程序为dhcdocinsuconfig.csp

// 应该和RBResource.Edit合并在一起维护

ClassMethod SaveConfig(InfoStr As %String) As %String
{
 //w ##class(web.DHCOPAdmReg).SaveConfig("621^N^N^N^^92!97!100!56!57!58!103!104")
 Set RecDocId="",RESReAdmFeeFlag="",RESEPMarkFlag="",retireFlag="",FeeTypetreeSelId="",DiagnostreeSelId=""
 Set RecDocId=$P(InfoStr,"^",1)
 Set RESReAdmFeeFlag=$P(InfoStr,"^",2)
 Set RESEPMarkFlag=$P(InfoStr,"^",3)
 Set retireFlag=$P(InfoStr,"^",4)
 Set FeeTypetreeSelId=$P(InfoStr,"^",5)
 Set DiagnostreeSelId=$P(InfoStr,"^",6)
 TSTART
 Set object=##class(User.DHCRBResource).%OpenId(RecDocId)
 Set object.RESDiagnosCatStr =DiagnostreeSelId
 Set object.RESFeeType =FeeTypetreeSelId
 Set object.RESReAdmFeeFlag=RESReAdmFeeFlag
 Set object.RESEPMarkFlag=RESEPMarkFlag
 //沈阳用,属性retire命名不符合规范,在东方医院修改为RESRetireFlag
 //Set object.retire=retireFlag
 Set object.RESRetireFlag=retireFlag
 Set sc=object.%Save()
 If $$$ISERR(sc) {
 Trollback
 Quit -100
 }
 TCommit
 Quit sc
}

/// Creator    ：周志强      
/// CreatDate  ：2010.02.27
/// Description: 受限费别标志保存到^PAC("ADMREA",RowId,"DHC")里
/// Table      ：PAC_AdmReason   
/// Input      ：InfoStr:以"!"分隔的费别RowId串
/// Return     ：0:成功
/// Others     ：在dhcdocinsu.limitbilltype.csp使用
ClassMethod SaveLimitBillType(InfoStr As %String) As %String
{
   
	s RowId=0 For  Set RowId=$O(^PAC("ADMREA",RowId)) q:(RowId="")  d
	.s LimitFlag=0
	.if ("!"_InfoStr_"!")[("!"_RowId_"!") s LimitFlag=1
	.s $p(^PAC("ADMREA",RowId,"DHC"),"^",1)=LimitFlag 
	Q 0
}

/// Creator    ：周志强      
/// CreatDate  ：2010.02.27
/// Description: 取得受限费别RowId串
/// Table      ：PAC_AdmReason   
/// Input      ：
/// Return     ：以"!"分隔的费别RowId串
/// Others     ：在dhcdocinsu.limitbilltype.csp使用
ClassMethod GetLimitBillType() As %String
{
	s RetStr=""
	s RowId=0 For  Set RowId=$O(^PAC("ADMREA",RowId)) q:(RowId="")  d
	.s LimitFlag=$p($G(^PAC("ADMREA",RowId,"DHC")),"^",1)
	.i LimitFlag=1 d
 	..If RetStr="" Set RetStr=RowId
 	..Else  Set RetStr=RetStr_"!"_RowId
 	Q RetStr
}

/// Creator    ：周志强      
/// CreatDate  ：2010.02.27
/// Description: 取得受限费别串
/// Table      ：PAC_AdmReason   
/// Input      ：
/// Return     ：以"!"分隔的费别RowId串+"^"+描述
/// Others     ：在dhcdocinsuconfig.csp使用
ClassMethod GetLimitBIllTypeStr() As %String
{
	Set RetStr=""
	Set RowId=0 For  Set RowId=$O(^PAC("ADMREA",RowId)) q:(RowId="")  d
	.Set Desc=$p(^PAC("ADMREA",RowId),"^", 2)
	.s LimitFlag=$p($G(^PAC("ADMREA",RowId,"DHC")),"^",1)
	.i LimitFlag=1 d
	..If RetStr="" Set RetStr=RowId_$c(1)_Desc
	..Else  Set RetStr=RetStr_"^"_RowId_$c(1)_Desc
	Q RetStr
}

/// 更新病人信息
ClassMethod SavePatient(PatInfo As %String) As %String
{
	s ^zhou("SavePatient")=PatInfo
	;w ##class(web.DHCOPAdmReg).SavePatient("93^zhou^3^10")
	s ret=0
	s PatRowId=$P(PatInfo,"^",1)
	s PatName=$P(PatInfo,"^",2)
	s PatSex=$P(PatInfo,"^",3)
	s Age=$P(PatInfo,"^",4)
	
	s myBirth=""
	i Age'="" {
		s DateStr=$ZD(+$H,3)
		s DateYear=$P(DateStr,"-",1)
		s DateMonth=$P(DateStr,"-",2)
		;s DateDay=$P(DateStr,"-",3)
		s DateDay=1
		s myBirthYear=DateYear-Age
		;s myBirthDateStr=myBirthYear_"-01-01"
		s myBirthDateStr=myBirthYear_"-"_DateMonth_"-"_DateDay
		s myBirth=$ZDH(myBirthDateStr,3)
	}
	
	Set person = ##class(User.PAPerson).%OpenId(PatRowId)
	Set person.PAPERName = PatName
	i (PatSex'=""){
		Do person.PAPERSexDRSetObjectId(PatSex)
	}
	Set person.PAPERDob = myBirth
	Set sc = person.%Save()
	If ($System.Status.IsError(sc))
	{
		Do $System.Status.DisplayError(sc)
		Set ret = "-100"
	}
	Q ret
}

ClassMethod TransferOPRegistBroker(itmjs As %Library.String = "", itmjsex As %Library.String = "", RegFeeRowId As %String, NewCardNo As %String, UserRowId As %String = "", GroupRowId As %String = "", LogonLocRowId As %String = "", ByRef NewRegfeeRowId As %String, PayModeCode As %String, AccRowId As %String)
{
	s NewPatientID=..GetPatientIDByCardNo(NewCardNo)
	if NewPatientID="" Q "-301"
	;w ##class(web.DHCOPAdmReg).TransferOPRegistBroker("","",127,"34||15",6,6,1)
	s ret=..TransferOPRegist(RegFeeRowId,NewPatientID,UserRowId,GroupRowId, LogonLocRowId,.NewRegfeeRowId,PayModeCode,AccRowId)
	s PrintData=""
	i ret="0" s PrintData=..GetPrintData(NewRegfeeRowId)
	s ret=ret_"$"_PrintData
	Q ret
}

Query AdmRegFee(UserRowId As %String, PatientID As %String, StartDate As %Date, EndDate As %Date, InvoiceNo As %String) As %Query(ROWSPEC = "INVNo:%String,INVDateTime:%String,RegfeeTime:%String,Flag:%String,HandInDesc:%String,PatientNo:%String,PatName:%String,AdmDep:%String,AdmDoc:%String,AdmDate:%String,RefundDateTime:%String,INVPRTAcount:%String,QueueNo:%String,INVUserName:%String,RefundUserName:%String,Adm:%String,INVRowId:%String")
{
}

Query DHCOPAdm(RegNo As %String, nday As %String, InvoiceNo As %String, PatientID As %String, UserRowId As %String, QueryCancel As %String, RegDate As %String = "", LogonHospID = "") As %Query(ROWSPEC = "Deptid:%String,Dept:%String,Doctorid:%String,Doctor:%String,TabTime:%String,UserName:%String,AdmId:%String,TabPrice:%String,Arcdr:%String,Regno:%String,Tph:%String,InvoiceId:%String,TabDate:%String,RegfeeDate:%String,RegfeeTime:%String,RegfeeRowId:%String,TabInvoiceNo:%String,TabRBASRowId:%String,TabTRRBASRowId:%String,TabTRDoc:%String,TabRBASStatus:%String,TabRBASStatusCode:%String,TabRegType:%String,TabAppFee:%String,RBASStatusReason:%String,PatName:%String,TRSum:%String,ChangeSum:%String,INVPayMode:%String,RegFee:%String,CheckFee:%String,AppFee:%String,ReCheckFee:%String,OtherFee:%String,HoliFee:%String,TabReturnFlag:%String,PatDr:%String,MRFee:%String,InsuAdmInfoDr:%String,AdmReasonId:%String,TabEinvprtNo:%String")
{
}

Query OPDept(Desc As %String) As %SQLQuery(ROWSPEC = "CTLOCDesc:%String,CTLOCRowId:%String")
{
	Select CTLOC_Desc,CTLOC_RowId From SQLUser.CT_LOC where (CTLOC_TYPE='E') and CTLOC_Desc [ %ALPHAUP :Desc
}

Query OPDeptList(UserId As %String, AdmType As %String, paradesc As %String = "", HospitalID As %String = "") As %Query(ROWSPEC = "CTCode:%String,CTDesc:%String:科室,CTAlias:%String")
{
}

Query OPDocList(Dept As %String = "") As %Query(ROWSPEC = "ASRowId:%String,MarkDesc:%String,Load:%String,AppLoad:%String,AddLoad:%String,AvailSeqNoStr:%String,AvailAddSeqNoStr:%String,RoomDesc:%String,ClinicGroupDesc:%String,SessionTypeDesc:%String,RegFee:%String,RegFeeDr:%String,ExamFee:%String,ReCheckFee:%String,HoliFee:%String,HoliFeeDr:%String,AppFee:%String,OtherFee:%String,RoomCode:%String,DepDesc:%String,RegedCount:%String,AppedCount:%String,AddedCount:%String,AvailNorSeqNoStr:%String,ScheduleStatus:%String,ScheduleDate:%String,ScheduleDateWeek:%String,TimeRange:%String,AppedArriveCount:%String,BorghAlertInfo:%String,StopRegFlag:%String,AdmWaitSum:%String,NoLimitLoadFlag:%String,ClinicGroupDr:%String,ID:%String")
{
}

Query OPResDoc(DepRowId As %String, Desc As %String) As %SQLQuery(ROWSPEC = "CTPCPDesc:%String,CTPCPRowId:%String")
{
	Select RES_CTPCP_DR->CTPCP_Desc,RES_CTPCP_DR->CTPCP_RowId From SQLUser.RB_Resource
	where RES_CTLOC_DR=:DepRowId And RES_CTPCP_DR->CTPCP_Desc [ %ALPHAUP :Desc
}

Query RegedMarkTab() As %Query(ROWSPEC = "MarkName:%String,Price:%String,ASRowId:%String")
{
}

ClassMethod CheckPreRegDay(Date)
{
	;w ##class(web.DHCOPAdmReg).CheckPreRegDay("2010-06-08")
	;s ^RP("CheckPreRegDay")=Date
	s Days=##class(web.DHCOPRegConfig).GetSpecConfigNode("PreDays")
	s Days=+$g(Days)
	s PreTime=##class(web.DHCOPRegConfig).GetSpecConfigNode("PreTime")
	i ($l(PreTime,":")>1) {
		s PreTimeF=..%ZTH(PreTime)
		s NowTime=..%SysTime()
		i NowTime<+$g(PreTimeF)&&(Days>=1) s Days=Days-1
	}
	s UIDay=""
	i $l(Date,"-")=3{
		s UIDay=$zdh(Date,3)
	}
	Q:UIDay-Days>+$h "false"
	Q ""
}

ClassMethod RMBDXXZH(itmjs As %Library.String = "", itmjsex As %Library.String = "", numstr As %Library.String = "")
{
	;+ by rp 0907
	;w ##class(web.DHCOPAdmReg).RMBDXXZH("","","23")
    ;RMB DAXIAOXIE CONVERSION,
	k P1
	s flag=0
	i numstr["-"  d
	.s flag="1"
	.s numstr=$p(numstr,"-",2)
	s numstr=$tr(numstr," ","")
	s i=0,lendec=0,lenint=0
	S a="",b="",c="",d="",bbak="",bs=""
	s numstr=+numstr
	i $p(numstr,".",1)=""  s numstr="0"_numstr
	s lenint=$l($p(numstr,".",1))
	s lendec=2
	i $p(numstr,".",2)="00" s lendec=0  
	s dxint(13)="",dxdec(2)="",sz(13)=""
	s dxstr="万|仟|佰|拾|亿|仟|佰|拾|万|仟|佰|拾|元"
	s szstr="零|壹|贰|叁|肆|伍|陆|柒|捌|玖"
	s lendxstr=$l(dxstr,"|")+1
	s lenszstr=$l(szstr,"|")+1
	f i=1:1:lendxstr d
	.s dxint(i)=$p(dxstr,"|",lendxstr-i)
	.s sz(i)=" "
	.i i<11  s sz(i)=$p(szstr,"|",i)  
	s dxdec(1)="角",dxdec(2)="分",dxstr=" "
	;**整数部分**
	f i=1:1:lenint d
	.s a=$e($e(numstr,1,lenint),i,i)
	.s b=sz(a+1)
	.s c=dxint(lenint-i+1)
	.s d=" "
	.i dxstr'=" "  s d=$e(dxstr,$l(dxstr)-1,($l(dxstr)-1)+2-1)  
	.i a="0"  s b="",bs="零"
	.i (b="零")&((d="零")!(b=bbak)!(c="元")!(c="万")!(c="亿"))  s b=""
	.i (a="0")&(c'="元")&(c'="万")&(c'="亿") s c=""
	.i ((c="元")!(c="万")!(c="亿"))&(d="零")&(a="0")  d 
	..s dxstr=$e(dxstr,1,1+($l(dxstr)-2)-1)
	.s d=$e(dxstr,$l(dxstr)-1,($l(dxstr)-1)+2-1)
	.i (c="元")&(d="万")&(c="万")&(d="亿")  s c=""
	.i (bs="零")&(a'=0)&(a'="") s b=bs_b,bs=""
	.s dxstr=dxstr_b_c,bbak=b
	;
	;**小数部分**
	i ($p(numstr,".",2)=0)!(lendec=0)!($p(numstr,".",2)="")  s dxstr=dxstr_"整" 
	i $p(numstr,".",2)>0  d
	.f i=1:1:lendec d
	..s a=$e($p(numstr,".",2),i,i)
	..s b=sz(a+1)
	..i (a="0")&(dxdec(i)="分")  s b=""  
	..i a="0"  s dxstr=dxstr_b
	..i a'="0"  s dxstr=dxstr_b_dxdec(i)   
	i numstr<1 s dxstr=$e(dxstr,3,$l(dxstr))
	i numstr<0.1 s dxstr=$e(dxstr,3,$l(dxstr))
	i numstr=0 s dxstr=""
	s P1=dxstr
	i flag="1"  s dxstr="负"_dxstr
	e  s dxstr=dxstr
	s retcode=dxstr
	q retcode
}

ClassMethod GetSessionTypeCode(ASRowId As %String) As %String
{
 q:ASRowId="" ""
 s SessionTypeDr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",6)
 s SessionTypeCode=""
	i SessionTypeDr'="" s SessionTypeCode=$P($G(^RBC("SESS",SessionTypeDr)),"^",1)
	q SessionTypeCode
}

ClassMethod GetFreeRegFeeArcimId(Age As %String, FreeRegFeeFlag As %String, OldManCardId As %String) As %String
{
   if (Age'="")
   { s FreeRegFeeAge=80 
      if (Age>FreeRegFeeAge) 
      {
		s ARCIMSubscript=$O(^ARCIM(0,"Code","110100001MF",""))
		s ARCIMVersion=$O(^ARCIM(0,"Code","110100001MF",ARCIMSubscript,""))
		Q ARCIMSubscript_"||"_ARCIMVersion	
      }
  }elseif ((FreeRegFeeFlag="Y")!(OldManCardId'="")) 
  {		s ARCIMSubscript=$O(^ARCIM(0,"Code","110100001MF",""))
		s ARCIMVersion=$O(^ARCIM(0,"Code","110100001MF",ARCIMSubscript,""))
		Q ARCIMSubscript_"||"_ARCIMVersion	
  } else{Q ""}
}

/// add by zhouzq 2009.08.21 取得病人某种预约方式下已经预约的总数
ClassMethod GetPADayAppMethodCount(PARowId As %String, FindASRowId As %String, FindAppMethodRowId As %String) As %String
{
	;w ##class(web.DHCOPAdmReg).GetPADayAppMethodCount(8,"261||20",1)
	s AppMethodCount=0
	s statuscode="I"
	s FindASDate=$P($G(^RBAS(+FindASRowId,$P(FindASRowId,"||",2))),"^",1)
	s statuscode="" f  s statuscode=$O(^PAPERDR(PARowId,"RB_Appt",statuscode)) Q:statuscode=""  d
	.Q:(statuscode'="I")&&(statuscode'="A")
	.s ResRowId=0 f  s ResRowId=$O(^PAPERDR(PARowId,"RB_Appt",statuscode,ResRowId)) Q:ResRowId=""  d
	..s ASChild=0 f  s ASChild=$O(^PAPERDR(PARowId,"RB_Appt",statuscode,ResRowId,ASChild)) Q:ASChild=""  d
	...s APPTChild=0 f  s APPTChild=$O(^PAPERDR(PARowId,"RB_Appt",statuscode,ResRowId,ASChild,APPTChild)) Q:APPTChild=""  d
	....s ASDate=$P($G(^RBAS(ResRowId,ASChild)),"^",1)
	....s AppMethodRowId=$P($G(^RBAS(ResRowId,ASChild,"APPT",APPTChild)),"^",12)
	....i (FindASDate=ASDate)&&(FindAppMethodRowId=AppMethodRowId) s AppMethodCount=AppMethodCount+1
	
	Q AppMethodCount
}

/// 检查卡是否已经建过
ClassMethod CheckNewCard(cardno As %String) As %String
{
	;s ^RP("vardno")=cardno
	;w ##class(web.DHCOPAdmReg).CheckNewCard("000000000045")
	s mycardid="",CardActived=""
	s mycardid=$o(^DHCCARDi("CF",0,"CardNo",cardno,0))
	i mycardid'=""{
		s CardActived=$p($g(^DHCCARD("CF",mycardid)),"^",10)
	}
	Q:CardActived="S" "S"
	Q mycardid
}

/// 医保取REA_AdmSource
ClassMethod GetREAAdmSource(REARowId) As %String
{
	q:REARowId="" "" 
	s AdmSource=""
	s AdmSource=$p($g(^PAC("ADMREA",REARowId)),"^",9)
	q AdmSource
}

/// 收取病历本费
ClassMethod GetMedicalBookInv(AdmID As %String, GroupID As %String, UserID As %String, LocID As %String) As %String
{
	s myBookInv=""
	Q:AdmID="" myBookInv
	
	s AdmReason=$P(^PAADM(AdmID,1),"^",7)
	s AdmDep=$P(^PAADM(AdmID),"^",4)
	s AdmDate=$P(^PAADM(AdmID),"^",6)
	s AdmTime=$P(^PAADM(AdmID),"^",7)
	s Fee=..GetMRFee()
	s ArcimId=..GetMRFeeArcimId()
	
	TS
	s ordstr=ArcimId_"^"_"1"_"^"_AdmDep_"^"_0_"^"_""_"^"_AdmReason_"^"_AdmDate_"^"_AdmTime
	s AddDoctor=$p(^SSU("SSUSR",UserID),"^",9)
	s ordcat=$p(^ARCIM(+ArcimId,1,1),"^",10)
	s ordtype=$p(^ARC("IC",ordcat),"^",7)
	s priority=$o(^OECPR(0,"Code","NORM",""))
	i priority="" Set priority=$o(^OECPR(0))
	s PackQty=1
	s NewOrdstr=ArcimId_"^"_ordtype_"^"_priority_"^"_..%ZD(AdmDate)_"^"_..%ZT(AdmTime,1)_"^"_PackQty_"^0^"_AdmDep_"^"_AdmReason
	s $p(NewOrdstr,"^",20)=1
	//s ResValue=##Class(web.DHCOPCashier).Insert(AdmID,ordstr,UserID,AdmDep,"","")
	s ResValue=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.ord.SaveOrderItems",AdmID,NewOrdstr,UserID,AdmDep,AddDoctor)
	s d=$p(ResValue,"^",1)
	i (d'=0)&&(d'=100) s d=0
	if d'=0 {
		TRO
		Q "-200"
	}
	s AccRowId=""
	s PayModeCode="CASH"
	s PayModeid=$o(^CT("CTPM",0,"Code",PayModeCode,0))
	s PayMode=PayModeid_"^^^^"
	s BillAccount=GroupID_"^"_AdmDep_"^"_AccRowId_"^"_"Y"_"^"_"R"
	s Value=##Class(web.DHCOPINVCons).OPBillCharge(AdmID,UserID,"",AdmReason,Fee,PayMode,GroupID,"0","","0",BillAccount)
	b ;bill over
	s d=$p(Value,"^",1)
	s InvoiceRowid=$P(Value,"^",2)
	s myBookInv=$p(Value,"^",1,2)
	i d'=0 {
		TRollback
		Q "-210"
	}
	TC
	Q myBookInv
}

/// 退病历本费
/// w ##class(web.DHCOPAdmReg).CancelMedicalBookBroker(2881,7,119,49)
ClassMethod CancelMedicalBookBroker(RegFeeRowId As %Library.String = "", UserRowId As %Library.String, GroupRowId As %String, LogonLocRowId As %String)
{
	s ^tmpgry("CancelMedicalBookBroker")=RegFeeRowId_","_UserRowId_","_GroupRowId_","_LogonLocRowId
	s NewInvoiceId=""
	s RefundBillSubType="MR"
	s ret=..CancelOtherFee(RegFeeRowId,UserRowId,GroupRowId,LogonLocRowId,.NewInvoiceId,RefundBillSubType)
	s APIFlag=$p(ret,"^",2)
	s ret=$p(ret,"^",1)
	if ret'=0 {
		if ret="-100" s ret=ret_"^没有找到可退病历本收费数据."
		if ret="-200" s ret=ret_"^生成负账单错误."
		if ret="-204" s ret=ret_"^更新挂号流水表失败."
		if ret="-210" s ret=ret_"^确认完成失败."
		Q ret
	}else{
		Q ret_"^"_NewInvoiceId_"^"_APIFlag
	}
}

ClassMethod FormatDesc(Desc As %String)
{
	s Desc1=$P(Desc,"-",2)
	if Desc1'="" s Desc=Desc1
	Q Desc
}

/// w ##class(web.DHCOPAdmReg).AppRegcheck("01,0000000000203")
ClassMethod AppRegcheck(CFCardTypeDR, CFCardNo) As %String
{
	s APPTFlag="N",OutStr=""
	s APPTDateComp=..%SysDate()
	;s APPTTimeComp=..%SysTime()
	w !, APPTDateComp
	s CFRowID=""
	f  s CFRowID=$o(^DHCCARDi("CF",0,"CardTypeNo",CFCardTypeDR,CFCardNo,CFRowID)) q:CFRowID=""  d        //卡表：DHCCardRef。卡类型并卡号找pa_patmas表Rowid
	.s CFPAPMIDR=$p(^DHCCARD("CF",CFRowID),"^",4)
	.s RESRowId="0"
	.f  s RESRowId=$o(^RBAS("APPT_Date",RESRowId)) q:RESRowId=""  d                                        //通过日期索引找今天的记录
	..q:('$d(^RBAS("APPT_Date",RESRowId,APPTDateComp)))
	..s tmpAPPTTimeComp=""
	..f  s tmpAPPTTimeComp=$o(^RBAS("APPT_Date",RESRowId,APPTDateComp,tmpAPPTTimeComp)) q:tmpAPPTTimeComp=""  d      
	...s ASChildSub=0
	...f  s ASChildSub=$o(^RBAS("APPT_Date",RESRowId,APPTDateComp,tmpAPPTTimeComp,ASChildSub)) q:ASChildSub=""  d
	....s TRRowId=$P($G(^RBAS(RESRowId,APPTChildSub,"DHC")),"^",17)			;号段 上午\下午
	....i TRRowId'="" s TRDesc=$P(^DHCTimeRange(TRRowId),"^",2)
	....e  s TRDesc="其他"	
	....s APPTChildSub=0
	....f  s APPTChildSub=$o(^RBAS("APPT_Date",RESRowId,APPTDateComp,tmpAPPTTimeComp,ASChildSub,APPTChildSub)) q:APPTChildSub=""  d
	.....s tmpCFPAPMIDR=$p($g(^RBAS(RESRowId,ASChildSub,"APPT",APPTChildSub)),"^",2)                               // 今天预约记录里查询pa_patmas表Rowid即PAPMIDR
	.....q:(tmpCFPAPMIDR'=CFPAPMIDR)                                                                               //找到匹配的病人记录
	.....s APPTFlag="Y"
	.....s Appt=$g(^RBAS(RESRowId,ASChildSub,"APPT",APPTChildSub))
	.....s StatusCode=$P(Appt,"^",3)
	.....q:(StatusCode'="I")        ;已取消，已取号的状态都不予提示
	.....s DepRowId=$P(^RB("RES",RESRowId),"^",1)
	.....s DocRowId=$P(^RB("RES",RESRowId),"^",2)
	.....s DepDesc=$p($g(^CTLOC(DepRowId)),"^",2)
	.....s DepDesc=..FormatDesc(DepDesc)
	.....s DocDesc=$P($g(^CTPCP(DocRowId,1)),"^",2)
	.....i OutStr=""   d
	......s OutStr=DepDesc_"^"_TRDesc
	....e             d
	
	......s OutStr=OutStr_"|"_DepDesc_"^"_TRDesc
	q OutStr
}

/// 诊间预约加号 w ##class(web.DHCOPAdmReg).OPAppDocBroker("","",4743533,"8660||8","",3888,"NURSEADD","","","")
/// input PatientID 患者ID ,ASRowId排班ID,QueueNo 指定的顺序号,UserRowId 登录的操作员,MethCode 预约方式, RegType 取号方式, AppPatInfo 无卡预约时患者信息，ExpStr 扩展信息,预约备注
/// AppPatInfo=Name+"$"+CreadNum+"$"+Phone+"$"+Address  患者姓名,证件号,联系电话,地址
ClassMethod OPAppDocBroker(PatientID As %String, ASRowId As %Library.String = "", QueueNo As %Library.String = "", UserRowId As %Library.String = "", MethCode As %Library.String = "", RegType As %Library.String = "", AppPatInfo As %Library.String = "", ExpStr As %String = "", Note As %String = "")
{
	//NeedListen:协和产科需要听课标识
	//判断是否有公共卡
	s AddStartTime=##class(web.DHCOPRegConfig).GetSpecConfigNode("AddStartTime")
	i AddStartTime'="" s AddStartTime=..%ZTH(AddStartTime)
	s CurrDate=..%SysDate()
	s CurrTime=..%SysTime()
	s CommonPatientID=..GetCommonPatientID()	
	s ResRowId=(+ASRowId)
	s AdmDep=$P($G(^RB("RES",ResRowId)),"^",1)
	s AdmDoc=$P($G(^RB("RES",ResRowId)),"^",2)
	s AdmDate=$P(^RBAS(+ASRowId,$p(ASRowId,"||",2)),"^",1)
	s ASStartTime=$P($G(^RBAS(+ASRowId,$p(ASRowId,"||",2))),"^",4) 
	s ASEndTime=$P($G(^RBAS(+ASRowId,$p(ASRowId,"||",2))),"^",5) 
	s ASTRRowId=$P($G(^RBAS(+ASRowId,$p(ASRowId,"||",2),"DHC")),"^",17)
	s MethCode=$zcvt(MethCode,"U")
	s TimeRangeStr=$p(ExpStr,"^",1)
	s LimitSexMsg=""
	s LimitAgeMsg=""
	s RegDeptAgeSexFlag=..CheckRegDeptAgeSex(ASRowId,PatientID)
	s LimitFlag=$P(RegDeptAgeSexFlag,$C(2),1)
	if (LimitFlag'=0){
		s LimitSex=$P(RegDeptAgeSexFlag,$C(2),2)
		s LimitAge=$P(RegDeptAgeSexFlag,$C(2),3)
		//"此科室支持性别【"+AllowSexDesc+"】"
		s:LimitAge'="" LimitAgeMsg="此科室支持年龄段【"_LimitAge_"】"
		s:LimitSex'="" LimitSexMsg="此科室支持性别【"_LimitSex_"】"
	}
	q:LimitSexMsg'="" LimitSexMsg
	q:LimitAgeMsg'="" LimitAgeMsg
	;公共卡不做限制 控制患者限额
	i (("^"_CommonPatientID_"^")'[("^"_PatientID_"^")){
		s ret=..CheckRegCountLimit(PatientID,ASRowId)
		if ret'=0 Q ret
	}
	if (MethCode=""){
		q "-1^预约途径不能为空!"
	}
	
	;为空的时候获取默认取号方式
	if (RegType=""){
		s RegType="APP"
		if AdmDate=..%SysDate() s RegType="DOCADD"
	}
	
	;护士加号权限控制
	if (RegType="DOCADD"){
		//停止挂号（医生坐诊信息开启停止挂号后，不允许挂号及取号）
	    s StopRegFlag=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",30)
	    if (StopRegFlag="Y"){
		   Q "-213^已经开启停止挂号,不予许挂号及取号!"
	    }
		s rtnstr=..NurAddNumLimt(PatientID,UserRowId)
		s flag=$P(rtnstr,"^",1)
		if (flag="N"){
			q "-1^您的加号限额已经用完或没有加号权限!"
		}
		if AdmDate=CurrDate {
			if (AddStartTime'="")&(CurrTime<AddStartTime) Q "-403^未到加号开始时间!"
			s TRRegEndTime=$P($G(^DHCTimeRange(ASTRRowId)),"^",10)
			if TRRegEndTime'="" s ASEndTime=TRRegEndTime
			if (CurrTime>ASEndTime) Q "-404^已经过了此排班记录出诊时间点!"
		}
		s AdmDocUser=$O(^SSU("SSUSR",0,"CTPCP",AdmDoc,0))
		if (AdmDocUser'="")&&(AdmDocUser'=UserRowId) Q "-405^非本人号别不能加号,仅允许预约!"
	}
	
	s MethodDR=+$O(^RBC("APTM",0,"Code",MethCode,0))	
	if (MethodDR=""){
		q "-1^预约途径无效!"
	}
	if ((PatientID="")&&(AppPatInfo="")){
		q "-1^患者信息不能为空,请确定有效的患者信息!"
	}
	///排版扩展设置限制
	i (("^"_CommonPatientID_"^")'[("^"_PatientID_"^")){
		s PatCatDr=$p(^PAPER(PatientID,"PER",1),"^",10)
		s AdmReason=..GetDefaultBillType(PatCatDr)
		s ret=##class(DHCDoc.OPAdm.ScheduleTemplateConfig).CheckOPRegExpandConfig(PatientID,ASRowId,AdmReason)
		if ret'=0 Q $p(ret,"^",2)
	}
	s Para=PatientID_"^"_ASRowId_"^"_MethodDR_"^"_"O"_"^"_UserRowId_"^"_QueueNo_"^"_RegType_"^"_AppPatInfo_"^"_Note_"^"_TimeRangeStr_"^^OPDOC"
	s ret=##class(web.DHCRBAppointment).Insert(Para)
	q ret
}

ClassMethod NurAddNumLimt(ASRowID, LogUserID)
{
	s $zt="ErrNurAddNumLimt"
	s CareProvType=##class(web.DHCDocOrderCommon).GetCareProvType(LogUserID)
	s rtnflag="Y" ;是否可以进行护士加号Y/N
	s NurseAddLoad="" ;可加号的总数量
	s NurseAddLoadUse="" ;已用加号数量
	s NurseAddLoadLeft="" ;剩余加号数量
	s superadd=$d(^DHCNurseAddLicense(0,"super",LogUserID)) ;超级权限不用处理
	if ((superadd=0)&(CareProvType="NURSE")) {
		s NurseAddObj=##class(User.DHCRBApptSchedule).%OpenId(ASRowID)
		s NurseAddLoad=+NurseAddObj.ASAuthAddQty ;护士可加号的数量 没有维护数量或者为0为不控制
		if (NurseAddLoad'=0){
			s APPTChildSub=0
			f  s APPTChildSub=$o(^RBAS(+ASRowID,$P(ASRowID,"||",2),"APPT",APPTChildSub)) q:APPTChildSub=""  d
			.s APPTStatus=$p(^RBAS(+ASRowID,$P(ASRowID,"||",2),"APPT",APPTChildSub),"^",3)
			.Q:APPTStatus="X"
			.s SpecSeqNo=$p(^RBAS(+ASRowID,$P(ASRowID,"||",2),"APPT",APPTChildSub),"^",5)
			.Q:SpecSeqNo'["+" ;只是判断加号权限
			.s TransUserDR=$p(^RBAS(+ASRowID,$P(ASRowID,"||",2),"APPT",APPTChildSub),"^",11)
			.s MethodDR=$p(^RBAS(+ASRowID,$P(ASRowID,"||",2),"APPT",APPTChildSub),"^",12)
			.s MethodDesc=""
			.i MethodDR'="" s MethodCode=$P(^RBC("APTM",MethodDR),"^",1)
			.if TransUserDR'=""  d
			..s TransCareProvType=##class(web.DHCDocOrderCommon).GetCareProvType(TransUserDR)
			..if (TransCareProvType="NURSE") d
			...s NurseAddLoadUse=(NurseAddLoadUse+1)
			s NurseAddLoadLeft=(NurseAddLoad-NurseAddLoadUse)
			if (NurseAddLoadLeft<=0) s rtnflag="N"
		}
	}
	q rtnflag_"^"_NurseAddLoad_"^"_NurseAddLoadUse_"^"_NurseAddLoadLeft
ErrNurAddNumLimt
	q "Y^^^"
}

// 获取卡号 

ClassMethod GetCardNumber(PatientNo, GJYLFlag As %String = "")
{
    set ^dhcGetCardNumber=PatientNo_","_GJYLFlag
    q:PatientNo="" ""
    s CFRowID="",CardID=""
    s PatientNo=$ZCVT(PatientNo,"U")
    q:$d(^PAPERi("PAPMI_PatNo",PatientNo))=0 ""
	s PatientID=$o(^PAPERi("PAPMI_PatNo",PatientNo,""))
	s ^GetCardNumber=PatientID

	q:+PatientID=0 ""
	set Active=$P($g(^PAPER(PatientID,"PAT",1)),"^",6)
	q:Active="N" ""
	q:($d(^DHCCARDi("CF",0,"PAPMIDR",PatientID))'=10&&(GJYLFlag'="")) ","_PatientID //无卡预约
	q:$d(^DHCCARDi("CF",0,"PAPMIDR",PatientID))'=10 ""
	s FindCardRowID=""
	for  s CFRowID=$o(^DHCCARDi("CF",0,"PAPMIDR",PatientID,CFRowID)) q:CFRowID=""  d
	.s ActiveFlag=$p(^DHCCARD("CF",CFRowID),"^",10)
	.s:ActiveFlag="N" FindCardRowID=CFRowID
	.q:ActiveFlag'="N"
	i FindCardRowID'=""{
		s CardID=$p(^DHCCARD("CF",FindCardRowID),"^",2)
		 
	}
	q:FindCardRowID'="" CardID_","_PatientID
	q ""
}

/// Creator:      guorongyong
/// CreatDate:    2012.09.22
/// Description:  得到医生是否当前星期有排班的标识
/// Table:        
/// Input:        LocId,DocId,ASDate 出诊日期    
/// Return:       1:有排班   0:无排班
ClassMethod GetIsScheduleFlag(LocId, DocId, ASDate, TimeRangeId = "") As %String
{
	;s ^tmpgry("GetIsScheduleFlag")=LocId_","_DocId_","_ASDate_","_TimeRangeId
	s myrtn=0
	q:(LocId="")||(DocId="")||(ASDate="") myrtn
	i $l(ASDate,"-")=3 s ASDate=$zdh(ASDate,3)
	i $l(ASDate,"/")=3 s ASDate=$zdh(ASDate,4)
	s ASWeek=$zd(ASDate,10)
	i ASWeek=0 s ASWeek=7
	s ResRowId=$o(^RB("RES",0,"CTPCP",DocId,LocId,""))
	s RBResEffDateChildsub=$O(^RB("RES",ResRowId,"DATE",""),-1)
	i RBResEffDateChildsub'="" {
		s SESSChildsub=0
		f  s SESSChildsub=$o(^RB("RES",ResRowId,"DATE",RBResEffDateChildsub,"SESS",SESSChildsub)) q:(SESSChildsub="")||(myrtn=1)  d
		.s SessionTypeID=$p(^RB("RES",ResRowId,"DATE",RBResEffDateChildsub,"SESS",SESSChildsub),"^",9)
		.S SessDOWRowid=$p(^RB("RES",ResRowId,"DATE",RBResEffDateChildsub,"SESS",SESSChildsub),"^",2)
		.S SessScheduleGenerFlag=$p(^RB("RES",ResRowId,"DATE",RBResEffDateChildsub,"SESS",SESSChildsub),"^",16)
		.Q:(SessScheduleGenerFlag="N")
		.Q:SessDOWRowid'=ASWeek
		.s myrtn=1
	}
	;排班没有找到,需要找出诊记录
	;i myrtn=0 {
		s SessStartTime=0
		for {
			s SessStartTime=$O(^RBAS(ResRowId,0,"DateSTime",ASDate,SessStartTime)) q:SessStartTime=""
			s AsChildId=0
			for {
				s AsChildId=$O(^RBAS(ResRowId,0,"DateSTime",ASDate,SessStartTime,AsChildId)) Q:AsChildId=""
				s myrtn=2
				s TRRowId=$P($G(^RBAS(ResRowId,AsChildId,"DHC")),"^",17)
				continue:(TimeRangeId'="")&&(TRRowId'=TimeRangeId)
				s status=""
				s statusDR=$P($G(^RBAS(ResRowId,AsChildId,"DHC")),"^",10)
				i statusDR'="" s status=$P($g(^DHCRBCASStatus(statusDR)),"^",1)
				i (status="S")||(status="TR")||(status="PS") s myrtn=-1
			}
		}
	;}
	
	Q myrtn
}

/// Creator:      guorongyong
/// CreatDate:    2012.09.22
/// Description:  得到医生当前星期排班记录的时段串
/// Table:        
/// Input:        LocId,DocId,ASDate 出诊日期    
/// Return:       排班模板时段串
ClassMethod GetScheduleTRangeStr(LocId, DocId, ASDate) As %String
{
	s myStr=""
	q:(LocId="")||(DocId="")||(ASDate="")
	i $l(ASDate,"-")=3 s ASDate=$zdh(ASDate,3)
	i $l(ASDate,"/")=3 s ASDate=$zdh(ASDate,4)
	s ASWeek=$zd(ASDate,10)
	i ASWeek=0 s ASWeek=7
	s ResRowId=$o(^RB("RES",0,"CTPCP",DocId,LocId,""))
	s RBResEffDateChildsub=$O(^RB("RES",ResRowId,"DATE",""),-1)
	i RBResEffDateChildsub'="" {
		s SESSChildsub=0
		f  s SESSChildsub=$o(^RB("RES",ResRowId,"DATE",RBResEffDateChildsub,"SESS",SESSChildsub)) q:(SESSChildsub="")  d
		.s SessionTypeID=$p(^RB("RES",ResRowId,"DATE",RBResEffDateChildsub,"SESS",SESSChildsub),"^",9)
		.S SessDOWRowid=$p(^RB("RES",ResRowId,"DATE",RBResEffDateChildsub,"SESS",SESSChildsub),"^",2)
		.S SessScheduleGenerFlag=$p(^RB("RES",ResRowId,"DATE",RBResEffDateChildsub,"SESS",SESSChildsub),"^",16)
		.Q:(SessScheduleGenerFlag="N")
		.Q:SessDOWRowid'=ASWeek
		.s SessionRangeID=$p(^RB("RES",ResRowId,"DATE",RBResEffDateChildsub,"SESS",SESSChildsub),"^",3)
		.Q:SessionRangeID=""
		.s SessionRangeDesc=$P($g(^DHCTimeRange(SessionRangeID)),"^",2)
		.i myStr="" s myStr=SessionRangeID_$C(2)_SessionRangeDesc
		.e  s myStr=myStr_"^"_SessionRangeID_$C(2)_SessionRangeDesc
	}
	
	;排班没有找到,需要找出诊记录
	i myStr="" {
		s SessStartTime=0
		for {
			s SessStartTime=$O(^RBAS(ResRowId,0,"DateSTime",ASDate,SessStartTime)) q:SessStartTime=""
			s AsChildId=0
			for {
				s AsChildId=$O(^RBAS(ResRowId,0,"DateSTime",ASDate,SessStartTime,AsChildId)) Q:AsChildId=""
				s status=""
				s statusDR=$P($G(^RBAS(ResRowId,AsChildId,"DHC")),"^",10)
				i statusDR'="" s status=$P($g(^DHCRBCASStatus(statusDR)),"^",1)
				Continue:(status="S")||(status="TR")||(status="PS")
				s TimeRangeDR=$P($G(^RBAS(ResRowId,AsChildId,"DHC")),"^",17)
				Continue:TimeRangeDR=""
				s TimeRangeDesc=$P($g(^DHCTimeRange(TimeRangeDR)),"^",2)
				Continue:myStr[(TimeRangeDR_$C(2))
				i myStr="" s myStr=TimeRangeDR_$C(2)_TimeRangeDesc
				e  s myStr=myStr_"^"_TimeRangeDR_$C(2)_TimeRangeDesc
			}
		}
	}
	
	Q myStr
}

/// Creator:      guorongyong
/// CreatDate:    2012.09.22
/// Description:  根据医生ID得到用户
/// Table:        
/// Input:            
/// Return:       用户Rowid
ClassMethod GetUserIDByDocId(DocId) As %String [ ProcedureBlock = 0 ]
{
	n (DocId)
	q:DocId="" ""
	s UserID=$O(^SSU("SSUSR",0,"CTPCP",DocId,""),-1)
	q UserID
}

Query GetDocByLoc(CTLocID As %String, Doctor As %String, Type As %String = "", AdmDate As %String = "") As %Query(ROWSPEC = "CareProvID:%String,DocDesc:%String,LocDesc:%String,LocID")
{
}

// d ##class(%ResultSet).RunQuery("web.DHCOPAdmReg","GetDocByLoc","53","","NurseAdd")

ClassMethod GetDocByLocExecute(ByRef QHandle As %Binary, CTLocID As %String, Doctor As %String, Type As %String = "", AdmDate As %String = "") As %Status
{
	s repid=$I(^CacheTemp)
	s ind=1
	s QHandle=$lb(0,repid,0)
	 s ^tmpGetDocBYLoc=CTLocID_","_Doctor_","_Type_","_AdmDate
	 //b "S"
	 s:$d(%session)=0 userid=11
	 i $d(%session)'=0 d
	 .s userid=%session.Get("LOGON.USERID")
      i CTLocID'="" d
	  .s RESRowId=""
	  .f  s RESRowId=$o(^RB("RES",0,"CTLOC",CTLocID,RESRowId))	q:RESRowId=""  d
	  	..s CareProvID=$p($g(^RB("RES",RESRowId)),"^",2)	
	  	..s DocDesc=$p(^CTPCP(CareProvID,1),"^",2)
	  	..s DocAlias=$p($g(^CTPCP(CareProvID,3)),"^",28)	  	
	  	..s:((DocAlias'="")&&(Type'="NurseAdd")) DocDesc=DocAlias_"-"_DocDesc
	  	..s ret=1
	  	..q:(Type="NurseAdd")&&($d(^DHCNurseAddLicense(userid,CTLocID,CareProvID))'=1) //护士诊间加号权限
	  	..d:Type="NurseAdd" CheckIfHasAvailRa
	  	..q:ret=0
	  	..s ^CacheTemp(repid,ind)=$lb(CareProvID,DocDesc)
	    ..s ind=ind+1
	  e   d	  
	  .s CareProvID="",CTLocID=""
	  .f  s CareProvID=$o(^RB("RES",0,"CTPCP",CareProvID))	q:CareProvID=""  d	
	    ..f  s CTLocID=$o(^RB("RES",0,"CTPCP",CareProvID,CTLocID)) q:CTLocID=""  d
	    ...//q:($d(^PAC("ADMLOC",0,"AdmType","O",CTLocID))'=10)&&($d(^PAC("ADMLOC",0,"AdmType","E",CTLocID))'=10)
	    ...s LocDesc=$p(^CTLOC(CTLocID),"^",2)
	    ...q:((Type="TXVIP")&&(LocDesc'["特需")) //体检VIP只显示特需科室
	  	...s DocDesc=$p(^CTPCP(CareProvID,1),"^",2)
	  	...s DocAlias=$p($g(^CTPCP(CareProvID,3)),"^",28)
	  	...s DocAlias=$ZCVT(DocAlias,"U")
	  	...q:(DocAlias'="")&&(DocAlias'=$ZCVT(Doctor,"U"))
	  	...q:(DocAlias="")&&(DocDesc'[Doctor)
	  	...s:((DocAlias'="")&&(Type'="NurseAdd")) DocDesc=DocAlias_"-"_DocDesc
	  	...//q:(Type="NurseAdd")&&($d(^DHCNurseAddLicense(userid,CTLocID,CareProvID))'=1) //护士诊间加号权限
	  	...s ^CacheTemp(repid,ind)=$lb(CareProvID,DocDesc,LocDesc,CTLocID)
	    ...s ind=ind+1
	Quit $$$OK
CheckIfHasAvailRa
    ;可分时段预约的直接显示
    s IsAllowTimeRangeRegFlag=##class(web.DHCBL.Doctor.Appoint).CheckIsAllowTimeRangeReg(CTLocID,CareProvID)
    q:IsAllowTimeRangeRegFlag=1 1
    s TimeRangeRowID=1
    s ret=1
	s SelectTRQuery=1,BookNum="",TotalNum=1,OverBookNum=0 //加号数
	
	s:AdmDate="" AdmDate=..%SysDate()
	s:AdmDate["-" AdmDate=$zdh(AdmDate,3)
	s AdmTime=""
	
    s ASRowIdStrAM=##Class(web.DHCRBApptSchedule).GetAvailRA(RESRowId,AdmDate,AdmTime,TimeRangeRowID,SelectTRQuery,1)
    s TimeRangeRowID=2
    s ASRowIdStrPM=##Class(web.DHCRBApptSchedule).GetAvailRA(RESRowId,AdmDate,AdmTime,TimeRangeRowID,SelectTRQuery,1)
    i (ASRowIdStrAM="")&&(ASRowIdStrPM=""){
	    s ret=0
    }
    q ""
}

ClassMethod GetDocByLocClose(ByRef QHandle As %Binary) As %Status [ PlaceAfter = GetDocByLocExecute ]
{
	Set repid=$LIST(QHandle,2)
 	Kill ^CacheTemp(repid)
 	Quit $$$OK
}

ClassMethod GetDocByLocFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetDocByLocExecute ]
{
	Set AtEnd=$LIST(QHandle,1)
 	Set repid=$LIST(QHandle,2)
 	Set ind=$LIST(QHandle,3)
 	Set ind=$o(^CacheTemp(repid,ind))
 	If ind="" {				// if there are no more rows, finish fetching
 		Set AtEnd=1
 		Set Row=""
 	}
 	Else      {				// fetch row
 		Set Row=^CacheTemp(repid,ind)
 	}
 	// Save QHandle
 	s QHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// Creator:      guorongyong
/// CreatDate:    2014.01.22
/// Description:  根据就诊或者科室或者出诊记录或者医嘱项得到当前医院
/// Table:        
/// Input:            
/// Return:       当前医院的Rowid^当前医院的代码
ClassMethod GetCurrentHosp(EpisodeID As %String = "", CTLocId As %String = "", ASRowId As %String = "", ArcimId As %String = "") As %String [ ProcedureBlock = 0 ]
{
	n (EpisodeID,CTLocId,ASRowId,ArcimId)
	q:(EpisodeID_CTLocId_ASRowId_ArcimId)="" ""
	s HospId="",HospCode=""
	;优先判断级别:就诊,科室,出诊记录,医嘱项目(暂未写)
	i EpisodeID'="" {
		s AdmDepId=$p(^PAADM(EpisodeID),"^",4)
		s HospId=$p(^CTLOC(AdmDepId),"^",22)
		i HospId'="" s HospCode=$p($g(^CT("HOSP",HospId)),"^",1)
		Q HospId_"^"_HospCode
	}
	i CTLocId'="" {
		s HospId=$p(^CTLOC(CTLocId),"^",22)
		i HospId'="" s HospCode=$p($g(^CT("HOSP",HospId)),"^",1)
		Q HospId_"^"_HospCode
	}
	i ASRowId'="" {
		s CTLocId=$p($g(^RB("RES",+ASRowId)),"^",1)
		s HospId=$p(^CTLOC(CTLocId),"^",22)
		i HospId'="" s HospCode=$p($g(^CT("HOSP",HospId)),"^",1)
		Q HospId_"^"_HospCode
	}
	i ArcimId'="" {
	}
	
	Q HospId_"^"_HospCode
}

/// Creator:guorongyong
/// Date:2012-08-13
/// Desc:检查预约序列号是否可以取号
/// output: 0 可取号,其他^错误描述 不可取号
/// input:PatientID ,AppSerialNo
/// other:仅限114电话预约使用预约序列号取号判断
ClassMethod CheckAppSerialNo(PatientID As %String, AppSerialNo As %String) As %String
{
	q:AppSerialNo="" "0^"
	q:PatientID="" "-100^请先读卡得到病人信息"
	s PatName=$p($g(^PAPER(PatientID,"ALL")),"^",1)
	
	;取预约信息,现因为此订单号产生方非一家,所以需要循环判断
	
	s AppMethodStr=" 114 "
	s DHCAppt=..GetDHCApptByAppSerialNo(AppSerialNo,AppMethodStr)
	s APPTRowid=$p(DHCAppt,"^",1)
	s ApptPatientName=$p(DHCAppt,"^",2)
	s ApptDOB=$p(DHCAppt,"^",3)
	s ApptSexDR=$p(DHCAppt,"^",4)
	;查找是否没有导入
	s CurrentDate=..%SysDate(),FailFlag=0,FailReason=""
	for Date=CurrentDate-7:1:CurrentDate {
		s DPFLRowId=0
		for {
			s DPFLRowId=$o(^DHCOPAPPFileLog(114,Date,"/tmp/DownloadFileLog114.txt",DPFLRowId)) q:DPFLRowId=""
			s Log=$g(^DHCOPAPPFileLog(114,Date,"/tmp/DownloadFileLog114.txt",DPFLRowId))
			continue:Log'["预约记录导入HIS失败"
		 	s Err=$p($g(^DHCOPAPPFileLog(114,Date,"/tmp/DownloadFileLog114.txt",DPFLRowId)),"^",2)
		 	i Err="" s Err=$p($g(^DHCOPAPPFileLog(114,Date,"/tmp/DownloadFileLog114.txt",DPFLRowId)),"^",1)
		 	s FailReason=$p(Err,",",1)
		 	s info=$p($p(Log,",",2),":",2)
		 	s LogApptDate=$zdh($p(info,"|",21),8)
		 	s LogPatName=$p(Log,"|",4)
		 	continue:PatName'=LogPatName
		 	s LogSerialNo=$p(Log,"|",28)
		 	continue:AppSerialNo'=LogSerialNo
		 	s FailFlag=1
		 	Q
		}
		Q:FailFlag=1
	}
	q:FailFlag=1 "-103^存在114预约记录,未成功导入,请告知病人到护士站咨询."
	q:APPTRowid="" "-101^此序列号没有预约记录,请确认预约序列号是否正确."
	
	set returnValue=""
	
	i ApptPatientName'=PatName{
	 	set ApptCredNo=$P($g(^RBAS(+APPTRowid,$P(APPTRowid,"||",2),"APPT",$P(APPTRowid,"||",3),"DHC")),"^",8)
	 	set PatCredNo=$P(^PAPER(PatientID,"PAT",3),"^",6)
	 	set returnValue="-102^114姓名:"_ApptPatientName_",HIS姓名:"_PatName_",114身份证号:"_ApptCredNo_",HIS身份证号:"_PatCredNo_",姓名不一致是否继续?"
		q returnValue
	}

	q 0_"^"_APPTRowid
}

ClassMethod GetDHCApptByAppSerialNo(AppSerialNo As %String, AppMethodStr As %String) As %String
{
	;n (AppSerialNo,AppMethodStr)
	s myStr=""
	s APPTRowid=""
	q:AppSerialNo="" ""
	s ResRowid=0
	for {
		s ResRowid=$O(^RBAS("SystemSess",AppSerialNo,ResRowid)) q:ResRowid=""
		s ASId=0
		for {
			s ASId=$O(^RBAS("SystemSess",AppSerialNo,ResRowid,ASId)) q:ASId=""
			s ScheduleDate=$P(^RBAS(ResRowid,ASId),"^",1)
			continue:ScheduleDate<+$h
			s APPTId=0
			for {
				s APPTId=$O(^RBAS("SystemSess",AppSerialNo,ResRowid,ASId,APPTId)) q:APPTId=""
				s MethodDR=$p($g(^RBAS(ResRowid,ASId,"APPT",APPTId)),"^",12)
				if MethodDR'="" s MethodCode=$p($g(^RBC("APTM",MethodDR)),"^",1)
				if (AppMethodStr'[(" "_$g(MethodCode)_" ")) continue
				s APPTRowid=ResRowid_"||"_ASId_"||"_APPTId
				s ApptPatientName=$p($g(^RBAS(ResRowid,ASId,"APPT",APPTId,"DHC")),"^",1)
				s ApptDOB=$p($g(^RBAS(ResRowid,ASId,"APPT",APPTId,"DHC")),"^",2)
				s ApptSexDR=$p($g(^RBAS(ResRowid,ASId,"APPT",APPTId,"DHC")),"^",3)
				s myStr=APPTRowid_"^"_ApptPatientName_"^"_ApptDOB_"^"_ApptSexDR
				quit
			}
		}
	}
	
	Q myStr
}

/// 挂号设置现场预约时间点判断
/// Y 可以预约 N 不可预约
/// w ##class(web.DHCOPAdmReg).CheckAppRegTime()
ClassMethod CheckAppRegTime() As %String
{
	s AppStartTime=##class(web.DHCOPRegConfig).GetSpecConfigNode("AppStartTime")
	s:AppStartTime'="" AppStartTime=..%ZTH(AppStartTime)
	Q:(AppStartTime="")||(AppStartTime)=0 "Y"
	s NowTime=..%SysTime()
	Q:NowTime>=AppStartTime "Y"
	Q "N"
}

/// w ##class(web.DHCOPAdmReg).GetTimeRangeStrApp("7||148","WIN","NOR","1","2")
/// input:	TRShowFlag		1 显示所有时间段
/// 						0 显示可用时间段
ClassMethod GetTimeRangeStrApp(ASRowid As %String, AppMedthod, RegType As %String = "APP", TRShowFlag As %Integer = 1, ClinicGroupDr As %String = "") As %Boolean
{
	//1-2,3-4,5-6,7-8,9-10,11-11,12-12,13-13,14-14,15-15,16-16,17-17,18-18,19-19,20-20
	//08:00-08:20,08:20-08:40,08:40-09:00,09:00-09:20,09:20-09:40,09:40-10:00,10:00-10:20,10:20-10:40,10:40-11:00,11:00-11:20,11:20-11:40,11:40-12:00,12:00-12:20,12:20-12:40,12:40-13:00
	s ^tempqujian("GetTimeRangeStrApp")=$LB(ASRowid , AppMedthod, RegType , TRShowFlag, ClinicGroupDr)
	s ReturnNotAllowAdd=##class(web.DHCOPRegConfig).GetSpecConfigNode("ReturnNotAllowAdd")
	Set ResRowId=+ASRowid
	Set Childsub=$P(ASRowid,"||",2)
	s AppStartSeqNo=$P(^RBAS(ResRowId,Childsub),"^",10)
	s APPSeqNoCount=$P(^RBAS(ResRowId,Childsub),"^",2)
	;zzy 取窗口预约起始号
	;s AppStartSeqNo=""
	s APPMethodRowId=$O(^RBC("APTM",0,"Code",AppMedthod,0))
	Set ASDate=$p(^RBAS(ResRowId,Childsub),"^",1)
	if ((ASDate>+$H)&&(RegType="NOR")) {s RegType="APP"}
	;Quit:(AppStartSeqNo=0)&&(ASDate>(+$H)) "{record:'"_"AppTimeRange"_"',row:["_""_"]}"
	s AppQty=$p(^RBAS(ResRowId,Childsub),"^",2)
	;Q:((AppQty="")||(AppQty="0")) "{record:'"_"AppTimeRange"_"',row:["_""_"]}"
	s AppAllNumber=##class(web.DHCRBAppointment).GetAvailableNum(ASRowid,RegType,AppMedthod,"","","","",ClinicGroupDr)
	q:AppAllNumber=0 "{record:'"_"AppTimeRange"_"',row:["_""_"]}"
	s TRFlag=$p(^RBAS(ResRowId,Childsub,"DHC"),"^",19)	
	s ASQueueNo=$P(^RBAS(ResRowId,Childsub,"DHC"),"^",4)   //;正号串与加号串 	
	s NormalQueueNoStr=$P(ASQueueNo,$C(1),1)    //正号串
	s TD=""
	if (TRFlag="Y"){
		s OneEndNo=0
		Set row=0
		Set RowData=""
		s TD=""
		s ASTRSub=0 for {
				s ASTRSub=$O(^RBAS(ResRowId,Childsub,"ASTR",ASTRSub))
				q:ASTRSub=""
				s starttime=$P(^RBAS(ResRowId,Childsub,"ASTR",ASTRSub),"^",1)
				s endtime=$P(^RBAS(ResRowId,Childsub,"ASTR",ASTRSub),"^",2)
				s TRLoad=$P(^RBAS(ResRowId,Childsub,"ASTR",ASTRSub),"^",3)
				s TimeRange=..%ZT(starttime)_"-"_..%ZT(endtime)
				s OneSttNo=OneEndNo+1,OneEndNo=OneEndNo+TRLoad
				s AppAllNumber=##class(web.DHCRBAppointment).GetAvailableNum(ASRowid,RegType,AppMedthod,"",..%ZT(starttime),..%ZT(endtime),"N",ClinicGroupDr)
				if ('TRShowFlag) {
					continue:AppAllNumber=0
				}
				if TD=""{
					Set TD="{SeqNo:'"_AppAllNumber_"',Time:'"_TimeRange_"',Status:"_AppAllNumber_"}"
				}else{
					Set TD=TD_","_"{SeqNo:'"_AppAllNumber_"',Time:'"_TimeRange_"',Status:"_AppAllNumber_"}"
				}
			}
	}else{
	
	}
	b ;323
	Set AppStr="{record:'"_"AppTimeRange"_"',row:["_TD_"]}"
	Quit AppStr
}

/// w ##class(web.DHCOPAdmReg).GetTimeRangeStrApp("3144||29","WIN")
ClassMethod GetTimeRangeStrAppOld(ASRowid As %String, AppMedthod) As %Boolean
{
	//1-2,3-4,5-6,7-8,9-10,11-11,12-12,13-13,14-14,15-15,16-16,17-17,18-18,19-19,20-20
	//08:00-08:20,08:20-08:40,08:40-09:00,09:00-09:20,09:20-09:40,09:40-10:00,10:00-10:20,10:20-10:40,10:40-11:00,11:00-11:20,11:20-11:40,11:40-12:00,12:00-12:20,12:20-12:40,12:40-13:00
	s ReturnNotAllowAdd=##class(web.DHCOPRegConfig).GetSpecConfigNode("ReturnNotAllowAdd")
	Set ResRowId=+ASRowid
	Set Childsub=$P(ASRowid,"||",2)
	s AppStartSeqNo=$P(^RBAS(ResRowId,Childsub),"^",10)
	s APPSeqNoCount=$P(^RBAS(ResRowId,Childsub),"^",2)
	;zzy 取窗口预约起始号
	;s AppStartSeqNo=""
	s APPMethodRowId=$O(^RBC("APTM",0,"Code",AppMedthod,0))
	s Child="" f  s Child=$O(^RBAS(ResRowId,Childsub,"AQ",Child)) Q:(Child="")  d
	.s APPData=$G(^RBAS(ResRowId,Childsub,"AQ",Child))
	.s APPMethodDR=$P(APPData,"^",1)
	.Quit:(APPMethodRowId'=APPMethodDR)
	.s LastUpUserDr=$P(APPData,"^",6)
	.i LastUpUserDr="" d
	..s startSeqNo=$P(APPData,"^",3)
	..s AppStartSeqNo=startSeqNo
	.s APPMethodCode=""
	.i APPMethodDR'="" s APPMethodCode=$P($g(^RBC("APTM",APPMethodDR)),"^",1)
	.;i APPMethodCode="WIN" s AppStartSeqNo=startSeqNo
	
	;end
	i AppStartSeqNo="" s AppStartSeqNo=0
	i APPSeqNoCount="" s APPSeqNoCount=0
	i APPSeqNoCount=0 s AppStartSeqNo=0
	
	Set ASDate=$p(^RBAS(ResRowId,Childsub),"^",1)
	Quit:(AppStartSeqNo=0)&&(ASDate>(+$H)) "{record:'"_"AppTimeRange"_"',row:["_""_"]}"
	Set RegNumStr=$P(^RBAS(ResRowId,Childsub,"DHC"),"^",24)
	Set RangStr=$P(^RBAS(ResRowId,Childsub,"DHC"),"^",25)
	s ASQueueNo=$P(^RBAS(ResRowId,Childsub,"DHC"),"^",4)   //;正号串与加号串 	
	s NormalQueueNoStr=$P(ASQueueNo,$C(1),1)    //正号串
	Set RegNumLen=$l(RegNumStr,",")
	Set rtn=""
	Set FirstTime=""
	Set row=0
	Set RowData=""
	for i=1:1:RegNumLen{
		Set RegNums=$p(RegNumStr,",",i)   //1-2
		Set StartNum=$p(RegNums,"-",1)
		Set EndNum=$p(RegNums,"-",2)
		Set TimeRange=$p(RangStr,",",i)
		if FirstTime="" {
			Set FirstTime=$p(TimeRange,"-",1)
			Set row=row+1
		}else{
			if FirstTime<$p(TimeRange,"-",1){
				Set FirstTime=$p(TimeRange,"-",1)
				Set row=row+1	
			}	
		}
		Set EndTime=$p(TimeRange,"-",2)
		Set TD=""
		for j=StartNum:1:EndNum{
			s QueueNoInAppFlag=+##class(web.DHCRBApptScheduleAppQty).CheckQueueNoInApp(ASRowid,j,APPMethodRowId)
			continue:QueueNoInAppFlag'=1 
			continue:((j<AppStartSeqNo)||(j>(AppStartSeqNo+APPSeqNoCount-1))&&(ASDate>(+$H)))
			Set NoStatus=$p($p(NormalQueueNoStr,",",j),":",2)
			//continue:(NoStatus=2)||(NoStatus=1)||(NoStatus=3)
			if (NoStatus=1)||(NoStatus=3)||((ReturnNotAllowAdd=1)&&(NoStatus=4)) Set NoStatus=2
			if TD=""{
				Set TD="{SeqNo:'"_j_"',Time:'"_TimeRange_"',Status:"_NoStatus_"}"
			}else{
				Set TD=TD_","_"{SeqNo:'"_j_"',Time:'"_TimeRange_"',Status:"_NoStatus_"}"
			}
		}	
		if TD'="" {
		Set RowDataTime(row)=FirstTime_"-"_EndTime
		if $d(RowData(row)){
			Set RowData(row)=RowData(row)_","_TD
		}else{
			Set RowData(row)=TD	
		}
		}
	}
	b ;323
	Set index=0
	Set AppStr=""
	for  Set index=$o(RowData(index)) Quit:index=""  do
	.Set TimeRange=RowDataTime(index)
	.if AppStr="" do
	..Set AppStr="{TimeRange:'"_TimeRange_"',col:["_RowData(index)_"]}"
	.else  do
	..Set AppStr=AppStr_","_"{TimeRange:'"_TimeRange_"',col:["_RowData(index)_"]}"
	Set AppStr="{record:'"_"AppTimeRange"_"',row:["_AppStr_"]}"
	Quit AppStr
}

/// 根据序号取分时段信息里对应的时间段
ClassMethod GetAdmTimeBySeqNo(ASRowid As %String, SeqNo As %String)
{
    Q:SeqNo["+" ""
	/*Set SeqNoStr=$p(^RBAS(+ASRowid,$p(ASRowid,"||",2),"DHC"),"^",24)
	Set TimeRangeStr=$p(^RBAS(+ASRowid,$p(ASRowid,"||",2),"DHC"),"^",25)
	Set SeqNoLen=$l(SeqNoStr,",")
	Set Index=""
	Set TimeStr=""
	for i=1:1:SeqNoLen {
		Quit:Index'=""
		Set NumStr=$p(SeqNoStr,",",i)
		Set StartNum=$p(NumStr,"-",1)
		Set EndNum=$p(NumStr,"-",2)
		continue:(SeqNo>EndNum)||(SeqNo<StartNum)
		Set Index=i	
	}
	if Index'="" {
		Set TimeStr=$p(TimeRangeStr,",",Index)		
	}
	Quit TimeStr*/
	s TimeRangeRegInfo=##class(web.DHCRBApptSchedule).GetTimeRangeRegInfo(ASRowid,SeqNo)
	Q:TimeRangeRegInfo="" ""
	S RangeTime=$p(TimeRangeRegInfo," ",2)
	Q RangeTime
}

ClassMethod GetAppReturnTimeBySeqNo(ASRowid As %String, SeqNo As %String)
{
	Q:SeqNo["+" ""
	s ResRowId=$P(ASRowid,"||",1)
	s Childsub=$P(ASRowid,"||",2)
	s TRFlag=$p(^RBAS(ResRowId,Childsub,"DHC"),"^",19)	
	s AppReturnTime=""
	i (TRFlag="Y") {
		s OneEndNo=0
		s ASTRSub=0 for {
			s ASTRSub=$O(^RBAS(ResRowId,Childsub,"ASTR",ASTRSub))
			q:ASTRSub=""
			s starttime=$P(^RBAS(ResRowId,Childsub,"ASTR",ASTRSub),"^",1)
			s endtime=$P(^RBAS(ResRowId,Childsub,"ASTR",ASTRSub),"^",2)
			s TRLoad=$P(^RBAS(ResRowId,Childsub,"ASTR",ASTRSub),"^",3)
			s OneSttNo=OneEndNo+1,OneEndNo=OneEndNo+TRLoad
			if ((SeqNo>=OneSttNo)&&(SeqNo<=OneEndNo)){
				s AppReturnTime=endtime
				}
			}
	}
	q AppReturnTime
	//1-1,2-2,3-3,4-4,5-5,6-6,7-7,8-8,9-9,10-10,11-11,12-12,13-13,14-14,15-15,16-16,17-17,18-18,19-19,20-20
	//08:00-08:30,08:30-09:00,09:00-09:30,09:30-10:00,10:00-10:30,10:30-11:00,11:00-11:30,11:30-12:00,12:00-12:30,12:30-13:00,13:00-13:30,13:30-14:00,14:00-14:30,14:30-15:00,15:00-15:30,15:30-16:00,16:00-16:30,16:30-17:00,17:00-17:30,17:30-18:00
	/*Set SeqNoStr=$p(^RBAS(+ASRowid,$p(ASRowid,"||",2),"DHC"),"^",24)
	Quit:SeqNoStr="" ""
	Set TimeRangeStr=$p(^RBAS(+ASRowid,$p(ASRowid,"||",2),"DHC"),"^",25)
	Set SeqNoLen=$l(SeqNoStr,",")
	Set Index=""
	for i=1:1:SeqNoLen {
		Quit:Index'=""
		Set NumStr=$p(SeqNoStr,",",i)
		Set StartNum=$p(NumStr,"-",1)
		Set EndNum=$p(NumStr,"-",2)
		continue:(SeqNo>EndNum)||(SeqNo<StartNum)
		Set Index=i	
	}
	Set AppReturnTime=""
	if Index=SeqNoLen {
		Set TimeStr=$p(TimeRangeStr,",",Index)
		Set AppReturnTime=..%ZTH($p(TimeStr,"-",2),2)   //-1800
	}else{
		Set TimeStr=""
		if Index'="" {
			Set TimeStr=$p(TimeRangeStr,",",Index)
			Set AppReturnTime=..%ZTH($p(TimeStr,"-",2),2)	
		}
	}
	
	Quit AppReturnTime*/
}

/// d ##class(%ResultSet).RunQuery("web.DHCOPAdmReg","GetTimeRangeTest","")
Query GetTimeRangeTest(desc As %String = "") As %Library.SQLQuery(CONTAINID = 3, ROWSPEC = "HIDDEN:%String,CTPCPDesc,CTPCPCode")
{
	
	SELECT TR_RowId,TR_Desc, TR_Code
	FROM SQLUser.DHC_TimeRange
	WHERE  ((TR_ValidStartDate<=+$H) or TR_ValidStartDate is null ) and ((TR_ValidEndDate>=+$h) or TR_ValidEndDate is null)
}

ClassMethod GetCardNoByPatientNo(PatientNo As %String, HospId As %String = "") As %String
{
  Quit:$g(PatientNo)="" ""
  s HospId=##Class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospId)
 Set CardNo=""
 Set Patient=$$ALPHAUP^SSUTIL4(PatientNo)
 Set langid=..%LanguageID()
 set PatientID=$O(^PAPERi("PAPMI_PatNo",Patient,""))
 if (PatientID'="") {
	 //q:PatientID="" ""
	 s PatName=$p($g(^PAPER(PatientID,"ALL")),"^",1)
	 set Active=$P($g(^PAPER(PatientID,"PAT",1)),"^",6)
	 Q:Active="N" "^^^"_$g(PatientID)
	 Q:'$d(^DHCCARDi("CF",0,"PAPMIDR",PatientID)) ""
	 Set FindCFType="",FindCFTypeDesc="",FindCardId="",FindCardSecurityNo="",TempCardId="",left=""
	 s IDCardNo=$P($G(^PAPER(PatientID,"ALL")),"^",9)   ;身份证
	 Set CFRowId=0
	 for {
		 set CFRowId=$O(^DHCCARDi("CF",0,"PAPMIDR",PatientID,CFRowId)) Q:CFRowId=""
		 set ActiveFlag=$p(^DHCCARD("CF",CFRowId),"^",10)
		 continue:ActiveFlag'="N"
		 set CFType=$P(^DHCCARD("CF",CFRowId),"^",16)
		 //判断卡类型是否给该院区授权
		 s Flag=##class(web.DHCBL.BDP.BDPMappingHOSP).GetHospShowDataFlag("DHC_CardTypeDef",CFType,HospId,+$H)
		 continue:Flag'="Y"
		 s CFIsTemporaryCard=$P(^DHCCARD("CF",CFRowId),"^",29)
		 if (CFIsTemporaryCard="Y") s TempCardId=CFRowId
		 else  s FindCardId=CFRowId
		 s myAccRowID=$p(^DHCCARD("CF",CFRowId),"^",1)	;myAccRowID
		 if myAccRowID'="" {
			s AccStatus=$p(^DHCACD("AccM",myAccRowID),"^",13)
			if (AccStatus="N"){
				s Balance=$p(^DHCACD("AccM",myAccRowID),"^",8)
				s DepPrice=##class(web.UDHCAccManageCLSIF).GetAccMDepPrice(myAccRowID, "","")
				s left=Balance-DepPrice
			}
		}
		Q:FindCardId'=""
	 }
	 if (FindCardId="") s FindCardId=TempCardId
	 if (FindCardId'="") {
		 set FindCFType=$P(^DHCCARD("CF",FindCardId),"^",16)
		 set:FindCFType'="" FindCFTypeDesc=$P(^DHCCARDTYPEDef(FindCFType),"^",2)
		 set CardNo=$P(^DHCCARD("CF",FindCardId),"^",2)
		 set FindCardSecurityNo=$P(^DHCCARD("CF",FindCardId),"^",3)
		 set FindCardSecurityNo=##class(web.UDHCAccEnrypt).Decrypt(FindCardSecurityNo)
		 set left= ##class(web.DHCBillInterface).IGetAccMDeposit(PatientID, HospId,CardNo,FindCFType)
	 }
	 ;死亡标志
	 s IsDeceased=##Class(web.PAPerson).CheckDeceased(PatientID)
	 s FindCFTypeDesc=##class(User.DHCCardTypeDef).GetTranByDesc("CTDDesc",FindCFTypeDesc,langid)
 }
 Quit $g(CardNo)_"^"_$g(FindCFType)_"^"_$g(FindCFTypeDesc)_"^"_$g(PatientID)_"^"_$g(PatName)_"^"_$g(FindCardId)_"^"_$g(FindCardSecurityNo)_"^"_$g(IsDeceased)_"^"_$g(left)_"^"_$G(IDCardNo)
}

/// 调用计费组接口打印发票
/// w ##class(web.DHCOPAdmReg).GetPrintInvInfo()
ClassMethod GetPrintInvInfo(itmjs As %Library.String = "", itmjsex As %Library.String = "", RegFeeID, UserID, PayMode, ExpStr)
{
	s ^TMP("GetPrintInvInfo")=$lb(RegFeeID, UserID, PayMode, ExpStr)
	set SSU=""
	set SSU=$g(^SSU("SSUSR",UserID))
	set SSUSRInitials=$P(SSU,"^",1)
	set:SSUSRInitials'="" UserID=SSUSRInitials
	s InvNo=""
	s InvPrtID=$list($g(^User.DHCRegistrationFeeD(RegFeeID)),11)
	i InvPrtID'="" s InvNo=$P(^DHCINVPRT(InvPrtID),"^",14)
	;集中打印发票的不打印
	i (InvNo="")&&(InvPrtID'="")&&(+$P(^DHCINVPRT(InvPrtID),"^",4)'=0) d
	.s InvPrtID=$P(^DHCINVPRT(InvPrtID),"^",4)
	.s itmjsex="INVPrtFlagCPP"
	
	q ##class(web.UDHCOPINVPrtIF).GetOPPrtData(itmjs,itmjsex,InvPrtID,UserID,PayMode,ExpStr)
}

ClassMethod CancelOtherFee(RegFeeRowId As %String = "", UserRowId As %String = "", GroupRowId As %String = "", LogonLocRowId As %String = "", ByRef NewInvoiceId As %String, RefundBillSubType As %String) [ ProcedureBlock = 0 ]
{
	n (RegFeeRowId,UserRowId,GroupRowId,LogonLocRowId,NewInvoiceId,RefundBillSubType,%session)
	//s ^liyufeng("CancelOtherFee")=RegFeeRowId_","_UserRowId_","_GroupRowId_","_LogonLocRowId_","_NewInvoiceId
	//w ##class(web.DHCOPAdmReg).CancelOtherFeeBroker(245,262,93,179)
	//Set $ZT="ERROR^DHCSSERR"
	&SQL(Select RegfeeAdmDr,RegfeeNo,RegfeeDoFlag,RegfeeRBASDr,Regfeetemp1,RegfeeDate,RegfeeTimeRangeDr,RegfeeDepDr
	   into :adm,:QueueNo,:doflag,:RBASRowId,:InvoiceId,:RegfeeDate,:RegfeeTimeRangeDr,:AdmDep
	   from SQLUser.DHCRegistrationFee 
	  Where %Id=:RegFeeRowId)
	s NewPay=0
	if InvoiceId'=""  set NewPay=..GetRegINVAppFee(InvoiceId,RefundBillSubType,1)
	s StopItem=""  
	if InvoiceId'="" s StopItem=..GetRegINVOrderItem(InvoiceId,RefundBillSubType,0)
	Q:StopItem="" "-100"
	TStart
	s ret=0
	b ;生成负帐单
	s NewInvoiceId="",APIFlag="N"
	;费用为0不会有发票,退费也就不需处理
	if InvoiceId'="" {
		;&sql(update SQLUser.DHC_INVPRT Set PRT_INVPrintFlag='N' where PRT_Rowid=:InvoiceId)
		s RefundStatusCode=..GetINVRefundStatus(InvoiceId,UserRowId)
		if (RefundStatusCode'="") {
			;s Paymode=$p(^DHCINVPRT(InvoiceId,"P",1),"^")
			s Paymode=""
			s Paymode=..GetSelfPayMode(InvoiceId)
			if Paymode=""{
				;s InvPayModeID=$O(^DHCINVPRT(InvoiceId,"P",""),-1)
				;s:InvPayModeID'="" Paymode=$p(^DHCINVPRT(InvoiceId,"P",InvPayModeID),"^")
			}
			;ACCPINVDR为集中打印发票表关联指针
			S ACCPINVDR=$P($G(^DHCINVPRT(InvoiceId)),"^",4)
			;S AccPayCount=$P($G(^DHCINVPRT(InvoiceId)),"^",1)
			S PRTPatientShare=$P($G(^DHCINVPRT(InvoiceId)),"^",16)
			s AccPayCount=PRTPatientShare
			i NewPay=0 {
				s RebillFlag=0
				;s Refoundcode=##class(web.udhcOPRefEditIF).RefundReceipt(InvoiceId, UserRowId, RefundStatusCode, "", 0, GroupRowId,RebillFlag,LogonLocRowId,Paymode)
				If ACCPINVDR'="" {
					//s PRTOrdStr=..GetINVPRTOrdStr(InvoiceId)
					s PRTOrdStr=InvoiceId_$c(3)_StopItem_$c(3)_RebillFlag_$c(3)_AccPayCount
					s Refoundcode=##class(web.udhcOPRefEditIF).AccPayINVRefund(ACCPINVDR, PRTOrdStr,UserRowId, RefundStatusCode, GroupRowId, LogonLocRowId,Paymode,AccPayCount,RebillFlag,"")
				}Else{
					s Refoundcode=##class(web.udhcOPRefEditIF).RefundReceipt(InvoiceId, UserRowId, RefundStatusCode, StopItem, 0, GroupRowId,RebillFlag,LogonLocRowId,Paymode)
				}
			}else{
				s RebillFlag=1
				;s Refoundcode=##class(web.udhcOPRefEditIF).RefundReceipt(InvoiceId, UserRowId, RefundStatusCode, StopItem, NewPay, GroupRowId,RebillFlag,LogonLocRowId,Paymode)
				If ACCPINVDR'="" {
					s AccPayCount=AccPayCount-NewPay
					//s PRTOrdStr=..GetINVPRTOrdStr(InvoiceId)
					s PRTOrdStr=InvoiceId_$c(3)_StopItem_$c(3)_RebillFlag_$c(3)_AccPayCount
					s Refoundcode=##class(web.udhcOPRefEditIF).AccPayINVRefund(ACCPINVDR, PRTOrdStr, UserRowId, RefundStatusCode, GroupRowId, LogonLocRowId, Paymode, AccPayCount, RebillFlag, "")
				    s ^temposcl("Refoundcode",RegFeeRowId)=Refoundcode
				}Else{
					s Refoundcode=##class(web.udhcOPRefEditIF).RefundReceipt(InvoiceId, UserRowId, RefundStatusCode, StopItem, NewPay, GroupRowId,RebillFlag,LogonLocRowId,Paymode)
				}
			}
			b ;Refoundcode
			if ACCPINVDR'=""{ //集中打印发票				
				s ret=$P(Refoundcode,"^",1)     ;$c(2),1)   ;计费组跟普通发票退费保持统一了
				s NewInvoiceId=$p(Refoundcode,"^",2) ;$c(2),2)
				;根据集中打印发票(dhc_accpayinv)rowid取小条表（dhc_invprt）rowid，保证DHCRegistrationFee的数据意义一致，防止统计组程序报错
				;前提默认集中打印发票表与小条表1:1
				if NewInvoiceId'="" d
				.s apiConPrtDr=$o(^DHCINVPRTCAPi(0,"APINVDR",NewInvoiceId,"0"))
				.i apiConPrtDr'="" s NewInvoiceId=$p(^DHCINVPRTCAP(apiConPrtDr),"^",1)
				s APIFlag="Y"
			}else {
				s ret=$P(Refoundcode,"^",1)
				s myPRTRowID=$P(Refoundcode,"^",2)
				s strikePrtRowID=$P(Refoundcode,"^",3)
				i (+myPRTRowID'=0) {
					//确认完成
					s AdmReasonId=$p($g(^DHCINVPRT(myPRTRowID)),"^",9)   //$P(^PAADM(adm,1),"^",7)
					s RequirINVFlag="Y"
					s FairType="R"
					s AccRowId=""
					s BillAccount=GroupRowId_"^"_AdmDep_"^"_AccRowId_"^"_RequirINVFlag_"^"_FairType
					
					//Modify 20200526 Lid 确认完成接口增加支付方式列表
					// 注意点：
					//	1.取负票支付放到这里，主要考虑新发票会修改支付方式的情况
					//	2.挂号自付部分不支持多种支付方式
					//	3.默认取第一笔自费支付方式（默认医保的支付方式再前，自付的支付方式在后）。
					//s myPayinfo=##class(web.DHCBillConsIF).ReadINVPayModeNew(InvoiceId)
					//s $p(myPayinfo,"^",8)=NewPay
					//s payList=myPayinfo
					s payList=##class(web.DHCBillConsIF).GetNewInvPayMList(InvoiceId,strikePrtRowID,myPRTRowID,"")
					s err=##class(web.DHCBillConsIF).CompleteCharge("0",UserRowId,AdmReasonId,myPRTRowID,"1",strikePrtRowID,BillAccount,payList)
					i +err'=0{
						TRollback
						s ^zhou("error","CompleteCharge")=err_",InvoiceRowid="_myPRTRowID_",payList="_payList	
						Q "-210"
					}
					//结束
				}
				s NewInvoiceId=$P(Refoundcode,"^",2)
				s APIFlag="N"
			}
			
			i ret'=0 {
				TRollback
				Q "-200"
			}
			
		}
		
		//if NewInvoiceId'="" {
			&SQL(Update SQLUser.DHCRegistrationFee Set Regfeetemp1=:NewInvoiceId Where %Id=:RegFeeRowId)
			if SQLCODE {
				TRollback
				Q "-204"
			}
		//}
	}	
	TCommit
	q ret_"^"_APIFlag
}

ClassMethod CutLetter(Str) As %String
{
	q:Str="" ""
	s len=$length(Str)
	s Str2=Str
	s Str3=""
	for i=1:1:len{
		s Str1=$e(Str2,i)
		s Str1Code=$ascii(Str1)
		if ((Str1Code>=65)&(Str1Code<=90))||((Str1Code>=97)&(Str1Code<=122)){
		}else{
			s Str3=$g(Str3)_Str1
		}
	}
	s:Str3="" Str3=Str
	q Str3
}

/// 医生站直接挂号接口 提供给新产品研发组
/// Input:	PatientID 患者ID,
/// 		ASRowId 排班ID(可空，空将根据LocID+DocRowId+TimeRangeRowId自动生成排班),
/// 		AdmReason 费别ID,
/// 		FeeStr 费用信息串(1||1||0||0:收取挂号费+诊查费; 0||0||0||0:收取挂号费), 
/// 		user 操作用户ID, group 当前安全组ID, 
/// 		LocID 就诊登记科室ID, DocRowId 就诊登记医生ID, 
/// 		TimeRangeRowId 时段ID（可空，空根据当前时间确认时段）, 
/// 		PayModeCode 支付方式代码（可空）, 
/// 		AccRowId 账户ID（可空,预交金支付方式时必传）
/// 		RegExpStr 扩展信息 所用就诊卡卡类型ID^就诊卡卡号^挂号渠道code^TabPCLRowID预检分级记录表ID
/// Output:	成功时返回:0^就诊ID^诊断主表ID 失败返回:非0
/// Debug:	w ##class(web.DHCOPAdmReg).OPDocRapidRegistNewBroker(1,"3048||67","","0||0||0||0",18881,28,55,1540,"","CPP","1","","1^2")
ClassMethod OPDocRapidRegistNewBroker(PatientID As %Library.String = "", ASRowId As %Library.String = "", AdmReason As %String, FeeStr As %String = "", user As %Library.String = "", group As %Library.String = "", LocID As %String = "", DocRowId As %String = "", TimeRangeRowId As %String = "", PayModeCode As %Library.String = "", AccRowId As %Library.String = "", RegExpStr As %String = "") As %String [ ProcedureBlock = 0 ]
{
	n (PatientID,ASRowId,AdmReason,FeeStr,user,group,LocID,DocRowId,TimeRangeRowId,PayModeCode,AccRowId,RegExpStr,%session)
	;w ##class(web.DHCOPAdmReg).OPDocRapidRegistNewBroker(7,"497||9","","1||1||0||0",600,99,63,854)
	s ^tmplog("OPDocRapidRegistNewBroker")=PatientID_","_ASRowId_","_AdmReason_","_FeeStr_","_user_","_group_","_LocID_","_DocRowId_","_TimeRangeRowId_","_PayModeCode_","_AccRowId_","_RegExpStr
	s EpisodeID=""
	s mradm=""
	s RegSource=$P(RegExpStr,"^",3)
	;如果查找排班记录为空的话那么新增一条非规则出诊记录
	if ASRowId="" {
		s NowDate=..%SysDate()
		s NowTime=..%SysTime()
		i TimeRangeRowId="" s TimeRangeRowId=##class(web.DHCRBResSession).GetTimeRangeByTime(NowTime)
		s Rtn=##class(web.DHCRBApptSchedule).InsertOneIrrSchedule(LocID,DocRowId,NowDate,TimeRangeRowId)
		s RtnFlag=$P(Rtn,"^",1)
		if RtnFlag=0{
			s ASRowId=$P(Rtn,"^",2)
		}
	}
	s IrregularRBASFlag="",RegfeeRowId=""
	Q:ASRowId="" "-101"
	s HospId = ##class(DHCDoc.Common.Hospital).GetLocHospitalId(LocID)
	s IrregularFlag=$p(^RBAS(+ASRowId,$p(ASRowId,"||",2)),"^",13)
	;如果是卡消费直接调用便民挂号程序
	if PayModeCode="CPP",AccRowId'="" {
		if (IrregularFlag = "A") {
			s RegExpStr=$p(RegExpStr,"^",1)_"^"_$p(RegExpStr,"^",2)_"^"_RegSource_"^"_$p(RegExpStr,"^",4)
			s ret=..OPRapidRegist(PatientID,ASRowId,AdmReason,PayModeCode,AccRowId,user,group,.RegfeeRowId,"","","","",RegExpStr)
			i RegfeeRowId'="" s EpisodeID=$List(^User.DHCRegistrationFeeD(RegfeeRowId),2)
		} else {
			// (走正常的挂号)解决急诊护士，预检分诊挂号有账户和预交金时，无号序(不占号)的问题
			i AdmReason="" s AdmReason=$$DefaultBillType(PatientID)
			s TabPCLRowID=$p(RegExpStr,"^",4)
			s RegExpStr=$p(RegExpStr,"^",1)_"^"_$p(RegExpStr,"^",2)_"^"_RegSource
			s ret=..OPRegistBroker(PatientID,ASRowId,AdmReason,"",FeeStr,PayModeCode,AccRowId,user,group,"","","","",.RegfeeRowId,"","","","",TabPCLRowID,"","","",HospId,"","",RegSource,RegExpStr)
			s retcode=$p(ret,"$",1)
			if (retcode=0){
				s EpisodeID=$List(^User.DHCRegistrationFeeD(RegfeeRowId),2) //$p($p(ret,"$",2),"^",1)
			}else{
				s EpisodeID=""
			}
			s ret=retcode
		}
	}else{
		Set IrregularFlag=$p(^RBAS(+ASRowId,$p(ASRowId,"||",2)),"^",13)
		if IrregularFlag="A" {
			s RegExpStr=$p(RegExpStr,"^",1)_"^"_$p(RegExpStr,"^",2)_"^"_RegSource
			s ret=..OPDocRapidRegist(PatientID,ASRowId,AdmReason,FeeStr,user,group,.EpisodeID,"",RegExpStr)
		}else{
			//OPRegistBroker(PatientID As %String, ASRowId As %Library.String = "", 1-2 
			//AdmReason As %String, QueueNo As %Library.String = "", FeeStr As %Library.String = "", 3-5
			//PayModeCode As %Library.String = "", AccRowId As %Library.String = "", 6-7
			//user As %Library.String = "", group As %Library.String = "", AdmType As %Library.String = "", 8-10
			//DiagnosCatRowId As %Library.String = "", FreeRegFlag As %Library.String = "", 11-12
			//FreeCheckFlag As %Library.String = "", ByRef RegfeeRowId As %String = "", 13-14
			//ByRef InsuJoinStr As %String = "", ByRef DiscountFactor As %String = "", ByRef TAPPTRowID As %String = "") 15-17
			//UnBillFlag 不账单标识
			s IrregularRBASFlag=1
			i AdmReason="" s AdmReason=$$DefaultBillType(PatientID)
			s DocResValue=..GetMarkRegFee(ASRowId,AdmReason,PatientID)
		    s RegFee=$p(DocResValue,"^",12)
	        s CheckFee=$p(DocResValue,"^",14)
	        s FeeStr=(RegFee+CheckFee)_"||"_FeeStr
			s TabPCLRowID=$p(RegExpStr,"^",4)
			s RegExpStr=$p(RegExpStr,"^",1)_"^"_$p(RegExpStr,"^",2)_"^"_RegSource
			s ret=..OPRegistBroker(PatientID,ASRowId,AdmReason,"",FeeStr,"","",user,group,"","","","",.RegfeeRowId,"","","","Y",TabPCLRowID,"","","",HospId,"","",RegSource,RegExpStr)
			s retcode=$p(ret,"$",1)
			if (retcode=0){
				s EpisodeID=$List(^User.DHCRegistrationFeeD(RegfeeRowId),2) //$p($p(ret,"$",2),"^",1)
			}else{
				s EpisodeID=""
			}
			s ret=retcode
		}
		
	}
	if EpisodeID'="",IrregularRBASFlag="" {
		s mradm=##Class(web.DHCPAADM).GetMRAdmID(EpisodeID)
		;调用平台组接口
		s rtn=##class(web.DHCENS.EnsHISService).DHCHisInterface("SENDOPREGINFO",EpisodeID)
	}
	b ;OPRegist OK
	s ret=ret_"^"_EpisodeID_"^"_mradm
	q ret
DefaultBillType(PatientID)
	if PatientID="" Q ""
	set PatCatDr=$p(^PAPER(PatientID,"PER",1),"^",10)
	i PatCatDr'="" set DHCPACADMDr=$O(^DHCPACADM(0,"Social",PatCatDr,""))
	set AdmReason=""
	if $g(DHCPACADMDr)'="" set AdmReason=$p(^DHCPACADM(DHCPACADMDr),"^",2)
	Q AdmReason
}

/// w ##class(web.DHCOPAdmReg).GetAllRegDepString("1","2")
ClassMethod GetAllRegDepString(GroupRowId As %String) As %String
{
    s FindFlag=""
    if GroupRowId="" q ""
    s ResString=$P($g(^SSU("SSGRP",GroupRowId,"DHC")),"^",1)
    if ResString="" q FindFlag
    s i=0 f  s i=i+1 q:i>$l(ResString,"!")  d
    .s resrowid=$p(ResString,"!",i)
    .s CTLocDr=$p($g(^RB("RES",resrowid)),"^",1)
    .if ("^"_FindFlag_"^")'[("^"_CTLocDr_"^") d
    ..s FindFlag=FindFlag_"^"_CTLocDr
    q:FindFlag="" ""
    q FindFlag_"^"
}

/// w ##class(web.DHCOPAdmReg).GetAllRegDocString("1","2")
ClassMethod GetAllRegDocString(GroupRowId As %String) As %String
{
    s FindFlag=""
    if GroupRowId="" q ""
    s ResString=$P(^SSU("SSGRP",GroupRowId,"DHC"),"^",1)
    if ResString="" q FindFlag
    s i=0 f  s i=i+1 q:i>$l(ResString,"!")  d
    .s resrowid=$p(ResString,"!",i)
    .s DocDr=$p(^RB("RES",resrowid),"^",2)
    .if FindFlag'[DocDr d
    ..s FindFlag=FindFlag_"^"_DocDr
    q:FindFlag="" ""
    q FindFlag_"^"
}

/// 挂号前进行的检测
/// w ##class(web.DHCOPAdmReg).CheckBeforeReg("1530||51",30,"")
ClassMethod CheckBeforeReg(ResRowId As %String, PatientID As %String, APPTRowId As %String = "", CardTypeDr As %String = "", CardNo As %String = "", HospitalId As %String = "", ASRowIdStr As %String = "", RegSource As %String = "", SessionStr As %String = "") As %String
{
	s ^tmplog("CheckBeforeReg")=ResRowId_"^"_PatientID_"^"_APPTRowId_"^"_CardTypeDr_"^"_CardNo_"^"_ASRowIdStr
    s langid = ..%LanguageID()
	s CurrDate=..%SysDate()
	s CurrTime=..%SysTime()
	s GroupID=$p(SessionStr,"^",2)
	s:HospitalId="" HospitalId=$p(SessionStr,"^",4)
	if HospitalId=""{
		i ($d(%session)){
			s HospitalId=%session.Get("LOGON.HOSPID")
		}else{
			s HospitalId=$p(..GetCurrentHosp("","",ResRowId,""),"^",1)	
		}
	}
	s:(GroupID="")&&($d(%session)) GroupID=%session.Get("LOGON.GROUPID")
	;挂号授权-功能控制(安全组)-可挂号的患者类型
	s OPAdmPatTypeStr=##class(web.DHCOPRegConfig).GetGroupConfig(HospitalId,GroupID,"OPAdmPatType")
	/*1、卡信息检测*/
	if CardNo'="" {
		s ret=..CheckTempCardEffe(CardTypeDr, CardNo)
		s IsTempCard=$p(ret,"^",1)
		s DiscDate=$p(ret,"^",2)
		i IsTempCard="Y" {
			q:DiscDate>0 "-700"_..%Translate("opadm.reg.hui.csp","临时卡已过能挂号有效天数!",langid)
		}
	}
	/*2、患者信息检测*/
	s Name=$p($g(^PAPER(PatientID,"ALL")),"^",1)
	s PatientNo=$p($g(^PAPER(PatientID,"PAT",1)),"^",1)
	s PatCatDr=$p(^PAPER(PatientID,"PER",1),"^",10)
	s IsDeceased=##Class(web.PAPerson).CheckDeceased(PatientID)
	if IsDeceased="Y"{
		q "-704^"_..%Translate("opadm.reg.hui.csp","患者已故!",langid)
	}
	s InPatAllowOPRegistFlag=##class(web.DHCOPAdmReg).GetInHospOrStayStatus(PatientID,HospitalId) 
  	if (InPatAllowOPRegistFlag=1)&&(RegSource'="MDT"){
	  	Q "-705^"_..%Translate("opadm.reg.hui.csp","住院患者不允许门诊挂号就诊!",langid)
	}
	if OPAdmPatTypeStr'=""{
		Q:(","_OPAdmPatTypeStr_",")'[(","_PatCatDr_",") "-706^"_..%Translate("opadm.reg.hui.csp","所属安全组不允许为此患者类型挂号预约!",langid)	
	}
	s AdmReason=..GetDefaultBillType(PatCatDr)
	
	/*3、排班信息检测*/
	s chkRet=0
	if ResRowId=""{
		Q chkRet	
	}
	
	if ASRowIdStr="" s ASRowIdStr=ResRowId
	s ASRowId=ResRowId
	s ASChild=$P(ResRowId,"||",2)
	s ResRowId=+ResRowId
	s EPMark=##class(web.DHCRBResource).GetEPMarkFlag(+ResRowId)
	s CommonPatientID=..GetCommonPatientID()
	s AdmDep=$P($G(^RB("RES",ResRowId)),"^",1)
	s AdmDoc=$P($G(^RB("RES",ResRowId)),"^",2)
	s ASDate=$P($G(^RBAS(ResRowId,ASChild)),"^",1) 
	s ASStartTime=$P($G(^RBAS(ResRowId,ASChild)),"^",4) 
	Q:($g(AdmDep)="")!($g(AdmDoc)="") "-1^"_..%Translate("opadm.reg.hui.csp","排班信息错误!",langid)
	s AdmDepDesc=$P(^CTLOC(AdmDep),"^",2)
	s AdmDocDesc=$P(^CTPCP(AdmDoc,1),"^",2)
	s ASTimeRangeDr=$P($G(^RBAS(+ResRowId,ASChild,"DHC")),"^",17)
	s RoomDr=$P($G(^RBAS(+ResRowId,ASChild,"DHC")),"^",5)
	s SessionTypeDr=$P($G(^RBAS(+ResRowId,ASChild,"DHC")),"^",6)
	
	s AdmType="O"
	if AdmType'="E" {
		s IsEmergency=..IsEmergency(AdmDep)
		if IsEmergency="1" s AdmType="E"
	}
	q:($g(IsTempCard)="Y")&&(AdmType'="E") "-701^"_..%Translate("opadm.reg.hui.csp","临时卡只能挂急诊号!",langid)
	
	s RegStartTime=##class(web.DHCOPRegConfig).GetSpecConfigNode("RegStartTime",HospitalId)
	s AppStartTime=##class(web.DHCOPRegConfig).GetSpecConfigNode("AppStartTime",HospitalId)
	s AddStartTime=##class(web.DHCOPRegConfig).GetSpecConfigNode("AddStartTime",HospitalId)
	i RegStartTime'="" s RegStartTime=..%ZTH(RegStartTime)
	i AppStartTime'="" s AppStartTime=..%ZTH(AppStartTime)
	i AddStartTime'="" s AddStartTime=..%ZTH(AddStartTime)
	s RegNoStartMsg="-401^"_..%Translate("opadm.reg.hui.csp","还未到挂号开始时间,不能进行挂号操作!",langid)
	s RegEndMsg="-406^"_..%Translate("opadm.reg.hui.csp","已过挂号结束时间,不能进行挂号操作!",langid)
	if APPTRowId'="" {
	    i (RegStartTime'="")&(CurrTime<RegStartTime)&&(EPMark'=1) Q RegNoStartMsg
		if ASDate=CurrDate {
			s TRRegSTTime=$P($G(^DHCTimeRange(ASTimeRangeDr)),"^",9)
	        s TRRegEndTime=$P($G(^DHCTimeRange(ASTimeRangeDr)),"^",10)
			i (TRRegSTTime'="")&(CurrTime<TRRegSTTime)&&(EPMark'=1) Q RegNoStartMsg
			i (TRRegEndTime'="")&(CurrTime>TRRegEndTime)&&(EPMark'=1) Q RegEndMsg
		}
	}else{
		;如果调用的不是当日的提班记录,则为预约
		if ASDate=CurrDate {
			i (RegStartTime'="")&(CurrTime<RegStartTime)&&(EPMark'=1) Q RegNoStartMsg
			s TRRegSTTime=$P($G(^DHCTimeRange(ASTimeRangeDr)),"^",9)
	        s TRRegEndTime=$P($G(^DHCTimeRange(ASTimeRangeDr)),"^",10)
			i (TRRegSTTime'="")&(CurrTime<TRRegSTTime)&&(EPMark'=1) Q RegNoStartMsg
			i (TRRegEndTime'="")&(CurrTime>TRRegEndTime)&&(EPMark'=1) Q RegEndMsg
		}
	}
	if (RegSource'="SERV")&&(ASDate>CurrDate){
	    i (AppStartTime'="")&(CurrTime<AppStartTime)&&(EPMark'=1) Q "-402^"_..%Translate("opadm.reg.hui.csp","还未到预约开始时间,不能进行预约操作!",langid)
	}
	s ScheduleStatus=..CheckScheduleStatus(ASRowId)
	if ScheduleStatus="S"{
		Q "-410^"_..%Translate("opadm.reg.hui.csp","该排班已停诊.",langid)
	}
	s chkRtn=..CheckRegDeptAgeSex(ASRowId,PatientID)
	s chkCode=$p(chkRtn,$c(2),1)
	if chkCode'=0{
		s chkMsg=""
		s AllowSexDesc=$p(chkRtn,$c(2),2)
		s AgeRange=$p(chkRtn,$c(2),3)
		if AllowSexDesc'=""{
			s chkMsg=..%Translate("opadm.reg.hui.csp","此科室支持性别",langid)_"【"_AllowSexDesc_"】"
		}
        s ageRangeTipTrans = ..%Translate("opadm.reg.hui.csp","此科室支持年龄段",langid)
		if AgeRange'=""{
			s chkMsg=$s(chkMsg="":ageRangeTipTrans_":"_AgeRange,1:chkMsg_","_ageRangeTipTrans_":"_AgeRange)
		}
		Q "-411^"_..%Translate("opadm.reg.hui.csp","不允许挂此科室",langid)_","_chkMsg
	}
	//停止挂号（医生坐诊信息开启停止挂号后，不允许挂号及取号）
   	s StopRegFlag=$P($G(^RBAS(+ResRowId,ASChild,"DHC")),"^",30)
   	if (StopRegFlag="Y"){
	   Q "-412^"_..%Translate("opadm.reg.hui.csp","该出诊信息已开启停止挂号,不予许挂号及取号!",langid)
	}
	//判断是否有公共卡
	s CommonPatientID=..GetCommonPatientID("",HospitalId)
	//公共卡不做限制
	i (("^"_CommonPatientID_"^")'[("^"_PatientID_"^"))&&(EPMark'=1){
		s rtn=..CheckRegCountLimitStr(PatientID,ASRowIdStr,HospitalId,APPTRowId)
		q rtn
		/*s AdmCountStr=..GetPADayAdmCount(PatientID,AdmType,ASDate,AdmDep,AdmDoc,ASTimeRangeDr)
		s AdmCount=$P(AdmCountStr,"^",1)
		s AdmDocCount=$P(AdmCountStr,"^",2)
		s AdmLocCount=$P(AdmCountStr,"^",3)
		s AdmTimeLocDocCount=$P(AdmCountStr,"^",4)
		
		s DayRegCountLimit=##class(web.DHCOPRegConfig).GetSpecConfigNode("DayRegCountLimit",HospitalId)
		s DaySameDocRegCountLimit=##class(web.DHCOPRegConfig).GetSpecConfigNode("DaySameDocRegCountLimit",HospitalId)
		s DaySameLocRegCountLimit=##class(web.DHCOPRegConfig).GetSpecConfigNode("DaySameLocRegCountLimit",HospitalId)
		s LocRegCountLimit=$p(##class(web.DHCOPRegConfig).GetConfigNode1("OPRegDepExpand",AdmDep),"^",3)
		s TimeLocDocCountLimit=##class(web.DHCOPRegConfig).GetSpecConfigNode("DaySameTimeRegLimit",HospitalId)
		;超过每天挂号限额
		if (AdmCount>=DayRegCountLimit)&&(DayRegCountLimit'=0) Q "-301^"_"挂号记录科室:【"_AdmDepDesc_""_"】,号别:【"_AdmDocDesc_"】,就诊日期:【"_..%ZD(ASDate)_"】"_",超过每人每天可挂号限额!不能进行挂号和预约."
		if (AdmDocCount>=DaySameDocRegCountLimit)&&(DaySameDocRegCountLimit'=0) Q "-302^"_"挂号记录科室:【"_AdmDepDesc_""_"】,号别:【"_AdmDocDesc_"】,就诊日期:【"_..%ZD(ASDate)_"】"_",超过每人每天可挂相同号的限额!"
		if (LocRegCountLimit=1)&&(AdmLocCount>=DaySameLocRegCountLimit)&&(DaySameLocRegCountLimit'=0) Q "-302^"_"挂号记录科室:【"_AdmDepDesc_""_"】,号别:【"_AdmDocDesc_"】,就诊日期:【"_..%ZD(ASDate)_"】"_",超过每人每天可挂相同科室号的限额!"
		b //34
		if ('$d(^DHCOPRegConfig("DaySameTimeRegLimit",TimeRangeDr,AdmDep,AdmDoc)))&&(AdmTimeLocDocCount>=TimeLocDocCountLimit)&&(TimeLocDocCountLimit'=0) q "-302^"_"挂号记录科室:【"_AdmDepDesc_""_"】,号别:【"_AdmDocDesc_"】,就诊日期:【"_..%ZD(ASDate)_"】"_",超过每人每天相同时段同科室同医生限额!"
		*/
	}
	q chkRet
}

ClassMethod GetEmChkInfo(PatientID As %String, TimeRangeRowId As %String, AdmReason As %String, GroupRowId As %String, RegConDisId As %String = "") As %String
{
	//先分诊患者，护士预检分诊后挂号处表取分诊的号别（24小时且未挂号）和绿色通道标识
    //返回:号别ID^科室ID^分级ID^分诊日期^分诊时间^绿色通道^抢救病区ID||号别ID^科室ID^分级ID^分诊日期^分诊时间^绿色通道^抢救病区ID
    s ^tempscl("GetEmChkInfo")=PatientID_","_TimeRangeRowId_","_AdmReason
    //##Class(web.DHCEMInterfaceCom).GetPatChkLvCareInfo("病人ID")
    q:PatientID="" ""
    s PatChkLvCareInfo=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.opadm.GetPatChkLvCareInfo",PatientID)
    q:PatChkLvCareInfo="" ""
	s CurrentTime=..%SysTime()
	i AdmReason="" s AdmReason=$$DefaultBillType(PatientID)
	s EmChkInfo=""
	For i=1:1:$l(PatChkLvCareInfo,"||") {
	    s OnePatChkLvCareInfo=$p(PatChkLvCareInfo,"||",i)
		continue:OnePatChkLvCareInfo=""
		s RESCTPCPDR=$p(OnePatChkLvCareInfo,"^",1)
		continue:RESCTPCPDR=""
		s RESCTLOCDR=$p(OnePatChkLvCareInfo,"^",2)
		continue:RESCTLOCDR=""
		s ResRowid=$o(^RB("RES",0,"CTPCP",RESCTPCPDR,RESCTLOCDR,""))
		continue:ResRowid=""
		//set GroupRowId=%session.Get("LOGON.GROUPID")
        Set GroupRes=##class(web.DHCOPRegConfig).GetGroupRes(GroupRowId)
		continue:(GroupRes'="")&&(("!"_GroupRes_"!")'[("!"_ResRowid_"!")) 
		s ASChildSub="",ASRowId="",ASSessStartTime=""
		for  {
			s ASSessStartTime=$o(^RBAS(ResRowid,0,"DateSTime",+$h,ASSessStartTime)) q:(ASSessStartTime="")||(ASRowId'="") 
			s ASChildSub=""
			for {
				s ASChildSub=$o(^RBAS(ResRowid,0,"DateSTime",+$h,ASSessStartTime,ASChildSub)) q:(ASChildSub="")||(ASRowId'="") 
			    continue:ASChildSub="AQ"
				continue:'$d(^RBAS(ResRowid,ASChildSub))
				s status=$P($G(^RBAS(ResRowid,ASChildSub,"DHC")),"^",10)
	            i status'="" s status=$P(^DHCRBCASStatus(status),"^",1)
				;过滤停诊和替诊
				continue:(status="S")||(status="TR")||(status="PS")
				s ASIrregularFlag=$p($g(^RBAS(ResRowid,ASChildSub)),"^",13)
				;默认是不找不规则出诊记录的
				continue:(ASIrregularFlag="A")
				s ASDate=$p(^RBAS(ResRowid,ASChildSub),"^",1)
				continue:(ASDate'=..%SysDate())
				s ASTimeRangeDR=$p(^RBAS(ResRowid,ASChildSub,"DHC"),"^",17)
				;continue:(TimeRangeRowId'="")&&(ASTimeRangeDR'=TimeRangeRowId)
				s TRStartTime=$p(^DHCTimeRange(ASTimeRangeDR),"^",3)
				s TREndTime=$p(^DHCTimeRange(ASTimeRangeDR),"^",4)
				continue:'((CurrentTime>=TRStartTime)&&(CurrentTime<=TREndTime))
				s ASRowId=ResRowid_"||"_ASChildSub
			}			
		}
		continue:ASRowId=""
		s DocResValue=##class(web.DHCOPAdmReg).GetMarkRegFee(ASRowId,AdmReason,PatientID,"",RegConDisId)
		s DocDr=$p(^RB("RES",+ASRowId),"^",2)
		S MarkDesc=$p(^CTPCP(DocDr,1),"^",2)
		i $l(MarkDesc,"(")>1 s MarkDesc=$p(MarkDesc,"(",1)
		Set DeptDr=$p(^RB("RES",+ASRowId),"^",1)
		Set DepDesc=$P(^CTLOC(DeptDr),"^",2)     //科室
		s RegFeeDr="",ExamFeeDr="",HoliFeeDr="",AppFeeDr=""
		s RegFee=$p(DocResValue,"^",12)
		s CheckFee=$p(DocResValue,"^",14)
		s HoliFee=$p(DocResValue,"^",16)
		s AppFee=$p(DocResValue,"^",18)
		s ReCheckFee=$p(DocResValue,"^",15)
		s OtherFee=$p(DocResValue,"^",20)
		s TRDesc=$p(DocResValue,"^",21)
		s ScheduleDate=$p(DocResValue,"^",28)
		s TotalFee=HoliFee+CheckFee+RegFee+AppFee+OtherFee
		s Source=""
		s SpecSeqNo="",ScheduleDate=..%ZD(+$h) 
		s PCLRowID=$p(OnePatChkLvCareInfo,"^",3) //分诊级别ID
		s oneInfo=ASRowId_"^"_MarkDesc_"^"_TotalFee_"^"_CheckFee_"^"_HoliFee_"^"_AppFee_"^"_DepDesc_"^"_ScheduleDate_"^"_SpecSeqNo_"^"_0_"^"_""_"^"_""_"^"_TRDesc_"^"_Source_"^"_""_"^"_PCLRowID_"^"_"^"
		i EmChkInfo="" s EmChkInfo=oneInfo
		e  s EmChkInfo=EmChkInfo_"#"_oneInfo
		
	}
    q EmChkInfo 
DefaultBillType(PatientID)
	if PatientID="" Q ""
	set PatCatDr=$p(^PAPER(PatientID,"PER",1),"^",10)
	i PatCatDr'="" set DHCPACADMDr=$O(^DHCPACADM(0,"Social",PatCatDr,""))
	set AdmReason=""
	if $g(DHCPACADMDr)'="" set AdmReason=$p(^DHCPACADM(DHCPACADMDr),"^",2)
	Q AdmReason
}

/// 更新挂号表中的发票数据--用于欠费补回
/// input AdmID 就诊ID InvoiceId 新挂号发票表ID
/// Output 0 成功 -1入参存在为空情况 -2不是单独完整结算挂号相关医嘱
/// w ##class(web.DHCOPAdmReg).UpdateRegistionFeeInv(97,218862,"93||1^93||2")
ClassMethod UpdateRegistionFeeInv(AdmID As %String, InvoiceId As %String, OPBilledOrdStr As %String) As %String
{
	s ^Tempscl("UpdateRegistionFeeInv")=AdmID_","_InvoiceId_","_OPBilledOrdStr
	Q:(AdmID="")||(InvoiceId="")||(OPBilledOrdStr="") "-1"
	s RegfeeRowId=$O(^User.DHCRegistrationFeeI("ADM",AdmID,0))
 	Q:RegfeeRowId="" "0"
 	s Regfeetemp1=$lg(^User.DHCRegistrationFeeD(RegfeeRowId),11)
 	//Q:Regfeetemp1'="" "0"
 	s RegLinkOrdListStr=..GetRegLinkOrdListByAdm(AdmID,"Y")
 	Q:RegLinkOrdListStr="" "0"
 	s OPBilledOrdSort=..OPBilledOrdSort(OPBilledOrdStr)
 	s FindRegOrdFlag=0
 	For i=1:1:$l(RegLinkOrdListStr,"^") q:FindRegOrdFlag=1  d
 	.s tmpRegLinkOrdId=$p(RegLinkOrdListStr,"^",i)
 	.i ("^"_OPBilledOrdSort_"^")[("^"_tmpRegLinkOrdId_"^") s FindRegOrdFlag=1
 	if (FindRegOrdFlag=1){
	 	Q:(OPBilledOrdSort'=RegLinkOrdListStr) "-2"
	 	s InsuDivID=$p($g(^DHCINVPRT(InvoiceId)),"^",30)
		s InsuAdmID=""
		if (InsuDivID'=""){
			s InsuAdmInfo=##class(web.DHCINSUPort).GetInAdmDrByInDivDr(InsuDivID)
			if InsuAdmInfo'["^" s InsuAdmID=InsuAdmInfo
			}
	 	&SQL(Update SQLUser.DHCRegistrationFee Set Regfeetemp1=:InvoiceId,RegfeeInsuAdmDr=:InsuAdmID Where %Id=:RegfeeRowId)
		q SQLCODE
	}
 	Q 0
}

// 根据就诊id获取本次就诊挂号费用相关的医嘱串

ClassMethod GetRegLinkOrdListByAdm(AdmID As %String, NotNoFee As %String = "")
{
	Set admloc=$p(^PAADM(AdmID),"^",4)
	s CurHospDr=$p($g(^CTLOC(admloc)),"^",22)
	s AdmDate=$p($g(^PAADM(AdmID)),"^",6)
	s RegConDisId=$p($g(^PAADM(AdmID,"DHC")),"^",25)
	k RegLinkOrdListArr($j)
	s RegSerBillSubTypeStr="^MR^Card^Reg^Check^ReCheck^App^Holi^Other^"
	Set OEORDRowId=$o(^OEORD(0,"Adm",AdmID,""))
	Q:OEORDRowId="" ""
	s OEORIChildsub=0
	f  s OEORIChildsub=$o(^OEORD(OEORDRowId,"I",OEORIChildsub)) q:OEORIChildsub=""  d
	.q:'$d(^OEORD(OEORDRowId,"I",OEORIChildsub,1))
	.s TOrderStatusDR=$p(^OEORD(OEORDRowId,"I",OEORIChildsub,1),"^",13)
	.s:+TOrderStatusDR>0 orderStatCode = $p(^OEC("OSTAT",TOrderStatusDR),"^",1)
	.Q:(orderStatCode'="V")&&(orderStatCode'="E")
	.s ARCIMRowId=$p($g(^OEORD(OEORDRowId,"I",OEORIChildsub,1)),"^",2)
	.Q:ARCIMRowId=""
	.s ARCIMServiceGroupDR=$p($g(^ARCIM(+ARCIMRowId,$p(ARCIMRowId,"||",2),8)),"^",7)
	.//$g(^DHCOPRegConfig("RegServiceGroup")
	.Q:(ARCIMServiceGroupDR'=##class(web.DHCOPRegConfig).GetSpecConfigNode("RegServiceGroup",CurHospDr)) //如果医嘱项服务组不是挂号设置-》挂号服务组，则退出
	.s AdmReason=$p($g(^OEORD(OEORDRowId,"I",OEORIChildsub,11)),"^",18)
	.s BillPrice=$p(##Class(web.UDHCJFPRICE).GetOrderPrice("",AdmReason,ARCIMRowId,AdmDate,"","","","",CurHospDr,RegConDisId),"^",4)
	.s RetPrice=##class(web.DHCDocOrderCommon).GetOEORIPrice(OEORDRowId_"||"_OEORIChildsub)
	.q:(+$p(RetPrice,"^",1)=0)&&(NotNoFee="Y")	;过滤0费用医嘱
	.s RegSerBillSubType=..GetRegArcimBillSubType(ARCIMRowId,CurHospDr)
	.s tmpRegSerBillSubType="^"_RegSerBillSubType_"^"
	.i (RegSerBillSubTypeStr[tmpRegSerBillSubType),RegSerBillSubType'="" d
	..s RegLinkOrdListArr($j,ARCIMRowId)=""
	s RegLinkOrdListStr=""
	s tmpARCIMRowId=0
	f  s tmpARCIMRowId=$o(RegLinkOrdListArr($j,tmpARCIMRowId)) q:tmpARCIMRowId=""  d
	.i RegLinkOrdListStr="" s RegLinkOrdListStr=tmpARCIMRowId
	.e  s RegLinkOrdListStr=RegLinkOrdListStr_"^"_tmpARCIMRowId
	k RegLinkOrdListArr($j)
	Q RegLinkOrdListStr
}

ClassMethod OPBilledOrdSort(OPBilledOrdStr As %String) As %String
{
	k OPBilledOrdArr($j)
	For i=1:1:$l(OPBilledOrdStr,"^") d
	.s tmpOrderRowId=$p(OPBilledOrdStr,"^",i)
	.Q:tmpOrderRowId=""
	.s tmpARCIMRowId=$p($g(^OEORD(+tmpOrderRowId,"I",$p(tmpOrderRowId,"||",2),1)),"^",2)
	.Q:tmpARCIMRowId=""
	.s OPBilledOrdArr($j,tmpARCIMRowId)=""
	s OPBilledOrdSortStr=""
	s tmpARCIMRowId=0
	f  s tmpARCIMRowId=$o(OPBilledOrdArr($j,tmpARCIMRowId)) q:tmpARCIMRowId=""  d
	.i OPBilledOrdSortStr="" s OPBilledOrdSortStr=tmpARCIMRowId
	.e  s OPBilledOrdSortStr=OPBilledOrdSortStr_"^"_tmpARCIMRowId
	k OPBilledOrdArr($j)
	Q OPBilledOrdSortStr
}

/// creator:郭荣勇
/// date:2017-06-02
/// desc:根据出诊记录id,病人id判断科室的性别/年龄限制 1 限制,0 非限制
ClassMethod CheckRegDeptAgeSex(ASRowId As %String, PatientID As %String, LocRowid As %String = "") As %String
{
	//q:(ASRowId="")||(PatientID="") 0
	if (LocRowid=""){
		q:ASRowId="" 0
		s LocRowid=$p(^RB("RES",+ASRowId),"^",1)
	}
	q:(LocRowid="")||(PatientID="") 0
	s CommonCardPatientNo=..GetCommonCardNoandPatientNo("")
	s PatientNo=$p($g(^PAPER(PatientID,"PAT",1)),"^",1)
	if ("^"_CommonCardPatientNo_"^")[("^"_PatientNo_"^") q 0  ;公共卡不做年龄的限制
	s PatDOB=$P($G(^PAPER(PatientID,"ALL")),"^",6)
	s SexId=$P($G(^PAPER(PatientID,"ALL")),"^",7)
	s Age=$$CalAge^at182(PatDOB,+$H,"","","")
	s Age=$p(Age,"|",12)
	
	q ..GetDeptAgeSexRestriction(LocRowid,SexId,Age,PatientID)
}

/// creator:郭荣勇
/// date:2017-06-02
/// desc:得到科室的性别/年龄限制 1 限制,0 非限制
ClassMethod GetDeptAgeSexRestriction(LocRowid, SexId, Age, PatientID) As %String
{
	;n (LocRowid,SexId,Age)
	;s ^tmpgry("AgeSex")=LocRowid_","_SexId_","_Age
	s rtn=0
	s SexId=$g(SexId)
	s Sex="",AgeRange="",SubSex=""
	q:LocRowid="" rtn
	Set langid=..%LanguageID()
	s logonHospID=$p($g(^CTLOC(LocRowid)),"^",22)
	Set AgeStr=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.reg.GetPapmiAge",PatientID,"",logonHospID,"","","",1)
    Set Age=$p(AgeStr,"||",1)
    Set AgeYear=+$p(AgeStr,"||",2)
    set AgeMorth=+$p(AgeStr,"||",3)
    set AgeDay=+$p(AgeStr,"||",4)
	s WardSingleSex=$p(^CTLOC(LocRowid),"^",64)
	s AgeFrom=$p(^CTLOC(LocRowid),"^",49)
	s AgeTo=$p(^CTLOC(LocRowid),"^",50)
	s AgeFromType=$p(^CTLOC(LocRowid),"^",102)
	s AgeToType=$p(^CTLOC(LocRowid),"^",103)
	if (WardSingleSex'="") {
		s SubSex=$p($g(^CT("SEX",WardSingleSex)),"^",2)
		s SubSex=##class(User.CTSex).GetTranByDesc("CTSEXDesc",SubSex,langid)
		if (WardSingleSex'=SexId) s rtn=1
	}
    s dayTrans = ..%Translate("opdoc.rapidregist.hui.csp","日",langid)
	s monthTrans = ..%Translate("opdoc.rapidregist.hui.csp","月",langid)
	s yearTrans = ..%Translate("opdoc.rapidregist.hui.csp","岁",langid)
	s AgeRange=""
	if (AgeFrom'=""){
		if ((AgeFromType="Y")&&(AgeFrom>AgeYear)) s rtn=1
		if ((AgeFromType="M")&&((AgeFrom>AgeMorth)&&(AgeYear<0))) s rtn=1
		if ((AgeFromType="D")&&((AgeFrom>AgeDay)&&(AgeYear<0)&&(AgeMorth<0))) s rtn=1
        s AgeRange=AgeFrom_$CASE(AgeFromType,"Y":yearTrans,"M":monthTrans,"D":dayTrans)
	}
	if (AgeTo'=""){
		if ((AgeToType="Y")&&(AgeTo<AgeYear)) s rtn=1
		if ((AgeToType="M")&&((AgeTo<AgeMorth)&&(AgeYear=0))) s rtn=1
		if ((AgeToType="D")&&((AgeTo<AgeDay)&&(AgeYear=0)&&(AgeMorth=0))) s rtn=1
		if (AgeRange=""){
			s AgeRange="0-"_AgeTo_$CASE(AgeToType,"Y":yearTrans,"M":monthTrans,"D":dayTrans)
		}else{
			s AgeRange=AgeRange_"-"_AgeTo_$CASE(AgeToType,"Y":yearTrans,"M":monthTrans,"D":dayTrans)
		}
	}
	q rtn_$c(2)_SubSex_$c(2)_AgeRange
}

/// w ##class(web.DHCOPAdmReg).CheckScheduleStatus()
ClassMethod CheckScheduleStatus(ASRowId As %String) As %String
{
	q:(ASRowId="") ""
	s ResRowId=+ASRowId
	s ASChildSub=$p(ASRowId,"||",2)
	s status=$P($G(^RBAS(ResRowId,ASChildSub,"DHC")),"^",10)
	i status'="" s status=$P($g(^DHCRBCASStatus(status)),"^",1)
	
	q status
}

ClassMethod LocDescFormate(desc) As %String
{
	q:desc="" desc
	i desc["-",$p(desc,"-",2)'="" s desc=$p(desc,"-",2)
	q desc
}

// 判断科室检索码、别名是否在入参查询条件内

// 1在 0 不在

ClassMethod CheckLocDesc(LocId As %String, desc As %String, langid As %String = "") As %String
{
	s FindFlag=0
	q:(LocId="")||(desc="") "1"
	s desc=$$ALPHAUP^SSUTIL4(desc)
	s CTLocContactName=$P(^CTLOC(LocId),"^",43)
	//科室检索码
	s CTLocContactName=$$ALPHAUP^SSUTIL4(CTLocContactName)
	Q:(CTLocContactName[desc) "1"
	//科室名称
	s CTLocDesc=$$ALPHAUP^SSUTIL4($P(^CTLOC(LocId),"^",2))
	s CTLocEngDesc=##class(DHCDoc.Common.Translate).GetTransLoc(CTLocDesc,langid)
	s CTLocEngDesc=$$ALPHAUP^SSUTIL4(CTLocEngDesc)
	Q:(CTLocDesc[desc)!(CTLocEngDesc[desc) "1"
	//别名查找
	s FindFlag=##class(DHCDoc.Util.Base).CheckAliasByTableName("CT_Loc",LocId,desc)
	/*s SubID=0  
	f  s SubID=$O(^User.BDPAliasI("DataRef","CT_Loc",LocId,SubID)) Q:(SubID="")||(FindFlag=1)  d
	.i $D(^User.BDPAliasD(SubID)) d
	..s SUbCode=$$ALPHAUP^SSUTIL4($list(^User.BDPAliasD(SubID),2))
	..i SUbCode[desc  d
	...s FindFlag=1*/
	Q FindFlag
}

/// Creator    ：陶越强
/// CreatDate  ：2017.06.23
/// Description: 医保实时挂号锁号接口
/// Table      : CT_LockSchedule
/// Input      : 锁号信息串：排班ID^序号^收费员ID^有效标志^登记号
/// Output     : 成功标志：CTLSRowId
/// d ##class(web.DHCOPAdmReg).OPRegLockSepNo(1)
ClassMethod OPRegLockSepNo(LockSepNoInfo As %String) As %String
{
	s ^Temp("OPRegLockSepNo")=LockSepNoInfo
	q:LockSepNoInfo="" "-1"
	;s LockSepNoInfo="45||54"_"^"_1_"^"_7_"^"_"Y"_"^"_"0000000001"
	s ASRowId=$p(LockSepNoInfo,"^",1)
	s SeqNo=$p(LockSepNoInfo,"^",2)
	s UserDr=$p(LockSepNoInfo,"^",3)
	s ValidFlag=$p(LockSepNoInfo,"^",4)
	s PatientNo=$p(LockSepNoInfo,"^",5)
		
	s object=##class(User.CTLockSchedule).%New()
	s object.CTSchedule=ASRowId	
	s object.CTLockQueueNo=SeqNo
	s object.CTUpdateDate=..%SysDate()	
	s object.CTUpdatTime=..%SysTime()
	s object.CTUserID=UserDr
	s object.CTActiveFlag=ValidFlag
	s object.CTPatNo=PatientNo
	s object.CTHISTradeNo=""
	s object.CTHISAdmDr=""
	s object.CTLastUpdateDate=""
	s object.CTLastUpdatTime=""
	s object.CTLastUpdatUser=""
	
	Set sc = object.%Save()
	If $$$ISERR(sc) {
		Do $System.Status.DisplayError()
		Q "-100"
	}
	s CTLSRowId=object.%Id()
	q CTLSRowId
}

/// Creator    ：陶越强
/// CreatDate  ：2017.06.23
/// Description: 医保实时挂号解锁接口
/// Table      : CT_LockSchedule
/// Input      : 锁号ID
/// Output     : 成功标志：1
/// d ##class(web.DHCOPAdmReg).OPRegUnLockSepNo(1)
ClassMethod OPRegUnLockSepNo(CTLSRowId As %String) As %String
{
	s LastUpdateDate=..%SysDate()
	s LastUpdateTime=..%SysTime()
	s CTActiveFlag="N"
	&SQL(Update SQLUser.CT_LockSchedule set CT_ActiveFlag=:CTActiveFlag,CT_LastUpdateDate=:LastUpdateDate,CT_LastUpdatTime=:LastUpdateTime where CT_LSRowID=:CTLSRowId)
	if SQLCODE {
		Q "-100"
	}
}

/// Creator    ：陶越强
/// CreatDate  ：2017.06.15
/// Description: 医保实时挂号异常订单存储
/// Table      : DHCOPAdm_INAB
/// Input      :异常订单信息串：病人ID^就诊ID^医保指针^操作人^订单状态^排班ID^是否挂号
/// Output     :存储成功标志:0:成功
/// d ##class(web.DHCOPAdmReg).SaveDHCOPAdmINAB(1_"^"_""_"^"_"549"_"^"_7_"^"_"N"_"^"_"45||54"_"^"_"Y"_"^"_1)
ClassMethod SaveDHCOPAdmINAB(InfoStr As %String) As %String
{
	s ^Temp("SaveDHCOPAdmINAB")=InfoStr
	q:InfoStr=""
	;s InfoStr=1_"^"_""_"^"_"549"_"^"_7_"^"_"N"_"^"_"45||54"_"^"_"Y"_"^"_1
	s PatientDr=$p(InfoStr,"^",1)
	s EpisodeId=$p(InfoStr,"^",2)
	s InsuAdmDr=$p(InfoStr,"^",3)
	s UserDr=$p(InfoStr,"^",4)
	s BornDate=..%SysDate()                                   ;产生日期
	s BornTime=..%SysTime()                          ;产生时间
	s DealUserDr=""                                  ;处理人
	s DealDate=""                                    ;处理日期
	s DealTime=""                                    ;处理时间
	s RecptStatus=$p(InfoStr,"^",5)	
	s ASRowId=$p(InfoStr,"^",6)
	s IsOPRegist=$p(InfoStr,"^",7)
	s AdmReasonId=$p(InfoStr,"^",8)
	
	i IsOPRegist="N" s ASRowId=$List(^User.DHCRegistrationFeeD(1),18)	
	s ResRowId=+ASRowId
	s AdmDepDr=$P($G(^RB("RES",ResRowId)),"^",1)
	s AdmDocDr=$P($G(^RB("RES",ResRowId)),"^",2)
	
	s object=##class(User.DHCOPAdmINAB).%New()
	d object.INABPatientDrSetObjectId(PatientDr)
	d object.INABPAADMDrSetObjectId(PatientDr)
	s object.INABADMRowid=InsuAdmDr
	d object.INABUserDrSetObjectId(UserDr)
	s object.INABDate=BornDate
	s object.INABTime=BornTime
	d object.INABDealUserDrSetObjectId(DealUserDr)
	s object.INABDealDate=DealDate
	s object.INABDealTime=DealTime
	s object.INABRecptStatus=RecptStatus
	d object.INABDepDrSetObjectId(AdmDepDr)
	d object.INABDocDrSetObjectId(AdmDocDr)
	d object.INABASRowIdSetObjectId(ASRowId)
	s object.INABComeFrom=IsOPRegist
	d object.INABAdmReasonDRSetObjectId(AdmReasonId)
	
	Set sc = object.%Save()
	If $$$ISERR(sc) {
		Do $System.Status.DisplayError()
		Q "-100" 
	}
	s INABRowId=object.%Id()
	q INABRowId
}

/// w ##class(web.DHCOPAdmReg).GetDepRowIdByASRowId
ClassMethod GetDepRowIdByASRowId(ASRowId As %String) As %String
{
	q:ASRowId="" ""
	s ResRowid=+ASRowId
	s DepRowId=$p($g(^RB("RES",ResRowid)),"^",1)
	q DepRowId
}

Query DHCOPINAB(PatientNO As %String, UserId As %String, StartDate As %Date, EndDate As %Date) As %Query(ROWSPEC = "TabAdmDepDesc:%String,TabAdmDocDesc:%String,TabPatientNo:%String,TabPatientName:%String,TabUserName:%String,TabBornDate:%String,TabBornTime:%String,TabInsuAccount:%String,TabRecptStatusDesc:%String,TabIsOPRegist:%String,INABUserDr:%String,InsuAdmRowid:%String,PatientId:%String,ASRowId:%String,AdmReasonId:%String,AdmReasonDesc:%String,INABRowID:%String")
{
}

ClassMethod DHCOPINABClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = DHCOPINABExecute ]
{
	Set repid=$LIST(qHandle,2)
    Kill ^CacheTemp(repid)
    Quit $$$OK
}

ClassMethod DHCOPINABExecute(ByRef qHandle As %Binary, PatientNO As %String, UserId As %String, StartDate As %Date, EndDate As %Date) As %Status
{
	;d ##class(%ResultSet).RunQuery("web.DHCOPAdmReg","DHCOPINAB","0000000018","","","")
	s ^Temp("DHCOPINAB")=PatientNO_","_UserId_","_StartDate_","_EndDate
	Set repid=$I(^CacheTemp)
	If $g(ind)="" Set ind=1
    i PatientNO="" {
	    Set qHandle=$lb(0,repid,0)
	    Quit $$$OK
	}
    s PatientId=0 f  s PatientId=$o(^PAPERi("PAPMI_PatNo",PatientNO,PatientId)) q:PatientId=""  d
    .s INABRowID=0 f  s INABRowID=$o(^INABi("PatientDr",PatientId,INABRowID)) q:INABRowID=""  d
    ..s (TabAdmDepDesc,TabAdmDocDesc,TabPatientNo,TabPatientName,TabUserName,TabBornDate,TabBornTime,TabInsuAccount,TabRecptStatusDesc,TabIsOPRegist,INABUserDr,InsuAdmRowid,ASRowId,AdmReasonId,AdmReasonDesc)=""
	..s INABUserDr=$p($g(^INAB(INABRowID)),"^",4)
    ..s BornDate=$p($g(^INAB(INABRowID)),"^",5)
    ..s INABRecptStatus=$p($g(^INAB(INABRowID)),"^",10)
    ..q:(UserId'="")&&(UserId'=INABUserDr)
    ..q:(StartDate'="")&&(StartDate>BornDate)  
    ..q:(EndDate'="")&&(EndDate<BornDate)
    ..q:INABRecptStatus="Y"
    ..s BornTime=$p($g(^INAB(INABRowID)),"^",6)
    ..s TabUserName=$p($g(^SSU("SSUSR",INABUserDr)),"^",2)
    ..s TabBornDate=$zd(BornDate,4)
    ..s TabBornTime=..%ZT(BornTime,3)
    ..s TabPatientName=$p($g(^PAPER(PatientId,"ALL")),"^",1)
    ..s TabPatientNo=$P($G(^PAPER(PatientId,"PAT",1)),"^",1)
    ..s PAAdmDr=$p($g(^INAB(INABRowID)),"^",2)
    ..s InsuAdmRowid=$p($g(^INAB(INABRowID)),"^",3)
    ..s ASRowId=$p($g(^INAB(INABRowID)),"^",13)
    ..s ComeFrom=$p($g(^INAB(INABRowID)),"^",14)
    ..i ComeFrom="Y" s TabIsOPRegist="是"
    ..e  s TabIsOPRegist="否"
    ..s AdmDepDr=$p($g(^INAB(INABRowID)),"^",11)
    ..s TabAdmDepDesc=$p($g(^CTLOC(AdmDepDr)),2)  
    ..s:TabAdmDepDesc'="" TabAdmDepDesc=$p(TabAdmDepDesc,"^",2)
    ..s AdmDocDr=$p($g(^INAB(INABRowID)),"^",12)
    ..s TabAdmDocDesc=$p($g(^CTPCP(AdmDocDr,1)),"^",2)
    ..i INABRecptStatus="Y" s TabRecptStatusDesc="已处理"
    ..e  s TabRecptStatusDesc="未处理"
    ..s TabInsuAccount=""
    ..s TabInsuAccount=$p($g(^DHCINADM(InsuAdmRowid)),"^",9)
    ..s:TabInsuAccount'="" TabInsuAccount=TabInsuAccount_"元"
    ..s AdmReasonId=$p($g(^INAB(INABRowID)),"^",15)
    ..s:AdmReasonId'="" AdmReasonDesc=$p($g(^PAC("ADMREA",AdmReasonId)),"^",2)
	..Do OutputRow
	
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK

OutputRow
	set Data=$lb(TabAdmDepDesc,TabAdmDocDesc,TabPatientNo,TabPatientName,TabUserName,TabBornDate,TabBornTime,TabInsuAccount,TabRecptStatusDesc,TabIsOPRegist,INABUserDr,InsuAdmRowid,PatientId,ASRowId,AdmReasonId,AdmReasonDesc,INABRowID)
	Set ^CacheTemp(repid,ind)=Data
	Set ind=ind+1
	quit
	
ResetVariables1
	///set (repid)=0 ,Admdoccode,admdoc,Username,AdmTime
	set (TabAdmDepDesc,TabAdmDocDesc,TabPatientNo,TabPatientName,TabUserName,TabBornDate,TabBornTime,TabInsuAccount,TabRecptStatusDesc,TabIsOPRegist,INABUserDr,InsuAdmRowid,PatientId,ASRowId,AdmReasonId,AdmReasonDesc)=""
	quit
}

ClassMethod DHCOPINABFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = DHCOPINABExecute ]
{
 Set AtEnd=$LIST(qHandle,1)
 Set repid=$LIST(qHandle,2)
 Set ind=$LIST(qHandle,3)
	//
 Set ind=$o(^CacheTemp(repid,ind))
 If ind="" {				// if there are no more rows, finish fetching
 Set AtEnd=1
 Set Row=""
 }
 Else      {				// fetch row
 Set Row=^CacheTemp(repid,ind)
 }
 // Save QHandle
 s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

ClassMethod FindInvUsrExecute(ByRef qHandle As %Binary, ChargeUser As %String = "") As %Status
{
	s ^Temp("FindInvUsr")=ChargeUser
	// d ##class(%ResultSet).RunQuery("web.udhcOPQUERYExp","FindInvUsr","收费")
	Set repid=$I(^CacheTemp)
	s ind=1
	s Usercode="",UserDesc=""
	if ChargeUser'="" d
	.s Usercode=ChargeUser
	.s len=$l(ChargeUser)
	.for i=1:1:len d
	..s fir=$Ascii($e(ChargeUser,i))
	..i (fir<48)||(fir>57) d
	...s UserDesc=ChargeUser
	...s Usercode=""

	s usr=""
	f  s usr=$o(^DHCINVPRT(0,"User",usr))  q:usr=""   d
	.q:'$d(^SSU("SSUSR",usr))
	.s code=$p(^SSU("SSUSR",usr),"^",1)
	.s name=$p(^SSU("SSUSR",usr),"^",2)
	.q:(Usercode'="")&&(code'=Usercode)
	.q:(UserDesc'="")&&(name'[UserDesc)
	.Do OutputRow1
	/*s usr=""
	f  s usr=$o(^DHCINVPRTAPi(0,"UseDR",usr))  q:usr=""   d
	.q:'$d(^SSU("SSUSR",usr))
	.s code=$p(^SSU("SSUSR",usr),"^",1)
	.s name=$p(^SSU("SSUSR",usr),"^",2)
	.q:(Usercode'="")&&(code'=Usercode)
	.q:(UserDesc'="")&&(name'[UserDesc)
	.Do OutputRow1
    */
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
OutputRow1
	set Data=$lb(code,name,usr)
	Set ^CacheTemp(repid,ind)=Data
	Set ind=ind+1
	quit
}

ClassMethod FindInvUsrFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = FindInvUsrExecute ]
{
	Set AtEnd=$LIST(qHandle,1)
    Set repid=$LIST(qHandle,2)
    Set ind=$LIST(qHandle,3)
    Set ind=$o(^CacheTemp(repid,ind))
	If ind="" {				// if there are no more rows, finish fetching
       Set AtEnd=1
	   Set Row=""
    }Else{Set Row=^CacheTemp(repid,ind)}
    s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

ClassMethod FindInvUsrClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = FindInvUsrExecute ]
{
	Set repid=$LIST(qHandle,2)
 Kill ^CacheTemp(repid)
	Quit $$$OK
}

Query FindInvUsr(ChargeUser As %String) As %Query(ROWSPEC = "UsrCode:%String,UsrName:%String,UsrID:%String")
{
}

/// tanjishan 2020-09-09
/// 获取存在可用账户的卡号列表
/// w ##Class(web.DHCOPAdmReg).GetValidAccMNoCardNoJson(57)
ClassMethod GetValidAccMNoCardNoJson(PatientID As %String) As %String
{
	set AccMNoNum=0
	k CardNoArr,AccMNoList
	set CardRowid=""
	for {
		s CardRowid=$o(^DHCCARDi("CF",0,"PAPMIDR",PatientID,CardRowid))
		q:(CardRowid="")
		s ActiveFlag=$P(^DHCCARD("CF",CardRowid),"^",10) 
		Continue:ActiveFlag'="N"
		s AccMNo=$P(^DHCCARD("CF",CardRowid),"^",1) 
		Continue:AccMNo=""
		s AccMAccStatus=$p($g(^DHCACD("AccM",AccMNo)),"^",13)
		Continue:AccMAccStatus'="N"
		s CardNo=$P(^DHCCARD("CF",CardRowid),"^",2)       //卡号
		s CardType=$P(^DHCCARD("CF",CardRowid),"^",16)
		s CardTypeConfig=$g(^DHCCARDTYPEDef(CardType))
		if ('$D(AccMNoList(AccMNo))){
			s AccMNoNum=AccMNoNum+1
		}
		s Index=$I(AccMNoList(AccMNo))
		s CardNoArr(AccMNoNum,"AccMInfo")=AccMNo
		s CardNoArr(AccMNoNum,"CardInfo",Index,"CardNo")=CardNo
		s CardNoArr(AccMNoNum,"CardInfo",Index,"CardType")=CardType
		s CardNoArr(AccMNoNum,"CardInfo",Index,"CardTypeConfig")=CardTypeConfig
	}
	s CardNoJson=##Class(DHCDoc.Util.FromJSON).GetArrJson(.CardNoArr)
	
	q CardNoJson
}

ClassMethod GetValidAccMNoCardNo(PatientID As %String) As %String
{
	set CardNo="",CardType="",CardTypeConfig=""
	set CardRowid=""
	f  s CardRowid=$o(^DHCCARDi("CF",0,"PAPMIDR",PatientID,CardRowid)) q:(CardRowid="")||(CardNo'="")  d
	.s ActiveFlag=$P(^DHCCARD("CF",CardRowid),"^",10) 
	.q:ActiveFlag'="N"
	.s AccMNo=$P(^DHCCARD("CF",CardRowid),"^",1) 
	.q:AccMNo=""
	.s AccMAccStatus=$p($g(^DHCACD("AccM",AccMNo)),"^",13)
	.q:AccMAccStatus'="N"
	.s CardNo=$P(^DHCCARD("CF",CardRowid),"^",2)       //卡号
	.s CardType=$P(^DHCCARD("CF",CardRowid),"^",16)
	.s CardTypeConfig=$g(^DHCCARDTYPEDef(CardType))
	Q CardNo_"^"_CardType_"^"_CardTypeConfig
}

ClassMethod GetCardBillCardTypeValue(PatientID As %String) As %String
{
	s PatDefCardInfo=##class(web.DHCOPAdmReg).GetValidAccMNoCardNo(PatientID)
    s CardBillCardTypeValue=$p(PatDefCardInfo,"^",2,$l(PatDefCardInfo,"^"))
    q CardBillCardTypeValue
}

ClassMethod GetAccmLeftBalance(AccRowId As %String) As %String
{
	q:AccRowId="" ""
	s AccmLeftBalance=$p($g(^DHCACD("AccM",AccRowId)),"^",8)
	q AccmLeftBalance
}

/// 原号重打
ClassMethod OldRegRePrintBroker(itmjs As %Library.String = "", itmjsex As %Library.String = "", RegFeeRowId As %String, UserRowId As %String, GroupRowId As %String, LogonLocRowId As %String)
{
	;w ##class(web.DHCOPAdmReg).RePrintBroker("","",256,5,93,2)
	s ^tmpzhou("RePrint")=RegFeeRowId_","_UserRowId_","_GroupRowId_","_LogonLocRowId
	s PrintData=""
	s InvoiceId=$List(^User.DHCRegistrationFeeD(RegFeeRowId),11)
	s ret="0"
	i InvoiceId="" {
		s ret="-300"
		s PrintData=""
	}else{
		s InvUserRowId=$P($g(^DHCINVPRT(InvoiceId)),"^",21)
		s InvHandin=$P($g(^DHCINVPRT(InvoiceId)),"^",10)
		if (InvHandin="Y")||(InvUserRowId'=UserRowId){
			Q "-200"
		}
		s PrintData=..GetPrintData(RegFeeRowId,"","Y")	
	}
	s ret=ret_"$"_PrintData
	Q ret
}

/// 		TypeFlag="DEP" 预交金
/// 		TypeFlag="FEE" 收费	--默认
/// 		TypeFlag="REG" 挂号
/// 		TypeFlag="REF" 退费
ClassMethod ReadGSPMListBroker(JSFunName As %String, ListName As %String, GPRowID As %String = "", TypeFlag As %String = "", PayModeID As %String = "") As %String
{
	//n (JSFunName,ListName,GPRowID,TypeFlag)
	s rtn=0,PayModeStr=""
	;w ##class(web.DHCOPAdmReg).ReadGSPMListBroker("GetPayModeToStr","","119")
	q:(GPRowID="") 100
	s myGSRowID=""
	;^DHCOPGSi("GS",0,"GSDR",{GS_SSGroup_DR},{GS_RowID})
	s myGSRowID=$o(^DHCOPGSi("GS",0,"GSDR",GPRowID,0))     ;;myGSRowID
	
	q:(myGSRowID="") 100
	
	;s rtn=##class(%ResultSet).RunQuery("web.UDHCOPGSConfig","ReadPMConfig","90")
	s json="["
	Set rset = ##class(%ResultSet).%New("web.UDHCOPGSConfig:ReadPMConfig")
	Set columns = rset.GetColumnCount()
	// Execute the query
	Set rs = rset.Execute(GPRowID)
	s myIdx=0
	
	While (rset.Next()) {
	 	s myRowVal=""
		;CTPMRowID, CTPMCode, CTPMDesc, PMRowID, DefFlag, RPFlag, INVPrtFlag
	 	;CTPMRowID^RPFlag^CTPMCode^INVPrtFlag
	 	;PMPDFlag:%String,PMOPCFlag:%String,PMOPRegFlag:%String,PMOPRefundFlag
	 	s myTypeFlag=""
		s:TypeFlag="DEP" myTypeFlag=$g(rset.Data("PMPDFlag"))	;预交金
		s:TypeFlag="FEE" myTypeFlag=$g(rset.Data("PMOPCFlag"))	;收费
		s:TypeFlag="REG" myTypeFlag=$g(rset.Data("PMOPRegFlag"))	;挂号
		s:TypeFlag="REF" myTypeFlag=$g(rset.Data("PMOPRefundFlag"))	;退费
	 	s:myTypeFlag="" myTypeFlag=$g(rset.Data("PMOPCFlag"))	;收费	--默认
	 	continue:(PayModeID'="")&&(PayModeID'=rset.Data("CTPMRowID"))
		;i (($g(rset.Data("PMRowID"))'="")&&($g(rset.Data("PMOPCFlag"))="Y")){
		i (($g(rset.Data("PMRowID"))'="")&&(myTypeFlag="Y")){
			s myRowVal=$g(rset.Data("CTPMRowID"))
			s mydes=rset.Data("CTPMDesc")
			s myval=myRowVal
			s myRowVal=##class(web.UDHCOPGSConfig).YNLogicToHTML($g(rset.Data("RPFlag")))
			s myval=myval_"^"_myRowVal
			s myRowVal=($g(rset.Data("CTPMCode")))
			s myval=myval_"^"_myRowVal
			s myRowVal=##class(web.UDHCOPGSConfig).YNLogicToHTML($g(rset.Data("INVPrtFlag")))
			s myval=myval_"^"_myRowVal
			s mySelFlag=0
			i ($g(rset.Data("DefFlag"))="Y") d
			.s mySelFlag=1
			if (JSFunName="GetPayModeToHUIJson") {
				s OneJsonData="{""text"":"""_$g(mydes)_""",""id"":"""_$g(myval)_""""
				i mySelFlag=1 s OneJsonData=OneJsonData_",""selected"":true"
				s OneJsonData=OneJsonData_"}"
				i myIdx=0 {
					s json=json_OneJsonData
				}else{
					s json=json_","_OneJsonData
				}
			}elseif(JSFunName="GetPayModeToStr"){
				/*
					空 或 支付方式Rowid^支付方式Code^支付方式Desc$c(2)支付方式Rowid^支付方式Code^支付方式Desc
				*/
				i PayModeStr="" s PayModeStr=$g(rset.Data("CTPMRowID"))_"^"_($g(rset.Data("CTPMCode")))_"^"_mydes
				else  s PayModeStr=PayModeStr_$C(2)_$g(rset.Data("CTPMRowID"))_"^"_($g(rset.Data("CTPMCode")))_"^"_mydes
			}else{
				s rtnval=JSFunName_"('"_ListName_"','"_$ZCVT($g(mydes),"O","JS")_"','"_$ZCVT($g(myval),"O","JS")_"','"_$ZCVT($g(myIdx),"O","JS")
				s rtnval=rtnval_"','"_$ZCVT(mySelFlag,"O","JS")_"');"
				&javascript<#(rtnval)#>
			}
			s myIdx=myIdx+1
	 	}
	}
	d rset.Close()
	s json=json_"]"    
	if (JSFunName="GetPayModeToHUIJson"){
		q json
	}
	Q:JSFunName="GetPayModeToStr" PayModeStr
	q 0
}

// w ##class(web.DHCOPAdmReg).GetDeptTreeList()

ClassMethod GetDeptTreeList() As %String
{
	s LogonHospId=%session.Get("LOGON.HOSPID")
    s langid = ..%LanguageID()
	w "["
	s LocmjId=0,index1=0
	for {
		Set LocmjId=$O(^DHCCTLoc(LocmjId)) q:LocmjId=""
		Set DepId=LocmjId
		Set DepCode=$p($g(^DHCCTLoc(LocmjId)),"^",2)
		Set DepDesc=$p($g(^DHCCTLoc(LocmjId)),"^",1)
        Set:$g(DepDesc)'="" DepDesc = ##class(User.DHCCTLocMajor).GetTranByDesc("CTLMJName",DepDesc,langid)
		Set HospDr=$p(^DHCCTLoc(LocmjId),"^",5)
     	Continue:(LogonHospId'="")&&(LogonHospId'=HospDr)
		Set StartDate=$p($g(^DHCCTLoc(LocmjId)),"^",3)
		Set EndDate=$p($g(^DHCCTLoc(LocmjId)),"^",4)
		Continue:(StartDate'="")&(StartDate>+$H)
		Continue:(EndDate'="")&(EndDate<+$H)
		Set DepartmentGroup=""
        &sql(select count(*) into :DepartmentGroup from SQLUser.DHC_CTLoc_Minor where CTLMN_ParRef=:LocmjId and CTLMN_ChildSub<>0 and CTLMN_IsActive<>0 and  CTLMN_CTLocDR->CTLOC_Hospital_DR=:LogonHospId)
		Continue:+DepartmentGroup<1
		s MajorCTLocSort=9999 
		s MajorCTLocSortType=##class(web.DHCOPRegConfig).GetSpecConfigNode("MajorCTLocSort",LogonHospId)
		if MajorCTLocSortType'="" d
		.s MajorCTLocSort=##class(web.DHCBL.BDP.BDPSort).GetSortNum("User.DHCCTLocMajor",MajorCTLocSortType,LocmjId)
		.if (MajorCTLocSort="") s MajorCTLocSort=9999
		s index1=index1+1
		s DeptTreeListArry(MajorCTLocSort,index1)=LocmjId_"^"_DepDesc_"^"_DepCode
		s CTMLNRowid=0
		s index2=0
		for {
			Set CTMLNRowid=$O(^DHCCTLoc(LocmjId,"MINOR",CTMLNRowid)) q:CTMLNRowid=""
			Set CTLMNCTLocDR=$p($g(^DHCCTLoc(LocmjId,"MINOR",CTMLNRowid)),"^",1)
			Set DepartmentName=""
			if CTLMNCTLocDR'="" Set DepartmentName=$p($g(^CTLOC(CTLMNCTLocDR)),"^",2)
            Set:$g(DepartmentName)'="" DepartmentName = ##class(User.CTLoc).GetTranByDesc("CTLOCDesc",DepartmentName,langid)
			Set CTLMNIsActive=$p($g(^DHCCTLoc(LocmjId,"MINOR",CTMLNRowid)),"^",2)
			Continue:CTLMNIsActive'=1
			Set HospId=$p(^CTLOC(CTLMNCTLocDR),"^",22)
			continue:HospId'=LogonHospId
			s DepCode=$p($g(^CTLOC(CTLMNCTLocDR)),"^",43)
			continue:($P(^CTLOC(CTLMNCTLocDR),"^",14)'="Y")
			s MinorCTLocSort=9999 
			s MinorCTLocSortType=##class(web.DHCOPRegConfig).GetSpecConfigNode("MinorCTLocSort"_LocmjId,LogonHospId)
			if MinorCTLocSortType'="" d
			.s MinorCTLocSort=##class(web.DHCBL.BDP.BDPSort).GetSortNum("User.DHCCTLocMinor",MinorCTLocSortType,LocmjId_"||"_CTMLNRowid)
			.if (MinorCTLocSort="") s MinorCTLocSort=9999
			s index2=index2+1
			s DeptTreeListArry(MajorCTLocSort,index1,MinorCTLocSort,index2)=CTLMNCTLocDR_"^"_DepartmentName_"^"_DepCode
		}
	}
	s index1=0
	s MajorCTLocSort=""
	for{
		s MajorCTLocSort=$O(DeptTreeListArry(MajorCTLocSort))
		q:MajorCTLocSort=""
		s ind=""
		for{
			s ind=$O(DeptTreeListArry(MajorCTLocSort,ind))
			q:ind=""
			s LocmjId=$P(DeptTreeListArry(MajorCTLocSort,ind),"^",1)
			s DepDesc=$P(DeptTreeListArry(MajorCTLocSort,ind),"^",2)
			s DepCode=$P(DeptTreeListArry(MajorCTLocSort,ind),"^",3)
			s index1=index1+1
			if (index1>1) w ",{"
			e  w "{"
			w """id"":"""_LocmjId_"-"_index1_""","
			w """text"":"""_DepDesc_""","
			w """attributes"":{""code"":"""_DepCode_"""},"
			w """children"":"_"["
			s index2=0
			s MinorCTLocSort=0
			for {
				s MinorCTLocSort=$O(DeptTreeListArry(MajorCTLocSort,ind,MinorCTLocSort))
				q:MinorCTLocSort=""
				s ind2=""
				for{
					s ind2=$O(DeptTreeListArry(MajorCTLocSort,ind,MinorCTLocSort,ind2))
					q:ind2=""
					s CTLMNCTLocDR=$P(DeptTreeListArry(MajorCTLocSort,ind,MinorCTLocSort,ind2),"^",1)
					s DepartmentName=$P(DeptTreeListArry(MajorCTLocSort,ind,MinorCTLocSort,ind2),"^",2)
					s DepCode=$P(DeptTreeListArry(MajorCTLocSort,ind,MinorCTLocSort,ind2),"^",3)
					s index2=index2+1
					if (index2>1) w ",{"
					else  w "{"
					w """id"":"""_CTLMNCTLocDR_""","
					w """text"":"""_DepartmentName_""","
					w """attributes"":{""code"":"""_DepCode_"""}"
					w "}"
				}
			}
			w "]}"
		}
	}
	/*for {
		Set LocmjId=$O(^DHCCTLoc(LocmjId)) q:LocmjId=""
		Set DepId=LocmjId
		Set DepCode=$p($g(^DHCCTLoc(LocmjId)),"^",2)
		Set DepDesc=$p($g(^DHCCTLoc(LocmjId)),"^",1)
		Set HospDr=$p(^DHCCTLoc(LocmjId),"^",5)
     	Continue:(LogonHospId'="")&&(LogonHospId'=HospDr)
		Set StartDate=$p($g(^DHCCTLoc(LocmjId)),"^",3)
		Set EndDate=$p($g(^DHCCTLoc(LocmjId)),"^",4)
		Continue:(StartDate'="")&(StartDate>+$H)
		Continue:(EndDate'="")&(EndDate<+$H)
		Set DepartmentGroup=""
        &sql(select count(*) into :DepartmentGroup from SQLUser.DHC_CTLoc_Minor where CTLMN_ParRef=:LocmjId and CTLMN_ChildSub<>0 and CTLMN_IsActive<>0 and  CTLMN_CTLocDR->CTLOC_Hospital_DR=:LogonHospId)
		Continue:+DepartmentGroup<1
		s index1=index1+1
		if (index1>1) w ",{"
		e  w "{"
		w """id"":"""_LocmjId_"-"_index1_""","
		w """text"":"""_DepDesc_""","
		w """attributes"":{""code"":"""_DepCode_"""},"
		w """children"":"_"["
		s index2=0
		s CTMLNRowid=0
		for {
			Set CTMLNRowid=$O(^DHCCTLoc(LocmjId,"MINOR",CTMLNRowid)) q:CTMLNRowid=""
			Set CTLMNCTLocDR=$p($g(^DHCCTLoc(LocmjId,"MINOR",CTMLNRowid)),"^",1)
			Set DepartmentName=""
			if CTLMNCTLocDR'="" Set DepartmentName=$p($g(^CTLOC(CTLMNCTLocDR)),"^",2)
			Set CTLMNIsActive=$p($g(^DHCCTLoc(LocmjId,"MINOR",CTMLNRowid)),"^",2)
			Continue:CTLMNIsActive'=1
			Set HospId=$p(^CTLOC(CTLMNCTLocDR),"^",22)
			continue:HospId'=LogonHospId
			s DepCode=$p($g(^CTLOC(CTLMNCTLocDR)),"^",43)
			s index2=index2+1
			if (index2>1) w ",{"
			else  w "{"
			w """id"":"""_CTLMNCTLocDR_""","
			w """text"":"""_DepartmentName_""","
			w """attributes"":{""code"":"""_DepCode_"""}"
			w "}"
		}
		w "]}"
	}*/
	q "]"
}

/// w ##class(web.DHCOPAdmReg).SetOEOrdLookup
ClassMethod SetOEOrdLookup(input As %String)
{
	i $o(^Temp("SetOEOrdLookup",0))="" s index=1
	e  s index=+$o(^Temp("SetOEOrdLookup",""),-1)+1
	s ^Temp("SetOEOrdLookup",index)=input_","_..%SysTime()
	
	q 0
}

/// 得到公共卡号和登记号
ClassMethod GetCommonCardNoandPatientNo(ChoseCommonCardNo As %String = "", CardTypeDR As %String = "") As %String
{
	//判断是否有公共卡
	Set langid=..%LanguageID()
	s CommonStr=""
	s CommonCardNoStr=##class(web.DHCOPRegConfig).GetSpecConfigNode("CommonCardNo")
	i (CommonCardNoStr'="") {
		s CardStrLong=$L(CommonCardNoStr,"&")
		for i=1:1:CardStrLong{
			s CommonCardNo=$P(CommonCardNoStr,"&",i)
			continue:CommonCardNo=""
			continue:((ChoseCommonCardNo'="")&&(ChoseCommonCardNo'=CommonCardNo))
			s ExpStr=""_$c(2)_""_$C(2)_"PatInfo"
			if ((ChoseCommonCardNo'="")&&($l(ChoseCommonCardNo,"&")=1)&&(CardTypeDR'="")) {
				s ExpStr=""_$c(2)_CardTypeDR_$C(2)_"PatInfo"
			}
			s ret=##class(web.UDHCAccManageCLSIF).getaccinfofromcardno(CommonCardNo,"",ExpStr)
			s retcode=$P(ret,"^",1)
			if (retcode="-201")!(retcode="0"){
				s CommonPatientNo=$P(ret,"^",9)
				s CommonCardRowID=$P(ret,"^",13)
				continue:CommonCardRowID=""
				s CommonCardType=$p(^DHCCARDTYPEDef(CommonCardRowID),"^",2)
				Set CommonCardType= ##class(User.DHCCardTypeDef).GetTranByDesc("CTDDesc",CommonCardType,langid)
				s CommonStr=CommonCardNo_"^"_CommonPatientNo_"^"_CommonCardType
			}
			q:CommonStr'=""
		}
	}
	Q CommonStr
}

/// 判断挂号是否打印过发票和是否集中打印过发票
/// w ##class(web.DHCOPAdmReg).CheckforCancleINvPrt(258)
ClassMethod CheckforCancleINvPrt(EpisodeID As %String = "") As %String
{
	Q:EpisodeID="" ""
	s RegfeeRowId=$O(^User.DHCRegistrationFeeI("ADM",EpisodeID,0))
 	Q:RegfeeRowId="" ""
	s InvoiceId=$List(^User.DHCRegistrationFeeD(RegfeeRowId),11)
	s rtn=""
	if (InvoiceId'=""){
		b ;09334
		S PRTinv =$P($G(^DHCINVPRT(InvoiceId)),"^",14)
		if (PRTinv'="") s rtn=2
		S ACCPINVDR=$P($G(^DHCINVPRT(InvoiceId)),"^",4)
		if (ACCPINVDR'="") s rtn=3
		}
	q rtn
}

/// 得到本周，下周，上周的日期
/// w ##class(web.DHCOPAdmReg).GetnextWeekDate("29/10/2018","Before")
ClassMethod GetnextWeekDate(AppDate, Type)
{
	q:AppDate=""||Type="" ""
	Set AdmDate=..%ZDH(AppDate)
	set Today=..%SysDate()+1
	if (Type="Now"){
		s limit=$zd(Today,10)
		s now=Today
		s NewtNow=Today+7-limit
	}elseif(Type="Next"){
		s limit=$zd(AdmDate,10)
		s now=AdmDate+8-limit
		s NewtNow=now+7
	}elseif(Type="Before"){
		s limit=$zd(AdmDate,10)
		if (limit=0) s limit=7
		s NewtNow=AdmDate-limit
		s now=NewtNow-6
		if (now<Today) {
			s now=Today
			s limit=$zd(Today,10)
			s NewtNow=Today+7-limit
		}
	} 
	s textdate=..%ZD(now)
	q textdate_"^"_now_"^"_NewtNow
}

/// 退号如果没有打印发票，则需要先打印发票
/// w ##class(web.DHCOPAdmReg).CheckforCanclePrint(313)
ClassMethod CheckforCanclePrint(adm As %String, HospRowId As %String = "")
{
	q:adm="" ""
	//挂号设置->退号需打印发票
	s CancelRegNeedINVPrt=##class(web.DHCOPRegConfig).GetSpecConfigNode("CancelRegNeedINVPrt",HospRowId)
	Q:CancelRegNeedINVPrt'=1 ""
	s rtn=""
	s RegFeeID=$O(^User.DHCRegistrationFeeI("ADM",adm,0))
	if (RegFeeID'=""){
		s InvoiceId=$List(^User.DHCRegistrationFeeD(RegFeeID),11)
		s OldInv=""
		i InvoiceId'="" s OldInv=$p($g(^DHCINVPRT(InvoiceId)),"^",29)
		;判断打印情况,只判断第一次发票情况
		if OldInv'="" s InvoiceId=OldInv
		;未打印发票不允许退号,增加集中打印发票限制
		if InvoiceId'="" {
			//挂号设置->无费用不走发票
			s CFNotNeedNotFeeBill=##class(web.DHCOPRegConfig).GetSpecConfigNode("NotNeedNotFeeBill",HospRowId)
			s PRTAcount=$P($G(^DHCINVPRT(InvoiceId)),"^",1)
			Q:(PRTAcount=0)&&(CFNotNeedNotFeeBill=1) rtn
			//s InvNo=$p($g(^DHCINVPRT(InvoiceId)),"^",14)
			//if (InvNo'=""){
				s ACCPINVDR=$P($G(^DHCINVPRT(InvoiceId)),"^",4)
				s InvPrtFlag=$P($g(^DHCINVPRT(InvoiceId)),"^",3)
				if (ACCPINVDR'=""){
					s ACCPINVPrtFlag=$P($G(^DHCINVPRTAP(ACCPINVDR)),"^",2)
					if (ACCPINVPrtFlag'="N"){
						s find=1
						s rtn="不可退号,请先集中打印发票"
					}
				}else{
					if (InvPrtFlag'="P"){
						s find=1
						s rtn="不可退号,发票未打印"
					}
				}
			//}
		}
	}
	Q rtn
}

/// Creator:      宋春莉
/// CreatDate:    2019.02.21
/// Description:  获取挂号凭条所有打印信息
/// Table:        
/// Input:        AdmId:就诊RowId
/// Return:      
/// Others:       w ##class(web.DHCOPAdmReg).GetPrintDataJson(AdmId) 
ClassMethod GetPrintDataJson(AdmId As %String)
{
	s Admi=AdmId
	s RegfeeRowId=$O(^User.DHCRegistrationFeeI("ADM",Admi,""))
	Q:RegfeeRowId="" ""
	s OPRegPrintData=..GetPrintData(RegfeeRowId)
	s ListTitle="AdmDr^PatName^DepDesc^DocDesc^SessionType^AdmDateStr^TimeRange^SeqNo"
	s ListTitle=ListTitle_"^RoomNo^RoomFloor^UserCode^User^RegDateYear^RegDateMonth^RegDateDay"
	s ListTitle=ListTitle_"^TransactionNo^Total^RegFee^AppFee^OtherFee^ClinicGroupCode^RegTime^RBASDr^ExabMemo"
	s ListTitle=ListTitle_"^InsuPayCash^InsuPayCount^InsuPayFund^InsuPayOverallPlanning^InsuPayOther"
	s ListTitle=ListTitle_"^TotalRMBDX^INVPRTNo^CardNo^Room^AdmReason^Regitems^AccBalance"
	s ListTitle=ListTitle_"^PatNo^TimeRangeInfo^HospitalDesc^PersonPay^YBPay^InMedical^RegfeeRowId"
	s ListTitle=ListTitle_"^EmployeeFunction^OPMedcare^IPMedcare"
	Q ##class(web.DHCAPPJsonCommon).getJsonData(ListTitle,OPRegPrintData)
}

/// Creator:      宋春莉
/// CreatDate:    2019.04.08
/// Description:  获得排班的提示信息
/// Table:        
/// Input:        ResRowId 资源id
/// Return:      
/// Others:       w ##class(web.DHCOPAdmReg).GetAlertInfo("318||7") 
ClassMethod GetAlertInfo(ASRowID As %String)
{
	Q:ASRowID="" ""
    s langid = ..%LanguageID()
	s ResRowId=+ASRowID
	Set DocDr=$p(^RB("RES",ResRowId),"^",2)
	Set DeptDr=$p(^RB("RES",ResRowId),"^",1)
	set ExabInfo=..GetExabInfo(DeptDr,DocDr)
	s ret=""
	if +$p(ExabInfo,"^",4)=0  s ret="未进行分诊区号别对照"
	if +$p(ExabInfo,"^",4)>1  s ret="分诊区号别对照不唯一"
    s:$g(ret)'="" ret = ..%Translate("opadm.reg.hui.csp",ret,langid)
	s RBASStatusCode=""
	s RBASStatusDr=$P(^RBAS(+ASRowID,$P(ASRowID,"||",2),"DHC"),"^",10)
	if RBASStatusDr'="" s RBASStatusCode=$P(^DHCRBCASStatus(RBASStatusDr),"^",1)
	b ;0932
	if (RBASStatusCode="R"){
		s TRRBASRowId=$P(^RBAS(+ASRowID,$P(ASRowID,"||",2),"DHC"),"^",12)
		i (TRRBASRowId'=""){
			s TRDocRowId= $P($G(^RB("RES",+TRRBASRowId)),"^",2)
			s TRDoc=$p($g(^CTPCP(TRDocRowId,1)),"^",2)
            s:$g(TRDoc)'="" TRDoc=##class(User.CTCareProv).GetTranByDesc("CTPCPDesc",TRDoc,langid)
			s ReplaceInfo=..%Translate("opadm.reg.hui.csp","替诊医生:",langid)_TRDoc
			if ret="" s ret=ReplaceInfo
			e  s ret=ret_";"_ReplaceInfo
		}
	}
	Q ret
}

/// Creator:      郭荣勇
/// CreatDate:    2019.04.09
/// Description:  根据科室,号别获取分诊区信息
/// Table:        
/// Input:        DepId 科室id,MarkId 号别id
/// Return:       诊区Id^诊区描述^诊区号别对照Id^同科室同号别对应的诊区数
/// Others:       w ##class(web.DHCOPAdmReg).GetExabInfo(231,22) 
ClassMethod GetExabInfo(DepId As %String, MarkId As %String)
{
	Q:(DepId="")||(MarkId="") ""
	s ExabId="",ExabDesc="",DepmId=""
	s ID=0,Count=0
	f  s ID=$o(^User.DHCDepMarkI("DepmMarkDrIndex",MarkId,ID)) Q:ID=""  d
	.s ExabDr=$lg(^User.DHCDepMarkD(ID),7)
	.s DepmDepDr=$lg(^User.DHCDepMarkD(ID),8)
	.Q:DepmDepDr'=DepId
	.s ActiveFlag=$lg(^User.DHCDepMarkD(ID),5)
	.Q:ActiveFlag'="Y"
	.Q:'$d(^User.DHCExaBoroughD(ExabDr))
	.s ExabId=ExabDr,ExabDesc=$lg(^User.DHCExaBoroughD(ExabId),5),DepmId=ID
	.s Count=Count+1
	
	i Count=1 {
		Q ExabId_"^"_ExabDesc_"^"_DepmId_"^"_Count
	}else{
		Q "^^^"_Count
	}
}

/// Creator:      宋春莉
/// CreatDate:    2019.04.15
/// Description:  根据排班ID获取该科室医保挂号不能实时结算设置
/// Table:        
/// Input:       ASRowId排班ID
/// Return:      1 不能实时结算 0 可以
/// Others:       w ##class(web.DHCOPAdmReg).GetCFLocInsuNotRealTime() 
ClassMethod GetCFLocInsuNotRealTime(ASRowId As %String)
{
	Q:(ASRowId="") 0
	Set DeptDr=$p(^RB("RES",+ASRowId),"^",1)
	s str=$g(^DHCOPRegConfig("OPRegDepExpand",DeptDr))
	Q:str="" 0
	s CFLocInsuNotRealTime=+$p(str,"^",1)
	Q CFLocInsuNotRealTime
}

/// Creator:      屈坚
/// CreatDate:    2019.05.19
/// Description:  根据排班ID和PatientID判断这个排班患者是否有预约记录
/// Table:        
/// Input:       ASRowID，PatientID
/// Return:      1 有 0 没有
/// Others:       w ##class(web.DHCOPAdmReg).CheckPatientAppionment() 
ClassMethod CheckPatientAppionment(ASRowId As %String, PatientID As %String)
{
	Q:((ASRowId="")||(PatientID="")) 0
	s RESRowId=+ASRowId
	s ASChildSub=$P(ASRowId,"||",2)
	s ChildSub=$O(^PAPERDR(PatientID,"RB_Appt","I",RESRowId,ASChildSub,""))
	s rtn=0
	if ChildSub'="" s rtn=1
	q rtn
}

/// 获取卡是否是临时卡以及是否在有效期内
/// create 20190529 by yl
/// input:卡类型id, 卡号
/// output: Y/other ^ DiscDate  other:非临时卡 Y:临时卡 DiscDate>0 不在有效期内
ClassMethod CheckTempCardEffe(CardTypeId As %String, CardNo As %String, HospId As %String = "") As %String
{
	q:(CardTypeId="")!(CardNo="") "0^0"
	s TempCardRegCountLimit=+##class(web.DHCOPRegConfig).GetSpecConfigNode("TempCardRegCountLimit",HospId)
	s IsTempCard=##class(web.DHCBL.CARD.UCardRefInfo).GetTemporaryCardFlag(CardTypeId, CardNo)
	s DiscDate=0
	if (IsTempCard="Y")&&(TempCardRegCountLimit'="") {
		s CreateCardDate=##class(web.DHCBL.CARD.UCardRefInfo).GetCreateCardDate(CardTypeId, CardNo)
		s CreateDate=+CreateCardDate
		s DiscDate=..%SysDate()-TempCardRegCountLimit-CreateDate
	}
	q IsTempCard_"^"_DiscDate
}

/// Creator:      QP
/// CreatDate:    2019.05.30
/// Description:  患者是否在院，或急诊留观
/// Table:        
/// Input:       
/// Return:      1在院，2留观
/// Others:       w ##class(web.DHCOPAdmReg).GetInHospOrStayStatus() 
ClassMethod GetInHospOrStayStatus(PatientID As %String, HospID As %String = "")
{
	s HospID=##Class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospID)
	s mRtn=0
	s PatInIPAdmission=##class(web.DHCDocOrderCommon).CheckPatInIPAdmission(PatientID,HospID)
	s InPatNotAllowOPRegist=##class(web.DHCOPRegConfig).GetSpecConfigNodeHosp("InPatNotAllowOPRegist",HospID)
	if ((PatInIPAdmission=1)&&(InPatNotAllowOPRegist=1)) s mRtn=1 Q mRtn
	s StayStatusFlag=0,PaadmRowId=""
	for {
		s PaadmRowId=$O(^PAPERdr(PatientID,"ADM","E",PaadmRowId)) Q:(PaadmRowId="")||(StayStatusFlag=1)  
		s PatVistiStatus=$p($g(^PAADM(PaadmRowId)),"^",20)
		if (PatVistiStatus'="A") continue // 不是在院病人则退出
		s AdmHospitalId=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(PaadmRowId)
		if (AdmHospitalId'=HospID) continue
		s StayStatusFlag=##class(web.DHCADMVisitStat).GetStayStatus(PaadmRowId)
		if StayStatusFlag=1 s mRtn=2
	}
	Q mRtn
}

/// create 20200116 by yl
/// input: ASRowId（排班id）
/// output:Y(需要), N(不需要)
/// 根据排班id来判断该排班是否需要报到（出诊时段维护的是否需要报到）
ClassMethod CheckCheckinBySched(ASRowId As %String)
{
	s Checkin="N"
	q:ASRowId="" Checkin
	s TimeRangeDr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",17)
	if TimeRangeDr'="" {
		s TRCheckin=$p(^DHCTimeRange(TimeRangeDr),"^",12)
		if TRCheckin="Y" s Checkin=TRCheckin
	}
	q Checkin
}

/// Others:w ##class(web.DHCOPAdmReg).GetPayModeStr(238,1) 
ClassMethod GetPayModeStr(GroupID, PayModeID)
{
	Q:PayModeID="" ""
	s CashPayModeJson=..ReadGSPMListBroker("GetPayModeToHUIJson","",GroupID,"REG",PayModeID)
	d ##Class(DHCDoc.Util.FromJSON).FromJSONToArr(CashPayModeJson,.CashPayModeArr)
	s CashPayModeStr=""
	if $d(CashPayModeArr){
		s CashPayModeStr=CashPayModeArr(1,"id")
	}
	Q CashPayModeStr
}

/// 获取当前就诊记录对应收取的挂号费用
ClassMethod GetAdmRegFeeInfo(Adm As %String, HospID As %String) [ ProcedureBlock = 0 ]
{
	n (Adm,HospID)
	s RegLinkOrdListStr=""
	Set OEORDRowId=$o(^OEORD(0,"Adm",Adm,""))
	s (Reg,Check,MR,Card,ReCheck,App,Holi,Other)=0
	if (OEORDRowId'="") {
		s OEORIChildsub=0
		for {
			s OEORIChildsub=$o(^OEORD(OEORDRowId,"I",OEORIChildsub))
			q:OEORIChildsub=""
			s ARCIMRowId=$p($g(^OEORD(OEORDRowId,"I",OEORIChildsub,1)),"^",2)
			continue:ARCIMRowId=""
			s TOrderStatusDR=$p(^OEORD(OEORDRowId,"I",OEORIChildsub,1),"^",13)
			s:+TOrderStatusDR>0 orderStatCode = $p(^OEC("OSTAT",TOrderStatusDR),"^",1)
			continue:(orderStatCode'="V")&&(orderStatCode'="E")
			s ARCIMServiceGroupDR=$p($g(^ARCIM(+ARCIMRowId,$p(ARCIMRowId,"||",2),8)),"^",7)
			continue:(ARCIMServiceGroupDR'=##class(web.DHCOPRegConfig).GetSpecConfigNode("RegServiceGroup",HospID)) //如果医嘱项服务组不是挂号设置-》挂号服务组，则退出
			s RegSerBillSubType=..GetRegArcimBillSubType(ARCIMRowId,HospID)
			s retPrice=##Class(web.DHCDocOrderCommon).GetOEORIPrice(OEORDRowId_"||"_OEORIChildsub)
			s OrderPrice=$P(retPrice,"^",1)
			if (RegSerBillSubType="NotRegFee"){
				s Other=Other+OrderPrice
			}else{
				s Str=RegSerBillSubType_"="_RegSerBillSubType_"+"_OrderPrice
				s @Str
			}
		}
	}
	q Reg_"^"_Check_"^"_MR_"^"_Card_"^"_ReCheck_"^"_App_"^"_Holi_"^"_Other
}

/// 保存挂号小条重打记录
ClassMethod SavePrintRecode(Adm, UserID)
{
	q:((Adm="")||(UserID=""))
	s Number=1
	s Date=..%SysDate()
	s Time =..%SysTime()
	&SQL(insert into SQLUser.DHC_DocOPRegPrintRecord(DHCDocOPRegPrintParRef,UserID,PrintDate,PrintTime,Number) 
	Values(:Adm,:UserID,:Date,:Time,:Number) )
	s rtn=SQLCODE
	q rtn
}

/// w ##class(web.DHCOPAdmReg).CheckRegCountLimitStr(14, "2182||76^1724||76",2)
ClassMethod CheckRegCountLimitStr(PatientID As %String, ASRowIdStr As %String, HospitalID As %String = "", APPTRowId As %String = "") As %String
{
    s langid = ..%LanguageID()
	for i=1:1:$L(ASRowIdStr,"^"){
		s ASRowID=$P(ASRowIdStr,"^",i)
		s ResRowId=+ASRowID
		s ASChild=$P(ASRowID,"||",2)
		s ASDate=$P($G(^RBAS(ResRowId,ASChild)),"^",1)
		s APPDoc=$p(^RB("RES",ResRowId),"^",2)
		s ASLoc=$P($G(^RB("RES",ResRowId)),"^",1)
		s ASTimeRange=$P($G(^RBAS(ResRowId,ASChild,"DHC")),"^",17)
		
		if ($G(RegCountAry(ASDate))=""){
			s RegCountAry(ASDate)=1
		}else{
			s RegCountAry(ASDate)=RegCountAry(ASDate)+1
		}
		
		if ($G(RegDocCountAry(ASDate,ASLoc,APPDoc))=""){
			s RegDocCountAry(ASDate,ASLoc,APPDoc)=1
		}else{
			s RegDocCountAry(ASDate,ASLoc,APPDoc)=RegDocCountAry(ASDate,ASLoc,APPDoc)+1
		}
		
		if ($G(RegLocCountAry(ASDate,ASLoc))=""){
			s RegLocCountAry(ASDate,ASLoc)=1
		}else{
			s RegLocCountAry(ASDate,ASLoc)=RegLocCountAry(ASDate,ASLoc)+1
		}
		
		if ($G(RegTimeDocLocAry(ASDate,ASLoc,ASRowID,ASTimeRange))=""){
			s RegTimeDocLocAry(ASDate,ASLoc,ASRowID,ASTimeRange)=1
		}else{
			s RegTimeDocLocAry(ASDate,ASLoc,ASRowID,ASTimeRange)=RegTimeDocLocAry(ASDate,ASLoc,ASRowID,ASTimeRange)+1
		}
		
		if ($g(ASArry(ASRowID))=""){
			s ASArry(ASRowID)=1
		}else{
			s ASArry(ASRowID)=ASArry(ASRowID)+1
		}
	}
	s rtn=""
	s ASRowId=""
	for {
		s ASRowId=$O(ASArry(ASRowId))
		q:ASRowId=""
		if HospitalID=""{
			i ($d(%session)){
				s HospitalID=##Class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospitalID)
			}else{
				s HospitalID=$p(..GetCurrentHosp("","",ASRowId,""),"^",1)	
			}
		}
		s ASNumber=ASArry(ASRowId)
		s AdmType="O"
		s obj=##class(User.RBApptSchedule).%OpenId(ASRowId)
		if $IsObject(obj){
			s AdmDate=obj.ASDate
			s AdmDep=obj.ASRESParRef.RESCTLOCDR.%Id()
			s AdmDoc=obj.ASRESParRef.RESCTPCPDR.%Id()
			s RegfeeTimeRangeDr=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",17)
			s AdmCountStr=##Class(web.DHCOPAdmReg).GetPADayAdmCount(PatientID,AdmType,AdmDate,AdmDep,AdmDoc,RegfeeTimeRangeDr)
			s AdmCount=$P(AdmCountStr,"^",1)
			s AdmDocCount=$P(AdmCountStr,"^",2)
			s AppLocCount=$P(AdmCountStr,"^",3)
			s AdmTimeLocDocCount=$P(AdmCountStr,"^",4)
			
			s AppCountStr=##Class(web.DHCOPAdmReg).GetPADayAppCount(PatientID,ASRowId,APPTRowId)
			s AppCount=$P(AppCountStr,"^",1)
			s AppDocCount=$P(AppCountStr,"^",2)
			s AdmLocCount=$P(AppCountStr,"^",3)
			s AppTimeLocDocCount=$P(AppCountStr,"^",4)
			
			s DayRegCountLimit=##class(web.DHCOPRegConfig).GetSpecConfigNode("DayRegCountLimit",HospitalID)
			s DaySameDocRegCountLimit=##class(web.DHCOPRegConfig).GetSpecConfigNode("DaySameDocRegCountLimit",HospitalID)
			s DaySameLocRegCountLimit=##class(web.DHCOPRegConfig).GetSpecConfigNode("DaySameLocRegCountLimit",HospitalID)
			s LocRegLimitConfig=+$p(##class(web.DHCOPRegConfig).GetConfigNode1("OPRegDepExpand",AdmDep),"^",3)
			s TimeLocDocCountLimit=##class(web.DHCOPRegConfig).GetSpecConfigNode("DaySameTimeRegLimit",HospitalID)
			s AdmDepDesc=$p($g(^CTLOC(AdmDep)),"^",2)  
			s AdmDocDesc=$p($g(^CTPCP(AdmDoc,1)),"^",2)
            s:$g(AdmDepDesc)'="" AdmDepDesc = ##class(User.CTLoc).GetTranByDesc("CTLOCDesc",AdmDepDesc,langid)
			s:$g(AdmDocDesc)'="" AdmDocDesc = ##class(User.CTCareProv).GetTranByDesc("CTPCPDesc",AdmDocDesc,langid)
			b ;超过每天挂号限额
			if ((AdmCount+AppCount+$G(RegCountAry(AdmDate)))>DayRegCountLimit)&&(DayRegCountLimit'=0) {
                s rtn = "-301^"_..%Translate("opadm.reg.hui.csp","挂号记录科室",langid)_":【"_AdmDepDesc_"】,"_..%Translate("opadm.reg.hui.csp","号别",langid)
				s rtn = rtn_":【"_AdmDocDesc_"】,"_..%Translate("opadm.reg.hui.csp","就诊日期",langid)_":【"_..%ZD(AdmDate)_"】,"
				;s rtn = rtn_..%Translate("opadm.reg.hui.csp","超过每人每天可挂号限额!不能进行挂号和预约.",langid)
				s rtn = rtn_..%Translate("opadm.reg.hui.csp","每人每天限挂",langid)_"【"_DayRegCountLimit_"】"_..%Translate("opadm.reg.hui.csp","个号!",langid)
			}
			if ((AdmDocCount+AppDocCount+$G(RegDocCountAry(AdmDate,AdmDep,AdmDoc)))>DaySameDocRegCountLimit)&&(DaySameDocRegCountLimit'=0){
                s rtn = "-302^"_..%Translate("opadm.reg.hui.csp","挂号记录科室",langid)_":【"_AdmDepDesc_"】,"_..%Translate("opadm.reg.hui.csp","号别",langid)
				s rtn = rtn_":【"_AdmDocDesc_"】,"_..%Translate("opadm.reg.hui.csp","就诊日期",langid)_":【"_..%ZD(AdmDate)_"】,"
				;s rtn = rtn_..%Translate("opadm.reg.hui.csp","超过每人每天可挂相同号的限额!",langid)
				s rtn = rtn_..%Translate("opadm.reg.hui.csp","每人每天相同医生号限挂",langid)_"【"_DaySameDocRegCountLimit_"】"_..%Translate("opadm.reg.hui.csp","个号!",langid)
			}
			if (LocRegLimitConfig=1)&&((AdmLocCount+AppLocCount+$G(RegLocCountAry(AdmDate,AdmDep)))>DaySameLocRegCountLimit)&&(DaySameLocRegCountLimit'=0){
            	s rtn = "-303^"_..%Translate("opadm.reg.hui.csp","挂号记录科室",langid)_":【"_AdmDepDesc_"】,"_..%Translate("opadm.reg.hui.csp","号别",langid)
				s rtn = rtn_":【"_AdmDocDesc_"】,"_..%Translate("opadm.reg.hui.csp","就诊日期",langid)_":【"_..%ZD(AdmDate)_"】,"
				;s rtn = rtn_..%Translate("opadm.reg.hui.csp","超过每人每天可挂相同科室号的限额!",langid)
				s rtn = rtn_..%Translate("opadm.reg.hui.csp","每人每天相同科室号限挂",langid)_"【"_DaySameLocRegCountLimit_"】"_..%Translate("opadm.reg.hui.csp","个号!",langid)
			}
			if ('$d(^DHCOPRegConfig("DaySameTimeRegLimit",RegfeeTimeRangeDr,AdmDep,AdmDoc)))&&((AdmTimeLocDocCount+AppTimeLocDocCount+$G(RegTimeDocLocAry(AdmDate,AdmDep,ASRowId,RegfeeTimeRangeDr)))>TimeLocDocCountLimit)&&(TimeLocDocCountLimit'=0){
                s rtn = "-304^"_..%Translate("opadm.reg.hui.csp","挂号记录科室",langid)_":【"_AdmDepDesc_"】,"_..%Translate("opadm.reg.hui.csp","号别",langid)
				s rtn = rtn_":【"_AdmDocDesc_"】,"_..%Translate("opadm.reg.hui.csp","就诊日期",langid)_":【"_..%ZD(AdmDate)_"】,"
				;s rtn = rtn_..%Translate("opadm.reg.hui.csp","超过每人每天相同时段同科室同医生限额!",langid)
				s rtn = rtn_..%Translate("opadm.reg.hui.csp","每人每天同时段同科室医生号限挂",langid)_"【"_TimeLocDocCountLimit_"】"_..%Translate("opadm.reg.hui.csp","个号!",langid)
			}

		}
		q:rtn'=""
	}
	Q rtn
}

ClassMethod GetDefaultSortType(ASRowID, LastQueue)
{
	q:ASRowID="" 00000000
	Set DeptDr=$p(^RB("RES",+ASRowID),"^",1)
	s HospitalID=$p($g(^CTLOC(DeptDr)),"^",22)
	s SessionTypeSortCheck=##class(web.DHCOPRegConfig).GetSpecConfigNode("SessionTypeSortCheck",HospitalID)
	s SessionTypeSort="9999"
	if (SessionTypeSortCheck=1){
		s SessionTypeSortType=##class(web.DHCOPRegConfig).GetSpecConfigNode("SessionTypeSort",HospitalID)
		s SessionTypeDr=$P($G(^RBAS(+ASRowID,$P(ASRowID,"||",2),"DHC")),"^",6)
		s SessionTypelist=##class(web.DHCBL.BDP.BDPSort).GetSortNum("User.RBCSessionType",SessionTypeSortType,SessionTypeDr)
		if (SessionTypelist="") s SessionTypelist=9999
		s SessionTypeSort=$E("0000",1,4-$L(SessionTypelist))_SessionTypelist
	}
	s LastQueueNoSortCheck=##class(web.DHCOPRegConfig).GetSpecConfigNode("LastQueueNoSortCheck",HospitalID)
	s ClinicGroupStr=$P($G(^RBAS(+ASRowID,$P(ASRowID,"||",2),"DHC")),"^",29)
	if ($l(ClinicGroupStr,",")>2) s LastQueue=999
	s LastQueueNoSort="9999"
	if (LastQueueNoSortCheck=1){
		s LastQueueNoSort=9999-LastQueue
	}
	s rtn=SessionTypeSort_LastQueueNoSort
	q rtn
}

/// 根据出诊级别配置，插入缴费医嘱和诊断
ClassMethod InsertPreOrderAndDiag(ASRowId, EpisodeID, UserID, HospId)
{
	s SessionTypeRowId=$P($G(^RBAS(+ASRowId,$P(ASRowId,"||",2),"DHC")),"^",6)
	i SessionTypeRowId'="" {
		s Child=0
		s ArcimStr=""
		for {
			s Child=$O(^RBC("SESS",SessionTypeRowId,"SER",Child)) 
			q:(Child="")
			s HospDr=$p($G(^RBC("SESS",SessionTypeRowId,"SER",Child)),"^",2)
			continue:(HospDr'="")&&(HospDr'=HospId)
			s SESSType=$p(^RBC("SESS",SessionTypeRowId,"SER",Child),"^",3)
			if (SESSType="OrderDiag"){
				s AdmDep=$P(^PAADM(EpisodeID),"^",4)
				s mrrowid=$p($G(^PAADM(EpisodeID)),"^",61)
				s ICDRowID=$p(^RBC("SESS",SessionTypeRowId,"SER",Child),"^",4)
				s AdmDoc=$P(^PAADM(EpisodeID),"^",9)
				s AdmUserID=$O(^SSU("SSUSR",0,"CTPCP",AdmDoc,"0"))
				if AdmUserID=""  s AdmUserID=UserID
				s MRDIAID=##class(web.DHCMRDiagnos).InsertMRDiagnos(AdmDep,mrrowid,ICDRowID,AdmUserID,"","门诊诊断","","","","","",3,"",AdmUserID,"","","","","O")
				if ($P(MRDIAID,"^",1)=0){
					s MRDIAID=$P(MRDIAID,"^",2)
					s Rtn=##class(web.DHCMRDiagnos).UpdateOnsetDate(MRDIAID,$ZD(+$H,3))
					set NewDataJson=##class(web.DHCDocDataChangeLog).GetLogJsonData("User.MRDiagnos"_$c(2)_MRDIAID)
	 				set ret=##class(web.DHCDocDataChangeLog).SaveLog("MR_Diagnos","User.MRDiagnos","诊断信息","User.MRDiagnos_"_MRDIAID,MRDIAID,"A",NewDataJson,"",UserID)
				}
			}
			if (SESSType="OrderPre"){
				s ArcimId=$p($G(^RBC("SESS",SessionTypeRowId,"SER",Child)),"^",1)
				continue:##class(DHCDoc.Common.Hospital).GetHospShowDataFlag("ARC_ItmMast",ArcimId,HospId)="N"
				if (ArcimStr="") {s ArcimStr=ArcimId}else{s ArcimStr=ArcimStr_"^"_ArcimId} 
				}
			}
		s ASQSub=""
		for{
			s ASQSub=$O(^RBAS(+ASRowId,$P(ASRowId,"||",2),"AQEC",ASQSub)) 
			Q:ASQSub=""
			s TemplateConfigID=$P(^RBAS(+ASRowId,$P(ASRowId,"||",2),"AQEC",ASQSub),"^",1)
			continue:TemplateConfigID=""
			s Value=$P(^RBAS(+ASRowId,$P(ASRowId,"||",2),"AQEC",ASQSub),"^",2)
			continue:((Value="")||(Value="false"))
			s Type=$p($g(^DHCSCHEDULETEMPCON(TemplateConfigID)),"^",3)
			s STCCode=$p($g(^DHCSCHEDULETEMPCON(TemplateConfigID)),"^",1)
			s STCActive=$p(^DHCSCHEDULETEMPCON(TemplateConfigID),"^",7)
		    continue:STCActive'="Y"
		    if (Type="Diag"){
			    s AdmDep=$P(^PAADM(EpisodeID),"^",4)
				s mrrowid=$p($G(^PAADM(EpisodeID)),"^",61)
				s ICDRowID=$p(^DHCSCHEDULETEMPCON(TemplateConfigID),"^",12)
				s AdmDoc=$P(^PAADM(EpisodeID),"^",9)
				s AdmUserID=$O(^SSU("SSUSR",0,"CTPCP",AdmDoc,"0"))
				if AdmUserID=""  s AdmUserID=UserID
				s MRDIAID=##class(web.DHCMRDiagnos).InsertMRDiagnos(AdmDep,mrrowid,ICDRowID,AdmUserID,"","门诊诊断","","","","","",3,"",AdmUserID,"","","","","O")
				if ($P(MRDIAID,"^",1)=0){
					s MRDIAID=$P(MRDIAID,"^",2)
					s Rtn=##class(web.DHCMRDiagnos).UpdateOnsetDate(MRDIAID,$ZD(+$H,3))
					set NewDataJson=##class(web.DHCDocDataChangeLog).GetLogJsonData("User.MRDiagnos"_$c(2)_MRDIAID)
	 				set ret=##class(web.DHCDocDataChangeLog).SaveLog("MR_Diagnos","User.MRDiagnos","诊断信息","User.MRDiagnos_"_MRDIAID,MRDIAID,"A",NewDataJson,"",UserID)
				}
			}
			if (Type="Order"){
				s ArcimId=$p(^DHCSCHEDULETEMPCON(TemplateConfigID),"^",11)
				continue:##class(DHCDoc.Common.Hospital).GetHospShowDataFlag("ARC_ItmMast",ArcimId,HospId)="N"
				if (ArcimStr="") {s ArcimStr=ArcimId}else{s ArcimStr=ArcimStr_"^"_ArcimId} 
				}
		}
		if (ArcimStr'=""){
			s OrderItemStr=""
			s DocID=$P(^SSU("SSUSR",UserID),"^",14)
			s AdmDep=$P(^PAADM(EpisodeID),"^",4)
			For Arcimi = 1:1:$L(ArcimStr,"^") {
				s OrderARCIMRowid =$P(ArcimStr,"^",Arcimi)
				s OrderPackQty=1
				s ItemCatDr=$P(^ARCIM(+OrderARCIMRowid,$P(OrderARCIMRowid,"||",2),1),"^",10) 
				s OrderType=$P(^ARC("IC",ItemCatDr),"^",7)
				s OrderPriorRowid=3
				s OrderStartDate=$zd($h,3)
				s OrderStartTime=$zt($P($h,",",2))
				s OrderPrice=""
				s GetLocRecLocStr=##class(web.DHCDocOrderCommon).GetLocRecLoc(AdmDep,OrderARCIMRowid)
				s OrderRecDepRowid="" //接收科室id赋初值，防止变量污染
				if (GetLocRecLocStr'=""){
					s OrderRecDepRowid=$P(GetLocRecLocStr,$c(1),1)
					s Len1=$l(GetLocRecLocStr,$c(2))
					for j=1:1:Len1{
						s OneLocRecStr=$P(GetLocRecLocStr,$C(2),j)
						s Defultflag=$p(OneLocRecStr,$C(1),3)
						if (Defultflag="Y"){
							s OrderRecDepRowid=$P(OneLocRecStr,$c(1),1)
						}
					}
				}
				continue:OrderRecDepRowid=""
				s PatientID=$P(^PAADM(EpisodeID),"^",1)
				s PatCatDr=$p(^PAPER(PatientID,"PER",1),"^",10)
				s AdmReason=$P(^PAADM(EpisodeID,1),"^",7)
				s BillTypeRowid=AdmReason
				s DrgformRowid=##class(web.DHCDocOrderEntry).GetDrgForm(OrderARCIMRowid)
				s OrderDrugFormRowid="",OrderDoseQty="",OrderDoseUOMRowid="",OrderFreqRowid="",OrderDurRowid=""
				s PHPrescType=""
				s OrderQtySum=OrderPackQty
				s OrderInstrRowid=""
				s OrderDepProcNotes=""
				s OrderMasterSeqNo=""
				Set ord=$o(^OEORD(0,"Adm",EpisodeID,""))
				s OrderSeqNo=$$GetSeqNo^DHCDocOrderCommonNew(ord,+$h)+Arcimi
				s OrderSkinTest="N"
				s OrderPhSpecInstr=""
				s OrderCoverMainIns=""
				s OrderActionRowid=""
				s OrderARCOSRowid=""
				s OrderEndDate=""
				s OrderEndTime=""
				s OrderLabSpecRowid=""
				if (OrderLabSpecRowid=""){
					s mListData=##class(web.DHCDocOrderCommon).GetLabSpec(OrderARCIMRowid)
					s Len = $L(mListData,$C(2))
					f i=1:1:Len d
					.s ListData = $p(mListData,$C(2),i)
					.Q:ListData=""
					.s ID = $p(ListData,$C(3),1)     	/// 标本代码
					.s Desc = $p(ListData,$C(3),2)      /// 标本描述
					.s Default = $p(ListData,$C(3),5)
					.s HavFlag=1
					.Q:(Default'="Y")
					.s OrderLabSpecRowid=ID
				}
				s OrderDurRowid=""
				s OrderItem=OrderARCIMRowid_"^"_OrderType_"^"_OrderPriorRowid_"^"_OrderStartDate_"^"_OrderStartTime_"^"_OrderPackQty_"^"_OrderPrice
				s OrderItem=OrderItem_"^"_OrderRecDepRowid_"^"_BillTypeRowid_"^"_OrderDrugFormRowid_"^"_OrderDepProcNotes
				s OrderItem=OrderItem_"^"_OrderDoseQty_"^"_OrderDoseUOMRowid_"^"_OrderQtySum_"^"_OrderFreqRowid_"^"_OrderDurRowid_"^"_OrderInstrRowid
				s OrderItem=OrderItem_"^"_PHPrescType_"^"_OrderMasterSeqNo_"^"_OrderSeqNo_"^"_OrderSkinTest_"^"_OrderPhSpecInstr_"^"_OrderCoverMainIns
				s OrderItem=OrderItem_"^"_OrderActionRowid_"^"_OrderARCOSRowid_"^"_OrderEndDate_"^"_OrderEndTime_"^"_OrderLabSpecRowid
				s $p(OrderItem,"^",58)="RPO"
				if (OrderItemStr="") s OrderItemStr=OrderItem 
				else  s OrderItemStr=OrderItemStr_$C(1)_OrderItem 
			}
			if (OrderItemStr'=""){
				s rtn=##class(web.DHCOEOrdItem).SaveOrderItems(EpisodeID,OrderItemStr,UserID,AdmDep,DocID)
			}	
			//如果插入医嘱失败观察是否和未维护默认接收科室有关
		}
	}
	q 0
}

/// /通过患者ID获取登记号
ClassMethod GetPatNoByID(PAPMIDR)
{
	q:PAPMIDR="" ""
	
	s PatNo=$p($G(^PAPER(PAPMIDR,"PAT",1)),"^",2) //登记号	
	q PatNo
}

/// 获取被合并后的登记号
ClassMethod GetUnitedRegNo(PatientID)
{
	q:PatientID="" ""
	s UnitRegNo=""
	s NewPatientID=$O(^User.DHCPATCardUniteLogI("OldNewPAPMI"," 1"," "_PatientID,""))
	if NewPatientID'="" {
		 s NewPatientID=$P(NewPatientID," ",2)
		 s UnitRegNo=$P($g(^PAPER(NewPatientID,"PAT",1)),"^",1)
	}
	q UnitRegNo
}

ClassMethod GetAdmReasonDr(EpisodeID As %String)
{
	Q:EpisodeID="" ""
	Set langid=..%LanguageID()
	s PAADMAdmReasonDR=$p(^PAADM(EpisodeID,1),"^",7)
	Q:PAADMAdmReasonDR="" ""
	s AdmReason=$p(^PAC("ADMREA",PAADMAdmReasonDR),"^",2)
	s AdmReason=##class(User.PACAdmReason).GetTranByDesc("READesc",AdmReason,langid)
	Q PAADMAdmReasonDR
}

}
